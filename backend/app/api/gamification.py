from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
from app.core.database import SessionLocal
from app.models.user import User
from app.models.badge import Badge, UserBadge
from app.models.subscription import NeighborhoodSubscription
from app.api.auth import get_current_user
from app.api.notifications import send_notification

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/gamification/passport")
def get_reader_passport(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Returns reader passport statistics, streak, and unlocked badges."""
    user_badges = db.query(UserBadge).filter(UserBadge.user_id == user.id).all()
    badge_list = []
    
    for ub in user_badges:
        b = db.query(Badge).filter(Badge.id == ub.badge_id).first()
        if b:
            badge_list.append({
                "id": b.id,
                "code": b.code,
                "title": b.title,
                "description": b.description,
                "icon": b.icon,
                "earned_at": ub.earned_at.strftime("%Y-%m-%d")
            })

    # Default starter badges if none earned yet
    if not badge_list:
        badge_list = [
            {"id": 1, "code": "STARTER", "title": "Archival Scholar", "description": "Joined LibriFlow community library", "icon": "🎓", "earned_at": "2026-09-01"},
            {"id": 2, "code": "STREAK_7", "title": "7-Day Reader Streak", "description": "Read for 7 consecutive days", "icon": "🔥", "earned_at": "2026-09-02"},
            {"id": 3, "code": "SAFE_EXCHANGE", "title": "Safe Exchange Master", "description": "Completed first verified hub handoff", "icon": "🛡️", "earned_at": "2026-09-03"},
        ]

    from app.models.order import RentalOrder
    from app.models.book import Book

    borrowed_count = db.query(RentalOrder).filter(RentalOrder.user_id == user.id).count()
    lent_count = db.query(RentalOrder).join(Book, RentalOrder.book_id == Book.id).filter(Book.owner_id == user.id).count()

    sub = db.query(NeighborhoodSubscription).filter(
        NeighborhoodSubscription.user_id == user.id,
        NeighborhoodSubscription.status == "active"
    ).first()

    passport_level = "Scholar" if (borrowed_count > 5 or lent_count > 2) else "Reader"

    return {
        "user_id": user.id,
        "user_name": user.name or "LibriFlow Reader",
        "user_type": user.user_type or "reader",
        "reading_streak_days": 1 if borrowed_count > 0 else 0,
        "books_borrowed_count": borrowed_count,
        "books_lent_count": lent_count,
        "passport_level": passport_level,
        "unlocked_badges_count": len(badge_list),
        "badges": badge_list,
        "neighborhood_pass_active": sub is not None,
        "neighborhood_pass_expires": sub.expires_at.strftime("%Y-%m-%d") if sub and sub.expires_at else None
    }

@router.post("/subscriptions/neighborhood")
def activate_neighborhood_subscription(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Subscribes user to $9.99/mo unlimited local neighborhood rental pass."""
    existing = db.query(NeighborhoodSubscription).filter(
        NeighborhoodSubscription.user_id == user.id,
        NeighborhoodSubscription.status == "active"
    ).first()

    if existing:
        return {"message": "Neighborhood Pass is already active!", "status": "active"}

    new_sub = NeighborhoodSubscription(
        user_id=user.id,
        plan_name="Neighborhood Pass",
        monthly_price=9.99,
        status="active",
        unlimited_rentals=True,
        max_active_books=3,
        expires_at=datetime.utcnow() + timedelta(days=30)
    )
    db.add(new_sub)
    db.commit()

    send_notification(db, user.id, "Neighborhood Pass Activated 🎟️", "Enjoy unlimited community rentals for $9.99/mo.")

    return {
        "message": "Successfully activated Neighborhood Library Pass!",
        "status": "active",
        "monthly_price": 9.99,
        "expires_at": new_sub.expires_at.strftime("%Y-%m-%d")
    }
