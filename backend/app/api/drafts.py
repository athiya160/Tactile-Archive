from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User
from app.api.auth import get_current_user
from app.models.book import Book
import uuid

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Temporary in-memory store for drafts for demo purposes
DRAFTS_STORE = {}

@router.get("/drafts/{draft_id}/review")
def get_draft_review(draft_id: str):
    if draft_id not in DRAFTS_STORE:
        # Generate a mock draft if it doesn't exist
        DRAFTS_STORE[draft_id] = {
            "draftId": draft_id,
            "title": "Untitled Draft",
            "author": "Unknown Author",
            "isbn13": "Unknown",
            "editionLabel": "1st Edition",
            "coverUrl": "https://via.placeholder.com/150",
            "progressPercent": 100,
            "summaryText": "This is a placeholder draft summary."
        }
    return DRAFTS_STORE[draft_id]

@router.post("/drafts/{draft_id}/save")
def save_draft(draft_id: str, data: dict):
    if draft_id in DRAFTS_STORE:
        DRAFTS_STORE[draft_id].update(data)
    else:
        DRAFTS_STORE[draft_id] = data
    return {"message": "Draft saved", "draftId": draft_id}

@router.post("/drafts/{draft_id}/publish")
def publish_draft(
    draft_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    if draft_id not in DRAFTS_STORE:
        raise HTTPException(status_code=404, detail="Draft not found")
        
    draft = DRAFTS_STORE[draft_id]
    
    # Create the book from the draft
    new_book = Book(
        title=draft.get("title", "Untitled"),
        author=draft.get("author", "Unknown"),
        description=draft.get("summaryText", ""),
        price=0.0,
        category="Fiction",
        cover_url=draft.get("coverUrl", ""),
        isbn=draft.get("isbn13", ""),
        edition=draft.get("editionLabel", ""),
        owner_id=user.id,
        approval_status="approved",
        condition_verification="verified"
    )
    db.add(new_book)
    db.commit()
    db.refresh(new_book)
    
    return {"message": "Draft published successfully", "bookId": new_book.id}
