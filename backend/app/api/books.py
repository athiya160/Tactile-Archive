from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.book import Book, BookImage
from app.models.user import User
from app.models.favorite import Favorite
from app.schemas.book import BookCreate, BookResponse, BookUpdate
from app.api.auth import get_current_user
from typing import Optional, List
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt
from app.core.security import SECRET_KEY, ALGORITHM, get_jwt_secret
from app.api.auth import REVOKED_TOKENS

router = APIRouter()
security = HTTPBearer(auto_error=False)

# DB connection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Helper to resolve user optionally for public routes
def get_optional_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security), db: Session = Depends(get_db)):
    if not credentials:
        return None
    try:
        token = credentials.credentials
        if token in REVOKED_TOKENS:
            return None
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])
        if payload.get("type") in ["refresh", "verification"]:
            return None
        email = payload.get("sub")
        if email:
            return db.query(User).filter(User.email == email).first()
    except Exception:
        pass
    return None

def serialize_book(book: Book, user_id: Optional[int] = None, db: Optional[Session] = None) -> dict:
    is_fav = False
    if user_id and db:
        fav = db.query(Favorite).filter(Favorite.user_id == user_id, Favorite.book_id == book.id).first()
        is_fav = fav is not None

    # Dynamically calculate rating
    avg_rating = book.rating or 0.0
    total_reviews = 0
    if book.reviews:
        total_reviews = len(book.reviews)
        avg_rating = sum(r.rating for r in book.reviews) / total_reviews

    # Build image gallery list (starting with primary cover)
    gallery_images = []
    if book.image_url:
        gallery_images.append(book.image_url)
    if book.images:
        for img in book.images:
            if img.image_url and img.image_url not in gallery_images:
                gallery_images.append(img.image_url)

    listing_type = "forSale"
    if (book.price or 0.0) == 0.0:
        listing_type = "donate"
    elif (book.price or 0.0) < 5.0 or (book.description and "rent" in book.description.lower()) or (book.edition and "academic" in book.edition.lower()):
        listing_type = "forRent"

    orig_price = None
    discount_pct = None
    if listing_type == "forRent" and book.price and book.price > 0:
        orig_price = round(book.price * 1.2, 2)
        discount_pct = 20.0
    elif listing_type == "forSale" and book.price and book.price > 10.0:
        orig_price = round(book.price * 1.25, 2)
        discount_pct = 20.0

    is_staff = (book.rating or 0.0) >= 4.9 or book.title in [
        "The Architect of Forgotten Dreams",
        "Whispers of the Ancient Vellum",
        "The Shadow of the Wind"
    ]

    cats = [book.category] if book.category else ["All Books"]
    if "All Books" not in cats:
        cats.append("All Books")

    # Safe Provider & Seller Serialization (Never invent ratings, locations, or badges)
    provider_info = None
    if book.owner:
        campus = None
        if hasattr(book.owner, "student_profile") and book.owner.student_profile:
            campus = getattr(book.owner.student_profile, "college", None) or getattr(book.owner.student_profile, "institution", None)
        
        provider_listings_count = len(book.owner.books) if book.owner.books else 1
        
        provider_info = {
            "id": book.owner.id,
            "name": book.owner.name or "Community Provider",
            "avatar_url": book.owner.avatar_url,
            "is_verified": bool(book.owner.is_verified or book.owner.provider_status == "active"),
            "role": book.owner.role or "customer",
            "level": book.owner.level or "Standard Reader",
            "campus": campus,
            "rating": None,  # Kept strictly null unless backed by real provider reviews
            "listings_count": provider_listings_count,
        }

    # Dynamic Availability & Action Modalities
    stock_count = book.stock if book.stock is not None else 1
    is_in_stock = stock_count > 0
    is_approved = (book.approval_status or "approved") == "approved"
    is_available = is_in_stock and is_approved

    can_buy = is_available and (book.price or 0.0) > 0.0 and listing_type in ["forSale", "forRent"]
    can_rent = is_available and listing_type in ["forRent", "forSale"]
    can_borrow = is_available and (listing_type in ["donate", "borrow"] or (book.description and "borrow" in book.description.lower()))

    base_price = book.price or 0.0
    rental_options = {
        "daily_rate": round(max(base_price * 0.015, 2.0), 2) if base_price > 0 else 5.0,
        "fee_7d": round(max(base_price * 0.10, 15.0), 2) if base_price > 0 else 25.0,
        "fee_14d": round(max(base_price * 0.15, 25.0), 2) if base_price > 0 else 40.0,
        "fee_30d": round(max(base_price * 0.25, 45.0), 2) if base_price > 0 else 75.0,
        "deposit": round(base_price * 0.50, 2) if base_price > 0 else 50.0,
    }

    return {
        "id": book.id,
        "title": book.title,
        "author": book.author,
        "description": book.description or "",
        "price": book.price or 0.0,
        "rating": avg_rating,
        "totalReviews": total_reviews,
        "category": book.category or "Uncategorized",
        "categories": cats,
        "listingType": listing_type,
        "originalPrice": orig_price,
        "discountPercentage": discount_pct,
        "isStaffPick": is_staff,
        "publisher": book.publisher or "",
        "language": book.language or "",
        "isbn": book.isbn or "",
        "edition": book.edition or "",
        "pages": book.pages or "",
        "condition": book.condition or "Good",
        "stock": stock_count,
        "coverUrl": book.image_url,
        "cover_url": book.cover_url,
        "image_url": book.image_url,
        "isFavorite": is_fav,
        "owner_id": book.owner_id,
        "approval_status": book.approval_status or "approved",
        "condition_verification": book.condition_verification or "verified",
        "verification_notes": book.verification_notes or "",
        "images": gallery_images,
        "provider": provider_info,
        "provider_name": provider_info["name"] if provider_info else None,
        "provider_campus": provider_info["campus"] if provider_info else None,
        "provider_verified": provider_info["is_verified"] if provider_info else False,
        "provider_rating": provider_info["rating"] if provider_info else None,
        "is_available": is_available,
        "availability_status": "in_stock" if is_available else ("out_of_stock" if not is_in_stock else "pending_review"),
        "can_buy": can_buy,
        "can_rent": can_rent,
        "can_borrow": can_borrow,
        "rental_options": rental_options,
    }

