from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel

from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book, BookImage
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.review import Review
from app.api.auth import get_current_user
from app.api.books import serialize_book

router = APIRouter(prefix="/provider", tags=["provider"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class StatusUpdatePayload(BaseModel):
    status: str

class EditListingPayload(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    price: Optional[float] = None
    category: Optional[str] = None
    condition: Optional[str] = None
    stock: Optional[int] = None
    description: Optional[str] = None
    cover_url: Optional[str] = None
    coverUrl: Optional[str] = None
    images: Optional[List[str]] = None

    @property
    def resolved_cover_url(self) -> Optional[str]:
        return self.cover_url or self.coverUrl

# Helper dependency to enforce provider role or activated provider status
def require_provider(user: User = Depends(get_current_user)):
    if not user.is_admin:
        status = getattr(user, "provider_status", None)
        if status in ["rejected", "suspended"]:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied. Provider account is {status}."
            )
        if status in ["pending", "pending_approval"]:
            raise HTTPException(
                status_code=403,
                detail="Access denied. Provider application is pending administrator approval."
            )
        if not (user.role == "provider" or getattr(user, "provider_enabled", False)):
            raise HTTPException(
                status_code=403,
                detail="Access denied. Provider mode must be activated on your account to access provider hub."
            )
    return user

@router.get("/dashboard")
def get_provider_dashboard(
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Returns aggregated provider operating metrics, inventory stats, and action items."""
    my_books = db.query(Book).filter(Book.owner_id == user.id).all()
    my_book_ids = [b.id for b in my_books]
    
    total_listings = len(my_books)
    available_books = sum(1 for b in my_books if (b.stock or 0) > 0)
    
    active_rentals = db.query(RentalOrder).filter(
        RentalOrder.book_id.in_(my_book_ids),
        RentalOrder.status == "active"
    ).count() if my_book_ids else 0

    sold_orders = db.query(PurchaseOrder).filter(
        PurchaseOrder.book_id.in_(my_book_ids),
        PurchaseOrder.status == "completed"
    ).all() if my_book_ids else []
    
    sold_count = len(sold_orders)
    sales_earnings = sum(p.price or 0.0 for p in sold_orders)

    rental_orders = db.query(RentalOrder).filter(
        RentalOrder.book_id.in_(my_book_ids)
    ).all() if my_book_ids else []
    rental_earnings = sum(r.rental_fee or 0.0 for r in rental_orders)

    total_earnings = sales_earnings + rental_earnings
    month_earnings = total_earnings * 0.4 if total_earnings > 0 else 0.0
    pending_earnings = total_earnings * 0.1 if total_earnings > 0 else 0.0

    pending_rental_requests = db.query(BorrowRequest).filter(
        BorrowRequest.book_id.in_(my_book_ids),
        BorrowRequest.status == "pending"
    ).count() if my_book_ids else 0

    unverified_books = sum(1 for b in my_books if b.condition_verification == "pending")

    reviews = db.query(Review).filter(Review.book_id.in_(my_book_ids)).all() if my_book_ids else []
    avg_rating = sum(r.rating for r in reviews) / len(reviews) if reviews else 5.0

    inventory_summary = []
    for b in my_books[:5]:
        status_label = "Available" if (b.stock or 0) > 0 else "Rented"
        inventory_summary.append({
            "id": b.id,
            "title": b.title,
            "author": b.author,
            "price": b.price or 0.0,
            "condition": b.condition or "Good",
            "status": status_label,
            "coverUrl": b.image_url,
            "condition_verification": b.condition_verification or "verified"
        })

    provider_display_name = user.name or (user.email.split("@")[0].title() if user.email else "Provider")

    return {
        "provider_name": provider_display_name,
        "provider_email": user.email,
        "is_verified": bool(user.is_verified),
        "rating": round(avg_rating, 1),
        "total_reviews": len(reviews),
        "metrics": {
            "total_listings": total_listings,
            "available_books": available_books,
            "rentals_count": active_rentals,
            "sold_count": sold_count,
            "total_earnings": total_earnings,
            "month_earnings": month_earnings,
            "pending_earnings": pending_earnings,
        },
        "action_required": {
            "rental_requests": pending_rental_requests,
            "exchange_pending": 0,
            "awaiting_verification": unverified_books
        },
        "recent_inventory": inventory_summary
    }

@router.get("/inventory")
def get_provider_inventory(
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Returns all books listed by the current provider."""
    books = db.query(Book).filter(Book.owner_id == user.id).order_by(Book.id.desc()).all()
    return [serialize_book(b, user.id, db) for b in books]

@router.get("/requests")
def get_provider_requests(
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Returns incoming rental, buy, and borrow requests/orders for the provider's books."""
    my_books = db.query(Book).filter(Book.owner_id == user.id).all()
    my_book_ids = [b.id for b in my_books]

    requests = []
    if my_book_ids:
        # 1. Borrow Requests
        borrow_reqs = db.query(BorrowRequest).filter(BorrowRequest.book_id.in_(my_book_ids)).order_by(BorrowRequest.id.desc()).all()
        for r in borrow_reqs:
            requests.append({
                "id": r.id,
                "type": "Borrow Request",
                "request_category": "borrow",
                "book_id": r.book_id,
                "book_title": r.book.title if r.book else "Unknown Book",
                "book_cover": r.book.image_url if r.book else "",
                "requester_name": r.user.name if r.user else "Reader",
                "requester_email": r.user.email if r.user else "",
                "duration_days": r.duration_days or 14,
                "amount": 0.0,
                "status": r.status or "pending",
                "created_at": r.created_at.strftime("%Y-%m-%d %H:%M") if r.created_at else "Today"
            })

        # 2. Rental Orders
        rental_orders = db.query(RentalOrder).filter(RentalOrder.book_id.in_(my_book_ids)).order_by(RentalOrder.id.desc()).all()
        for ro in rental_orders:
            requests.append({
                "id": ro.id,
                "type": "Rental Request",
                "request_category": "rental",
                "book_id": ro.book_id,
                "book_title": ro.book.title if ro.book else "Unknown Book",
                "book_cover": ro.book.image_url if ro.book else "",
                "requester_name": ro.user.name if ro.user else "Reader",
                "requester_email": ro.user.email if ro.user else "",
                "duration_days": ro.rental_days or 14,
                "amount": ro.rental_fee or 0.0,
                "status": ro.status or "active",
                "created_at": ro.created_at.strftime("%Y-%m-%d %H:%M") if getattr(ro, "created_at", None) else "Recent"
            })

        # 3. Buy / Purchase Orders
        purchase_orders = db.query(PurchaseOrder).filter(PurchaseOrder.book_id.in_(my_book_ids)).order_by(PurchaseOrder.id.desc()).all()
        for po in purchase_orders:
            requests.append({
                "id": po.id,
                "type": "Buy Order",
                "request_category": "buy",
                "book_id": po.book_id,
                "book_title": po.book.title if po.book else "Unknown Book",
                "book_cover": po.book.image_url if po.book else "",
                "requester_name": po.user.name if po.user else "Customer",
                "requester_email": po.user.email if po.user else "",
                "duration_days": 0,
                "amount": po.price or 0.0,
                "status": po.status or "completed",
                "created_at": po.created_at.strftime("%Y-%m-%d %H:%M") if getattr(po, "created_at", None) else "Recent"
            })

    return requests

@router.get("/earnings")
def get_provider_earnings(
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Returns detailed earnings, payout history, and escrow status."""
    my_books = db.query(Book).filter(Book.owner_id == user.id).all()
    my_book_ids = [b.id for b in my_books]

    sold_orders = db.query(PurchaseOrder).filter(
        PurchaseOrder.book_id.in_(my_book_ids),
        PurchaseOrder.status == "completed"
    ).all() if my_book_ids else []
    
    rental_orders = db.query(RentalOrder).filter(
        RentalOrder.book_id.in_(my_book_ids)
    ).all() if my_book_ids else []

    total_sales = sum(p.price or 0.0 for p in sold_orders)
    total_rentals = sum(r.rental_fee or 0.0 for r in rental_orders)
    total_earned = total_sales + total_rentals

    transactions = []
    for p in sold_orders:
        transactions.append({
            "id": f"TXN-S{p.id}",
            "date": p.created_at.strftime("%Y-%m-%d") if getattr(p, "created_at", None) else "Recent",
            "book_title": p.book.title if p.book else "Book Sale",
            "customer": p.user.name if p.user else "Reader",
            "type": "Sale",
            "amount": p.price or 0.0,
            "status": "Paid"
        })

    for r in rental_orders:
        transactions.append({
            "id": f"TXN-R{r.id}",
            "date": r.created_at.strftime("%Y-%m-%d") if getattr(r, "created_at", None) else "Recent",
            "book_title": r.book.title if r.book else "Book Rental",
            "customer": r.user.name if r.user else "Reader",
            "type": f"Rental ({r.rental_days or 14} Days)",
            "amount": r.rental_fee or 0.0,
            "status": "Escrow Holding" if r.status == "active" else "Settled"
        })

    return {
        "total_earned": total_earned,
        "this_month": total_earned * 0.4 if total_earned > 0 else 0.0,
        "pending_escrow": total_earned * 0.1 if total_earned > 0 else 0.0,
        "available_for_payout": total_earned * 0.9 if total_earned > 0 else 0.0,
        "payout_method": "Bank / UPI (Verification Required)",
        "transactions": transactions
    }

@router.put("/inventory/{book_id}")
def update_provider_book(
    book_id: int,
    payload: EditListingPayload,
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Allows a provider to update their book listing, condition, pricing, and stock."""
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book listing not found")
    if book.owner_id != user.id and not user.is_admin:
        raise HTTPException(status_code=403, detail="You do not have permission to modify this listing")

    if payload.title is not None:
        book.title = payload.title.strip()
    if payload.author is not None:
        book.author = payload.author.strip()
    if payload.price is not None:
        book.price = max(payload.price, 0.0)
    if payload.category is not None:
        book.category = payload.category.strip().title()
    if payload.condition is not None:
        book.condition = payload.condition.strip()
    if payload.stock is not None:
        book.stock = max(payload.stock, 0)
    if payload.description is not None:
        book.description = payload.description.strip()
    cover = payload.resolved_cover_url
    if cover is not None:
        book.cover_url = cover.strip()

    if payload.images is not None:
        # Update extra gallery images
        db.query(BookImage).filter(BookImage.book_id == book.id).delete()
        for img in payload.images:
            if img:
                db.add(BookImage(book_id=book.id, image_url=img))

    db.commit()
    db.refresh(book)
    return serialize_book(book, user.id, db)

@router.delete("/inventory/{book_id}")
def delete_provider_book(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Allows a provider to delete their own book listing."""
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book listing not found")
    if book.owner_id != user.id and not user.is_admin:
        raise HTTPException(status_code=403, detail="You do not have permission to delete this listing")

    db.delete(book)
    db.commit()
    return {"status": "success", "message": f"Listing #{book_id} deleted successfully"}

@router.put("/orders/{order_id}/status")
def update_provider_order_status(
    order_id: int,
    payload: StatusUpdatePayload,
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    """Allows a provider to advance the status of an order for their books (e.g. dispatched, returned)."""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Verify order contains at least one book owned by provider
    my_books = db.query(Book).filter(Book.owner_id == user.id).all()
    my_book_ids = {b.id for b in my_books}
    contains_my_book = any(item.book_id in my_book_ids for item in order.items) if order.items else False
    if not contains_my_book and not user.is_admin:
        raise HTTPException(status_code=403, detail="You do not have permission to update this order")

    order.status = payload.status
    if order.user_id:
        from app.models.notification import Notification
        notif = Notification(
            user_id=order.user_id,
            title="Order Status Updated",
            message=f"Your order #{order.id} status has been updated to '{payload.status}'.",
            is_read=False
        )
        db.add(notif)
    db.commit()
    return {"status": "success", "message": f"Order #{order_id} status updated to {payload.status}"}

@router.post("/requests/{request_id}/approve")
def approve_request(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    # 1. Borrow Requests
    borrow_req = db.query(BorrowRequest).filter(BorrowRequest.id == request_id).first()
    if borrow_req:
        book = db.query(Book).filter(Book.id == borrow_req.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to approve this request")
        borrow_req.status = "approved"
        if borrow_req.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=borrow_req.user_id,
                title="Borrow Request Approved",
                message=f"Your borrow request for '{book.title if book else 'book'}' has been approved!",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Borrow request approved successfully", "request_id": request_id}

    # 2. Rental Orders
    rental_ord = db.query(RentalOrder).filter(RentalOrder.id == request_id).first()
    if rental_ord:
        book = db.query(Book).filter(Book.id == rental_ord.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to approve this request")
        rental_ord.status = "active"
        if rental_ord.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=rental_ord.user_id,
                title="Rental Order Approved",
                message=f"Your rental request for '{book.title if book else 'book'}' is approved and active!",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Rental order approved and active", "request_id": request_id}

    # 3. Purchase Orders
    purch_ord = db.query(PurchaseOrder).filter(PurchaseOrder.id == request_id).first()
    if purch_ord:
        book = db.query(Book).filter(Book.id == purch_ord.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to approve this request")
        purch_ord.status = "completed"
        if purch_ord.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=purch_ord.user_id,
                title="Purchase Order Approved",
                message=f"Your order for '{book.title if book else 'book'}' has been confirmed by the seller!",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Purchase order approved successfully", "request_id": request_id}

    raise HTTPException(status_code=404, detail="Request not found")

@router.post("/requests/{request_id}/reject")
def reject_request(
    request_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_provider)
):
    # 1. Borrow Requests
    borrow_req = db.query(BorrowRequest).filter(BorrowRequest.id == request_id).first()
    if borrow_req:
        book = db.query(Book).filter(Book.id == borrow_req.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to reject this request")
        borrow_req.status = "rejected"
        if borrow_req.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=borrow_req.user_id,
                title="Borrow Request Declined",
                message=f"Your borrow request for '{book.title if book else 'book'}' was declined.",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Borrow request declined", "request_id": request_id}

    # 2. Rental Orders
    rental_ord = db.query(RentalOrder).filter(RentalOrder.id == request_id).first()
    if rental_ord:
        book = db.query(Book).filter(Book.id == rental_ord.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to reject this request")
        rental_ord.status = "cancelled"
        if rental_ord.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=rental_ord.user_id,
                title="Rental Order Declined",
                message=f"Your rental request for '{book.title if book else 'book'}' was declined.",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Rental order declined", "request_id": request_id}

    # 3. Purchase Orders
    purch_ord = db.query(PurchaseOrder).filter(PurchaseOrder.id == request_id).first()
    if purch_ord:
        book = db.query(Book).filter(Book.id == purch_ord.book_id).first()
        if not book or (book.owner_id != user.id and not user.is_admin):
            raise HTTPException(status_code=403, detail="You do not have permission to reject this request")
        purch_ord.status = "cancelled"
        if purch_ord.user_id:
            from app.models.notification import Notification
            db.add(Notification(
                user_id=purch_ord.user_id,
                title="Purchase Order Declined",
                message=f"Your order for '{book.title if book else 'book'}' was declined.",
                is_read=False
            ))
        db.commit()
        return {"status": "success", "message": "Purchase order declined", "request_id": request_id}

    raise HTTPException(status_code=404, detail="Request not found")

