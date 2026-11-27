import sys
import os
from sqlalchemy import create_engine, text
from app.core.database import engine, Base

# Import all models to satisfy SQLAlchemy configuration
from app.models.user import User
from app.models.book import Book, BookImage
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.address import Address
from app.models.notification import Notification, FCMToken
from app.models.review import Review

def patch_db_v3():
    try:
        with engine.connect() as conn:
            print("1. Altering 'reviews' table to add order_id...")
            conn.execute(text("ALTER TABLE reviews ADD COLUMN IF NOT EXISTS order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE;"))
            conn.commit()
            print("Reviews table altered successfully with order_id.")
    except Exception as e:
        print("Error altering database columns:", e)

    print("Running Base.metadata.create_all to ensure all models exist...")
    try:
        Base.metadata.create_all(bind=engine)
        print("Metadata check complete.")
    except Exception as e:
        print("Error checking metadata tables:", e)

if __name__ == "__main__":
    patch_db_v3()
