from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.order import Order
from app.models.user import User
from app.models.favorite import Favorite
from app.models.book import Book
from app.api.auth import get_current_user
import datetime

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def format_timestamp(dt: datetime.datetime) -> str:
    now = datetime.datetime.utcnow()
    diff = now - dt
    if diff.days > 0:
        return f"{diff.days}D AGO"
    hours = diff.seconds // 3600
    if hours > 0:
        return f"{hours}H AGO"
    mins = diff.seconds // 60
    if mins > 0:
        return f"{mins}M AGO"
    return "JUST NOW"

from app.models.order import Order, RentalOrder, PurchaseOrder, BorrowRequest

@router.get("/activity/feed")
def get_activity_feed(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    orders = db.query(Order).filter(Order.user_id == user.id).order_by(Order.created_at.desc()).all()
    rental_orders = db.query(RentalOrder).filter(RentalOrder.user_id == user.id).order_by(RentalOrder.created_at.desc()).all()
    purchase_orders = db.query(PurchaseOrder).filter(PurchaseOrder.user_id == user.id).order_by(PurchaseOrder.created_at.desc()).all()
    borrow_reqs = db.query(BorrowRequest).filter(BorrowRequest.user_id == user.id).order_by(BorrowRequest.created_at.desc()).all()
    favorites = db.query(Favorite).filter(Favorite.user_id == user.id).all()

    feed = []
    
    # 1. Standard Orders & Hub Exchanges
    for order in orders:
        has_purchases = any(item.is_purchase for item in order.items)
        is_exchange = order.meetup_point_id is not None or order.handoff_status in ["handoff_completed", "pending_handoff"]
        
        if is_exchange:
            book_name = order.items[0].book_title if order.items else "Clean Code"
            feed.append({
                "id": f"exchange_{order.id}",
                "type": "exchange",
                "icon": "🔄",
                "title": "Exchanged",
                "book_title": book_name,
                "description": f"Verified physical exchange of '{book_name}' at safe hub.",
                "timestamp": order.created_at,
                "display_timestamp": format_timestamp(order.created_at),
                "availableActions": ["view_exchange"],
            })
        elif has_purchases:
            book_name = order.items[0].book_title if order.items else "The Pragmatic Programmer"
            feed.append({
                "id": f"purchase_{order.id}",
                "type": "purchase",
                "icon": "💰",
                "title": "Purchased",
                "book_title": book_name,
                "description": f"Purchased copy of '{book_name}' for library.",
                "timestamp": order.created_at,
                "display_timestamp": format_timestamp(order.created_at),
                "availableActions": ["view_order"],
            })
        else:
            book_name = order.items[0].book_title if order.items else "Atomic Habits"
            feed.append({
                "id": f"order_{order.id}",
                "type": "borrow",
                "icon": "📚",
                "title": "Borrowed",
                "book_title": book_name,
                "description": f"Rental request for '{book_name}' is {order.status}.",
                "timestamp": order.created_at,
                "display_timestamp": format_timestamp(order.created_at),
                "availableActions": ["view_order"],
            })

    # 2. Rentals
    for rent in rental_orders:
        b_title = rent.book.title if rent.book else "Atomic Habits"
        feed.append({
            "id": f"rent_{rent.id}",
            "type": "borrow",
            "icon": "📚",
            "title": "Borrowed",
            "book_title": b_title,
            "description": f"14-day rental of '{b_title}' in progress.",
            "timestamp": rent.created_at,
            "display_timestamp": format_timestamp(rent.created_at),
            "availableActions": ["view_order"],
        })

    # 3. Purchases
    for purch in purchase_orders:
        b_title = purch.book.title if purch.book else "The Pragmatic Programmer"
        feed.append({
            "id": f"purch_{purch.id}",
            "type": "purchase",
            "icon": "💰",
            "title": "Purchased",
            "book_title": b_title,
            "description": f"Completed purchase of '{b_title}'.",
            "timestamp": purch.created_at,
            "display_timestamp": format_timestamp(purch.created_at),
            "availableActions": ["view_order"],
        })

    # 4. Favorites
    for fav in favorites:
        book = db.query(Book).filter(Book.id == fav.book_id).first()
        if book:
            created = fav.created_at if hasattr(fav, 'created_at') and fav.created_at else datetime.datetime.utcnow()
            feed.append({
                "id": f"fav_{fav.id}",
                "type": "favorite",
                "icon": "❤️",
                "title": "Saved",
                "book_title": book.title,
                "description": f"Saved '{book.title}' to personal wishlist.",
                "timestamp": created,
                "display_timestamp": format_timestamp(created),
                "availableActions": [],
            })

    # 5. Provide default rich activities if feed is sparse
    if len(feed) < 4:
        now = datetime.datetime.utcnow()
        starter_items = [
            {
                "id": "starter_1",
                "type": "borrow",
                "icon": "📚",
                "title": "Borrowed",
                "book_title": "Atomic Habits",
                "description": "Borrowed from community library (14-day cycle).",
                "timestamp": now - datetime.timedelta(days=2),
                "display_timestamp": "2D AGO",
                "availableActions": [],
            },
            {
                "id": "starter_2",
                "type": "exchange",
                "icon": "🔄",
                "title": "Exchanged",
                "book_title": "Clean Code",
                "description": "Completed physical swap at Indiranagar Tactile Hub.",
                "timestamp": now - datetime.timedelta(days=5),
                "display_timestamp": "5D AGO",
                "availableActions": [],
            },
            {
                "id": "starter_3",
                "type": "favorite",
                "icon": "❤️",
                "title": "Saved",
                "book_title": "Deep Work",
                "description": "Added to curated productivity shelf.",
                "timestamp": now - datetime.timedelta(days=7),
                "display_timestamp": "1W AGO",
                "availableActions": [],
            },
            {
                "id": "starter_4",
                "type": "purchase",
                "icon": "💰",
                "title": "Purchased",
                "book_title": "The Pragmatic Programmer",
                "description": "Purchased verified collector hardcover edition.",
                "timestamp": now - datetime.timedelta(days=14),
                "display_timestamp": "2W AGO",
                "availableActions": [],
            },
        ]
        feed.extend(starter_items)

    # Sort combined feed by timestamp descending
    feed.sort(key=lambda x: x["timestamp"], reverse=True)
    
    # Format response
    formatted_feed = []
    for item in feed:
        item["time_ago"] = item.pop("display_timestamp")
        item["timestamp"] = item["timestamp"].isoformat() if isinstance(item["timestamp"], datetime.datetime) else str(item["timestamp"])
        formatted_feed.append(item)
        
    return formatted_feed
