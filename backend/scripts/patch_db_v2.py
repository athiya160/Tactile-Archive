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

def patch_db_v2():
    try:
        with engine.connect() as conn:
            print("1. Altering 'books' table to add approval status and condition verification...")
            conn.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS approval_status VARCHAR DEFAULT 'approved';"))
            conn.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS condition_verification VARCHAR DEFAULT 'verified';"))
            conn.execute(text("ALTER TABLE books ADD COLUMN IF NOT EXISTS verification_notes VARCHAR NULL;"))
            conn.commit()
            print("Books table altered successfully.")
            
            print("2. Altering 'orders' table to add tracking info...")
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS tracking_id VARCHAR NULL;"))
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS carrier VARCHAR NULL;"))
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery TIMESTAMP NULL;"))
            conn.execute(text("ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipping_status VARCHAR DEFAULT 'pending';"))
            conn.commit()
            print("Orders table altered successfully.")
            
            print("3. Creating 'reviews' table if not exists...")
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS reviews (
                    id SERIAL PRIMARY KEY,
                    book_id INTEGER REFERENCES books(id) ON DELETE CASCADE,
                    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                    rating FLOAT NOT NULL,
                    comment TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """))
            conn.commit()
            print("Reviews table created or checked successfully.")

            print("4. Creating 'book_images' table if not exists...")
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS book_images (
                    id SERIAL PRIMARY KEY,
                    book_id INTEGER REFERENCES books(id) ON DELETE CASCADE,
                    image_url VARCHAR NOT NULL
                );
            """))
            conn.commit()
            print("Book images table created or checked successfully.")

            print("Database migration (patch_db_v2) completed successfully!")
    except Exception as e:
        print("Error altering database columns:", e)

    # Recreate SQLAlchemy metadata tables if any are missing
    print("Running Base.metadata.create_all to ensure all models exist...")
    try:
        Base.metadata.create_all(bind=engine)
        print("Metadata check complete.")
    except Exception as e:
        print("Error checking metadata tables:", e)

if __name__ == "__main__":
    patch_db_v2()
