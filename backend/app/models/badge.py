from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class Badge(Base):
    __tablename__ = "badges"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False) # e.g. "SCHOLAR_10", "STREAK_7", "COMMUNITY_LENDER"
    title = Column(String, nullable=False)
    description = Column(String, nullable=False)
    icon = Column(String, default="🏅")
    category = Column(String, default="Reading")


class UserBadge(Base):
    __tablename__ = "user_badges"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    badge_id = Column(Integer, ForeignKey("badges.id"))
    earned_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    badge = relationship("Badge")
