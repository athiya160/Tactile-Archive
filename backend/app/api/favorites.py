from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User
from app.models.favorite import Favorite
from app.models.book import Book
from app.api.auth import get_current_user
from app.api.books import serialize_book
from typing import List

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/favorites")
def get_favorites(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    favorites = db.query(Favorite).filter(Favorite.user_id == user.id).all()
    
    response = []
    for fav in favorites:
        book = db.query(Book).filter(Book.id == fav.book_id).first()
        if book:
            response.append(serialize_book(book, user.id, db))
            
    return response

@router.post("/favorites/{book_id}")
def toggle_favorite_route(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    fav = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    is_favorite = False
    
    if fav:
        db.delete(fav)
        db.commit()
    else:
        new_fav = Favorite(user_id=user.id, book_id=book_id)
        db.add(new_fav)
        db.commit()
        is_favorite = True
        
    return {"isFavorite": is_favorite, "book_id": book_id, "message": "Favorite updated"}

@router.delete("/favorites/{book_id}")
def remove_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    fav = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    if not fav:
        raise HTTPException(status_code=404, detail="Favorite not found")
        
    db.delete(fav)
    db.commit()
    
    return {"message": "Favorite removed successfully", "isFavorite": False}
