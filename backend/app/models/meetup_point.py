from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class MeetupPoint(Base):
    __tablename__ = "meetup_points"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False) # e.g. "Central Campus Library - Safe Exchange Desk"
    address = Column(String, nullable=False)
    city = Column(String, default="University City")
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_verified_hub = Column(Boolean, default=True)
    operating_hours = Column(String, default="08:00 AM - 08:00 PM")
    security_features = Column(String, default="CCTV Monitored • Verified Student Counter")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
