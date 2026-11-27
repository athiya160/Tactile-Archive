import sys
import os
import pytest
import datetime
from fastapi import HTTPException
from starlette.requests import Request
from unittest.mock import MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["TESTING"] = "true"

from app.core.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile
from app.models.student_data import StudentSubject, StudentScheduleItem, StudentAssignment, StudentGoal
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
    get_student_subjects,
    create_student_subject,
    get_student_subject_by_id,
    update_student_subject,
    delete_student_subject,
    get_student_schedule,
    create_student_schedule_item,
    update_student_schedule_item,
    delete_student_schedule_item,
    get_student_assignments,
    create_student_assignment,
    update_student_assignment,
    delete_student_assignment,
    get_student_goals,
    create_student_goal,
    update_student_goal,
    delete_student_goal,
)
from app.api.reader import (
    get_reader_dashboard,
    get_bookshelf_items,
    add_bookshelf_item,
    get_bookshelf_item_by_id,
    update_bookshelf_item,
    move_bookshelf_item,
    delete_bookshelf_item,
    get_reading_goal,
    update_reading_goal,
)
from app.api.profile import get_user_composite_profile
from app.api.auth import hash_password

def get_clean_test_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    # Clean up test users
    emails = ["student_a@test.com", "student_b@test.com", "reader_a@test.com", "reader_b@test.com"]
    for email in emails:
        user = db.query(User).filter(User.email == email).first()
        if user:
            db.delete(user)
    db.commit()
    return db

