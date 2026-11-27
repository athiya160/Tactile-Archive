from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException

from app.models.book import Book
from app.models.order import Order, OrderItem
from app.models.payment import Payment
from app.models.inventory_reservation import InventoryReservation

# Verified Codebase Constants
ARCHIVE_FEE_PAISE = 120  # ₹1.20 archive/platform fee
SHIPPING_FEE_PAISE = 0   # ₹0.00 standard delivery fee
DEFAULT_RESERVATION_MINUTES = 15

@dataclass
class ClaimResult:
    success: bool
    reason: str = ""
    reconciliation: bool = False

def calculate_item_price_paise(price_in_rupees: float) -> int:
    """Safely converts a rupee float to integer paise."""
    return int(round((price_in_rupees or 0.0) * 100))

def calculate_buy_pricing_paise(items_tuples: List[Tuple[Book, int]]) -> Dict[str, int]:
    """
    Calculates integer paise breakdown for buy items:
    - items_total_paise: sum of unit_price_paise * quantity
    - platform_fee_paise: 120 paise (₹1.20)
    - shipping_fee_paise: 0 paise (₹0.00 Free Delivery)
    - deposit_total_paise: 0 paise
    - total_amount_paise: sum of all fees
    """
    items_total_paise = sum(calculate_item_price_paise(book.price) * qty for book, qty in items_tuples)
    platform_fee_paise = ARCHIVE_FEE_PAISE
    shipping_fee_paise = SHIPPING_FEE_PAISE
    deposit_total_paise = 0
    total_amount_paise = items_total_paise + platform_fee_paise + shipping_fee_paise + deposit_total_paise
    
    return {
        "items_total_paise": items_total_paise,
        "platform_fee_paise": platform_fee_paise,
        "shipping_fee_paise": shipping_fee_paise,
        "deposit_total_paise": deposit_total_paise,
        "total_amount_paise": total_amount_paise,
    }

# =========================================================================
# RESERVATION LIFECYCLE MANAGEMENT
# =========================================================================

def expire_stale_reservations(db: Session, now: Optional[datetime] = None) -> int:
    """
    Finds all active reservations that have exceeded their expiry timestamp
    and updates their status to 'expired'.
    """
    if now is None:
        now = datetime.utcnow()
        
    stale_reservations = db.query(InventoryReservation).filter(
        InventoryReservation.status == "active",
        InventoryReservation.expires_at <= now
    ).all()
    
    count = 0
    for res in stale_reservations:
        res.status = "expired"
        count += 1
        
    if count > 0:
        db.flush()
    return count

def get_active_reserved_quantity(db: Session, book_id: int, exclude_order_id: Optional[int] = None) -> int:
    """
    Calculates the total quantity currently locked in active, unexpired reservations
    for a given book.
    """
    now = datetime.utcnow()
    query = db.query(func.coalesce(func.sum(InventoryReservation.quantity), 0)).filter(
        InventoryReservation.book_id == book_id,
        InventoryReservation.status == "active",
        InventoryReservation.expires_at > now
    )
    if exclude_order_id is not None:
        query = query.filter(InventoryReservation.order_id != exclude_order_id)
        
    return int(query.scalar() or 0)

def get_available_stock(db: Session, book_id: int, exclude_order_id: Optional[int] = None) -> int:
    """
    Returns available physical stock minus active unexpired reservations.
    """
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        return 0
    reserved = get_active_reserved_quantity(db, book_id, exclude_order_id=exclude_order_id)
    return max(0, (book.stock or 0) - reserved)

def create_reservation(
    db: Session,
    book_id: int,
    order_id: int,
    user_id: int,
    quantity: int = 1,
    duration_minutes: int = DEFAULT_RESERVATION_MINUTES
) -> InventoryReservation:
    """
    Creates an active inventory reservation holding stock for a checkout session.
    """
    expire_stale_reservations(db)
    available = get_available_stock(db, book_id, exclude_order_id=order_id)
    if available < quantity:
        raise HTTPException(
            status_code=400,
            detail=f"Insufficient available stock to reserve book {book_id}. Available: {available}, Requested: {quantity}"
        )
        
    expires_at = datetime.utcnow() + timedelta(minutes=duration_minutes)
    reservation = InventoryReservation(
        book_id=book_id,
        order_id=order_id,
        user_id=user_id,
        quantity=quantity,
        status="active",
        expires_at=expires_at,
        created_at=datetime.utcnow()
    )
    db.add(reservation)
    db.flush()
    return reservation

def release_reservations_for_order(db: Session, order_id: int) -> int:
    """
    Releases any active reservations associated with an order (e.g. on cancellation or failure).
    """
    reservations = db.query(InventoryReservation).filter(
        InventoryReservation.order_id == order_id,
        InventoryReservation.status == "active"
    ).all()
    count = 0
    for res in reservations:
        res.status = "released"
        count += 1
    if count > 0:
        db.flush()
    return count

# =========================================================================
# ATOMIC STOCK CLAIMS (ONLINE & COD)
# =========================================================================

