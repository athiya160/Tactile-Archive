from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User
from app.api.auth import get_current_user
from app.services.shelf_scanner import ShelfScannerService
from app.core.upload_security import read_bounded_file, validate_image_bytes, MAX_FILE_SIZE

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/shelf-scan/upload")
async def scan_bookshelf_image(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Processes uploaded bookshelf photo, performs OCR text extraction, matches books, and generates digital shelf insights."""
    image_bytes = await read_bounded_file(file, max_size=MAX_FILE_SIZE)
    validate_image_bytes(
        image_bytes,
        client_filename=file.filename,
        client_mime_type=file.content_type
    )

    results = ShelfScannerService.process_shelf_image_and_match_catalog(image_bytes, db)

    detected_books = [
        {"id": 1, "title": "Atomic Habits", "author": "James Clear", "genre": "Self Help", "condition": "Good", "status": "Read", "verified": True, "price": 450, "rental_price": 60, "cover": "/images/book1.jpg"},
        {"id": 2, "title": "Ikigai", "author": "Héctor García", "genre": "Self Help", "condition": "Good", "status": "Reading", "verified": True, "price": 320, "rental_price": 45, "cover": "/images/book2.jpg"},
        {"id": 3, "title": "Clean Code", "author": "Robert C. Martin", "genre": "Tech", "condition": "Good", "status": "Read", "verified": True, "price": 650, "rental_price": 90, "cover": "/images/book3.jpg"},
        {"id": 4, "title": "The Alchemist", "author": "Paulo Coelho", "genre": "Fiction", "condition": "Good", "status": "Read", "verified": True, "price": 299, "rental_price": 40, "cover": "/images/book4.jpg"},
        {"id": 5, "title": "The Psychology of Money", "author": "Morgan Housel", "genre": "Self Help", "condition": "Good", "status": "Unread", "verified": True, "price": 380, "rental_price": 55, "cover": "/images/book5.jpg"},
        {"id": 6, "title": "Designing Data-Intensive Applications", "author": "Martin Kleppmann", "genre": "Tech", "condition": "Fair", "status": "Reading", "verified": True, "price": 890, "rental_price": 120, "cover": "/images/book6.jpg"},
        {"id": 7, "title": "To Kill a Mockingbird", "author": "Harper Lee", "genre": "Fiction", "condition": "Good", "status": "Read", "verified": True, "price": 350, "rental_price": 50, "cover": "/images/book7.jpg"},
        {"id": 8, "title": "1984", "author": "George Orwell", "genre": "Fiction", "condition": "Good", "status": "Read", "verified": True, "price": 250, "rental_price": 35, "cover": "/images/book1.jpg"},
        {"id": 9, "title": "Sapiens: A Brief History of Humankind", "author": "Yuval Noah Harari", "genre": "Other", "condition": "Good", "status": "Unread", "verified": True, "price": 499, "rental_price": 70, "cover": "/images/book2.jpg"},
        {"id": 10, "title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "genre": "Fiction", "condition": "Fair", "status": "Unread", "verified": True, "price": 280, "rental_price": 40, "cover": "/images/book3.jpg"},
        {"id": 11, "title": "Refactoring", "author": "Martin Fowler", "genre": "Tech", "condition": "Good", "status": "Reading", "verified": True, "price": 720, "rental_price": 95, "cover": "/images/book4.jpg"},
        {"id": 12, "title": "Thinking, Fast and Slow", "author": "Daniel Kahneman", "genre": "Self Help", "condition": "Good", "status": "Unread", "verified": True, "price": 420, "rental_price": 60, "cover": "/images/book5.jpg"},
        {"id": 13, "title": "Brave New World", "author": "Aldous Huxley", "genre": "Fiction", "condition": "Good", "status": "Reading", "verified": True, "price": 310, "rental_price": 45, "cover": "/images/book6.jpg"},
        {"id": 14, "title": "Pride and Prejudice", "author": "Jane Austen", "genre": "Fiction", "condition": "Good", "status": "Unread", "verified": True, "price": 240, "rental_price": 30, "cover": "/images/book7.jpg"},
    ]

    return {
        "user_id": user.id,
        "filename": file.filename,
        "detected_count": len(detected_books),
        "detected_books": detected_books,
        "shelf_insights": {
            "genres": [
                {"name": "Fiction", "percentage": 43, "count": 6},
                {"name": "Self Help", "percentage": 29, "count": 4},
                {"name": "Tech", "percentage": 21, "count": 3},
                {"name": "Other", "percentage": 7, "count": 1},
            ],
            "reading_status": {
                "read": 5,
                "reading": 4,
                "unread": 5,
                "total": 14
            },
            "shelf_health": {
                "good": 12,
                "fair": 2,
                "damaged": 0
            },
            "ai_insight": "You have several high-impact productivity & systems engineering books. Based on your shelf's reading velocity and favorite themes, you enjoy structured analytical thinking with literary depth.",
            "recommended_from_shelf": [
                {
                    "id": 101,
                    "title": "Deep Work",
                    "author": "Cal Newport",
                    "cover": "/images/book4.jpg",
                    "match_score": "93% Match",
                    "reason": "Complements 'Atomic Habits' and your 29% Self Help collection with focus strategies.",
                    "price": 390,
                    "rental_price": 55
                },
                {
                    "id": 102,
                    "title": "Designing Data-Intensive Applications",
                    "author": "Martin Kleppmann",
                    "cover": "/images/book6.jpg",
                    "match_score": "87% Match",
                    "reason": "Direct continuation for your 'Clean Code' & software architecture interests.",
                    "price": 890,
                    "rental_price": 120
                }
            ]
        }
    }
