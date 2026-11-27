from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base

class ReaderProfile(Base):
    __tablename__ = "reader_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)
    genres = Column(Text, nullable=True) # Stored as JSON string
    favorite_authors = Column(Text, nullable=True) # Stored as JSON string
    reading_goal = Column(String, nullable=True) # e.g. Read 12 books this year
    preferred_duration = Column(Integer, default=30) # minutes per session
    favorite_moods = Column(Text, nullable=True) # Stored as JSON string
    reading_frequency = Column(String, default="Daily") # Daily, Weekly, Monthly
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", back_populates="reader_profile")
