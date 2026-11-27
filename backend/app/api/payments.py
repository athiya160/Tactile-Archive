import os
import uuid
import hmac
import hashlib
import json
import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, Request
from pydantic import BaseModel
from sqlalchemy.orm import Session
import razorpay
from app.api.auth import get_current_user, get_db
from app.models.user import User
from app.models.order import Order, OrderItem, PurchaseOrder, RentalOrder
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.models.payment import Payment
from app.api.notifications import send_notification
from app.core.mail import send_order_confirmation_email, send_book_purchase_email, send_book_sold_email
from app.services.inventory_service import (
    claim_order_inventory,
    claim_cod_inventory,
    create_reservation,
    mark_order_reconciliation_required,
    ARCHIVE_FEE_PAISE,
    SHIPPING_FEE_PAISE
)

logger = logging.getLogger("app.api.payments")
router = APIRouter(prefix="/payments")

# Razorpay client instance (lazily initialized, credentials loaded strictly from environment)
client = None

def get_razorpay_client():
    global client
    key_id = os.getenv("RAZORPAY_KEY_ID")
    key_secret = os.getenv("RAZORPAY_KEY_SECRET")
    if not key_id or not key_secret:
        logger.error("[RAZORPAY] RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET environment variable is missing")
        return None
    if client is None:
        try:
            client = razorpay.Client(auth=(key_id, key_secret))
            logger.info("[RAZORPAY] Razorpay client initialized in test mode.")
        except Exception as e:
            logger.error(f"[RAZORPAY] Failed to initialize client: {e}")
            return None
    return client

class CheckoutRequest(BaseModel):
    payment_method: str
    shipping_address: str
    mode: Optional[str] = "cart"
    book_id: Optional[int] = None
    rental_days: Optional[int] = 14

class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str

