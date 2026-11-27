from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base

def current_year():
    return datetime.datetime.utcnow().year

class BookshelfItem(Base):
    __tablename__ = "bookshelf_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    book_id = Column(Integer, ForeignKey("books.id", ondelete="SET NULL"), nullable=True)
    title = Column(String, nullable=False)
    author = Column(String, nullable=False)
    cover_url = Column(String, nullable=True)
    category = Column(String, default="want_to_read") # "currently_reading", "want_to_read", "completed", "history"
    progress = Column(Float, default=0.0) # 0.0 to 1.0
    current_page = Column(Integer, default=0)
    total_pages = Column(Integer, default=300)
    status = Column(String, default="Personal Library") # "Active Rental", "Personal Library", "Borrowed", "Finished"
    format = Column(String, default="Paperback") # "Paperback", "Hardcover", "E-book", "Audiobook"
    days_left = Column(Integer, nullable=True) # for rentals/borrows
    genre = Column(String, nullable=True)
    personal_notes = Column(Text, nullable=True)
    rating = Column(Float, nullable=True) # 1.0 to 5.0
    started_at = Column(DateTime, nullable=True)
    finished_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="bookshelf_items")
    book = relationship("Book")


class ReadingGoal(Base):
    __tablename__ = "reading_goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    year = Column(Integer, default=current_year)
    target_books = Column(Integer, default=12)
    completed_books = Column(Integer, default=0)
    target_pages = Column(Integer, default=3000)
    pages_read = Column(Integer, default=0)
    daily_reading_goal_minutes = Column(Integer, default=30)
    streak_days = Column(Integer, default=0)
    last_read_date = Column(String, nullable=True) # YYYY-MM-DD
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="reading_goals")
