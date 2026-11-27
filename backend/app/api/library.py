from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.api.auth import get_current_user
from app.models.user import User
from app.models.order import Order, OrderItem
from app.models.book import Book

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/library/rentals")
def get_rentals(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    orders = db.query(Order).filter(Order.user_id == user.id).all()
    rented_books = []
    
    for order in orders:
        for item in order.items:
            if not item.is_purchase:
                rented_books.append({
                    "id": str(item.book_id),
                    "title": item.book_title,
                    "author": item.book_author,
                    "coverUrl": item.book_image,
                    "rentalDays": item.rental_days,
                    "orderDate": order.created_at,
                    "status": order.status
                })
                
    return rented_books

@router.get("/library/uploads")
def get_uploads(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    books = db.query(Book).filter(Book.owner_id == user.id).all()
    uploaded_books = []
    
    for book in books:
        uploaded_books.append({
            "id": str(book.id),
            "title": book.title,
            "author": book.author,
            "coverUrl": book.image_url,
            "price": book.price,
            "rating": book.rating,
            "status": "active" if book.approval_status == "approved" else "pending"
        })
        
    return uploaded_books

@router.delete("/library/uploads/{book_id}")
def delete_upload(book_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
    if book.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this book")
    
    db.delete(book)
    db.commit()
    return {"status": "success", "message": "Book deleted successfully"}
