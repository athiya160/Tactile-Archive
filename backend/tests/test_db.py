from app.core.database import SessionLocal
from app.models.book import Book

def test_database_connection_and_book_query():
    """Verify database connection and querying of books."""
    db = SessionLocal()
    try:
        books = db.query(Book).limit(5).all()
        assert isinstance(books, list)
    finally:
        db.close()
