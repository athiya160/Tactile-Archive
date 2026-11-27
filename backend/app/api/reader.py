import json
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.api.auth import get_current_user, get_db
from app.models.user import User
from app.models.reader_profile import ReaderProfile
from app.models.reader_data import BookshelfItem, ReadingGoal
from app.schemas.reader import (
    BookshelfItemCreate,
    BookshelfItemUpdate,
    BookshelfItemMove,
    BookshelfItemResponse,
    ReadingGoalCreate,
    ReadingGoalUpdate,
    ReadingGoalResponse,
    ReaderDashboardSummary,
)

router = APIRouter(prefix="/reader", tags=["Reader"])

def _parse_json_list(val):
    if not val:
        return []
    try:
        res = json.loads(val)
        return res if isinstance(res, list) else []
    except Exception:
        return []

def _get_or_create_reading_goal(user_id: int, db: Session, year: Optional[int] = None) -> ReadingGoal:
    target_year = year if isinstance(year, int) else datetime.datetime.utcnow().year
    goal = db.query(ReadingGoal).filter(
        ReadingGoal.user_id == user_id,
        ReadingGoal.year == target_year
    ).first()
    if not goal:
        goal = ReadingGoal(
            user_id=user_id,
            year=target_year,
            target_books=12,
            completed_books=0,
            target_pages=3000,
            pages_read=0,
            daily_reading_goal_minutes=30,
            streak_days=0,
        )
        db.add(goal)
        db.commit()
        db.refresh(goal)
    return goal

def _sync_reading_goal(user_id: int, db: Session):
    try:
        completed_count = db.query(BookshelfItem).filter(
            BookshelfItem.user_id == user_id,
            BookshelfItem.category == "completed"
        ).count()
        goal = _get_or_create_reading_goal(user_id, db)
        goal.completed_books = completed_count
        db.commit()
    except Exception as e:
        print(f"[WARN] Failed to sync reading goal: {e}")

# ─── DASHBOARD SUMMARY ────────────────────────────────────────────────────────

