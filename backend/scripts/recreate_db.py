import sys
import os

from app.core.database import engine, Base

# Import all models to register on Base.metadata
from app.models.user import User
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.address import Address
from app.models.notification import Notification, FCMToken

from sqlalchemy import text

def reset_db():
    print("Dropping all tables...")
    with engine.connect() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public;"))
        conn.commit()
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("Database reset successfully.")

if __name__ == "__main__":
    reset_db()
