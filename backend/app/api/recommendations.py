from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.api.auth import get_current_user
from app.api.books import get_optional_user
from app.services.recommendation_engine import RecommendationEngine

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/recommendations/me")
def get_user_recommendations(
    limit: int = Query(default=10, ge=1, le=50),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Returns ranked candidate recommendations tailored to user's persona profile."""
    recommendations = RecommendationEngine.get_recommendations_for_user(user, db, limit=limit)
    return {
        "user_type": user.user_type,
        "count": len(recommendations),
        "recommendations": recommendations,
    }

@router.get("/recommendations")
def get_public_recommendations(
    limit: int = Query(default=10, ge=1, le=50),
    user: Optional[User] = Depends(get_optional_user),
    db: Session = Depends(get_db)
):
    """Returns recommendations tailored to user persona, with fallback for guests."""
    if user:
        recommendations = RecommendationEngine.get_recommendations_for_user(user, db, limit=limit)
        user_type = user.user_type
    else:
        books = db.query(Book).filter(Book.approval_status == "approved").order_by(Book.rating.desc(), Book.id.desc()).limit(limit).all()
        recommendations = [{
            "id": b.id,
            "title": b.title,
            "author": b.author,
            "category": b.category or "Curated",
            "price": float(b.price or 0.0),
            "rental_price": round((b.price or 0.0) * 0.25, 2) if b.price else 0.0,
            "cover_url": getattr(b, "image_url", b.cover_url or ""),
            "image": getattr(b, "image_url", b.cover_url or ""),
            "image_url": getattr(b, "image_url", b.cover_url or ""),
            "rating": float(b.rating or 4.5),
            "available": (b.stock if b.stock is not None else 1) > 0,
            "match_score": 5.0,
            "match_reasons": ["Editor's Choice", "Staff Recommended"]
        } for b in books]
        user_type = "guest"

    return {
        "user_type": user_type,
        "count": len(recommendations),
        "recommendations": recommendations,
    }