@router.get("/dashboard", response_model=ReaderDashboardSummary)
def get_reader_dashboard(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = user.reader_profile
    goal = _get_or_create_reading_goal(user.id, db)
    
    currently_reading = db.query(BookshelfItem).filter(
        BookshelfItem.user_id == user.id,
        BookshelfItem.category == "currently_reading"
    ).all()

    want_to_read = db.query(BookshelfItem).filter(
        BookshelfItem.user_id == user.id,
        BookshelfItem.category == "want_to_read"
    ).all()

    completed = db.query(BookshelfItem).filter(
        BookshelfItem.user_id == user.id,
        BookshelfItem.category == "completed"
    ).all()

    paused = db.query(BookshelfItem).filter(
        BookshelfItem.user_id == user.id,
        BookshelfItem.category == "paused"
    ).all()

    # Recalculate completed count if needed
    total_completed = len(completed)
    if goal.completed_books != total_completed:
        goal.completed_books = total_completed
        db.commit()
        db.refresh(goal)

    genres = _parse_json_list(profile.genres) if profile else []
    freq = profile.reading_frequency if profile else "Daily"

    return ReaderDashboardSummary(
        goal=ReadingGoalResponse.from_orm(goal),
        currently_reading=[BookshelfItemResponse.from_orm(b) for b in currently_reading],
        want_to_read=[BookshelfItemResponse.from_orm(b) for b in want_to_read],
        completed=[BookshelfItemResponse.from_orm(b) for b in completed],
        paused=[BookshelfItemResponse.from_orm(b) for b in paused],
        total_books_read=total_completed,
        current_streak_days=goal.streak_days,
        reading_frequency=freq,
        preferred_genres=genres,
    )

# ─── BOOKSHELF CRUD ───────────────────────────────────────────────────────────

@router.get("/bookshelf", response_model=List[BookshelfItemResponse])
def get_bookshelf_items(
    category: Optional[str] = Query(None, description="currently_reading, want_to_read, completed, history"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(BookshelfItem).filter(BookshelfItem.user_id == user.id)
    if category:
        query = query.filter(BookshelfItem.category == category)
    items = query.all()
    return [BookshelfItemResponse.from_orm(i) for i in items]

@router.post("/bookshelf", response_model=BookshelfItemResponse, status_code=status.HTTP_201_CREATED)
def add_bookshelf_item(
    payload: BookshelfItemCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Prevent duplicate bookshelf entries for same user and book
    existing = None
    if payload.book_id:
        existing = db.query(BookshelfItem).filter(
            BookshelfItem.user_id == user.id,
            BookshelfItem.book_id == payload.book_id
        ).first()
    if not existing and payload.title:
        existing = db.query(BookshelfItem).filter(
            BookshelfItem.user_id == user.id,
            BookshelfItem.title.ilike(payload.title.strip()),
            BookshelfItem.author.ilike(payload.author.strip())
        ).first()

    if existing:
        if payload.category and payload.category != existing.category:
            existing.category = payload.category
            if payload.category == "completed":
                existing.progress = 1.0
                existing.current_page = existing.total_pages
                existing.finished_at = datetime.datetime.utcnow()
            elif payload.category == "currently_reading" and not existing.started_at:
                existing.started_at = datetime.datetime.utcnow()
        if payload.rating is not None:
            existing.rating = payload.rating
        if payload.personal_notes is not None:
            existing.personal_notes = payload.personal_notes
        if payload.progress is not None and payload.progress > existing.progress:
            existing.progress = payload.progress
        if payload.current_page is not None and payload.current_page > existing.current_page:
            existing.current_page = payload.current_page
        db.commit()
        db.refresh(existing)
        return BookshelfItemResponse.from_orm(existing)

    item = BookshelfItem(
        user_id=user.id,
        book_id=payload.book_id,
        title=payload.title,
        author=payload.author,
        cover_url=payload.cover_url,
        category=payload.category,
        progress=payload.progress,
        current_page=payload.current_page,
        total_pages=payload.total_pages,
        status=payload.status,
        format=payload.format,
        days_left=payload.days_left,
        genre=payload.genre,
        personal_notes=payload.personal_notes,
        rating=payload.rating,
        started_at=datetime.datetime.utcnow() if payload.category == "currently_reading" else None,
        finished_at=datetime.datetime.utcnow() if payload.category == "completed" else None,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    if payload.category == "completed":
        _sync_reading_goal(user.id, db)
    return BookshelfItemResponse.from_orm(item)

@router.get("/bookshelf/{item_id}", response_model=BookshelfItemResponse)
def get_bookshelf_item_by_id(
    item_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(BookshelfItem).filter(BookshelfItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Bookshelf item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this bookshelf item")
    return BookshelfItemResponse.from_orm(item)

@router.put("/bookshelf/{item_id}", response_model=BookshelfItemResponse)
def update_bookshelf_item(
    item_id: int,
    payload: BookshelfItemUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(BookshelfItem).filter(BookshelfItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Bookshelf item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this bookshelf item")

    update_dict = payload.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(item, k, v)

    # Auto-adjust status/dates if category changed
    if "category" in update_dict:
        if update_dict["category"] == "completed":
            item.progress = 1.0
            item.current_page = item.total_pages
            item.finished_at = datetime.datetime.utcnow()
        elif update_dict["category"] == "currently_reading" and not item.started_at:
            item.started_at = datetime.datetime.utcnow()

    db.commit()
    db.refresh(item)
    if "category" in update_dict and update_dict["category"] == "completed":
        _sync_reading_goal(user.id, db)
    return BookshelfItemResponse.from_orm(item)

@router.patch("/bookshelf/{item_id}/move", response_model=BookshelfItemResponse)
def move_bookshelf_item(
    item_id: int,
    payload: BookshelfItemMove,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(BookshelfItem).filter(BookshelfItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Bookshelf item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this bookshelf item")

    item.category = payload.category
    if payload.current_page is not None:
        item.current_page = payload.current_page
    if payload.progress is not None:
        item.progress = payload.progress
    if payload.status is not None:
        item.status = payload.status

    if payload.category == "completed":
        item.progress = 1.0
        item.current_page = item.total_pages
        item.finished_at = datetime.datetime.utcnow()
        if not item.status or item.status == "Active Rental":
            item.status = "Finished"
    elif payload.category == "currently_reading":
        if not item.started_at:
            item.started_at = datetime.datetime.utcnow()

    db.commit()
    db.refresh(item)
    if payload.category == "completed":
        _sync_reading_goal(user.id, db)
    return BookshelfItemResponse.from_orm(item)

@router.delete("/bookshelf/{item_id}", status_code=status.HTTP_200_OK)
def delete_bookshelf_item(
    item_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(BookshelfItem).filter(BookshelfItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Bookshelf item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this bookshelf item")

    db.delete(item)
    db.commit()
    _sync_reading_goal(user.id, db)
    return {"message": "Bookshelf item deleted successfully", "id": item_id}

# ─── READING GOALS ────────────────────────────────────────────────────────────

@router.get("/goals", response_model=ReadingGoalResponse)
def get_reading_goal(
    year: Optional[int] = Query(None, description="Target year, defaults to current UTC year"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = _get_or_create_reading_goal(user.id, db, year)
    return ReadingGoalResponse.from_orm(goal)

@router.put("/goals", response_model=ReadingGoalResponse)
def update_reading_goal(
    payload: ReadingGoalUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_year = payload.year or datetime.datetime.utcnow().year
    goal = _get_or_create_reading_goal(user.id, db, target_year)

    update_dict = payload.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(goal, k, v)

    db.commit()
    db.refresh(goal)
    return ReadingGoalResponse.from_orm(goal)
