from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
# Import all other models that might be referenced
from app.models.order import Order, OrderItem
from app.models.cart import Cart, CartItem
from app.models.review import Review
from app.models.favorite import Favorite
from sqlalchemy import func

def check_user():
    db = SessionLocal()
    users = db.query(User).all()
    print("--------------------------------------------------")
    print("REGISTERED USERS IN DATABASE:")
    for u in users:
        print(f"- {u.email} (Verified: {u.is_verified})")
    print("--------------------------------------------------")
    
    books = db.query(Book).all()
    print("BOOKS IN DATABASE:")
    for b in books:
        print(f"- {b.title} (Category: {b.category})")
    print("--------------------------------------------------")
    
    db.close()

if __name__ == "__main__":
    check_user()
