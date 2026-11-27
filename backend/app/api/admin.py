from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.order import Order, OrderItem
from app.api.auth import get_current_user

router = APIRouter(prefix="/admin")

# Input Schemas
class AdminRoleUpdate(BaseModel):
    level: str
    is_admin: bool
    role: Optional[str] = None
    provider_enabled: Optional[bool] = None
    provider_status: Optional[str] = None

class AdminOrderStatusUpdate(BaseModel):
    status: str

class ProviderStatusUpdate(BaseModel):
    status: str

# Helper dependency to enforce admin role
def require_admin(user: User = Depends(get_current_user)):
    if not user.is_admin:
        raise HTTPException(status_code=403, detail="Access denied. Admin role required.")
    return user

# DB connection dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 🔒 List all users (Admin only)
@router.get("/users")
def get_users(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    users = db.query(User).order_by(User.id).all()
    return [
        {
            "id": u.id,
            "email": u.email,
            "name": u.name,
            "level": u.level,
            "is_admin": u.is_admin,
            "role": u.role or "customer",
            "provider_enabled": bool(u.provider_enabled),
            "provider_status": getattr(u, "provider_status", "not_enrolled") or "not_enrolled",
            "join_date": u.join_date,
            "phone": u.phone,
            "address": u.address
        }
        for u in users
    ]

# 🔒 Update user role/admin level (Admin only)
@router.put("/users/{user_id}/role")
def update_user_role(
    user_id: int,
    data: AdminRoleUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.level = data.level
    user.is_admin = data.is_admin
    if data.role is not None:
        user.role = data.role
    if data.provider_enabled is not None:
        user.provider_enabled = data.provider_enabled
    if data.provider_status is not None:
        user.provider_status = data.provider_status
    db.commit()
    return {"message": "User roles updated successfully"}

# 🔒 List all books (Admin only)
@router.get("/books")
def get_books(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    books = db.query(Book).order_by(Book.id.desc()).all()
    return [
        {
            "id": b.id,
            "title": b.title,
            "author": b.author,
            "category": b.category,
            "price": b.price,
            "owner_id": b.owner_id
        }
        for b in books
    ]

# 🔒 Delete book (Admin only)
@router.delete("/books/{book_id}")
def delete_book(
    book_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
    db.delete(book)
    db.commit()
    return {"message": "Book deleted successfully"}

# 🔒 List all orders (Admin only)
@router.get("/orders")
def get_orders(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    orders = db.query(Order).order_by(Order.created_at.desc()).all()
    res = []
    for o in orders:
        user = db.query(User).filter(User.id == o.user_id).first()
        for item in o.items:
            res.append({
                "id": o.id,
                "user_email": user.email if user else "Unknown",
                "book_title": item.book_title,
                "is_purchase": item.is_purchase,
                "rental_days": item.rental_days,
                "status": o.status,
                "created_at": o.created_at
            })
    return res

# 🔒 Update order status (Admin only)
@router.put("/orders/{order_id}/status")
def update_order_status(
    order_id: int,
    data: AdminOrderStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.status = data.status
    db.commit()
    return {"message": "Order status updated successfully"}

# 🔒 Get Dashboard stats (Admin only)
@router.get("/stats")
def get_dashboard_stats(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    total_users = db.query(User).count()
    total_books = db.query(Book).count()
    total_orders = db.query(Order).count()
    pending_books = db.query(Book).filter(Book.approval_status == "pending_approval").count()
    total_providers = db.query(User).filter((User.provider_enabled == True) | (User.role == "provider")).count()
    
    # Calculate revenue
    from app.models.order import RentalOrder, PurchaseOrder
    rental_rev = db.query(RentalOrder).filter(RentalOrder.status == "active").all()
    purchase_rev = db.query(PurchaseOrder).all()
    
    total_revenue = sum(r.rental_fee for r in rental_rev) + sum(p.price for p in purchase_rev)

    return {
        "totalUsers": total_users,
        "totalBooks": total_books,
        "totalOrders": total_orders,
        "totalRevenue": total_revenue,
        "pendingBooks": pending_books,
        "totalProviders": total_providers,
    }

# 🔒 List all providers for approval & moderation (Admin only)
@router.get("/providers")
def get_admin_providers(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """List all registered providers and their approval statuses for moderation."""
    providers = db.query(User).filter((User.provider_enabled == True) | (User.role == "provider")).order_by(User.id.desc()).all()
    results = []
    for p in providers:
        book_count = db.query(Book).filter(Book.owner_id == p.id).count()
        results.append({
            "id": p.id,
            "name": p.name or "Community Provider",
            "email": p.email,
            "phone": p.phone or "Not provided",
            "address": p.address or "Standard Hub",
            "provider_status": getattr(p, "provider_status", "active") or "active",
            "provider_enabled": bool(p.provider_enabled),
            "listings_count": book_count,
            "join_date": p.join_date
        })
    return results

# 🔒 Update provider status (Admin only)
@router.put("/providers/{user_id}/status")
def update_provider_status(
    user_id: int,
    data: ProviderStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")
    target.provider_status = data.status
    if data.status == "active":
        target.provider_enabled = True
        target.role = "provider"
    elif data.status in ["rejected", "suspended"]:
        target.provider_enabled = False
    db.commit()
    return {"message": f"Provider status updated to '{data.status}' successfully"}

# 🔒 System activity logs (Admin only)
@router.get("/activity")
def get_admin_activity_logs(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """Returns recent platform audit log events and operational records."""
    recent_orders = db.query(Order).order_by(Order.created_at.desc()).limit(15).all()
    recent_books = db.query(Book).order_by(Book.id.desc()).limit(15).all()
    
    logs = []
    for o in recent_orders:
        logs.append({
            "timestamp": o.created_at.strftime("%Y-%m-%d %H:%M") if o.created_at else "Recently",
            "type": "Order",
            "description": f"Order #{o.id} ({o.total_items or 1} items) placed. Status: '{o.status}'",
            "severity": "info"
        })
    for b in recent_books:
        logs.append({
            "timestamp": b.created_at.strftime("%Y-%m-%d %H:%M") if b.created_at else "Recently",
            "type": "Catalogue",
            "description": f"Book '{b.title}' by {b.author} listed (Status: {b.approval_status})",
            "severity": "info" if b.approval_status == "approved" else "warning"
        })
    logs.sort(key=lambda x: x["timestamp"], reverse=True)
    return logs

class AdminBookApprovalRequest(BaseModel):
    notes: Optional[str] = None

# 🔒 List all pending books for approval (Admin only)
@router.get("/pending-books")
def get_pending_books(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    books = db.query(Book).filter(Book.approval_status == "pending_approval").all()
    # Import serialize_book inside the function to avoid circular import issues
    from app.api.books import serialize_book
    return [
        serialize_book(b, None, db)
        for b in books
    ]

# 🔒 Approve a book (Admin only)
@router.post("/books/{book_id}/approve")
def approve_book(
    book_id: int,
    data: AdminBookApprovalRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    book.approval_status = "approved"
    book.condition_verification = "verified"
    if data.notes:
        book.verification_notes = data.notes
        
    db.commit()
    return {"message": "Book approved and verified successfully"}

# 🔒 Reject a book (Admin only)
@router.post("/books/{book_id}/reject")
def reject_book(
    book_id: int,
    data: AdminBookApprovalRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    book.approval_status = "rejected"
    book.condition_verification = "rejected"
    if data.notes:
        book.verification_notes = data.notes
        
    db.commit()
    return {"message": "Book rejected successfully"}


# ---------------------------------------------------------------------------
# 🔒 Account Deletion Request Administration (Admin only)
# ---------------------------------------------------------------------------
from app.models.account_deletion_request import AccountDeletionRequest
from app.schemas.user import AccountDeletionStatusUpdate


@router.get("/deletion-requests")
def get_deletion_requests(
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    List external account deletion intake requests with privacy-safe email masking.
    Staff can inspect pending deletion obligations and request queues.
    """
    query = db.query(AccountDeletionRequest)
    if status:
        query = query.filter(AccountDeletionRequest.status == status)

    total = query.count()
    requests = query.order_by(AccountDeletionRequest.created_at.desc()).offset(offset).limit(limit).all()

    return {
        "total": total,
        "items": [
            {
                "id": req.id,
                "request_id": req.request_id,
                "user_id": req.user_id,
                "masked_email": req.mask_email(),
                "reason": req.reason,
                "status": req.status,
                "created_at": req.created_at.isoformat() if req.created_at else None,
                "updated_at": req.updated_at.isoformat() if req.updated_at else None,
                "processed_at": req.processed_at.isoformat() if req.processed_at else None,
                "processed_by": req.processed_by,
                "resolution_notes": req.resolution_notes
            }
            for req in requests
        ]
    }


@router.put("/deletion-requests/{request_id}/status")
def update_deletion_request_status(
    request_id: str,
    payload: AccountDeletionStatusUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin)
):
    """
    Update the processing status of an account deletion request.
    Allowed statuses: pending, in_review, completed, rejected, cancelled.
    """
    valid_statuses = ["pending", "in_review", "completed", "rejected", "cancelled"]
    target_status = payload.status.strip().lower()
    if target_status not in valid_statuses:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status '{payload.status}'. Allowed statuses: {', '.join(valid_statuses)}"
        )

    req = None
    if request_id.isdigit():
        req = db.query(AccountDeletionRequest).filter(AccountDeletionRequest.id == int(request_id)).first()
    if not req:
        req = db.query(AccountDeletionRequest).filter(AccountDeletionRequest.request_id == request_id).first()

    if not req:
        raise HTTPException(status_code=404, detail="Account deletion request not found.")

    req.status = target_status
    if payload.resolution_notes is not None:
        req.resolution_notes = payload.resolution_notes.strip()
    req.processed_by = admin.id
    req.processed_at = datetime.utcnow()
    req.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(req)

    return {
        "success": True,
        "message": f"Account deletion request {req.request_id} updated to '{req.status}'.",
        "request": {
            "id": req.id,
            "request_id": req.request_id,
            "user_id": req.user_id,
            "masked_email": req.mask_email(),
            "reason": req.reason,
            "status": req.status,
            "created_at": req.created_at.isoformat() if req.created_at else None,
            "updated_at": req.updated_at.isoformat() if req.updated_at else None,
            "processed_at": req.processed_at.isoformat() if req.processed_at else None,
            "processed_by": req.processed_by,
            "resolution_notes": req.resolution_notes
        }
    }
