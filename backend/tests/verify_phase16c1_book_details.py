import os
import sys

# Ensure backend root is on sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)
os.environ["TESTING"] = "true"

from fastapi import HTTPException
from app.core.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.book import Book
from app.api.books import get_book_details, serialize_book, get_catalog

def run_tests():
    print("=" * 70)
    print("PHASE 16C.1 BOOK DETAILS & LISTINGS VERIFICATION")
    print("=" * 70)
    
    # Ensure UTF-8 output on Windows
    if sys.platform == "win32":
        sys.stdout.reconfigure(encoding="utf-8")
    db = SessionLocal()
    
    try:
        # Create test provider with campus and verification
        provider = db.query(User).filter(User.email == "test_provider_16c1@example.com").first()
        if not provider:
            provider = User(
                email="test_provider_16c1@example.com",
                password="hashed_pw_mock",
                name="Prof. Eleanor Vance",
                is_verified=True,
                role="provider",
                provider_status="active",
                level="Master Scholar"
            )
            db.add(provider)
            db.commit()
            db.refresh(provider)

        # Ensure student profile with campus/college
        st_prof = db.query(StudentProfile).filter(StudentProfile.user_id == provider.id).first()
        if not st_prof:
            st_prof = StudentProfile(
                user_id=provider.id,
                college="Oxford Department of Rare Manuscripts",
                course="Archival Studies",
                semester="Final Year"
            )
            db.add(st_prof)
            db.commit()
            db.refresh(st_prof)

        # Create test customer
        customer = db.query(User).filter(User.email == "test_customer_16c1@example.com").first()
        if not customer:
            customer = User(
                email="test_customer_16c1@example.com",
                password="hashed_pw_mock",
                name="Julian Blackwood",
                role="customer",
                user_type="reader"
            )
            db.add(customer)
            db.commit()
            db.refresh(customer)

        # Book 1: Approved, In Stock, For Sale & Rent
        book_active = db.query(Book).filter(Book.title == "Codex of Ancient Cartography").first()
        if not book_active:
            book_active = Book(
                title="Codex of Ancient Cartography",
                author="Gerardus Mercator",
                description="Rare folio reproduction with comprehensive map commentaries.",
                price=320.0,
                rating=4.8,
                category="History & Maps",
                isbn="978-0198534531",
                publisher="Clarendon Press",
                language="English & Latin",
                pages="480 pages",
                condition="Fine Pristine",
                stock=3,
                owner_id=provider.id,
                approval_status="approved",
                condition_verification="verified"
            )
            db.add(book_active)
            db.commit()
            db.refresh(book_active)

        # Book 2: Out of Stock
        book_out_of_stock = db.query(Book).filter(Book.title == "Tome of Zero Inventory").first()
        if not book_out_of_stock:
            book_out_of_stock = Book(
                title="Tome of Zero Inventory",
                author="Cassian Drake",
                description="Out of print treatise on medieval heraldry.",
                price=150.0,
                stock=0, # Out of stock!
                owner_id=provider.id,
                approval_status="approved",
                condition_verification="inspected"
            )
            db.add(book_out_of_stock)
            db.commit()
            db.refresh(book_out_of_stock)

        # Book 3: Unapproved / Pending Review
        book_pending = db.query(Book).filter(Book.title == "Secret Unpublished Manuscript").first()
        if not book_pending:
            book_pending = Book(
                title="Secret Unpublished Manuscript",
                author="Anonymous Monk",
                description="Under editorial verification.",
                price=500.0,
                stock=1,
                owner_id=provider.id,
                approval_status="pending_approval" # Not approved yet!
            )
            db.add(book_pending)
            db.commit()
            db.refresh(book_pending)

        # Book 4: Free Community Lending / Borrow
        book_borrow = db.query(Book).filter(Book.title == "Community Open Reader").first()
        if not book_borrow:
            book_borrow = Book(
                title="Community Open Reader",
                author="Peer Collective",
                description="Available for free borrow and peer exchange.",
                price=0.0, # Free
                stock=2,
                owner_id=provider.id,
                approval_status="approved",
                condition_verification="verified"
            )
            db.add(book_borrow)
            db.commit()
            db.refresh(book_borrow)

        print("[OK] Test fixtures and database entities configured successfully.\n")

        # --- Test 1: Full Book details API response structure ---
        print("--- Test 1: Full Book Details API Response ---")
        data1 = get_book_details(book_id=book_active.id, db=db, user=None)
        assert data1["id"] == book_active.id
        assert data1["title"] == "Codex of Ancient Cartography"
        assert data1["author"] == "Gerardus Mercator"
        assert data1["isbn"] == "978-0198534531"
        assert data1["publisher"] == "Clarendon Press"
        assert data1["price"] == 320.0
        assert data1["stock"] == 3
        print(f"[PASS] Retrieved book details for '{data1['title']}' with price Rs.{data1['price']}")

        # --- Test 2: Provider serialization integrity ---
        print("\n--- Test 2: Provider Serialization Integrity ---")
        assert "provider" in data1 and data1["provider"] is not None
        provider_data = data1["provider"]
        assert provider_data["id"] == provider.id
        assert provider_data["name"] == "Prof. Eleanor Vance"
        assert provider_data["is_verified"] is True
        assert provider_data["campus"] == "Oxford Department of Rare Manuscripts"
        assert provider_data["rating"] is None, "Ratings must not be fabricated"
        # Verify private fields are strictly excluded
        assert "password" not in provider_data
        assert "email" not in provider_data
        assert "phone" not in provider_data
        print("[PASS] Provider serialized with real identity, campus, verified badge, and 0 private leaks")

        # --- Test 3: Missing / 404 book details handling ---
        print("\n--- Test 3: Non-Existent Book Listing (404) ---")
        try:
            get_book_details(book_id=99999999, db=db, user=None)
            assert False, "Should have raised 404 for non-existent book"
        except HTTPException as e:
            assert e.status_code == 404
            print(f"[PASS] Non-existent book returned HTTP 404 cleanly: {e.detail}")

        # --- Test 4: Unapproved / Pending Review Listing Access Control ---
        print("\n--- Test 4: Listing Ownership & Authorization on Pending Review ---")
        # Anonymous non-owner access -> 404
        try:
            get_book_details(book_id=book_pending.id, db=db, user=None)
            assert False, "Should have raised 404 for anonymous user on unapproved listing"
        except HTTPException as e:
            assert e.status_code == 404
            print(f"[PASS] Anonymous request blocked with 404: {e.detail}")

        # Customer (non-owner) access -> 404
        try:
            get_book_details(book_id=book_pending.id, db=db, user=customer)
            assert False, "Should have raised 404 for non-owner customer on unapproved listing"
        except HTTPException as e:
            assert e.status_code == 404
            print(f"[PASS] Customer non-owner request blocked with 404: {e.detail}")

        # Owner access -> 200 (Owner can view their own pending listing)
        owner_data = get_book_details(book_id=book_pending.id, db=db, user=provider)
        assert owner_data["id"] == book_pending.id
        assert owner_data["approval_status"] == "pending_approval"
        print("[PASS] Owner authorized to view their own pending listing")

        # --- Test 5: Out of Stock Availability Resolution ---
        print("\n--- Test 5: Out of Stock Listing Availability Flag ---")
        data5 = get_book_details(book_id=book_out_of_stock.id, db=db, user=None)
        assert data5["stock"] == 0
        assert data5["is_available"] is False
        assert data5["availability_status"] == "out_of_stock"
        assert data5["can_buy"] is False
        assert data5["can_rent"] is False
        print("[PASS] Out-of-stock listing resolved is_available=False, can_buy=False, can_rent=False")

        # --- Test 6: Multi-Modal Transaction Eligibility (Buy / Rent / Borrow) ---
        print("\n--- Test 6: Multi-Modal Action Eligibility ---")
        # Active book has price=320, stock=3 -> can buy, can rent
        assert data1["is_available"] is True
        assert data1["can_buy"] is True
        assert data1["can_rent"] is True
        
        # Free borrow book has price=0, stock=2 -> can borrow, cannot buy
        data6 = get_book_details(book_id=book_borrow.id, db=db, user=None)
        assert data6["can_borrow"] is True
        assert data6["can_buy"] is False
        print("[PASS] Action modalities dynamically resolved: Buy & Rent for priced books, Borrow for lending books")

        # --- Test 7: Rental Options & Deposit Calculation ---
        print("\n--- Test 7: Dynamic Rental Schedule & Deposit Rates ---")
        assert "rental_options" in data1
        opts = data1["rental_options"]
        assert opts["fee_7d"] > 0
        assert opts["fee_14d"] > opts["fee_7d"]
        assert opts["fee_30d"] > opts["fee_14d"]
        assert opts["deposit"] == round(320.0 * 0.50, 2)
        print(f"[PASS] Verified realistic rental schedule: 7d=Rs.{opts['fee_7d']}, 14d=Rs.{opts['fee_14d']}, 30d=Rs.{opts['fee_30d']}, deposit=Rs.{opts['deposit']}")

        # --- Test 8: Backward-Compatibility with Catalog Listing ---
        print("\n--- Test 8: Catalog Backward Compatibility ---")
        catalog_res = get_catalog(db=db, user=customer, page=1, limit=5)
        books_list = catalog_res.get("books", catalog_res.get("data", []))
        assert len(books_list) > 0
        assert "provider" in books_list[0]
        assert "is_available" in books_list[0]
        print("[PASS] Catalog endpoints retain complete backward compatibility with enriched schema")

        print("\n" + "=" * 70)
        print("ALL 8 PHASE 16C.1 BACKEND BOOK DETAILS TESTS PASSED PERFECTLY!")
        print("=" * 70)

    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