# 🔒 Add Book (Protected)
@router.post("/books", response_model=BookResponse)
def add_book(
    book: BookCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    # Auto-approve all books for demonstration purposes
    status = "approved"
    verification = "verified"

    new_book = Book(
        title=book.title,
        author=book.author,
        description=book.description,
        price=book.price,
        category=book.category.strip().title() if book.category else None,
        cover_url=book.resolved_cover_url,
        stock=book.stock if book.stock is not None else 1,
        publisher=book.publisher,
        language=book.language,
        isbn=book.isbn,
        edition=book.edition,
        pages=book.pages,
        condition=book.condition,
        owner_id=user.id,
        approval_status=status,
        condition_verification=verification
    )
    db.add(new_book)
    db.commit()
    db.refresh(new_book)

    # Insert additional gallery photos
    if book.images:
        for img_url in book.images:
            if img_url:
                db.add(BookImage(book_id=new_book.id, image_url=img_url))
        db.commit()
        db.refresh(new_book)

    return serialize_book(new_book, user.id, db)

# 🔓 Get Featured Books (Public)
@router.get("/books/featured")
def get_featured_books(db: Session = Depends(get_db), user: Optional[User] = Depends(get_optional_user)):
    from sqlalchemy import case
    priority_titles = [
        'The Architect of Forgotten Dreams',
        'Whispers of the Ancient Vellum',
        'Window into Dawn',
        'Synthesis: The AI Era',
        'The Sea of Stars',
        'Crimson Leaves',
        'Calculus & Craft',
        'The Shadow of the Wind',
    ]
    order_case = case({title: idx for idx, title in enumerate(priority_titles)}, value=Book.title, else_=999)
    books = db.query(Book).filter(Book.approval_status == "approved").order_by(order_case, Book.rating.desc()).limit(8).all()
    
    return {
        "data": [
            serialize_book(book, user.id if (user and hasattr(user, 'id')) else None, db)
            for book in books
        ]
    }

# 🔒 Toggle Favorite Book
@router.post("/books/{book_id}/favorite")
def toggle_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    fav = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    is_favorite = False
    
    if fav:
        db.delete(fav)
        db.commit()
    else:
        new_fav = Favorite(user_id=user.id, book_id=book_id)
        db.add(new_fav)
        db.commit()
        is_favorite = True
        
    return {"isFavorite": is_favorite}

@router.get("/books/categories")
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Book.category).filter(Book.approval_status == "approved").distinct().all()
    result = ["All Books"] + [c[0] for c in categories if c[0]]
    if len(result) == 1:
        return ["All Books", "Fiction", "Non-Fiction", "Science", "History"]
    return result

