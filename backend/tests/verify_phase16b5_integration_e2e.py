import sys
import os
import datetime

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["TESTING"] = "true"

from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.core.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.book import Book
from app.models.favorite import Favorite
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile
from app.models.student_data import (
    StudentSubject,
    StudentScheduleItem,
    StudentAssignment,
    StudentGoal,
)
from app.models.reader_data import BookshelfItem, ReadingGoal
from app.schemas.student import (
    StudentSubjectCreate,
    StudentSubjectUpdate,
    StudentScheduleItemCreate,
    StudentScheduleItemUpdate,
    StudentAssignmentCreate,
    StudentAssignmentUpdate,
    StudentGoalCreate,
    StudentGoalUpdate,
)
from app.schemas.reader import (
    BookshelfItemCreate,
    BookshelfItemUpdate,
    BookshelfItemMove,
    ReadingGoalUpdate,
)
from app.api.student import (
    get_student_dashboard,
    create_student_subject,
    get_student_subjects,
    get_student_subject_by_id,
    update_student_subject,
    delete_student_subject,
    create_student_schedule_item,
    get_student_schedule,
    delete_student_schedule_item,
    create_student_assignment,
    update_student_assignment,
    get_student_assignments,
    delete_student_assignment,
    create_student_goal,
    get_student_goals,
    rebalance_student_schedule,
)
from app.api.reader import (
    get_reader_dashboard,
    add_bookshelf_item,
    get_bookshelf_items,
    get_bookshelf_item_by_id,
    update_bookshelf_item,
    move_bookshelf_item,
    delete_bookshelf_item,
    get_reading_goal,
    update_reading_goal,
)
from app.api.books import get_catalog
from app.api.favorites import get_favorites, toggle_favorite_route
from app.api.recommendations import get_user_recommendations, get_public_recommendations
from app.api.profile import get_user_composite_profile


def cleanup_test_data(db: Session, emails: list):
    for email in emails:
        user = db.query(User).filter(User.email == email).first()
        if user:
            db.query(Favorite).filter(Favorite.user_id == user.id).delete()
            db.query(BookshelfItem).filter(BookshelfItem.user_id == user.id).delete()
            db.query(ReadingGoal).filter(ReadingGoal.user_id == user.id).delete()
            db.query(StudentSubject).filter(StudentSubject.user_id == user.id).delete()
            db.query(StudentScheduleItem).filter(StudentScheduleItem.user_id == user.id).delete()
            db.query(StudentAssignment).filter(StudentAssignment.user_id == user.id).delete()
            db.query(StudentGoal).filter(StudentGoal.user_id == user.id).delete()
            db.query(StudentProfile).filter(StudentProfile.user_id == user.id).delete()
            db.query(ReaderProfile).filter(ReaderProfile.user_id == user.id).delete()
            db.delete(user)
    db.commit()