def test_student_data_crud_and_cross_user_isolation():
    """Verify Student CRUD operations and strict cross-user data isolation."""
    db = get_clean_test_db()
    try:
        # Create Student A
        student_a = User(
            name="Alice Student",
            email="student_a@test.com",
            password=hash_password("Pass123!"),
            user_type="student",
            active_experience="student"
        )
        db.add(student_a)
        db.commit()
        db.refresh(student_a)

        # Create Student B
        student_b = User(
            name="Bob Student",
            email="student_b@test.com",
            password=hash_password("Pass123!"),
            user_type="student",
            active_experience="student"
        )
        db.add(student_b)
        db.commit()
        db.refresh(student_b)

        # ── 1. Create Subject for Student A ──
        subj_payload = StudentSubjectCreate(
            name="Data Structures & Algorithms",
            code="CS201",
            progress=0.65,
            target=0.90,
            is_lagging=False,
            color="#1B4D3E",
            instructor="Prof. Turing",
            credits=4,
            hours_per_week=5,
            syllabus="Trees, Graphs, Sorting, Dynamic Programming",
            textbook_ids=[101, 102]
        )
        created_subj = create_student_subject(subj_payload, student_a, db)
        assert created_subj.id is not None
        assert created_subj.user_id == student_a.id
        assert created_subj.name == "Data Structures & Algorithms"
        assert created_subj.textbook_ids == [101, 102]

        # ── 2. Create Schedule Item for Student A ──
        sched_payload = StudentScheduleItemCreate(
            subject_id=created_subj.id,
            subject_name="Data Structures & Algorithms",
            topic="Red-Black Trees Analysis",
            time_slot="10:00 AM - 11:30 AM",
            date="2026-11-10",
            duration_minutes=90,
            status="Pending",
            color="#1B4D3E",
            is_boosted=True
        )
        created_sched = create_student_schedule_item(sched_payload, student_a, db)
        assert created_sched.id is not None
        assert created_sched.user_id == student_a.id
        assert created_sched.topic == "Red-Black Trees Analysis"

        # ── 3. Create Assignment for Student A ──
        assign_payload = StudentAssignmentCreate(
            subject_id=created_subj.id,
            title="Algorithm Complexity Problem Set",
            description="Complete exercises 4.1 through 4.8",
            due_date="2026-11-15",
            priority="High",
            status="In Progress"
        )
        created_assign = create_student_assignment(assign_payload, student_a, db)
        assert created_assign.id is not None
        assert created_assign.user_id == student_a.id

        # ── 4. Create Goal for Student A ──
        goal_payload = StudentGoalCreate(
            title="Maintain 3.8+ GPA in Semester 5",
            target_date="2026-12-31",
            progress=0.70,
            category="Academic",
            status="Active"
        )
        created_goal = create_student_goal(goal_payload, student_a, db)
        assert created_goal.id is not None
        assert created_goal.user_id == student_a.id

        # ── 5. Student A fetches Dashboard Summary ──
        dashboard_a = get_student_dashboard(student_a, db)
        assert dashboard_a.total_subjects == 1
        assert len(dashboard_a.subjects) == 1
        assert len(dashboard_a.schedule) == 1
        assert len(dashboard_a.assignments) == 1
        assert len(dashboard_a.goals) == 1
        assert dashboard_a.overall_progress == 0.65

        # ── 6. Student B isolation: Student B sees EMPTY dashboard ──
        dashboard_b = get_student_dashboard(student_b, db)
        assert dashboard_b.total_subjects == 0
        assert len(dashboard_b.subjects) == 0
        assert len(dashboard_b.schedule) == 0
        assert len(dashboard_b.assignments) == 0
        assert len(dashboard_b.goals) == 0

        # ── 7. Cross-User Security Check: Student B CANNOT access Student A's Subject ──
        with pytest.raises(HTTPException) as exc_info:
            get_student_subject_by_id(created_subj.id, student_b, db)
        assert exc_info.value.status_code == 403

        # Student B CANNOT modify Student A's Subject
        with pytest.raises(HTTPException) as exc_info:
            update_student_subject(created_subj.id, StudentSubjectUpdate(name="Hacked Subject"), student_b, db)
        assert exc_info.value.status_code == 403

        # Student B CANNOT delete Student A's Subject
        with pytest.raises(HTTPException) as exc_info:
            delete_student_subject(created_subj.id, student_b, db)
        assert exc_info.value.status_code == 403

        # ── 8. Cross-User Security Check: Student B CANNOT modify Schedule / Assignment / Goal ──
        with pytest.raises(HTTPException) as exc_info:
            update_student_schedule_item(created_sched.id, StudentScheduleItemUpdate(topic="Tampered"), student_b, db)
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            delete_student_schedule_item(created_sched.id, student_b, db)
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            update_student_assignment(created_assign.id, StudentAssignmentUpdate(status="Completed"), student_b, db)
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            delete_student_assignment(created_assign.id, student_b, db)
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            update_student_goal(created_goal.id, StudentGoalUpdate(title="Tampered Goal"), student_b, db)
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            delete_student_goal(created_goal.id, student_b, db)
        assert exc_info.value.status_code == 403

        # ── 9. Student A updates and deletes cleanly ──
        updated_subj = update_student_subject(
            created_subj.id,
            StudentSubjectUpdate(progress=0.85, is_lagging=False),
            student_a,
            db
        )
        assert updated_subj.progress == 0.85

        del_res = delete_student_subject(created_subj.id, student_a, db)
        assert del_res["id"] == created_subj.id

        subjects_after = get_student_subjects(student_a, db)
        assert len(subjects_after) == 0

    finally:
        db.close()


