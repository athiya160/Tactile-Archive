from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.book import Book
from app.models.review import Review
from app.models.user import User
from app.api.auth import get_current_user
from pydantic import BaseModel
from typing import Optional, List
import datetime

router = APIRouter()

# DB connection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Schemas
class ReviewCreate(BaseModel):
    book_id: int
    order_id: int  # This is the OrderItem ID from the frontend
    rating: float
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: int
    book_id: int
    user_id: int
    user_name: str
    rating: float
    comment: Optional[str] = None
    created_at: datetime.datetime

    class Config:
        from_attributes = True

@router.get("/reviews/book/{book_id}", response_model=List[ReviewResponse])
@router.get("/books/{book_id}/reviews", response_model=List[ReviewResponse])
def get_reviews(book_id: int, db: Session = Depends(get_db)):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    reviews = db.query(Review).filter(Review.book_id == book_id).order_by(Review.created_at.desc()).all()
    
    # Map to schema manually to populate user_name easily
    response = []
    for r in reviews:
        response.append({
            "id": r.id,
            "book_id": r.book_id,
            "user_id": r.user_id,
            "user_name": r.user.name or r.user.email.split('@')[0].capitalize(),
            "rating": r.rating,
            "comment": r.comment,
            "created_at": r.created_at
        })
    return response

@router.post("/reviews", response_model=ReviewResponse)
def create_review(
    req: ReviewCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    from app.models.order import Order, OrderItem
    
    # Fetch book
    book = db.query(Book).filter(Book.id == req.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    if req.rating < 1 or req.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")

    # Fetch OrderItem
    order_item = db.query(OrderItem).filter(OrderItem.id == req.order_id).first()
    if not order_item:
        raise HTTPException(status_code=400, detail="Order item not found.")

    # Retrieve Order
    order = order_item.order
    if not order:
        raise HTTPException(status_code=400, detail="Order not found.")

    # Verify ownership
    if order.user_id != user.id:
        raise HTTPException(status_code=403, detail="You do not own this order.")

    # Verify status is delivered
    if (order.shipping_status or "").lower() != "delivered":
        raise HTTPException(status_code=400, detail="Review is only allowed after order status is Delivered.")

    # Verify book matches the order item
    if order_item.book_id != req.book_id:
        raise HTTPException(status_code=400, detail="This book does not match the order item.")

    # Check for duplicate review for the same master order
    existing_review = db.query(Review).filter(
        Review.order_id == order.id,
        Review.book_id == req.book_id
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="You have already submitted a review for this order.")
        
    # Create new review
    review = Review(
        book_id=req.book_id,
        user_id=user.id,
        order_id=order.id,
        rating=req.rating,
        comment=req.comment
    )
    db.add(review)
    db.commit()
    db.refresh(review)

    # Recalculate book average rating and update column
    all_reviews = db.query(Review).filter(Review.book_id == req.book_id).all()
    avg_rating = sum(r.rating for r in all_reviews) / len(all_reviews) if all_reviews else 0.0
    book.rating = avg_rating
    db.commit()
        
    return {
        "id": review.id,
        "book_id": review.book_id,
        "user_id": review.user_id,
        "user_name": user.name or user.email.split('@')[0].capitalize(),
        "rating": review.rating,
        "comment": review.comment,
        "created_at": review.created_at
    }