def run_e2e_integration_tests():
    Base.metadata.create_all(bind=engine)
    db: Session = SessionLocal()

    print("=" * 70)
    print("PHASE 16B.5 INTEGRATION, PERSISTENCE & SECURITY END-TO-END VERIFICATION")
    print("=" * 70)

    test_emails = [
        "e2e_student_alice@test.com",
        "e2e_reader_bob@test.com",
        "e2e_unified_charlie@test.com",
        "e2e_intruder_eve@test.com",
    ]

    cleanup_test_data(db, test_emails)

    try:
        # ──────────────────────────────────────────────────────────────────────
        # SETUP USERS & PROFILES
        # ──────────────────────────────────────────────────────────────────────
        alice = User(
            name="Alice Student",
            email="e2e_student_alice@test.com",
            user_type="student",
            is_verified=True,
        )
        bob = User(
            name="Bob Reader",
            email="e2e_reader_bob@test.com",
            user_type="reader",
            is_verified=True,
        )
        charlie = User(
            name="Charlie Unified",
            email="e2e_unified_charlie@test.com",
            user_type="student",
            is_verified=True,
        )
        eve = User(
            name="Eve Intruder",
            email="e2e_intruder_eve@test.com",
            user_type="reader",
            is_verified=True,
        )
        db.add_all([alice, bob, charlie, eve])
        db.commit()
        for u in [alice, bob, charlie, eve]:
            db.refresh(u)

        # Profiles
        sp_alice = StudentProfile(
            user_id=alice.id,
            education_level="Undergraduate",
            course="Computer Science",
            college="Indian Institute of Technology",
            semester=6,
            subjects='["Data Structures", "Algorithms", "Operating Systems"]',
            exam_goal="GATE CS 2027",
            study_duration="3 hours/day",
            difficulty_level="Advanced",
            academic_interests='["Algorithms", "Distributed Systems"]',
        )
        rp_bob = ReaderProfile(
            user_id=bob.id,
            genres='["Literary Fiction", "Philosophy", "Science"]',
            favorite_authors='["Gabriel Garcia Marquez", "Italo Calvino"]',
            reading_goal=24,
            preferred_duration="45 mins/day",
            favorite_moods='["Reflective", "Immersive"]',
            reading_frequency="Daily",
        )
        sp_charlie = StudentProfile(
            user_id=charlie.id,
            education_level="Postgraduate",
            course="Data Science",
            college="BITS Pilani",
            semester=2,
            subjects='["Machine Learning", "Statistical Inference"]',
            exam_goal="Master Thesis",
            study_duration="4 hours/day",
            difficulty_level="Expert",
            academic_interests='["AI", "Statistics"]',
        )
        rp_charlie = ReaderProfile(
            user_id=charlie.id,
            genres='["Science Fiction", "History"]',
            favorite_authors='["Isaac Asimov", "Yuval Noah Harari"]',
            reading_goal=18,
            preferred_duration="30 mins/day",
            favorite_moods='["Analytical"]',
            reading_frequency="Weekly",
        )
        db.add_all([sp_alice, rp_bob, sp_charlie, rp_charlie])
        db.commit()

        # Seed 2 books for catalog and bookshelf integration
        book1 = db.query(Book).filter(Book.title == "Advanced Algorithms & Optimization").first()
        if not book1:
            book1 = Book(
                title="Advanced Algorithms & Optimization",
                author="Thomas H. Cormen",
                isbn="9780262033848",
                price=650.0,
                category="Academic & Textbooks",
                condition="New",
                description="Comprehensive coverage of advanced algorithms.",
                stock=10,
                rating=4.9,
                approval_status="approved",
                cover_url="https://images.unsplash.com/photo-5",
            )
            db.add(book1)
        else:
            book1.approval_status = "approved"

        book2 = db.query(Book).filter(Book.title == "One Hundred Years of Solitude").first()
        if not book2:
            book2 = Book(
                title="One Hundred Years of Solitude",
                author="Gabriel Garcia Marquez",
                isbn="9780060883287",
                price=380.0,
                category="Literature & Classics",
                condition="Like New",
                description="The brilliant masterwork of magical realism.",
                stock=5,
                rating=4.95,
                approval_status="approved",
                cover_url="https://images.unsplash.com/photo-6",
            )
            db.add(book2)
        else:
            book2.approval_status = "approved"

        db.commit()
        db.refresh(book1)
        db.refresh(book2)

        print("[OK] Initial test fixtures configured successfully.")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 1: STUDENT END-TO-END ACADEMIC JOURNEY
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 1: Student End-to-End Academic Journey ---")
        # 1.1 Add Subjects
        subj1 = create_student_subject(
            StudentSubjectCreate(
                name="Algorithms & Complexity",
                code="CS301",
                progress=0.45,
                target=0.85,
                is_lagging=True,
                instructor="Prof. Knuth",
                credits=4,
                hours_per_week=5,
                syllabus="Graph algorithms, NP-completeness, Dynamic programming",
            ),
            user=alice,
            db=db,
        )
        assert subj1.name == "Algorithms & Complexity"
        assert subj1.is_lagging is True

        subj2 = create_student_subject(
            StudentSubjectCreate(
                name="Operating Systems",
                code="CS302",
                progress=0.75,
                target=0.80,
                is_lagging=False,
                instructor="Prof. Tanenbaum",
                credits=4,
                hours_per_week=4,
                syllabus="Processes, Threads, Virtual Memory, File Systems",
            ),
            user=alice,
            db=db,
        )
        assert subj2.name == "Operating Systems"

        # 1.2 Study Sessions
        sess = create_student_schedule_item(
            StudentScheduleItemCreate(
                subject_id=subj1.id,
                subject_name=subj1.name,
                topic="Dynamic Programming Mastery",
                time_slot="10:00 AM - 12:00 PM",
                date="2026-11-15",
                duration_minutes=120,
                status="Pending",
                notes="Review matrix chain multiplication",
            ),
            user=alice,
            db=db,
        )
        assert sess.topic == "Dynamic Programming Mastery"

        # 1.3 Assignments
        asgn = create_student_assignment(
            StudentAssignmentCreate(
                subject_id=subj1.id,
                title="Implement Dijkstra with Fibonacci Heap",
                description="Graph shortest path optimization",
                due_date="2026-11-20",
                priority="High",
                status="Pending",
            ),
            user=alice,
            db=db,
        )
        assert asgn.status == "Pending"

        # Update assignment to in_progress then completed
        asgn_updated = update_student_assignment(
            asgn.id,
            StudentAssignmentUpdate(status="Completed"),
            user=alice,
            db=db,
        )
        assert asgn_updated.status == "Completed"

        # 1.4 Goals
        goal = create_student_goal(
            StudentGoalCreate(
                title="Master All NP-Complete Proofs",
                category="Academic",
                target_date="2026-12-31",
                progress=0.30,
                status="Active",
            ),
            user=alice,
            db=db,
        )
        assert goal.progress == 0.30

        # 1.5 AI Schedule Rebalancing
        rebalance_res = rebalance_student_schedule(user=alice, db=db)
        assert rebalance_res["status"] == "success"
        assert rebalance_res["sessions_added"] >= 1

        # 1.6 Verify Aggregated Student Dashboard
        dash = get_student_dashboard(user=alice, db=db)
        assert dash.total_subjects == 2
        assert dash.lagging_subjects_count == 1
        assert len(dash.schedule) >= 2  # 1 manual + boosted
        print(f"[PASS] Student E2E Journey complete: {dash.total_subjects} subjects, {len(dash.schedule)} sessions, progress={dash.overall_progress:.0%}")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 2: READER END-TO-END LIVING BOOKSHELF JOURNEY
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 2: Reader End-to-End Living Bookshelf Journey ---")
        # 2.1 Add Bookshelf Items across 4 categories
        b1 = add_bookshelf_item(
            BookshelfItemCreate(
                book_id=book2.id,
                title=book2.title,
                author=book2.author,
                category="currently_reading",
                total_pages=417,
                current_page=120,
                progress=0.29,
                cover_url=book2.image_url,
                notes="Chapter 4: The founding of Macondo",
            ),
            user=bob,
            db=db,
        )
        assert b1.category == "currently_reading"

        b2 = add_bookshelf_item(
            BookshelfItemCreate(
                book_id=book1.id,
                title=book1.title,
                author=book1.author,
                category="want_to_read",
                total_pages=1312,
                current_page=0,
                progress=0.0,
            ),
            user=bob,
            db=db,
        )
        assert b2.category == "want_to_read"

        b3 = add_bookshelf_item(
            BookshelfItemCreate(
                title="Invisible Cities",
                author="Italo Calvino",
                category="paused",
                total_pages=165,
                current_page=50,
                progress=0.30,
            ),
            user=bob,
            db=db,
        )
        assert b3.category == "paused"

        # 2.2 Move shelf item from want_to_read to currently_reading
        b2_moved = move_bookshelf_item(
            b2.id,
            BookshelfItemMove(category="currently_reading", current_page=100),
            user=bob,
            db=db,
        )
        assert b2_moved.category == "currently_reading"
        assert b2_moved.current_page == 100

        # 2.3 Update progress and mark book 1 completed
        b1_done = update_bookshelf_item(
            b1.id,
            BookshelfItemUpdate(
                current_page=417,
                progress=1.0,
                category="completed",
                notes="A masterpiece of magical realism.",
            ),
            user=bob,
            db=db,
        )
        assert b1_done.category == "completed"
        assert b1_done.progress == 1.0

        # 2.4 Verify Reading Goal Auto-synchronization
        reader_goal = get_reading_goal(year=None, user=bob, db=db)
        assert reader_goal.completed_books >= 1

        # 2.5 Verify Aggregated Reader Dashboard
        reader_dash = get_reader_dashboard(user=bob, db=db)
        total_shelf_items = len(reader_dash.currently_reading) + len(reader_dash.want_to_read) + len(reader_dash.completed) + len(reader_dash.paused)
        assert total_shelf_items >= 3
        assert len(reader_dash.completed) >= 1
        assert len(reader_dash.currently_reading) >= 1
        print(f"[PASS] Reader E2E Journey complete: {total_shelf_items} shelf books, {len(reader_dash.completed)} completed, goal synced={reader_goal.completed_books}")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 3: UNIFIED ACCOUNT & MULTI-PERSONA COEXISTENCE
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 3: Unified Account & Multi-Persona Coexistence ---")
        # Charlie has both student and reader profiles
        # Add a student subject to Charlie
        c_subj = create_student_subject(
            StudentSubjectCreate(
                name="Statistical Machine Learning",
                code="DS501",
                progress=0.60,
                target=0.90,
                is_lagging=False,
                instructor="Prof. Bishop",
            ),
            user=charlie,
            db=db,
        )
        # Add a reader bookshelf item to Charlie
        c_shelf = add_bookshelf_item(
            BookshelfItemCreate(
                title="Foundation",
                author="Isaac Asimov",
                category="currently_reading",
                total_pages=255,
                current_page=140,
                progress=0.55,
            ),
            user=charlie,
            db=db,
        )

        # Charlie queries Student Dashboard: should contain 1 subject, 0 shelf books
        c_student_dash = get_student_dashboard(user=charlie, db=db)
        assert c_student_dash.total_subjects == 1
        assert c_student_dash.subjects[0].name == "Statistical Machine Learning"

        # Charlie queries Reader Dashboard: should contain 1 shelf book, 0 subjects
        c_reader_dash = get_reader_dashboard(user=charlie, db=db)
        c_total_shelf = len(c_reader_dash.currently_reading) + len(c_reader_dash.want_to_read) + len(c_reader_dash.completed) + len(c_reader_dash.paused)
        assert c_total_shelf == 1
        assert len(c_reader_dash.currently_reading) == 1

        # Charlie queries Composite Profile: both student and reader data coexist
        c_composite = get_user_composite_profile(user=charlie, db=db)
        assert c_composite["student_profile"] is not None
        assert c_composite["reader_profile"] is not None
        assert c_composite["student_profile"]["course"] == "Data Science"
        assert "Science Fiction" in c_composite["reader_profile"]["genres"]
        print("[PASS] Unified account clean multi-persona coexistence verified with 0 cross-bleed!")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 4: EXPLORE DISCOVERY, SEARCH & FAVORITES INTEGRATION
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 4: Explore Discovery, Search & Favorites Integration ---")
        # Search catalog
        search_res = get_catalog(
            q="Algorithms",
            category="Academic & Textbooks",
            sort_by="price_asc",
            user=alice,
            db=db,
        )
        assert search_res["total"] >= 1
        found_book = search_res["data"][0]
        assert "Algorithms" in found_book["title"]

        # Toggle favorite for Alice
        fav_toggle = toggle_favorite_route(book_id=found_book["id"], db=db, user=alice)
        assert fav_toggle["isFavorite"] is True

        # Alice verifies favorites list
        alice_favs = get_favorites(db=db, user=alice)
        assert len(alice_favs) == 1
        assert alice_favs[0]["id"] == found_book["id"]

        # Bob verifies his favorites list is empty (strict isolation)
        bob_favs = get_favorites(db=db, user=bob)
        assert len(bob_favs) == 0

        # Personalized recommendations for Alice (student)
        alice_rec_res = get_user_recommendations(limit=5, user=alice, db=db)
        alice_recs = alice_rec_res.get("recommendations", [])
        assert len(alice_recs) > 0
        # Check that recommendations prioritize relevant books
        assert any("Academic" in r.get("category", "") or "Algorithms" in r.get("title", "") for r in alice_recs)
        print(f"[PASS] Explore & discovery integrated: {len(search_res['data'])} found, favorites isolated, recommendations scored.")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 5: MULTI-TENANT SECURITY & STRICT ACCOUNT ISOLATION
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 5: Multi-Tenant Security & Strict Account Isolation ---")
        # Eve (intruder) tries to read Alice's subject
        try:
            get_student_subject_by_id(subj1.id, user=eve, db=db)
            raise AssertionError("Intruder should NOT read Alice's subject!")
        except HTTPException as e:
            assert e.status_code == 403, f"Expected 403, got {e.status_code}"
            print("[PASS] Blocked cross-tenant subject access (HTTP 403)")

        # Eve tries to update Alice's subject
        try:
            update_student_subject(subj1.id, StudentSubjectUpdate(name="Hacked Subject"), user=eve, db=db)
            raise AssertionError("Intruder should NOT update Alice's subject!")
        except HTTPException as e:
            assert e.status_code == 403

        # Eve tries to delete Alice's assignment
        try:
            delete_student_assignment(asgn.id, user=eve, db=db)
            raise AssertionError("Intruder should NOT delete Alice's assignment!")
        except HTTPException as e:
            assert e.status_code == 403
            print("[PASS] Blocked cross-tenant assignment deletion (HTTP 403)")

        # Eve tries to read Bob's bookshelf item
        try:
            get_bookshelf_item_by_id(b1.id, user=eve, db=db)
            raise AssertionError("Intruder should NOT read Bob's bookshelf item!")
        except HTTPException as e:
            assert e.status_code == 403
            print("[PASS] Blocked cross-tenant bookshelf access (HTTP 403)")

        # Eve tries to move Bob's bookshelf item
        try:
            move_bookshelf_item(b1.id, BookshelfItemMove(category="want_to_read"), user=eve, db=db)
            raise AssertionError("Intruder should NOT move Bob's bookshelf item!")
        except HTTPException as e:
            assert e.status_code == 403

        # Eve tries to delete Bob's bookshelf item
        try:
            delete_bookshelf_item(b1.id, user=eve, db=db)
            raise AssertionError("Intruder should NOT delete Bob's bookshelf item!")
        except HTTPException as e:
            assert e.status_code == 403
            print("[PASS] Blocked cross-tenant bookshelf deletion (HTTP 403)")

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 6: DEEP PERSISTENCE ACROSS SESSIONS & CONNECTION POOL RESET
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 6: Deep Persistence Across Sessions & Pool Reset ---")
        alice_id = alice.id
        bob_id = bob.id
        subj1_id = subj1.id
        b1_id = b1.id
        b2_id = b2.id

        # Explicitly close session and dispose connection pool
        db.close()
        engine.dispose()

        # Open brand new session
        db2 = SessionLocal()
        try:
            # Re-fetch Alice and verify student data persistence
            re_alice = db2.query(User).filter(User.id == alice_id).first()
            assert re_alice is not None
            assert re_alice.name == "Alice Student"

            re_subj = db2.query(StudentSubject).filter(StudentSubject.id == subj1_id).first()
            assert re_subj is not None
            assert re_subj.name == "Algorithms & Complexity"
            assert re_subj.progress == 0.45
            assert re_subj.user_id == alice_id

            re_asgns = db2.query(StudentAssignment).filter(StudentAssignment.user_id == alice_id).all()
            assert len(re_asgns) >= 1
            assert re_asgns[0].status == "Completed"

            # Re-fetch Bob and verify bookshelf persistence
            re_bob = db2.query(User).filter(User.id == bob_id).first()
            assert re_bob is not None

            re_b1 = db2.query(BookshelfItem).filter(BookshelfItem.id == b1_id).first()
            assert re_b1 is not None
            assert re_b1.category == "completed"
            assert re_b1.progress == 1.0

            re_b2 = db2.query(BookshelfItem).filter(BookshelfItem.id == b2_id).first()
            assert re_b2 is not None
            assert re_b2.category == "currently_reading"
            assert re_b2.current_page == 100

            print("[PASS] 100% of Student and Reader data survived complete engine/session reset cleanly!")
        finally:
            db2.close()

        # ──────────────────────────────────────────────────────────────────────
        # SCENARIO 7: EDGE CASES & SAFE COMPUTATIONS
        # ──────────────────────────────────────────────────────────────────────
        print("\n--- Scenario 7: Edge Cases & Safe Computations ---")
        db3 = SessionLocal()
        try:
            # Zero-division safety on Reading Goal
            rg = db3.query(ReadingGoal).filter(ReadingGoal.user_id == bob_id).first()
            rg.target_books = 0
            rg.target_pages = 0
            db3.commit()

            bob_user = db3.query(User).filter(User.id == bob_id).first()
            # Calling reader dashboard with 0 target should not crash
            safe_dash = get_reader_dashboard(user=bob_user, db=db3)
            assert safe_dash is not None
            safe_shelf_count = len(safe_dash.currently_reading) + len(safe_dash.want_to_read) + len(safe_dash.completed) + len(safe_dash.paused)
            assert safe_shelf_count >= 3
            print("[PASS] Zero-target reading goal handled gracefully without division by zero")

            # Non-existent ID handling returns 404
            try:
                get_student_subject_by_id(999999, user=alice, db=db3)
                raise AssertionError("Expected 404 for non-existent subject")
            except HTTPException as e:
                assert e.status_code == 404
                print("[PASS] Non-existent subject returned HTTP 404")

            try:
                get_bookshelf_item_by_id(999999, user=bob, db=db3)
                raise AssertionError("Expected 404 for non-existent bookshelf item")
            except HTTPException as e:
                assert e.status_code == 404
                print("[PASS] Non-existent bookshelf item returned HTTP 404")
        finally:
            db3.close()

        print("\n" + "=" * 70)
        print("ALL 7 PHASE 16B.5 INTEGRATION & PERSISTENCE SCENARIOS PASSED PERFECTLY!")
        print("=" * 70)

    finally:
        # Clean up test users
        clean_db = SessionLocal()
        cleanup_test_data(clean_db, test_emails)
        clean_db.close()
        print("[INFO] Cleaned up temporary integration test users.")


if __name__ == "__main__":
    run_e2e_integration_tests()
