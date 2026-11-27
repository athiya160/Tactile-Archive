import os
import sys
# Make sure app path is in system path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
# Import all models to register them with SQLAlchemy
from app.models.user import User
from app.models.favorite import Favorite
from app.models.book import Book, BookImage
from app.models.review import Review
from app.models.cart import Cart, CartItem
from app.models.address import Address
from app.models.notification import Notification
from app.models.order import Order, OrderItem

from app.api.books import get_catalog

db = SessionLocal()
try:
    print("Calling get_catalog(...) directly:")
    result = get_catalog(page=1, limit=10, db=db)
    print(f"Catalog result: {result}")
finally:
    db.close()
