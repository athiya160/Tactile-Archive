from sqlalchemy import Column, Integer, String, ForeignKey, Float, DateTime
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base

class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True)
    title = Column(String)
    author = Column(String)
    description = Column(String, nullable=True)
    price = Column(Float, default=0.0)
    rating = Column(Float, default=0.0)
    category = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    publisher = Column(String, nullable=True)
    language = Column(String, nullable=True)
    isbn = Column(String, nullable=True)
    edition = Column(String, nullable=True)
    pages = Column(String, nullable=True)
    condition = Column(String, nullable=True)
    stock = Column(Integer, default=1)
    owner_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    # Amazon-like additions
    approval_status = Column(String, default="pending_approval")
    condition_verification = Column(String, default="pending")
    verification_notes = Column(String, nullable=True)

    owner = relationship("User", back_populates="books")
    favorited_by = relationship("Favorite", back_populates="book", cascade="all, delete-orphan")
    images = relationship("BookImage", back_populates="book", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="book", cascade="all, delete-orphan")

    @property
    def image_url(self):
        if self.cover_url:
            return self.cover_url
        if self.images and len(self.images) > 0:
            return self.images[0].image_url
        image_id = ((self.id - 1) % 7) + 1
        return f"/images/book{image_id}.jpg"

class BookImage(Base):
    __tablename__ = "book_images"

    id = Column(Integer, primary_key=True)
    book_id = Column(Integer, ForeignKey("books.id", ondelete="CASCADE"))
    image_url = Column(String)

    book = relationship("Book", back_populates="images")
