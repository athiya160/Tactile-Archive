from app.core.database import SessionLocal
from app.models.user import User
# Make sure to import Book so the relationship maps properly
from app.models.book import Book
from sqlalchemy import func

def check_user():
    db = SessionLocal()
    email1 = "athiya160@gmail.com"
    email2 = "kfasiha609@gmail.com"
    
    users = db.query(User).all()
    print("Registered Users in Database:")
    for u in users:
        print(f"- {u.email}")
    
    db.close()

if __name__ == "__main__":
    check_user()
