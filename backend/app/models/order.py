from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, DateTime, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="pending")
    total_items = Column(Integer)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Order tracking additions
    tracking_id = Column(String, nullable=True)
    carrier = Column(String, nullable=True)
    estimated_delivery = Column(DateTime, nullable=True)
    shipping_status = Column(String, default="pending")
    
    # Financials and Delivery
    total_amount = Column(Float, default=0.0)
    delivery_address = Column(String, nullable=True)
    payment_method = Column(String, nullable=True)
    payment_status = Column(String, default="pending")

    # Phase 16C.2B Additive Pricing & Fulfillment Fields
    items_total_paise = Column(Integer, nullable=True)
    deposit_total_paise = Column(Integer, nullable=True)
    shipping_fee_paise = Column(Integer, default=0, nullable=True)
    platform_fee_paise = Column(Integer, default=120, nullable=True)
    total_amount_paise = Column(Integer, nullable=True)
    delivery_method = Column(String(50), default="standard", nullable=True)
    recipient_name = Column(String(255), nullable=True)
    recipient_phone = Column(String(50), nullable=True)
    idempotency_key = Column(String(100), unique=True, index=True, nullable=True)
    stock_deducted = Column(Boolean, default=False, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=True)

    # Safe Exchange & QR Escrow Handoff
    handoff_status = Column(String, default="pending_handoff") # pending_handoff, handoff_completed, returned_completed
    meetup_point_id = Column(Integer, ForeignKey("meetup_points.id"), nullable=True)
    lender_qr_token = Column(String, nullable=True)
    borrower_qr_token = Column(String, nullable=True)
    lender_scanned = Column(Boolean, default=False)
    borrower_scanned = Column(Boolean, default=False)
    escrow_released_at = Column(DateTime, nullable=True)

    user = relationship("User")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    reservations = relationship("InventoryReservation", back_populates="order", cascade="all, delete-orphan")

    @property
    def subtotal_in_rupees(self) -> float:
        if self.items_total_paise is not None:
            return round(self.items_total_paise / 100.0, 2)
        return float(self.total_amount or 0.0)

    @property
    def total_in_rupees(self) -> float:
        if self.total_amount_paise is not None:
            return round(self.total_amount_paise / 100.0, 2)
        return float(self.total_amount or 0.0)


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    
    # Snapshot data
    book_title = Column(String)
    book_author = Column(String)
    book_image = Column(String)
    
    is_purchase = Column(Boolean, default=False)
    rental_days = Column(Integer, default=14)
    quantity = Column(Integer, default=1)
    price = Column(Float, default=0.0)

    # Phase 16C.2B Additive Pricing & Item Tracking Fields
    provider_id = Column(Integer, nullable=True)
    transaction_type = Column(String(20), default="buy", nullable=True) # buy, rent, borrow
    unit_price_paise = Column(Integer, nullable=True)
    rental_fee_paise = Column(Integer, nullable=True)
    deposit_paise = Column(Integer, nullable=True)
    total_item_paise = Column(Integer, nullable=True)
    status = Column(String(50), default="pending", nullable=True)

    order = relationship("Order", back_populates="items")


class BorrowRequest(Base):
    __tablename__ = "borrow_requests"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    duration_days = Column(Integer, default=14)
    status = Column(String, default="approved")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    book = relationship("Book")


class RentalOrder(Base):
    __tablename__ = "rental_orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    rental_days = Column(Integer)
    rental_fee = Column(Float)
    payment_method = Column(String)
    shipping_address = Column(String)
    status = Column(String, default="active")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    book = relationship("Book")


class PurchaseOrder(Base):
    __tablename__ = "purchase_orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    book_id = Column(Integer, ForeignKey("books.id"))
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    price = Column(Float)
    payment_method = Column(String)
    shipping_address = Column(String)
    status = Column(String, default="completed")
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
    book = relationship("Book")
    order = relationship("Order")
