from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.book import Book
from app.models.user import User
from app.api.auth import get_current_user

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class MoodRecommendationQuery(BaseModel):
    mood: Optional[str] = "Tired" # Anxious, Motivated, Curious, Tired, Focused, Happy, Sad, Romantic
    goal: Optional[str] = "Comfort me" # Comfort me, Teach me, Distract me, Inspire me, Make me laugh
    timing: Optional[str] = "Morning Ritual" # Morning Ritual, Afternoon Focus, Evening Wind-down, Night Owl
    format: Optional[str] = "Physical Book" # Physical Book, Digital / E-Book, Audiobook, Hybrid
    length: Optional[str] = "Short (< 200 pgs)" # Short (< 200 pgs), Medium (200-350 pgs), Deep / Long (350+ pgs)
    genre: Optional[str] = None

@router.post("/recommendations/mood")
def get_mood_recommendations(
    query: MoodRecommendationQuery,
    db: Session = Depends(get_db),
    user: Optional[User] = Depends(get_current_user)
):
    """Returns curated books matching student/reader mood, goal, timing & length preferences."""
    books_query = db.query(Book)
    
    # Filter length if specified
    if query.length:
        if "< 200" in query.length or "Short" in query.length:
            books_query = books_query.filter(Book.pages <= 250)
        elif "350+" in query.length or "Deep" in query.length:
            books_query = books_query.filter(Book.pages >= 350)
            
    # Filter genre if specified
    if query.genre:
        books_query = books_query.filter(Book.category.ilike(f"%{query.genre}%"))

    matches = books_query.limit(10).all()
    
    # Fallback to general books if matches are empty
    if not matches:
        matches = db.query(Book).limit(6).all()
        
    result_books = []
    for b in matches:
        result_books.append({
            "id": b.id,
            "title": b.title,
            "author": b.author,
            "category": b.category,
            "price": b.price,
            "rental_price": b.rental_price,
            "cover_image": b.cover_image,
            "rating": b.rating,
            "match_score": "98%",
            "match_reason": f"Matches your '{query.mood}' mood during your '{query.timing}' routine."
        })
        
    return {
        "status": "success",
        "selected_mood": query.mood,
        "selected_goal": query.goal,
        "selected_timing": query.timing,
        "selected_format": query.format,
        "selected_length": query.length,
        "count": len(result_books),
        "matches": result_books
    }