def claim_order_inventory(db: Session, order: Order) -> ClaimResult:
    """
    Atomically claims inventory for all purchase items in an order upon payment verification.
    - Idempotent: If stock was already deducted, returns success immediately.
    - Checks reservations first; if expired or absent, checks remaining physical stock.
    - If any item cannot be fulfilled, does NOT deduct stock, leaves order for reconciliation.
    """
    if order.stock_deducted:
        return ClaimResult(success=True, reason="Inventory already claimed")
        
    expire_stale_reservations(db)
    
    # 1. First pass: verify stock availability for ALL purchase items
    buy_items = [item for item in order.items if item.is_purchase or getattr(item, "transaction_type", None) == "buy"]
    
    books_to_claim: List[Tuple[Book, int, Optional[InventoryReservation]]] = []
    
    for item in buy_items:
        book = db.query(Book).filter(Book.id == item.book_id).with_for_update().first()
        if not book:
            return ClaimResult(
                success=False,
                reason=f"Book ID {item.book_id} ('{item.book_title}') no longer exists.",
                reconciliation=True
            )
            
        qty_needed = item.quantity or 1
        
        # Check if there is an active reservation for this order & book
        res = db.query(InventoryReservation).filter(
            InventoryReservation.order_id == order.id,
            InventoryReservation.book_id == book.id,
            InventoryReservation.status == "active"
        ).first()
        
        if res and not res.is_expired():
            # Stock is protected by reservation: verify physical stock is >= qty
            if (book.stock or 0) < qty_needed:
                return ClaimResult(
                    success=False,
                    reason=f"Physical stock depleted for '{book.title}' despite reservation.",
                    reconciliation=True
                )
            books_to_claim.append((book, qty_needed, res))
        else:
            # No valid reservation: check unreserved available stock
            avail = get_available_stock(db, book.id, exclude_order_id=order.id)
            if avail < qty_needed:
                return ClaimResult(
                    success=False,
                    reason=f"'{book.title}' is out of stock (available: {avail}, requested: {qty_needed}).",
                    reconciliation=True
                )
            books_to_claim.append((book, qty_needed, None))
            
    # 2. Second pass: execute stock deductions and fulfill reservations atomically
    for book, qty, res in books_to_claim:
        book.stock = max(0, (book.stock or 0) - qty)
        if res:
            res.status = "fulfilled"
            
    order.stock_deducted = True
    db.flush()
    return ClaimResult(success=True, reason="Inventory successfully claimed")

def claim_cod_inventory(db: Session, items_to_snapshot: List[Dict[str, Any]]) -> ClaimResult:
    """
    Atomically verifies and deducts stock for Cash on Delivery orders at order placement.
    """
    expire_stale_reservations(db)
    
    buy_snapshots = [s for s in items_to_snapshot if s.get("is_purchase")]
    
    # Verify all items have available stock
    for s in buy_snapshots:
        book = s["book"]
        qty = s.get("qty", 1)
        avail = get_available_stock(db, book.id)
        if avail < qty:
            return ClaimResult(
                success=False,
                reason=f"'{book.title}' is out of stock (available: {avail}, requested: {qty}).",
                reconciliation=False
            )
            
    # Deduct stock atomically
    for s in buy_snapshots:
        book = s["book"]
        qty = s.get("qty", 1)
        db_book = db.query(Book).filter(Book.id == book.id).with_for_update().first()
        if db_book:
            db_book.stock = max(0, (db_book.stock or 0) - qty)
            
    db.flush()
    return ClaimResult(success=True, reason="COD inventory successfully claimed")

# =========================================================================
# ATOMIC CANCELLATION & EXACTLY-ONCE RESTOCK
# =========================================================================

def cancel_order_and_restore_inventory(db: Session, order_id: int, user_id: int) -> Dict[str, Any]:
    """
    Atomically cancels an order and restores deducted inventory exactly once.
    Guarantees:
    - Rejects already cancelled/shipped/delivered orders.
    - If stock was deducted, restores stock and flips stock_deducted to False in the same transaction.
    - Releases any pending active reservations.
    """
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == user_id).with_for_update().first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    if order.status == "cancelled":
        raise HTTPException(status_code=400, detail="Order has already been cancelled")
        
    if order.shipping_status in ("shipped", "out_for_delivery", "delivered"):
        raise HTTPException(status_code=400, detail=f"Order cannot be cancelled in shipping status '{order.shipping_status}'")
        
    order.status = "cancelled"
    order.shipping_status = "cancelled"
    
    restocked_count = 0
    if order.stock_deducted:
        for item in order.items:
            if item.is_purchase or getattr(item, "transaction_type", None) == "buy":
                book = db.query(Book).filter(Book.id == item.book_id).with_for_update().first()
                if book:
                    qty = item.quantity or 1
                    book.stock = (book.stock or 0) + qty
                    restocked_count += qty
        # Flip flag to ensure restock can never execute twice
        order.stock_deducted = False

    # Release any active reservations
    release_reservations_for_order(db, order.id)
    
    db.commit()
    return {
        "success": True,
        "message": f"Order #{order_id} cancelled successfully.",
        "restocked_items": restocked_count
    }

# =========================================================================
# DURABLE RECONCILIATION HANDLING
# =========================================================================

def mark_order_reconciliation_required(
    db: Session,
    order: Order,
    payment: Payment,
    reason: str
) -> Dict[str, Any]:
    """
    Durably records an order as requiring administrative/financial reconciliation:
    - Order status marked 'reconciliation_required'
    - Order delivery status set to 'hold'
    - Payment status set to 'refund_pending'
    - Preserves cart items and skips confirmation notifications
    """
    order.status = "reconciliation_required"
    order.shipping_status = "hold"
    payment.status = "refund_pending"
    
    # Release any reservations that failed to fulfill
    release_reservations_for_order(db, order.id)
    
    db.commit()
    return {
        "order_id": order.id,
        "payment_id": payment.razorpay_payment_id,
        "status": "reconciliation_required",
        "payment_status": "refund_pending",
        "reason": reason
    }