@router.post("/create-order")
def create_payment_order(req: CheckoutRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(get_current_user)):

    total_qty = 0
    total_price = 0.0
    items_to_snapshot = []
    
    if req.mode == "cart":
        # 1. Calculate total from cart
        cart = db.query(Cart).filter(Cart.user_id == user.id).first()
        if not cart or not cart.items:
            raise HTTPException(status_code=400, detail="Cart is empty")

        total_qty = sum(item.quantity for item in cart.items)
        for item in cart.items:
            book = db.query(Book).filter(Book.id == item.book_id).first()
            if not book: continue
            qty = item.quantity or 1
            if item.is_purchase:
                total_price += (book.price or 0.0) * qty
                items_to_snapshot.append({"book": book, "is_purchase": True, "qty": qty, "rental_days": 14})
            else:
                days = item.rental_days or 14
                total_price += (book.price or 0.0) * 0.15 * (days / 14.0) * qty
                items_to_snapshot.append({"book": book, "is_purchase": False, "qty": qty, "rental_days": days})
                
    elif req.mode in ["purchase", "rental", "buy", "rent"]:
        if not req.book_id:
            raise HTTPException(status_code=400, detail="book_id is required for direct purchase or rental")
        book = db.query(Book).filter(Book.id == req.book_id).first()
        if not book:
            raise HTTPException(status_code=404, detail="Book not found")
            
        total_qty = 1
        is_purchase = req.mode in ["purchase", "buy"]
        if is_purchase:
            total_price = book.price or 0.0
            items_to_snapshot.append({"book": book, "is_purchase": True, "qty": 1, "rental_days": 14})
        else:
            days = req.rental_days or 14
            total_price = (book.price or 0.0) * 0.15 * (days / 14.0)
            items_to_snapshot.append({"book": book, "is_purchase": False, "qty": 1, "rental_days": days})
    else:
        raise HTTPException(status_code=400, detail="Invalid mode")

    if total_price <= 0:
        raise HTTPException(status_code=400, detail="Invalid total amount")

    total_paise = int(round(total_price * 100))
    # 2. Create internal pending Order with additive pricing fields
    order = Order(
        user_id=user.id,
        status="pending",
        total_items=total_qty,
        total_amount=total_price,
        items_total_paise=total_paise,
        platform_fee_paise=ARCHIVE_FEE_PAISE,
        shipping_fee_paise=SHIPPING_FEE_PAISE,
        total_amount_paise=total_paise,
        delivery_address=req.shipping_address,
        payment_method=req.payment_method,
        payment_status="pending"
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # Move items to OrderItem snapshots
    for snapshot in items_to_snapshot:
        book = snapshot["book"]
        qty = snapshot["qty"]
        is_purchase = snapshot["is_purchase"]
        days = snapshot["rental_days"]
        
        if is_purchase:
            item_price = (book.price or 0.0) * qty
        else:
            item_price = (book.price or 0.0) * 0.15 * (days / 14.0) * qty
            
        order_item = OrderItem(
            order_id=order.id,
            book_id=book.id,
            book_title=book.title,
            book_author=book.author,
            book_image=book.image_url,
            is_purchase=is_purchase,
            transaction_type="buy" if is_purchase else "rent",
            rental_days=days,
            quantity=qty,
            price=item_price,
            unit_price_paise=int(round((book.price or 0.0) * 100)) if is_purchase else None,
            rental_fee_paise=int(round(item_price * 100)) if not is_purchase else None,
            total_item_paise=int(round(item_price * 100)),
            status="pending"
        )
        db.add(order_item)
    db.commit()

    # Create inventory reservation for online buy orders (holding stock for 15 mins)
    if req.payment_method != "cod":
        for snapshot in items_to_snapshot:
            if snapshot.get("is_purchase"):
                create_reservation(db, snapshot["book"].id, order.id, user.id, snapshot.get("qty", 1))
        db.commit()

    # 3. Cash on Delivery handling (no Razorpay payment gateway needed)
    if req.payment_method == "cod":
        cod_claim = claim_cod_inventory(db, items_to_snapshot)
        if not cod_claim.success:
            order.status = "failed"
            order.payment_status = "failed"
            db.commit()
            raise HTTPException(status_code=400, detail=f"Cannot place COD order: {cod_claim.reason}")

        order.payment_status = "cod_pending"
        order.status = "placed"
        order.stock_deducted = True
        
        for snapshot in items_to_snapshot:
            b = snapshot["book"]
            q = snapshot["qty"]
            is_p = snapshot["is_purchase"]
            d = snapshot["rental_days"]
            if is_p:
                po = PurchaseOrder(
                    user_id=user.id,
                    book_id=b.id,
                    order_id=order.id,
                    price=(b.price or 0.0) * q,
                    payment_method="cod",
                    shipping_address=order.delivery_address,
                    status="completed"
                )
                db.add(po)
                if b.owner_id:
                    owner = db.query(User).filter(User.id == b.owner_id).first()
                    if owner and owner.email:
                        background_tasks.add_task(send_book_sold_email, owner.email, b.title, (b.price or 0.0) * q, user.name or "A reader")
            else:
                ro = RentalOrder(
                    user_id=user.id,
                    book_id=b.id,
                    rental_days=d,
                    rental_fee=(b.price or 0.0) * 0.15 * (d / 14.0) * q,
                    payment_method="cod",
                    shipping_address=order.delivery_address,
                    status="active"
                )
                db.add(ro)

        if req.mode == "cart":
            db.query(CartItem).filter(CartItem.cart.has(user_id=user.id)).delete()

        send_notification(db, user.id, "Order Confirmed", f"Your Cash on Delivery order #{order.id} was placed successfully.")
        if user.email:
            background_tasks.add_task(send_order_confirmation_email, user.email, order.total_items, order.total_amount)

        db.commit()
        return {
            "success": True,
            "is_cod": True,
            "order_id": order.id,
            "message": "Order placed successfully via Cash on Delivery."
        }

    # 4. Create Online Razorpay Order
    rzp = get_razorpay_client()
    if not rzp:
        raise HTTPException(status_code=500, detail="Payment gateway is not configured")

    amount_in_paise = int(total_price * 100)
    data = {
        "amount": amount_in_paise,
        "currency": "INR",
        "receipt": f"receipt_order_{order.id}",
        "notes": {
            "internal_order_id": str(order.id),
            "user_email": user.email
        }
    }
    
    try:
        rzp_order = rzp.order.create(data=data)
    except Exception as e:
        logger.error(f"Razorpay order creation failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to initiate payment")

    # 5. Save Payment record
    payment = Payment(
        order_id=order.id,
        user_id=user.id,
        razorpay_order_id=rzp_order['id'],
        amount=total_price,
        currency="INR",
        status="pending"
    )
    db.add(payment)
    db.commit()

    return {
        "is_cod": False,
        "razorpay_order_id": rzp_order['id'],
        "amount": amount_in_paise,
        "currency": "INR",
        "key_id": os.getenv("RAZORPAY_KEY_ID", "")
    }

@router.post("/verify")
def verify_payment(req: VerifyPaymentRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    rzp = get_razorpay_client()
    if not rzp:
        raise HTTPException(status_code=500, detail="Payment gateway is not configured")

    payment = db.query(Payment).filter(Payment.razorpay_order_id == req.razorpay_order_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment record not found")
        
    if payment.status == "paid":
        return {"message": "Payment already verified successfully."}

    # Verify Signature
    try:
        rzp.utility.verify_payment_signature({
            'razorpay_order_id': req.razorpay_order_id,
            'razorpay_payment_id': req.razorpay_payment_id,
            'razorpay_signature': req.razorpay_signature
        })
    except razorpay.errors.SignatureVerificationError:
        logger.error(f"Signature verification failed for order {req.razorpay_order_id}")
        payment.status = "failed"
        order = db.query(Order).filter(Order.id == payment.order_id).first()
        if order:
            order.payment_status = "failed"
            order.status = "failed"
        db.commit()
        raise HTTPException(status_code=400, detail="Invalid payment signature")

    payment.razorpay_payment_id = req.razorpay_payment_id
    payment.razorpay_signature = req.razorpay_signature
    payment.status = "paid"
    
    order = db.query(Order).filter(Order.id == payment.order_id).first()
    if order:
        # Atomic inventory claim check
        claim_result = claim_order_inventory(db, order)
        if not claim_result.success:
            mark_order_reconciliation_required(db, order, payment, claim_result.reason)
            return {
                "success": False,
                "reconciliation": True,
                "status": "reconciliation_required",
                "payment_status": "refund_pending",
                "message": f"Payment captured, but item is out of stock ({claim_result.reason}). A refund is pending.",
                "order_id": order.id,
                "payment_id": payment.razorpay_payment_id
            }

        order.payment_status = "paid"
        order.status = "processing"
        
        # Now generate the specific Purchase/Rental orders and clear cart
        for item in order.items:
            if item.is_purchase:
                po = PurchaseOrder(
                    user_id=user.id,
                    book_id=item.book_id,
                    order_id=order.id,
                    price=item.price,
                    payment_method=order.payment_method,
                    shipping_address=order.delivery_address,
                    status="completed"
                )
                db.add(po)
                book = db.query(Book).filter(Book.id == item.book_id).first()
                if book:
                    owner = db.query(User).filter(User.id == book.owner_id).first()
                    if owner and owner.email:
                        background_tasks.add_task(send_book_sold_email, owner.email, book.title, item.price, user.name or "A reader")
            else:
                ro = RentalOrder(
                    user_id=user.id,
                    book_id=item.book_id,
                    rental_days=item.rental_days,
                    rental_fee=item.price,
                    payment_method=order.payment_method,
                    shipping_address=order.delivery_address,
                    status="active"
                )
                db.add(ro)
                
        # Clear the cart
        db.query(CartItem).filter(CartItem.cart.has(user_id=user.id)).delete()
        
        send_notification(db, user.id, "Order Confirmed", f"Your payment for order #{order.id} was successful.")
        background_tasks.add_task(send_order_confirmation_email, user.email, order.total_items, order.total_amount)

    db.commit()
    return {"message": "Payment verified successfully", "order_id": order.id if order else None}

@router.post("/webhook")
async def razorpay_webhook(request: Request, db: Session = Depends(get_db)):
    """
    Webhook endpoint for Razorpay payment events with idempotency protection,
    signature verification, refund handling, and automatic provider escrow credit.
    """
    webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET")
    if not webhook_secret:
        logger.warning("[WEBHOOK] RAZORPAY_WEBHOOK_SECRET not configured, skipping signature check in dev.")
        
    webhook_signature = request.headers.get("X-Razorpay-Signature")
    body = await request.body()
    body_str = body.decode("utf-8")

    if webhook_secret and webhook_signature and client:
        try:
            client.utility.verify_webhook_signature(body_str, webhook_signature, webhook_secret)
        except Exception as e:
            logger.error(f"[WEBHOOK] Invalid webhook signature: {e}")
            raise HTTPException(status_code=400, detail="Invalid signature")

    try:
        data = json.loads(body_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON payload")

    event = data.get("event")
    logger.info(f"[WEBHOOK] Received payment event: {event}")

    # 1. Payment Captured / Succeeded
    if event in ["payment.captured", "order.paid"]:
        payload = data.get("payload", {}).get("payment", {}).get("entity", {})
        razorpay_order_id = payload.get("order_id")
        payment_id = payload.get("id")

        if razorpay_order_id:
            payment = db.query(Payment).filter(Payment.razorpay_order_id == razorpay_order_id).first()
            if payment and payment.status != "paid":
                # Idempotency guard: update only once
                payment.status = "paid"
                payment.razorpay_payment_id = payment_id

                order = db.query(Order).filter(Order.id == payment.order_id).first()
                if order and order.payment_status != "paid":
                    order.payment_status = "paid"
                    order.status = "processing"
                    
                    # Clear user's active cart
                    db.query(CartItem).filter(CartItem.cart.has(user_id=order.user_id)).delete()
                    
                    # Notify customer
                    send_notification(
                        db,
                        order.user_id,
                        "Payment Confirmed ✅",
                        f"Your payment of ₹{order.total_amount:.2f} for Order #{order.id} was successfully processed."
                    )
                db.commit()

    # 2. Payment Failed / Cancelled
    elif event in ["payment.failed", "payment.cancelled"]:
        payload = data.get("payload", {}).get("payment", {}).get("entity", {})
        razorpay_order_id = payload.get("order_id")

        if razorpay_order_id:
            payment = db.query(Payment).filter(Payment.razorpay_order_id == razorpay_order_id).first()
            if payment and payment.status != "failed":
                payment.status = "failed"
                order = db.query(Order).filter(Order.id == payment.order_id).first()
                if order:
                    order.payment_status = "failed"
                    order.status = "failed"
                    send_notification(
                        db,
                        order.user_id,
                        "Payment Incomplete ❌",
                        f"Payment for Order #{order.id} could not be completed. Please retry from your cart."
                    )
                db.commit()

    # 3. Refund Created / Processed
    elif event in ["refund.created", "refund.processed"]:
        payload = data.get("payload", {}).get("refund", {}).get("entity", {})
        payment_id = payload.get("payment_id")
        refund_amount = (payload.get("amount", 0)) / 100.0

        if payment_id:
            payment = db.query(Payment).filter(Payment.razorpay_payment_id == payment_id).first()
            if payment:
                payment.status = "refunded"
                order = db.query(Order).filter(Order.id == payment.order_id).first()
                if order:
                    order.payment_status = "refunded"
                    order.status = "refunded"
                    send_notification(
                        db,
                        order.user_id,
                        "Refund Processed 💳",
                        f"A refund of ₹{refund_amount:.2f} has been processed back to your original payment method."
                    )
                db.commit()

    return {"status": "ok", "event": event}
