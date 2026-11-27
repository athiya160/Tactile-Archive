from pydantic import BaseModel, Field
from typing import Optional, List
import datetime

# --- Bookshelf Item Schemas ---
class BookshelfItemBase(BaseModel):
    title: str
    author: str
    book_id: Optional[int] = None
    cover_url: Optional[str] = None
    category: str = "want_to_read" # "currently_reading", "want_to_read", "completed", "history"
    progress: float = Field(default=0.0, ge=0.0, le=1.0)
    current_page: int = 0
    total_pages: int = 300
    status: str = "Personal Library" # "Active Rental", "Personal Library", "Borrowed", "Finished"
    format: str = "Paperback" # "Paperback", "Hardcover", "E-book", "Audiobook"
    days_left: Optional[int] = None
    genre: Optional[str] = None
    personal_notes: Optional[str] = None
    rating: Optional[float] = Field(default=None, ge=1.0, le=5.0)

class BookshelfItemCreate(BookshelfItemBase):
    pass

class BookshelfItemUpdate(BaseModel):
    title: Optional[str] = None
    author: Optional[str] = None
    book_id: Optional[int] = None
    cover_url: Optional[str] = None
    category: Optional[str] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    current_page: Optional[int] = None
    total_pages: Optional[int] = None
    status: Optional[str] = None
    format: Optional[str] = None
    days_left: Optional[int] = None
    genre: Optional[str] = None
    personal_notes: Optional[str] = None
    rating: Optional[float] = Field(default=None, ge=1.0, le=5.0)

class BookshelfItemMove(BaseModel):
    category: str # Target category: "currently_reading", "want_to_read", "completed", "history"
    current_page: Optional[int] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    status: Optional[str] = None

class BookshelfItemResponse(BookshelfItemBase):
    id: int
    user_id: int
    started_at: Optional[datetime.datetime] = None
    finished_at: Optional[datetime.datetime] = None
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Reading Goal Schemas ---
def current_year():
    return datetime.datetime.now().year

class ReadingGoalBase(BaseModel):
    year: int = Field(default_factory=current_year)
    target_books: int = 12
    completed_books: int = 0
    target_pages: int = 3000
    pages_read: int = 0
    daily_reading_goal_minutes: int = 30
    streak_days: int = 0
    last_read_date: Optional[str] = None

class ReadingGoalCreate(ReadingGoalBase):
    pass

class ReadingGoalUpdate(BaseModel):
    year: Optional[int] = None
    target_books: Optional[int] = None
    completed_books: Optional[int] = None
    target_pages: Optional[int] = None
    pages_read: Optional[int] = None
    daily_reading_goal_minutes: Optional[int] = None
    streak_days: Optional[int] = None
    last_read_date: Optional[str] = None

class ReadingGoalResponse(ReadingGoalBase):
    id: int
    user_id: int
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Reader Dashboard Summary Schema ---
class ReaderDashboardSummary(BaseModel):
    goal: Optional[ReadingGoalResponse] = None
    currently_reading: List[BookshelfItemResponse] = []
    want_to_read: List[BookshelfItemResponse] = []
    completed: List[BookshelfItemResponse] = []
    paused: List[BookshelfItemResponse] = []
    total_books_read: int = 0
    current_streak_days: int = 0
    reading_frequency: Optional[str] = "Daily"
    preferred_genres: List[str] = []
