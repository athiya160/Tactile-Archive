"""
Phase 16B.2 Student Dashboard & Academic Planner Verification Suite
Tests:
1. Student Academic Profile Setup (college, degree, semester)
2. Subject & Syllabus CRUD (progress, credits, instructor, syllabus concepts)
3. Study Sessions & Time-Block Scheduling (regular + boosted focus sessions)
4. Assignments & Deadlines CRUD (priority, due dates, completion toggle)
5. Academic Goals CRUD (categories, target dates, progress tracking)
6. AI Schedule Rebalance (automatic insertion of 90-min boosted review blocks)
7. Aggregated Student Dashboard View (subjects, schedule, assignments, goals)
8. Multi-tenant / Cross-Student Strict Isolation (no data leaks across students)
"""
import sys
import os
import datetime

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
os.environ["TESTING"] = "true"

from app.core.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.student_profile import StudentProfile
from app.models.student_data import (
    StudentSubject,
    StudentScheduleItem,
    StudentAssignment,
    StudentGoal,
)
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
    rebalance_student_schedule,
    get_student_assignments,
    create_student_assignment,
    update_student_assignment,
    delete_student_assignment,
    get_student_goals,
    create_student_goal,
    update_student_goal,
    delete_student_goal,
)
from app.api.auth import hash_password

