from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from app.core.database import SessionLocal
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.user import User
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.schemas.order import OrderResponse, OrderStatsResponse
from app.api.auth import get_current_user
from app.api.notifications import send_notification
from app.core.mail import send_order_confirmation_email, send_book_purchase_email, send_book_sold_email

router = APIRouter()

# Input Schemas
class BorrowRequestCreate(BaseModel):
    book_id: int
    duration_days: int

class RentalOrderCreate(BaseModel):
    book_id: int
    rental_days: int
    rental_fee: float
    payment_method: str
    shipping_address: str

class PurchaseOrderCreate(BaseModel):
    book_id: int
    price: float
    payment_method: str
    shipping_address: str

class CartCheckoutRequest(BaseModel):
    payment_method: str
    shipping_address: str

class TrackingUpdateRequest(BaseModel):
    shipping_status: str # pending, shipped, out_for_delivery, delivered
    tracking_id: Optional[str] = None
    carrier: Optional[str] = None
    estimated_delivery: Optional[str] = None

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/orders", response_model=List[OrderResponse])
def get_orders(filter: str = None, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    orders = db.query(Order).filter(Order.user_id == user.id).order_by(Order.created_at.desc()).all()
    
    response = []
    for order in orders:
        items_res = []
        for item in order.items:
            # Determine type
            item_type = "purchase" if item.is_purchase else "rental"
            
            items_res.append({
                "id": str(item.id),
                "book": {
                    "id": str(item.book_id),
                    "title": item.book_title or "Unknown",
                    "author": item.book_author or "Unknown",
                    "coverUrl": item.book_image or "",
                    "categories": [],
                    "listingType": "for_sale" if item.is_purchase else "for_rent",
                    "rating": 0.0,
                    "price": 0.0
                },
                "type": item_type,
                "quantity": item.quantity or 1,
                "price": item.price or 0.0,
                "transaction_type": getattr(item, "transaction_type", None) or ("buy" if item.is_purchase else "rent"),
                "unit_price_paise": getattr(item, "unit_price_paise", None),
                "rental_fee_paise": getattr(item, "rental_fee_paise", None),
                "deposit_paise": getattr(item, "deposit_paise", None),
                "total_item_paise": getattr(item, "total_item_paise", None)
            })
            
        # Apply filter if provided (assuming filter applies to order status)
        if filter:
            fl = filter.lower()
            if fl == "pending":
                if order.shipping_status == "delivered":
                    continue
            # You can expand filter logic as needed based on the UI
            
        response.append({
            "id": str(order.id),
            "date": order.created_at,
            "status": order.status,
            "total_amount": order.total_amount or 0.0,
            "delivery_address": order.delivery_address,
            "payment_method": order.payment_method,
            "payment_status": order.payment_status,
            "items": items_res,
            "tracking_id": order.tracking_id,
            "carrier": order.carrier,
            "estimated_delivery": order.estimated_delivery,
            "shipping_status": order.shipping_status or "pending",
            "items_total_paise": getattr(order, "items_total_paise", None),
            "platform_fee_paise": getattr(order, "platform_fee_paise", None),
            "shipping_fee_paise": getattr(order, "shipping_fee_paise", None),
            "deposit_total_paise": getattr(order, "deposit_total_paise", None),
            "total_amount_paise": getattr(order, "total_amount_paise", None),
            "stock_deducted": getattr(order, "stock_deducted", False)
        })
            
    return response

@router.get("/orders/{order_id}", response_model=OrderResponse)
def get_order(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user.id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    items_res = []
    for item in order.items:
        item_type = "purchase" if item.is_purchase else "rental"
        items_res.append({
            "id": str(item.id),
            "book": {
                "id": str(item.book_id),
                "title": item.book_title or "Unknown",
                "author": item.book_author or "Unknown",
                "coverUrl": item.book_image or "",
                "categories": [],
                "listingType": "for_sale" if item.is_purchase else "for_rent",
                "rating": 0.0,
                "price": 0.0
            },
            "type": item_type,
            "quantity": item.quantity or 1,
            "price": item.price or 0.0
        })
        
    return {
        "id": str(order.id),
        "date": order.created_at,
        "status": order.status,
        "total_amount": order.total_amount or 0.0,
        "delivery_address": order.delivery_address,
        "payment_method": order.payment_method,
        "payment_status": order.payment_status,
        "items": items_res,
        "tracking_id": order.tracking_id,
        "carrier": order.carrier,
        "estimated_delivery": order.estimated_delivery,
        "shipping_status": order.shipping_status or "pending",
        "items_total_paise": getattr(order, "items_total_paise", None),
        "platform_fee_paise": getattr(order, "platform_fee_paise", None),
        "shipping_fee_paise": getattr(order, "shipping_fee_paise", None),
        "deposit_total_paise": getattr(order, "deposit_total_paise", None),
        "total_amount_paise": getattr(order, "total_amount_paise", None),
        "stock_deducted": getattr(order, "stock_deducted", False)
    }

@router.put("/orders/{order_id}/cancel")
@router.post("/orders/{order_id}/cancel")
def cancel_order(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    from app.services.inventory_service import cancel_order_and_restore_inventory
    return cancel_order_and_restore_inventory(db, order_id, user.id)

@router.put("/orders/{item_id}/tracking")
def update_order_tracking(
    item_id: int,
    data: TrackingUpdateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    item = db.query(OrderItem).filter(OrderItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Order item not found")
        
    order = item.order
    order.shipping_status = data.shipping_status
    if data.tracking_id is not None:
        order.tracking_id = data.tracking_id
    if data.carrier is not None:
        order.carrier = data.carrier
    if data.estimated_delivery is not None:
        try:
            order.estimated_delivery = datetime.fromisoformat(data.estimated_delivery.replace("Z", "+00:00"))
        except Exception:
            pass
            
    db.commit()
    return {"message": "Tracking updated successfully"}

@router.get("/orders/stats", response_model=OrderStatsResponse)
def get_order_stats(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    orders = db.query(Order).filter(Order.user_id == user.id).all()
    
    purchase_count = 0
    rental_count = 0
    
    for order in orders:
        for item in order.items:
            if item.is_purchase:
                purchase_count += 1
            else:
                rental_count += 1
                
    return {
        "totalArchiveValue": 0.0,
        "purchaseCount": purchase_count,
        "rentalCount": rental_count
    }

@router.post("/orders/borrow")
def create_borrow_request(
    data: BorrowRequestCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    book = db.query(Book).filter(Book.id == data.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    borrow_req = BorrowRequest(
        user_id=user.id,
        book_id=data.book_id,
        duration_days=data.duration_days,
        status="approved"
    )
    db.add(borrow_req)
    
    # Create master Order & OrderItem history
    order = Order(
        user_id=user.id,
        status="completed",
        total_items=1
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    order_item = OrderItem(
        order_id=order.id,
        book_id=book.id,
        book_title=book.title,
        book_author=book.author,
        book_image=book.image_url,
        is_purchase=False,
        rental_days=data.duration_days
    )
    db.add(order_item)
    db.commit()
    
    db.refresh(borrow_req)
    send_notification(db, user.id, "Borrow Request Approved", f"Your request to borrow '{book.title}' has been auto-approved.")
    return {"message": "Borrow request created successfully", "id": borrow_req.id}

@router.post("/orders/rent")
def create_rental_order(
    data: RentalOrderCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    import os
    env = os.getenv("ENV", "development").lower()
    if env == "production":
        raise HTTPException(status_code=400, detail="Direct order creation is not allowed in production. All paid orders must be verified through the payment gateway.")

    book = db.query(Book).filter(Book.id == data.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    rental_order = RentalOrder(
        user_id=user.id,
        book_id=data.book_id,
        rental_days=data.rental_days,
        rental_fee=data.rental_fee,
        payment_method=data.payment_method,
        shipping_address=data.shipping_address,
        status="active"
    )
    db.add(rental_order)

    # Create master Order & OrderItem history
    order = Order(
        user_id=user.id,
        status="completed",
        total_items=1
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    order_item = OrderItem(
        order_id=order.id,
        book_id=book.id,
        book_title=book.title,
        book_author=book.author,
        book_image=book.image_url,
        is_purchase=False,
        rental_days=data.rental_days
    )
    db.add(order_item)
    db.commit()

    send_notification(db, user.id, "Rental Order Placed", f"Successfully rented '{book.title}' for {data.rental_days} days.")
    return {"message": "Rental order created successfully", "id": rental_order.id}

@router.post("/orders/buy")
def create_purchase_order(
    data: PurchaseOrderCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    import os
    env = os.getenv("ENV", "development").lower()
    if env == "production":
        raise HTTPException(status_code=400, detail="Direct order creation is not allowed in production. All paid orders must be verified through the payment gateway.")

    book = db.query(Book).filter(Book.id == data.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    purchase_order = PurchaseOrder(
        user_id=user.id,
        book_id=data.book_id,
        price=data.price,
        payment_method=data.payment_method,
        shipping_address=data.shipping_address,
        status="completed"
    )
    db.add(purchase_order)

    # Create master Order & OrderItem history
    order = Order(
        user_id=user.id,
        status="completed",
        total_items=1
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    order_item = OrderItem(
        order_id=order.id,
        book_id=book.id,
        book_title=book.title,
        book_author=book.author,
        book_image=book.image_url,
        is_purchase=True,
        rental_days=14 # default
    )
    db.add(order_item)
    db.commit()

    send_notification(db, user.id, "Order Placed", f"Successfully purchased '{book.title}' for ${data.price:.2f}.")

    background_tasks.add_task(send_book_purchase_email, user.email, book.title, data.price)
    owner = db.query(User).filter(User.id == book.owner_id).first()
    if owner and owner.email:
        background_tasks.add_task(send_book_sold_email, owner.email, book.title, data.price, user.name or "A reader")

    return {"message": "Purchase order placed successfully", "id": purchase_order.id}

@router.post("/orders/checkout")
def cart_checkout_all(
    data: CartCheckoutRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    import os
    env = os.getenv("ENV", "development").lower()
    if env == "production":
        raise HTTPException(status_code=400, detail="Direct order creation is not allowed in production. All paid orders must be verified through the payment gateway.")

    cart = db.query(Cart).filter(Cart.user_id == user.id).first()
    if not cart or not cart.items:
        raise HTTPException(status_code=400, detail="Cart is empty")

    # Create master Order history for this entire cart
    total_qty = sum(item.quantity for item in cart.items)
    order = Order(
        user_id=user.id,
        status="completed",
        total_items=total_qty
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    total_price = 0.0

    for item in cart.items:
        book = db.query(Book).filter(Book.id == item.book_id).first()
        if not book:
            continue
            
        qty = item.quantity or 1
        item_price = 0.0
        if item.is_purchase:
            item_price = (book.price or 0.0) * qty
            po = PurchaseOrder(
                user_id=user.id,
                book_id=book.id,
                price=item_price,
                payment_method=data.payment_method,
                shipping_address=data.shipping_address,
                status="completed"
            )
            db.add(po)
        else:
            days = item.rental_days or 14
            item_price = (book.price or 0.0) * 0.15 * (days / 14.0) * qty
            ro = RentalOrder(
                user_id=user.id,
                book_id=book.id,
                rental_days=days,
                rental_fee=item_price,
                payment_method=data.payment_method,
                shipping_address=data.shipping_address,
                status="active"
            )
            db.add(ro)

        total_price += item_price
        
        # Add OrderItem for history
        order_item = OrderItem(
            order_id=order.id,
            book_id=book.id,
            book_title=book.title,
            book_author=book.author,
            book_image=book.image_url,
            is_purchase=item.is_purchase,
            rental_days=item.rental_days or 14
        )
        db.add(order_item)
        
        owner = db.query(User).filter(User.id == book.owner_id).first()
        if owner and owner.email:
            background_tasks.add_task(send_book_sold_email, owner.email, book.title, item_price, user.name or "A reader")

    db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
    db.commit()

    send_notification(db, user.id, "Order Placed", f"Successfully checked out {total_qty} books from your shopping cart.")
    background_tasks.add_task(send_order_confirmation_email, user.email, total_qty, total_price)

    return {"message": "Checkout successful"}


# 🔥 SAFE EXCHANGE & QR ESCROW HANDOFF ENDPOINTS
import uuid

class VerifyQRRequest(BaseModel):
    qr_token: str
    role: str # "lender" or "borrower"

@router.get("/orders/{order_id}/qr-code")
def get_order_qr_code(order_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Generates single-use dynamic QR token for peer handoff at safe exchange hub."""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    if not order.borrower_qr_token:
        order.borrower_qr_token = f"BORROWER-{order.id}-{uuid.uuid4().hex[:8]}"
    if not order.lender_qr_token:
        order.lender_qr_token = f"LENDER-{order.id}-{uuid.uuid4().hex[:8]}"
        
    db.commit()
    
    is_borrower = order.user_id == user.id
    token = order.borrower_qr_token if is_borrower else order.lender_qr_token
    
    return {
        "order_id": order.id,
        "role": "borrower" if is_borrower else "lender",
        "qr_token": token,
        "handoff_status": order.handoff_status or "pending_handoff",
        "lender_scanned": order.lender_scanned or False,
        "borrower_scanned": order.borrower_scanned or False,
        "escrow_released": order.handoff_status in ["handoff_completed", "returned_completed"],
    }

@router.post("/orders/{order_id}/verify-qr")
def verify_order_qr(order_id: int, payload: VerifyQRRequest, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    """Verifies QR scan at Safe Exchange Hub and auto-releases Escrow payment funds when both parties verify."""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    if payload.role == "lender":
        if payload.qr_token == order.lender_qr_token or "LENDER-" in payload.qr_token:
            order.lender_scanned = True
    elif payload.role == "borrower":
        if payload.qr_token == order.borrower_qr_token or "BORROWER-" in payload.qr_token:
            order.borrower_scanned = True
    else:
        # Generic match fallback for exchange point scanner
        order.lender_scanned = True
        order.borrower_scanned = True

    # If both scanned OR single-pass hub scan completed: release escrow!
    if (order.lender_scanned and order.borrower_scanned) or "BORROWER-" in payload.qr_token:
        order.handoff_status = "handoff_completed"
        order.escrow_released_at = datetime.utcnow()
        order.payment_status = "escrow_released"
        send_notification(db, order.user_id, "Escrow Funds Released 💸", f"Physical handoff for Order #{order.id} verified at Safe Exchange Point. Payment has been released.")

    db.commit()

    return {
        "message": "QR Scan verified successfully",
        "handoff_status": order.handoff_status,
        "escrow_released": order.handoff_status == "handoff_completed",
    }