def test_reader_bookshelf_crud_and_cross_user_isolation():
    """Verify Reader Bookshelf CRUD, move lifecycle, and cross-user data isolation."""
    db = get_clean_test_db()
    try:
        # Create Reader A
        reader_a = User(
            name="Clara Reader",
            email="reader_a@test.com",
            password=hash_password("ReaderPass123!"),
            user_type="reader",
            active_experience="reader"
        )
        db.add(reader_a)
        db.commit()
        db.refresh(reader_a)

        # Create Reader B
        reader_b = User(
            name="David Reader",
            email="reader_b@test.com",
            password=hash_password("ReaderPass123!"),
            user_type="reader",
            active_experience="reader"
        )
        db.add(reader_b)
        db.commit()
        db.refresh(reader_b)

        # ── 1. Reader A adds book to Bookshelf ──
        book_payload = BookshelfItemCreate(
            title="The Shadow of the Wind",
            author="Carlos Ruiz Zafón",
            category="currently_reading",
            progress=0.35,
            current_page=175,
            total_pages=500,
            status="Active Rental",
            format="Hardcover",
            days_left=12,
            genre="Historical Fiction"
        )
        added_book = add_bookshelf_item(book_payload, reader_a, db)
        assert added_book.id is not None
        assert added_book.user_id == reader_a.id
        assert added_book.category == "currently_reading"
        assert added_book.started_at is not None

        # ── 2. Reader A updates Reading Goal ──
        goal_payload = ReadingGoalUpdate(
            target_books=25,
            target_pages=7500,
            daily_reading_goal_minutes=45,
            streak_days=7
        )
        updated_goal = update_reading_goal(goal_payload, reader_a, db)
        assert updated_goal.target_books == 25
        assert updated_goal.daily_reading_goal_minutes == 45
        assert updated_goal.streak_days == 7

        # ── 3. Reader A Dashboard Summary ──
        dash_a = get_reader_dashboard(reader_a, db)
        assert len(dash_a.currently_reading) == 1
        assert dash_a.currently_reading[0].title == "The Shadow of the Wind"
        assert dash_a.goal.target_books == 25
        assert dash_a.current_streak_days == 7

        # ── 4. Cross-User Security Check: Reader B CANNOT see Reader A's bookshelf ──
        dash_b = get_reader_dashboard(reader_b, db)
        assert len(dash_b.currently_reading) == 0
        assert len(dash_b.want_to_read) == 0
        assert len(dash_b.completed) == 0

        bookshelf_b = get_bookshelf_items(None, reader_b, db)
        assert len(bookshelf_b) == 0

        # Reader B CANNOT get Reader A's bookshelf item
        with pytest.raises(HTTPException) as exc_info:
            get_bookshelf_item_by_id(added_book.id, reader_b, db)
        assert exc_info.value.status_code == 403

        # Reader B CANNOT update Reader A's bookshelf item
        with pytest.raises(HTTPException) as exc_info:
            update_bookshelf_item(added_book.id, BookshelfItemUpdate(title="Hijacked Book"), reader_b, db)
        assert exc_info.value.status_code == 403

        # Reader B CANNOT move Reader A's bookshelf item
        with pytest.raises(HTTPException) as exc_info:
            move_bookshelf_item(added_book.id, BookshelfItemMove(category="completed"), reader_b, db)
        assert exc_info.value.status_code == 403

        # Reader B CANNOT delete Reader A's bookshelf item
        with pytest.raises(HTTPException) as exc_info:
            delete_bookshelf_item(added_book.id, reader_b, db)
        assert exc_info.value.status_code == 403

        # ── 5. Reader A moves item from currently_reading to completed ──
        moved_item = move_bookshelf_item(
            added_book.id,
            BookshelfItemMove(category="completed", current_page=500, progress=1.0),
            reader_a,
            db
        )
        assert moved_item.category == "completed"
        assert moved_item.progress == 1.0
        assert moved_item.current_page == 500
        assert moved_item.finished_at is not None

        # Verify completed shelf now has the book
        completed_shelf = get_bookshelf_items("completed", reader_a, db)
        assert len(completed_shelf) == 1
        assert completed_shelf[0].id == added_book.id

        # Verify currently_reading shelf is now empty
        current_shelf = get_bookshelf_items("currently_reading", reader_a, db)
        assert len(current_shelf) == 0

        # ── 6. Reader A deletes bookshelf item cleanly ──
        del_res = delete_bookshelf_item(added_book.id, reader_a, db)
        assert del_res["id"] == added_book.id
        assert len(get_bookshelf_items(None, reader_a, db)) == 0

    finally:
        db.close()


