import json
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile
from app.schemas.student_profile import StudentProfilePayload, StudentProfileResponse
from app.schemas.reader_profile import ReaderProfilePayload, ReaderProfileResponse
from app.api.auth import get_current_user, get_db

router = APIRouter()

def parse_json_list(val):
    if not val:
        return []
    try:
        return json.loads(val)
    except Exception:
        return []

from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.favorite import Favorite
from app.models.book import Book

@router.get("/users/me/profile")
def get_user_composite_profile(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Retrieve full composite user profile including persona-specific preferences and real computed statistics."""
    student_data = None
    reader_data = None

    if user.student_profile:
        sp = user.student_profile
        student_data = {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "college": getattr(sp, "college", None),
            "semester": getattr(sp, "semester", None),
            "graduation_year": getattr(sp, "graduation_year", None),
            "syllabus_details": getattr(sp, "syllabus_details", None),
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }

    if user.reader_profile:
        rp = user.reader_profile
        reader_data = {
            "id": rp.id,
            "user_id": rp.user_id,
            "genres": parse_json_list(rp.genres),
            "favorite_authors": parse_json_list(rp.favorite_authors),
            "reading_goal": rp.reading_goal,
            "preferred_duration": rp.preferred_duration,
            "favorite_moods": parse_json_list(rp.favorite_moods),
            "reading_frequency": rp.reading_frequency,
        }

    # 1. Real Database Calculations for Stats
    orders = db.query(Order).filter(Order.user_id == user.id).all()
    rental_orders = db.query(RentalOrder).filter(RentalOrder.user_id == user.id).all()
    purchase_orders = db.query(PurchaseOrder).filter(PurchaseOrder.user_id == user.id).all()
    borrow_reqs = db.query(BorrowRequest).filter(BorrowRequest.user_id == user.id).all()
    
    total_order_items = sum(len(o.items) for o in orders)
    books_count = total_order_items + len(rental_orders) + len(purchase_orders) + len(borrow_reqs)
    saved_count = db.query(Favorite).filter(Favorite.user_id == user.id).count()

    exchanges_count = db.query(Order).filter(
        Order.user_id == user.id,
        (Order.meetup_point_id.isnot(None)) | (Order.handoff_status.in_(["handoff_completed", "returned_completed"]))
    ).count()

    from app.models.student_data import StudentSubject
    from app.models.reader_data import BookshelfItem
    persistent_subj_count = db.query(StudentSubject).filter(StudentSubject.user_id == user.id).count()
    plans_count = persistent_subj_count if persistent_subj_count > 0 else (len(student_data["subjects"]) if student_data and student_data.get("subjects") else 0)

    # 2. Currently Reading book (Check bookshelf first, then active rental / purchase)
    currently_reading = None
    active_shelf = db.query(BookshelfItem).filter(BookshelfItem.user_id == user.id, BookshelfItem.category == "currently_reading").first()
    if active_shelf:
        currently_reading = {
            "id": active_shelf.book_id or active_shelf.id,
            "title": active_shelf.title,
            "author": active_shelf.author,
            "progress": active_shelf.progress,
            "progress_text": f"{int(active_shelf.progress * 100)}% Read"
        }
    else:
        active_rental = db.query(RentalOrder).filter(RentalOrder.user_id == user.id, RentalOrder.status == "active").first()
        if active_rental and active_rental.book:
            currently_reading = {
                "id": active_rental.book.id,
                "title": active_rental.book.title,
                "author": active_rental.book.author or "Author",
                "progress": 0.50,
                "progress_text": "In Progress"
            }
        elif orders and orders[0].items:
            first_item = orders[0].items[0]
            currently_reading = {
                "id": first_item.book_id or 1,
                "title": first_item.book_title or "Purchased Book",
                "author": first_item.book_author or "Author",
                "progress": 0.10,
                "progress_text": "Reading"
            }

    # 3. Reader Passport Real Metrics
    completed_books = db.query(Order).filter(Order.user_id == user.id, Order.status == "completed").count()
    reused_books = exchanges_count
    money_saved_val = reused_books * 250 + completed_books * 50
    money_saved_str = f"₹{money_saved_val:,}"

    user_display_name = user.name or (user.email.split("@")[0].title() if user.email else "Reader")

    return {
        "id": user.id,
        "email": user.email,
        "name": user_display_name,
        "role": user.role or "customer",
        "user_type": user.user_type or "reader",
        "persona": user.user_type or "reader",
        "active_experience": getattr(user, "active_experience", None) or user.user_type or "reader",
        "provider_enabled": bool(getattr(user, "provider_enabled", False)),
        "provider_status": getattr(user, "provider_status", "not_enrolled") or "not_enrolled",
        "onboarding_completed": bool(user.onboarding_completed),
        "student_profile": student_data,
        "reader_profile": reader_data,
        "stats": {
            "books_count": books_count,
            "saved_count": saved_count,
            "exchanges_count": exchanges_count,
            "plans_count": plans_count,
        },
        "currently_reading": currently_reading,
        "passport": {
            "tier": "⭐ Trusted Reader" if (completed_books > 5 or exchanges_count > 2) else "🌱 New Reader",
            "member_id": f"LF-2026-{user.id:04d}",
            "books_completed": completed_books,
            "books_reused": reused_books,
            "exchanges": exchanges_count,
            "money_saved": money_saved_str,
        }
    }

@router.put("/users/me/student-profile")
def update_student_profile(
    payload: StudentProfilePayload,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create or update StudentProfile for current user and set onboarding_completed = True."""
    db_user = db.query(User).filter(User.id == user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db_user.user_type = "student"
    db_user.onboarding_completed = True

    sp = db.query(StudentProfile).filter(StudentProfile.user_id == db_user.id).first()
    if not sp:
        sp = StudentProfile(user_id=db_user.id)
        db.add(sp)

    sp.education_level = payload.education_level
    sp.course = payload.course
    if getattr(payload, "college", None) is not None:
        sp.college = payload.college
    if getattr(payload, "semester", None) is not None:
        sp.semester = payload.semester
    if getattr(payload, "graduation_year", None) is not None:
        sp.graduation_year = payload.graduation_year
    if getattr(payload, "syllabus_details", None) is not None:
        sp.syllabus_details = payload.syllabus_details
    sp.subjects = json.dumps(payload.subjects or [])
    sp.exam_goal = payload.exam_goal
    sp.study_duration = payload.study_duration or 60
    sp.difficulty_level = payload.difficulty_level or "Intermediate"
    sp.academic_interests = json.dumps(payload.academic_interests or [])

    db.commit()
    db.refresh(sp)
    db.refresh(db_user)

    return {
        "message": "Student profile updated successfully.",
        "user_type": db_user.user_type,
        "onboarding_completed": db_user.onboarding_completed,
        "student_profile": {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "college": getattr(sp, "college", None),
            "semester": getattr(sp, "semester", None),
            "graduation_year": getattr(sp, "graduation_year", None),
            "syllabus_details": getattr(sp, "syllabus_details", None),
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }
    }

@router.put("/users/me/reader-profile")
def update_reader_profile(
    payload: ReaderProfilePayload,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create or update ReaderProfile for current user and set onboarding_completed = True."""
    db_user = db.query(User).filter(User.id == user.id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    db_user.user_type = "reader"
    db_user.onboarding_completed = True

    rp = db.query(ReaderProfile).filter(ReaderProfile.user_id == db_user.id).first()
    if not rp:
        rp = ReaderProfile(user_id=db_user.id)
        db.add(rp)

    rp.genres = json.dumps(payload.genres or [])
    rp.favorite_authors = json.dumps(payload.favorite_authors or [])
    rp.reading_goal = payload.reading_goal
    rp.preferred_duration = payload.preferred_duration or 30
    rp.favorite_moods = json.dumps(payload.favorite_moods or [])
    rp.reading_frequency = payload.reading_frequency or "Daily"

    db.commit()
    db.refresh(rp)
    db.refresh(db_user)

    return {
        "message": "Reader profile updated successfully.",
        "user_type": db_user.user_type,
        "onboarding_completed": db_user.onboarding_completed,
        "reader_profile": {
            "id": rp.id,
            "user_id": rp.user_id,
            "genres": parse_json_list(rp.genres),
            "favorite_authors": parse_json_list(rp.favorite_authors),
            "reading_goal": rp.reading_goal,
            "preferred_duration": rp.preferred_duration,
            "favorite_moods": parse_json_list(rp.favorite_moods),
            "reading_frequency": rp.reading_frequency,
        }
    }