def _build_book_query(
    db: Session,
    q: Optional[str] = None,
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    listing_type: Optional[str] = None,
    condition: Optional[str] = None,
    available_only: Optional[bool] = None,
    sort_by: Optional[str] = "relevance"
):
    from sqlalchemy import func, or_, case

    if min_price is not None and min_price < 0:
        raise HTTPException(status_code=422, detail="min_price must be >= 0")
    if max_price is not None and max_price < 0:
        raise HTTPException(status_code=422, detail="max_price must be >= 0")
    if min_price is not None and max_price is not None and min_price > max_price:
        raise HTTPException(status_code=422, detail="min_price cannot be greater than max_price")

    query = db.query(Book).filter(Book.approval_status == "approved")

    if q and q.strip():
        term = f"%{q.strip()}%"
        clean_isbn = f"%{q.replace('-', '').strip()}%"
        query = query.filter(
            or_(
                Book.title.ilike(term),
                Book.author.ilike(term),
                func.replace(Book.isbn, '-', '').ilike(clean_isbn),
                Book.description.ilike(term),
                Book.publisher.ilike(term),
                Book.category.ilike(term)
            )
        )

    if category and category.strip() and category.strip().lower() not in ["all", "all books"]:
        query = query.filter(func.lower(Book.category) == category.strip().lower())

    if min_price is not None:
        query = query.filter(Book.price >= min_price)

    if max_price is not None:
        query = query.filter(Book.price <= max_price)

    if condition and condition.strip() and condition.strip().lower() != "all":
        query = query.filter(func.lower(Book.condition) == condition.strip().lower())

    if available_only is True:
        query = query.filter(func.coalesce(Book.stock, 1) > 0)

    if listing_type and listing_type.strip() and listing_type.strip().lower() != "all":
        lt = listing_type.strip().lower()
        if lt in ["forsale", "sale", "buy"]:
            query = query.filter(Book.price >= 5.0)
        elif lt in ["forrent", "rent", "rental"]:
            query = query.filter(
                or_(
                    (Book.price > 0) & (Book.price < 5.0),
                    func.lower(func.coalesce(Book.description, '')).contains('rent'),
                    func.lower(func.coalesce(Book.edition, '')).contains('academic')
                )
            )
        elif lt in ["donate", "borrow", "exchange"]:
            query = query.filter(
                or_(
                    Book.price == 0.0,
                    func.lower(func.coalesce(Book.description, '')).contains('donate'),
                    func.lower(func.coalesce(Book.description, '')).contains('borrow')
                )
            )

    # Sorting
    sb = (sort_by or "relevance").strip().lower()
    if sb in ["price_asc", "price_low", "lowest price"]:
        query = query.order_by(Book.price.asc(), Book.id.desc())
    elif sb in ["price_desc", "price_high", "highest price"]:
        query = query.order_by(Book.price.desc(), Book.id.desc())
    elif sb in ["newest", "recent"]:
        query = query.order_by(Book.created_at.desc(), Book.id.desc())
    elif sb in ["rating", "popularity", "popular", "most popular"]:
        query = query.order_by(Book.rating.desc(), Book.id.desc())
    else:
        priority_titles = [
            'Window into Dawn',
            'Synthesis: The AI Era',
            'The Sea of Stars',
            'Crimson Leaves',
            'Calculus & Craft',
            'The Architect of Forgotten Dreams',
            'Whispers of the Ancient Vellum',
            'The Shadow of the Wind',
        ]
        order_case = case({title: idx for idx, title in enumerate(priority_titles)}, value=Book.title, else_=999)
        query = query.order_by(order_case, Book.rating.desc(), Book.id.desc())

    return query

# 🔓 Search Books (Public) with Filters, Sorting and Pagination
@router.get("/books/search")
def search_books(
    q: Optional[str] = None,
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    listing_type: Optional[str] = None,
    condition: Optional[str] = None,
    available_only: Optional[bool] = None,
    sort_by: Optional[str] = "relevance",
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    user: Optional[User] = Depends(get_optional_user)
):
    if page < 1:
        raise HTTPException(status_code=422, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=422, detail="limit must be >= 1")

    query = _build_book_query(
        db=db,
        q=q,
        category=category,
        min_price=min_price,
        max_price=max_price,
        listing_type=listing_type,
        condition=condition,
        available_only=available_only,
        sort_by=sort_by
    )
    total_count = query.count()
    offset = (page - 1) * limit
    books = query.offset(offset).limit(limit).all()
    has_more = (page * limit) < total_count

    return {
        "data": [
            serialize_book(book, user.id if user else None, db)
            for book in books
        ],
        "total": total_count,
        "page": page,
        "limit": limit,
        "has_more": has_more
    }

