from sqlalchemy import Column, Integer, String, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class InventoryReservation(Base):
    __tablename__ = "inventory_reservations"

    id = Column(Integer, primary_key=True, index=True)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    quantity = Column(Integer, nullable=False, default=1)
    status = Column(String(20), nullable=False, default="active")  # active, fulfilled, expired, released
    expires_at = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    book = relationship("Book")
    order = relationship("Order", back_populates="reservations")
    user = relationship("User")

    def is_expired(self, now: datetime = None) -> bool:
        if now is None:
            now = datetime.utcnow()
        return self.status == "active" and self.expires_at <= now
