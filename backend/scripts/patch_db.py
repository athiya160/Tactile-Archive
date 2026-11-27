import sys
from sqlalchemy import create_engine, text
from app.core.database import engine, Base

# Import all models to populate Base.metadata
from app.models.user import User
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.address import Address
from app.models.notification import Notification, FCMToken

DATABASE_URL = "postgresql://library_user:1234@localhost:5432/library_db"

def patch_db():
    try:
        # 1. Add missing columns to users table
        with engine.connect() as conn:
            print("Altering users table to add missing columns if they don't exist...")
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR NULL;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR NULL;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS bio VARCHAR NULL;"))
            conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications VARCHAR NULL;"))
            conn.commit()
            print("Users table altered successfully.")
            
            # 2. Set as@gmail.com as admin
            print("Setting user 'as@gmail.com' as admin...")
            res = conn.execute(text("UPDATE users SET is_admin = TRUE WHERE email = 'as@gmail.com';"))
            conn.commit()
            print("Updated rows:", res.rowcount)
            
            # 3. Double check and print users
            res_users = conn.execute(text("SELECT id, email, is_admin FROM users"))
            print("Current users:")
            for r in res_users:
                print(r)
                
    except Exception as e:
        print("Error altering database columns:", e)
        
    # 4. Create missing tables (e.g. notifications, fcm_tokens)
    print("Creating all tables via metadata...")
    try:
        Base.metadata.create_all(bind=engine)
        print("Table creation complete.")
    except Exception as e:
        print("Error creating tables:", e)

if __name__ == "__main__":
    patch_db()