# 🔓 Get Books (Public) with Pagination, Search, Filtering and Sorting
@router.get("/books")
def get_catalog(
    page: int = 1,
    limit: int = 20,
    q: Optional[str] = None,
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    listing_type: Optional[str] = None,
    condition: Optional[str] = None,
    available_only: Optional[bool] = None,
    sort_by: Optional[str] = "relevance",
    sortBy: Optional[str] = None,
    db: Session = Depends(get_db),
    user: Optional[User] = Depends(get_optional_user)
):
    if page < 1:
        raise HTTPException(status_code=422, detail="page must be >= 1")
    if limit < 1:
        raise HTTPException(status_code=422, detail="limit must be >= 1")

    effective_sort = sortBy or sort_by or "relevance"
    query = _build_book_query(
        db=db,
        q=q,
        category=category,
        min_price=min_price,
        max_price=max_price,
        listing_type=listing_type,
        condition=condition,
        available_only=available_only,
        sort_by=effective_sort
    )
    total_count = query.count()
    offset = (page - 1) * limit
    books = query.offset(offset).limit(limit).all()
    has_more = (page * limit) < total_count

    return {
        "data": [
            serialize_book(book, user.id if user else None, db)
            for book in books
        ],
        "total": total_count,
        "page": page,
        "limit": limit,
        "has_more": has_more
    }

# 🔓 Get Related Books (Public)
@router.get("/books/{book_id}/related")
def get_related_books(
    book_id: int,
    db: Session = Depends(get_db),
    user: Optional[User] = Depends(get_optional_user)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    # Fetch books in same category (or other categories if few exist)
    related = db.query(Book).filter(
        Book.id != book_id,
        Book.category == book.category,
        Book.approval_status == "approved"
    ).order_by(Book.rating.desc()).limit(5).all()

    if len(related) < 3:
        more_books = db.query(Book).filter(
            Book.id != book_id,
            Book.id.notin_([b.id for b in related]),
            Book.approval_status == "approved"
        ).order_by(Book.rating.desc()).limit(5 - len(related)).all()
        related.extend(more_books)

    return {
        "data": [
            serialize_book(b, user.id if user else None, db)
            for b in related
        ]
    }

# 🔓 Get Book Details (Public)
@router.get("/books/{book_id}")
def get_book_details(book_id: int, db: Session = Depends(get_db), user: Optional[User] = Depends(get_optional_user)):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    # Enforce listing ownership & availability:
    # If a listing is pending approval, rejected, or paused, non-owners/non-admins cannot access it
    if book.approval_status and book.approval_status not in ["approved", "active"]:
        user_id = user.id if (user and hasattr(user, "id")) else None
        is_admin = bool(user and hasattr(user, "is_admin") and user.is_admin)
        if not (user_id and (user_id == book.owner_id or is_admin)):
            raise HTTPException(status_code=404, detail="Listing not available or under review")

    user_id = user.id if (user and hasattr(user, "id")) else None
    return serialize_book(book, user_id, db)

# 🔒 Toggle Favorite (Protected - Frontend uses this)
@router.post("/books/{book_id}/favorite")
def toggle_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    favorite = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    if favorite:
        db.delete(favorite)
        db.commit()
        return {"message": "Favorite removed", "isFavorite": False}
    else:
        new_fav = Favorite(user_id=user.id, book_id=book_id)
        db.add(new_fav)
        db.commit()
        return {"message": "Added to favorites", "isFavorite": True}

# 🔒 Favorites Logic (Legacy/Alternative backend routes)
@router.post("/favorites/{book_id}")
def add_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    book = db.query(Book).filter(Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    favorite = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    if favorite:
        return {"message": "Already favorited", "isFavorite": True}
    else:
        new_fav = Favorite(user_id=user.id, book_id=book_id)
        db.add(new_fav)
        db.commit()
        return {"message": "Added", "isFavorite": True}

@router.delete("/favorites/{book_id}")
def remove_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    favorite = db.query(Favorite).filter(Favorite.user_id == user.id, Favorite.book_id == book_id).first()
    if favorite:
        db.delete(favorite)
        db.commit()
    return {"message": "Favorite removed"}

@router.get("/favorites")
def get_favorites(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    favorites = db.query(Favorite).filter(Favorite.user_id == user.id).all()
    if not favorites:
        return []

    book_ids = [fav.book_id for fav in favorites]
    books = db.query(Book).filter(Book.id.in_(book_ids)).all()

    return [
        serialize_book(book, user.id, db)
        for book in books
    ]