def run_tests():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    print("=" * 70)
    print("PHASE 16B.2 STUDENT ACADEMIC PLANNER & DASHBOARD VERIFICATION")
    print("=" * 70)

    ts = int(datetime.datetime.now().timestamp())
    email_a = f"alice_student_{ts}@test.com"
    email_b = f"bob_student_{ts}@test.com"

    try:
        # 1. Create Student Users
        student_a = User(
            name="Alice Academic",
            email=email_a,
            password=hash_password("Pass123!"),
            role="customer",
            user_type="student",
            active_experience="student",
        )
        db.add(student_a)

        student_b = User(
            name="Bob Reader",
            email=email_b,
            password=hash_password("Pass123!"),
            role="customer",
            user_type="student",
            active_experience="student",
        )
        db.add(student_b)
        db.commit()
        db.refresh(student_a)
        db.refresh(student_b)

        # Create Student Profile
        prof_a = StudentProfile(
            user_id=student_a.id,
            college="National Institute of Technology",
            course="B.Tech Computer Science",
            semester="Semester 5",
            education_level="Undergraduate",
        )
        db.add(prof_a)
        db.commit()

        print(f"[OK] Created Test Students: Alice (id={student_a.id}), Bob (id={student_b.id})")

        # 2. Subject & Syllabus CRUD
        print("\n--- Test 2: Subject & Syllabus Tracking ---")
        subj_payload = StudentSubjectCreate(
            name="Database Systems",
            code="CS302",
            progress=0.55,
            target=0.90,
            is_lagging=True,
            color="#1A5235",
            instructor="Dr. E.F. Codd",
            credits=4,
            hours_per_week=5,
            syllabus="Relational Algebra, SQL, Normalization, ACID Transactions, B+ Trees",
            textbook_ids=[101, 102],
        )
        created_subj = create_student_subject(subj_payload, student_a, db)
        assert created_subj.id is not None
        assert created_subj.user_id == student_a.id
        assert created_subj.name == "Database Systems"
        assert created_subj.is_lagging is True
        print(f"[PASS] Created Subject: {created_subj.name} (id={created_subj.id})")

        # Add second subject
        subj_payload2 = StudentSubjectCreate(
            name="Computer Networks",
            code="CS304",
            progress=0.80,
            target=0.85,
            is_lagging=False,
            color="#2A6B45",
            instructor="Prof. Kurose",
            credits=3,
            hours_per_week=4,
            syllabus="OSI Model, TCP/IP, Routing Algorithms, Congestion Control",
            textbook_ids=[105],
        )
        created_subj2 = create_student_subject(subj_payload2, student_a, db)
        print(f"[PASS] Created Subject 2: {created_subj2.name} (id={created_subj2.id})")

        # Verify subjects retrieval
        subjects_list = get_student_subjects(student_a, db)
        assert len(subjects_list) == 2
        print(f"[PASS] Retrieved {len(subjects_list)} subjects for Alice")

        # 3. Study Session & Time-Block Scheduling
        print("\n--- Test 3: Study Sessions & Time-Blocking ---")
        sched_payload = StudentScheduleItemCreate(
            subject_id=created_subj.id,
            subject_name="Database Systems",
            topic="ACID Properties & Crash Recovery",
            time_slot="10:00 AM - 11:30 AM",
            date="2026-11-10",
            duration_minutes=90,
            status="Pending",
            color="#1A5235",
            is_boosted=False,
            notes="Review write-ahead logging",
        )
        created_sched = create_student_schedule_item(sched_payload, student_a, db)
        assert created_sched.id is not None
        assert created_sched.user_id == student_a.id
        assert created_sched.topic == "ACID Properties & Crash Recovery"
        print(f"[PASS] Scheduled Session: {created_sched.topic} (id={created_sched.id})")

        # 4. Assignments & Deadlines
        print("\n--- Test 4: Assignments & Deadlines ---")
        assign_payload = StudentAssignmentCreate(
            subject_id=created_subj.id,
            title="B+ Tree Indexing Implementation",
            description="Implement node split and merge algorithms",
            due_date="2026-11-20",
            priority="High",
            status="Pending",
        )
        created_assign = create_student_assignment(assign_payload, student_a, db)
        assert created_assign.id is not None
        assert created_assign.priority == "High"
        print(f"[PASS] Created Assignment: {created_assign.title} (id={created_assign.id})")

        # Update assignment to completed
        up_assign = update_student_assignment(
            created_assign.id,
            StudentAssignmentUpdate(status="Completed"),
            student_a,
            db,
        )
        assert up_assign.status == "Completed"
        print(f"[PASS] Updated Assignment status to Completed")

        # 5. Academic Goals
        print("\n--- Test 5: Academic Goals ---")
        goal_payload = StudentGoalCreate(
            title="Achieve 9.0+ Semester GPA",
            category="Academic",
            target_date="2026-12-31",
            progress=0.75,
            status="Active",
        )
        created_goal = create_student_goal(goal_payload, student_a, db)
        assert created_goal.id is not None
        assert created_goal.progress == 0.75
        print(f"[PASS] Created Goal: {created_goal.title} (id={created_goal.id})")

        # 6. AI Schedule Optimizer / Rebalancer
        print("\n--- Test 6: AI Schedule Optimizer Rebalance ---")
        rebal_result = rebalance_student_schedule(student_a, db)
        assert rebal_result["status"] == "success"
        assert rebal_result["sessions_added"] >= 1
        print(f"[PASS] AI Rebalancer scheduled {rebal_result['sessions_added']} boosted review sessions")

        # Verify boosted session exists
        all_sessions = get_student_schedule(None, student_a, db)
        boosted_sessions = [s for s in all_sessions if s.is_boosted]
        assert len(boosted_sessions) >= 1
        print(f"[PASS] Found {len(boosted_sessions)} boosted study sessions in schedule")

        # 7. Aggregated Student Dashboard
        print("\n--- Test 7: Student Dashboard Aggregated Endpoint ---")
        dash = get_student_dashboard(student_a, db)
        assert dash.college == "National Institute of Technology"
        assert dash.course == "B.Tech Computer Science"
        assert dash.semester == "Semester 5"
        assert dash.total_subjects == 2
        assert dash.lagging_subjects_count == 1
        assert len(dash.subjects) == 2
        assert len(dash.schedule) >= 2
        assert len(dash.assignments) >= 1
        assert len(dash.goals) >= 1
        print(f"[PASS] Student Dashboard returned complete academic view:")
        print(f"       Profile: {dash.college} | {dash.course} | {dash.semester}")
        print(f"       Total Subjects: {dash.total_subjects}, Lagging: {dash.lagging_subjects_count}")
        print(f"       Sessions: {len(dash.schedule)}, Assignments: {len(dash.assignments)}, Goals: {len(dash.goals)}")

        # 8. Strict Multi-tenant Cross-Student Isolation
        print("\n--- Test 8: Cross-Student Multi-tenant Isolation ---")
        dash_b = get_student_dashboard(student_b, db)
        assert len(dash_b.subjects) == 0, "Bob should not see Alice's subjects!"
        assert len(dash_b.schedule) == 0, "Bob should not see Alice's schedule!"
        assert len(dash_b.assignments) == 0, "Bob should not see Alice's assignments!"
        assert len(dash_b.goals) == 0, "Bob should not see Alice's goals!"
        print(f"[PASS] Bob's dashboard is completely isolated (0 subjects, 0 sessions)")

        # Verify Bob cannot delete Alice's subject
        try:
            delete_student_subject(created_subj.id, student_b, db)
            assert False, "Bob should NOT be allowed to delete Alice's subject!"
        except Exception as e:
            assert "403" in str(e) or "Access denied" in str(e)
            print(f"[PASS] Bob cannot delete Alice's subject: {e}")

        # Verify Bob cannot delete Alice's assignment
        try:
            delete_student_assignment(created_assign.id, student_b, db)
            assert False, "Bob should NOT be allowed to delete Alice's assignment!"
        except Exception as e:
            assert "403" in str(e) or "Access denied" in str(e)
            print(f"[PASS] Bob cannot delete Alice's assignment: {e}")

        print("\n" + "=" * 70)
        print("ALL 8 PHASE 16B.2 ACADEMIC PLANNER & DASHBOARD TESTS PASSED!")
        print("=" * 70)

    finally:
        # Cleanup test records
        try:
            db.query(StudentScheduleItem).filter(StudentScheduleItem.user_id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.query(StudentAssignment).filter(StudentAssignment.user_id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.query(StudentGoal).filter(StudentGoal.user_id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.query(StudentSubject).filter(StudentSubject.user_id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.query(StudentProfile).filter(StudentProfile.user_id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.query(User).filter(User.id.in_([student_a.id, student_b.id])).delete(synchronize_session=False)
            db.commit()
            print("[INFO] Cleaned up temporary test data.")
        except Exception as e:
            print(f"[WARN] Cleanup error: {e}")
        db.close()

if __name__ == "__main__":
    run_tests()