def test_unified_account_multi_experience_integrity():
    """Verify that a single user account retains persistent data across both Student and Reader experiences."""
    db = get_clean_test_db()
    try:
        # Create user with primary experience as Student
        user = User(
            name="Elena Scholar",
            email="student_a@test.com",
            password=hash_password("Pass123!"),
            user_type="student",
            active_experience="student"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

        # Add Student Subject
        create_student_subject(
            StudentSubjectCreate(
                name="Quantum Computing",
                code="QC401",
                progress=0.50,
                credits=4
            ),
            user,
            db
        )

        # Add Reader Bookshelf item
        add_bookshelf_item(
            BookshelfItemCreate(
                title="Sapiens: A Brief History of Humankind",
                author="Yuval Noah Harari",
                category="currently_reading",
                progress=0.40,
                current_page=160,
                total_pages=400
            ),
            user,
            db
        )

        # Check composite profile when in Student experience
        profile_res = get_user_composite_profile(user, db)
        assert profile_res["stats"]["plans_count"] == 1
        assert profile_res["currently_reading"] is not None
        assert profile_res["currently_reading"]["title"] == "Sapiens: A Brief History of Humankind"

        # Switch active experience to Reader (unified account)
        user.active_experience = "reader"
        db.commit()
        db.refresh(user)

        # Verify Student data is still preserved in DB
        subjects = get_student_subjects(user, db)
        assert len(subjects) == 1
        assert subjects[0].name == "Quantum Computing"

        # Verify Reader data is still preserved in DB
        bookshelf = get_bookshelf_items(None, user, db)
        assert len(bookshelf) == 1
        assert bookshelf[0].title == "Sapiens: A Brief History of Humankind"

    finally:
        db.close()


def test_database_persistence_across_sessions():
    """Verify data is persisted to disk and retrievable across fresh database sessions."""
    db = get_clean_test_db()
    user_id = None
    subject_id = None
    book_id = None
    try:
        user = User(
            name="Persistence Test User",
            email="student_a@test.com",
            password=hash_password("Pass123!"),
            user_type="student",
            active_experience="student"
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        user_id = user.id

        subj = create_student_subject(
            StudentSubjectCreate(name="Database Internals", code="DB301", progress=0.8),
            user,
            db
        )
        subject_id = subj.id

        book = add_bookshelf_item(
            BookshelfItemCreate(title="Designing Data-Intensive Applications", author="Martin Kleppmann", category="want_to_read"),
            user,
            db
        )
        book_id = book.id
    finally:
        db.close()

    # Open completely new database session
    db2 = SessionLocal()
    try:
        reloaded_user = db2.query(User).filter(User.id == user_id).first()
        assert reloaded_user is not None
        assert reloaded_user.name == "Persistence Test User"

        reloaded_subj = db2.query(StudentSubject).filter(StudentSubject.id == subject_id).first()
        assert reloaded_subj is not None
        assert reloaded_subj.name == "Database Internals"
        assert reloaded_subj.user_id == user_id

        reloaded_book = db2.query(BookshelfItem).filter(BookshelfItem.id == book_id).first()
        assert reloaded_book is not None
        assert reloaded_book.title == "Designing Data-Intensive Applications"
        assert reloaded_book.user_id == user_id
    finally:
        db2.close()

if __name__ == "__main__":
    print("Running Phase 16B.1 Persistence and Security Tests...")
    test_student_data_crud_and_cross_user_isolation()
    print("[PASS] test_student_data_crud_and_cross_user_isolation")
    test_reader_bookshelf_crud_and_cross_user_isolation()
    print("[PASS] test_reader_bookshelf_crud_and_cross_user_isolation")
    test_unified_account_multi_experience_integrity()
    print("[PASS] test_unified_account_multi_experience_integrity")
    test_database_persistence_across_sessions()
    print("[PASS] test_database_persistence_across_sessions")
    print("ALL Phase 16B.1 Persistence & Security Tests PASSED cleanly!")
