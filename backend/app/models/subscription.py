from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class NeighborhoodSubscription(Base):
    __tablename__ = "neighborhood_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    plan_name = Column(String, default="Neighborhood Pass")
    monthly_price = Column(Float, default=9.99)
    status = Column(String, default="active") # active, canceled, expired
    unlimited_rentals = Column(Boolean, default=True)
    max_active_books = Column(Integer, default=3)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)

    user = relationship("User")
