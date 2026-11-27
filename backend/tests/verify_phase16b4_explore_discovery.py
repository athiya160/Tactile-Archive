import sys
import os

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["TESTING"] = "true"

from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.book import Book
from app.models.favorite import Favorite
from app.models.reader_profile import ReaderProfile
from app.models.student_profile import StudentProfile
from app.api.books import get_catalog
from app.api.favorites import get_favorites, toggle_favorite_route, remove_favorite
from app.api.recommendations import get_user_recommendations, get_public_recommendations

def run_tests():
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()
    print("=" * 70)
    print("PHASE 16B.4 EXPLORE, SEARCH, FILTERS & RECOMMENDATIONS VERIFICATION")
    print("=" * 70)

    # Setup 2 isolated test users
    reader_user = db.query(User).filter(User.email == "test_explore_reader@example.com").first()
    if not reader_user:
        reader_user = User(
            name="Explore Reader",
            email="test_explore_reader@example.com",
            user_type="reader",
            is_verified=True
        )
        db.add(reader_user)
        db.commit()
        db.refresh(reader_user)

    student_user = db.query(User).filter(User.email == "test_explore_student@example.com").first()
    if not student_user:
        student_user = User(
            name="Explore Student",
            email="test_explore_student@example.com",
            user_type="student",
            is_verified=True
        )
        db.add(student_user)
        db.commit()
        db.refresh(student_user)

    # Ensure profiles exist for recommendation scoring
    rp = db.query(ReaderProfile).filter(ReaderProfile.user_id == reader_user.id).first()
    if not rp:
        rp = ReaderProfile(user_id=reader_user.id, genres='["Fiction", "Non-fiction"]')
        db.add(rp)
        db.commit()

    sp = db.query(StudentProfile).filter(StudentProfile.user_id == student_user.id).first()
    if not sp:
        sp = StudentProfile(user_id=student_user.id, course="Computer Science", subjects='["Algorithms", "Architecture"]')
        db.add(sp)
        db.commit()

    # Ensure test books exist
    test_books_data = [
        {"title": "Clean Code Architecture", "author": "Robert C. Martin", "isbn": "978-0132350884", "category": "Tech & Programming", "price": 450.0, "condition": "Like New", "rating": 4.9, "stock": 5},
        {"title": "The Shadow of the Wind", "author": "Carlos Ruiz Zafón", "isbn": "978-0143034902", "category": "Fiction", "price": 299.0, "condition": "Good", "rating": 4.8, "stock": 3},
        {"title": "Calculus and Analytical Geometry", "author": "George B. Thomas", "isbn": "978-0201531749", "category": "Academic & Textbooks", "price": 3.5, "condition": "Fair", "rating": 4.6, "stock": 1, "description": "Academic text available for rental"},
        {"title": "Community Vellum Archive", "author": "Anonymous Scribe", "isbn": "978-0000000001", "category": "Rare Finds", "price": 0.0, "condition": "Good", "rating": 5.0, "stock": 1, "description": "Free borrow and community donate"},
    ]

    created_book_ids = []
    for bdata in test_books_data:
        existing = db.query(Book).filter(Book.title == bdata["title"]).first()
        if not existing:
            nb = Book(
                title=bdata["title"],
                author=bdata["author"],
                isbn=bdata["isbn"],
                category=bdata["category"],
                price=bdata["price"],
                condition=bdata["condition"],
                rating=bdata["rating"],
                stock=bdata["stock"],
                description=bdata.get("description", "A classic addition to the library"),
                approval_status="approved"
            )
            db.add(nb)
            db.commit()
            db.refresh(nb)
            created_book_ids.append(nb.id)
        else:
            existing.approval_status = "approved"
            db.commit()
            created_book_ids.append(existing.id)

    print(f"[OK] Test setup complete with {len(created_book_ids)} target books.")

    try:
        # --- Test 1: Search by Title ---
        print("\n--- Test 1: Search by Title ---")
        res = get_catalog(q="Clean Code Architecture", db=db, user=reader_user)
        data = res["data"]
        assert len(data) >= 1, "Expected at least 1 match for 'Clean Code Architecture'"
        assert any(b["title"] == "Clean Code Architecture" for b in data)
        print(f"[PASS] Found book by title search: {data[0]['title']}")

        # --- Test 2: Search by Author ---
        print("\n--- Test 2: Search by Author ---")
        res = get_catalog(q="Carlos Ruiz", db=db, user=reader_user)
        data = res["data"]
        assert any("Zafón" in b["author"] or "Carlos" in b["author"] for b in data)
        print(f"[PASS] Found book by author search: {data[0]['title']} by {data[0]['author']}")

        # --- Test 3: Search by ISBN (with & without hyphens) ---
        print("\n--- Test 3: Search by ISBN ---")
        res = get_catalog(q="9780132350884", db=db, user=reader_user)
        data = res["data"]
        assert any(b["title"] == "Clean Code Architecture" for b in data)
        print(f"[PASS] Found book by unhyphenated ISBN search: {data[0]['title']}")

        # --- Test 4: Category Filtering ---
        print("\n--- Test 4: Category Filtering ---")
        res = get_catalog(category="Academic & Textbooks", db=db, user=student_user)
        data = res["data"]
        assert all(b["category"].lower() == "academic & textbooks" for b in data)
        print(f"[PASS] Filter by category 'Academic & Textbooks' returned {len(data)} books")

        # --- Test 5: Price Range Filters ---
        print("\n--- Test 5: Price Range Filters ---")
        res = get_catalog(min_price=100.0, max_price=350.0, db=db, user=reader_user)
        data = res["data"]
        assert all(100.0 <= b["price"] <= 350.0 for b in data)
        print(f"[PASS] Filter by price [100.0, 350.0] returned {len(data)} books within range")

        # --- Test 6: Combined Multi-dimensional Filters ---
        print("\n--- Test 6: Combined Multi-dimensional Filters ---")
        res = get_catalog(category="Tech & Programming", condition="Like New", min_price=400.0, db=db, user=reader_user)
        data = res["data"]
        assert all(b["category"] == "Tech & Programming" and b["condition"] == "Like New" and b["price"] >= 400.0 for b in data)
        print(f"[PASS] Combined category + condition + price filters matched {len(data)} books")

        # --- Test 7: Sorting Behavior ---
        print("\n--- Test 7: Sorting Behavior ---")
        res_asc = get_catalog(sort_by="price_asc", limit=10, db=db, user=reader_user)
        prices_asc = [b["price"] for b in res_asc["data"]]
        assert prices_asc == sorted(prices_asc), f"Expected ascending prices, got {prices_asc}"

        res_desc = get_catalog(sort_by="price_desc", limit=10, db=db, user=reader_user)
        prices_desc = [b["price"] for b in res_desc["data"]]
        assert prices_desc == sorted(prices_desc, reverse=True), f"Expected descending prices, got {prices_desc}"
        print("[PASS] Verified price_asc and price_desc sorting orders correctly")

        # --- Test 8: Pagination & Total Counts ---
        print("\n--- Test 8: Pagination & Total Counts ---")
        res_p1 = get_catalog(page=1, limit=2, db=db, user=reader_user)
        assert len(res_p1["data"]) == 2
        assert res_p1["total"] >= 4
        assert res_p1["has_more"] is True

        res_p2 = get_catalog(page=2, limit=2, db=db, user=reader_user)
        assert len(res_p2["data"]) == 2
        p1_ids = {b["id"] for b in res_p1["data"]}
        p2_ids = {b["id"] for b in res_p2["data"]}
        assert len(p1_ids.intersection(p2_ids)) == 0, "Pages overlap!"
        print(f"[PASS] Pagination verified: page 1 count={len(res_p1['data'])}, page 2 count={len(res_p2['data'])}, total={res_p1['total']}")

        # --- Test 9: Empty Search Results ---
        print("\n--- Test 9: Empty Search Results ---")
        res_empty = get_catalog(q="NonExistentZebraBookTitleXyZ999", db=db, user=reader_user)
        assert res_empty["data"] == []
        assert res_empty["total"] == 0
        assert res_empty["has_more"] is False
        print("[PASS] Empty search results handled cleanly with total=0 and data=[]")

        # --- Test 10: Invalid Search / Filter Parameters Validation ---
        print("\n--- Test 10: Invalid Search / Filter Parameters Validation ---")
        try:
            get_catalog(min_price=-5.0, db=db)
            assert False, "Expected 422 for negative min_price"
        except HTTPException as e:
            assert e.status_code == 422

        try:
            get_catalog(min_price=500.0, max_price=100.0, db=db)
            assert False, "Expected 422 for reversed price range"
        except HTTPException as e:
            assert e.status_code == 422

        try:
            get_catalog(page=0, db=db)
            assert False, "Expected 422 for page=0"
        except HTTPException as e:
            assert e.status_code == 422
        print("[PASS] Rejected negative prices, reversed ranges, and page=0 with 422 Unprocessable Entity")

        # --- Test 11: Favorites Persistence & Ownership ---
        print("\n--- Test 11: Favorites Persistence & Ownership ---")
        target_book_id = created_book_ids[0]
        # Clean existing
        db.query(Favorite).filter(Favorite.user_id.in_([reader_user.id, student_user.id])).delete()
        db.commit()

        # Reader favorites book
        res_fav = toggle_favorite_route(book_id=target_book_id, db=db, user=reader_user)
        assert res_fav["isFavorite"] is True

        # Check reader favorites list
        reader_favs = get_favorites(db=db, user=reader_user)
        assert len(reader_favs) == 1
        assert reader_favs[0]["id"] == target_book_id

        # Student favorites list must be isolated (0 favorites)
        student_favs = get_favorites(db=db, user=student_user)
        assert len(student_favs) == 0, "Student should have 0 favorites!"
        print(f"[PASS] Favorites persisted for Reader and strictly isolated from Student")

        # Delete favorite
        res_del = remove_favorite(book_id=target_book_id, db=db, user=reader_user)
        assert res_del["isFavorite"] is False
        res_after = get_favorites(db=db, user=reader_user)
        assert len(res_after) == 0
        print("[PASS] Favorite removed successfully")

        # --- Test 12: Persona Tailored Recommendations ---
        print("\n--- Test 12: Persona Tailored Recommendations ---")
        rec_reader = get_user_recommendations(limit=10, user=reader_user, db=db)
        recs_r = rec_reader["recommendations"]
        assert len(recs_r) > 0
        assert "match_score" in recs_r[0]
        assert "match_reasons" in recs_r[0]

        rec_student = get_user_recommendations(limit=10, user=student_user, db=db)
        recs_s = rec_student["recommendations"]
        assert len(recs_s) > 0

        rec_public = get_public_recommendations(limit=4, user=None, db=db)
        assert len(rec_public["recommendations"]) == 4
        print(f"[PASS] Personalized recommendations operational for Reader ({len(recs_r)}), Student ({len(recs_s)}), and Public guest fallback (4)")

        print("=" * 70)
        print("ALL 12 PHASE 16B.4 BACKEND DISCOVERY & SEARCH TESTS PASSED PERFECTLY!")
        print("=" * 70)

    finally:
        # Cleanup favorites
        db.query(Favorite).filter(Favorite.user_id.in_([reader_user.id, student_user.id])).delete()
        db.commit()
        db.close()

if __name__ == "__main__":
    run_tests()
