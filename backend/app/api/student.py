import json
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.api.auth import get_current_user, get_db
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
    StudentSubjectResponse,
    StudentScheduleItemCreate,
    StudentScheduleItemUpdate,
    StudentScheduleItemResponse,
    StudentAssignmentCreate,
    StudentAssignmentUpdate,
    StudentAssignmentResponse,
    StudentGoalCreate,
    StudentGoalUpdate,
    StudentGoalResponse,
    StudentDashboardSummary,
)

router = APIRouter(prefix="/student", tags=["Student"])

def _format_subject(subj: StudentSubject) -> StudentSubjectResponse:
    textbook_ids = []
    if subj.textbook_ids:
        try:
            textbook_ids = json.loads(subj.textbook_ids)
            if not isinstance(textbook_ids, list):
                textbook_ids = []
        except Exception:
            textbook_ids = []

    return StudentSubjectResponse(
        id=subj.id,
        user_id=subj.user_id,
        name=subj.name,
        code=subj.code,
        progress=subj.progress,
        target=subj.target,
        is_lagging=subj.is_lagging,
        color=subj.color,
        instructor=subj.instructor,
        credits=subj.credits,
        hours_per_week=subj.hours_per_week,
        syllabus=subj.syllabus,
        textbook_ids=textbook_ids,
        created_at=subj.created_at,
        updated_at=subj.updated_at,
    )

# ─── DASHBOARD SUMMARY ────────────────────────────────────────────────────────

@router.get("/dashboard", response_model=StudentDashboardSummary)
def get_student_dashboard(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    profile = user.student_profile
    subjects = db.query(StudentSubject).filter(StudentSubject.user_id == user.id).all()
    schedule = db.query(StudentScheduleItem).filter(StudentScheduleItem.user_id == user.id).all()
    assignments = db.query(StudentAssignment).filter(StudentAssignment.user_id == user.id).all()
    goals = db.query(StudentGoal).filter(StudentGoal.user_id == user.id).all()

    total_progress = sum(s.progress for s in subjects) if subjects else 0.0
    overall_progress = round(total_progress / len(subjects), 2) if subjects else 0.0
    lagging_count = sum(1 for s in subjects if s.is_lagging or s.progress < 0.4)
    pending_tasks = sum(1 for a in assignments if a.status != "Completed")

    return StudentDashboardSummary(
        education_level=profile.education_level if profile else None,
        course=profile.course if profile else None,
        college=profile.college if profile else None,
        semester=profile.semester if profile else None,
        graduation_year=profile.graduation_year if profile else None,
        total_subjects=len(subjects),
        overall_progress=overall_progress,
        lagging_subjects_count=lagging_count,
        upcoming_tasks_count=pending_tasks,
        subjects=[_format_subject(s) for s in subjects],
        schedule=[StudentScheduleItemResponse.from_orm(sc) for sc in schedule],
        assignments=[StudentAssignmentResponse.from_orm(a) for a in assignments],
        goals=[StudentGoalResponse.from_orm(g) for g in goals],
    )

# ─── SUBJECTS CRUD ────────────────────────────────────────────────────────────

@router.get("/subjects", response_model=List[StudentSubjectResponse])
def get_student_subjects(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subjects = db.query(StudentSubject).filter(StudentSubject.user_id == user.id).all()
    return [_format_subject(s) for s in subjects]

@router.post("/subjects", response_model=StudentSubjectResponse, status_code=status.HTTP_201_CREATED)
def create_student_subject(
    payload: StudentSubjectCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    textbook_json = json.dumps(payload.textbook_ids or [])
    new_subject = StudentSubject(
        user_id=user.id,
        name=payload.name,
        code=payload.code,
        progress=payload.progress,
        target=payload.target,
        is_lagging=payload.is_lagging,
        color=payload.color or "#006644",
        instructor=payload.instructor,
        credits=payload.credits,
        hours_per_week=payload.hours_per_week,
        syllabus=payload.syllabus,
        textbook_ids=textbook_json,
    )
    db.add(new_subject)
    db.commit()
    db.refresh(new_subject)
    return _format_subject(new_subject)

@router.get("/subjects/{subject_id}", response_model=StudentSubjectResponse)
def get_student_subject_by_id(
    subject_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subject = db.query(StudentSubject).filter(StudentSubject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    if subject.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this subject")
    return _format_subject(subject)

@router.put("/subjects/{subject_id}", response_model=StudentSubjectResponse)
def update_student_subject(
    subject_id: int,
    payload: StudentSubjectUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subject = db.query(StudentSubject).filter(StudentSubject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    if subject.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this subject")

    if payload.name is not None:
        subject.name = payload.name
    if payload.code is not None:
        subject.code = payload.code
    if payload.progress is not None:
        subject.progress = payload.progress
    if payload.target is not None:
        subject.target = payload.target
    if payload.is_lagging is not None:
        subject.is_lagging = payload.is_lagging
    if payload.color is not None:
        subject.color = payload.color
    if payload.instructor is not None:
        subject.instructor = payload.instructor
    if payload.credits is not None:
        subject.credits = payload.credits
    if payload.hours_per_week is not None:
        subject.hours_per_week = payload.hours_per_week
    if payload.syllabus is not None:
        subject.syllabus = payload.syllabus
    if payload.textbook_ids is not None:
        subject.textbook_ids = json.dumps(payload.textbook_ids)

    db.commit()
    db.refresh(subject)
    return _format_subject(subject)

@router.delete("/subjects/{subject_id}", status_code=status.HTTP_200_OK)
def delete_student_subject(
    subject_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subject = db.query(StudentSubject).filter(StudentSubject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    if subject.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this subject")

    db.delete(subject)
    db.commit()
    return {"message": "Subject deleted successfully", "id": subject_id}

# ─── SCHEDULE CRUD ────────────────────────────────────────────────────────────

@router.get("/schedule", response_model=List[StudentScheduleItemResponse])
def get_student_schedule(
    date: Optional[str] = Query(None, description="Filter by date YYYY-MM-DD"),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(StudentScheduleItem).filter(StudentScheduleItem.user_id == user.id)
    if date:
        query = query.filter(StudentScheduleItem.date == date)
    items = query.all()
    return items

@router.post("/schedule", response_model=StudentScheduleItemResponse, status_code=status.HTTP_201_CREATED)
def create_student_schedule_item(
    payload: StudentScheduleItemCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = StudentScheduleItem(
        user_id=user.id,
        subject_id=payload.subject_id,
        subject_name=payload.subject_name,
        topic=payload.topic,
        time_slot=payload.time_slot,
        date=payload.date,
        duration_minutes=payload.duration_minutes,
        status=payload.status,
        color=payload.color,
        is_boosted=payload.is_boosted,
        notes=payload.notes,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item

@router.post("/schedule/rebalance")
def rebalance_student_schedule(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    subjects = db.query(StudentSubject).filter(StudentSubject.user_id == user.id).all()
    lagging = [s for s in subjects if s.is_lagging or (s.progress is not None and s.target is not None and s.progress < s.target)]
    if not lagging and subjects:
        lagging = subjects[:2]

    added_count = 0
    now = datetime.datetime.utcnow()
    for s in lagging:
        date_str = (now + datetime.timedelta(days=added_count + 1)).strftime("%Y-%m-%d")
        rebal_item = StudentScheduleItem(
            user_id=user.id,
            subject_id=s.id,
            subject_name=s.name,
            topic=f"Boosted Deep Review: {s.name}",
            time_slot="10:00 AM - 11:30 AM",
            date=date_str,
            duration_minutes=90,
            status="Pending",
            color=s.color or "#1B4D3E",
            is_boosted=True,
            notes="AI-optimized catch-up focus block to close progress gap.",
        )
        db.add(rebal_item)
        added_count += 1

    db.commit()
    return {"status": "success", "sessions_added": added_count}

@router.put("/schedule/{item_id}", response_model=StudentScheduleItemResponse)
def update_student_schedule_item(
    item_id: int,
    payload: StudentScheduleItemUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(StudentScheduleItem).filter(StudentScheduleItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Schedule item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this schedule item")

    update_dict = payload.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(item, k, v)

    db.commit()
    db.refresh(item)
    return item

@router.delete("/schedule/{item_id}", status_code=status.HTTP_200_OK)
def delete_student_schedule_item(
    item_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    item = db.query(StudentScheduleItem).filter(StudentScheduleItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Schedule item not found")
    if item.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this schedule item")

    db.delete(item)
    db.commit()
    return {"message": "Schedule item deleted successfully", "id": item_id}

# ─── ASSIGNMENTS CRUD ─────────────────────────────────────────────────────────

@router.get("/assignments", response_model=List[StudentAssignmentResponse])
def get_student_assignments(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(StudentAssignment).filter(StudentAssignment.user_id == user.id).all()

@router.post("/assignments", response_model=StudentAssignmentResponse, status_code=status.HTTP_201_CREATED)
def create_student_assignment(
    payload: StudentAssignmentCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    assignment = StudentAssignment(
        user_id=user.id,
        subject_id=payload.subject_id,
        title=payload.title,
        description=payload.description,
        due_date=payload.due_date,
        priority=payload.priority,
        status=payload.status,
    )
    db.add(assignment)
    db.commit()
    db.refresh(assignment)
    return assignment

@router.put("/assignments/{assignment_id}", response_model=StudentAssignmentResponse)
def update_student_assignment(
    assignment_id: int,
    payload: StudentAssignmentUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    assignment = db.query(StudentAssignment).filter(StudentAssignment.id == assignment_id).first()
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    if assignment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this assignment")

    update_dict = payload.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(assignment, k, v)

    db.commit()
    db.refresh(assignment)
    return assignment

@router.delete("/assignments/{assignment_id}", status_code=status.HTTP_200_OK)
def delete_student_assignment(
    assignment_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    assignment = db.query(StudentAssignment).filter(StudentAssignment.id == assignment_id).first()
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    if assignment.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this assignment")

    db.delete(assignment)
    db.commit()
    return {"message": "Assignment deleted successfully", "id": assignment_id}

# ─── GOALS CRUD ───────────────────────────────────────────────────────────────

@router.get("/goals", response_model=List[StudentGoalResponse])
def get_student_goals(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return db.query(StudentGoal).filter(StudentGoal.user_id == user.id).all()

@router.post("/goals", response_model=StudentGoalResponse, status_code=status.HTTP_201_CREATED)
def create_student_goal(
    payload: StudentGoalCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = StudentGoal(
        user_id=user.id,
        title=payload.title,
        target_date=payload.target_date,
        progress=payload.progress,
        category=payload.category,
        status=payload.status,
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)
    return goal

@router.put("/goals/{goal_id}", response_model=StudentGoalResponse)
def update_student_goal(
    goal_id: int,
    payload: StudentGoalUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = db.query(StudentGoal).filter(StudentGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this goal")

    update_dict = payload.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(goal, k, v)

    db.commit()
    db.refresh(goal)
    return goal

@router.delete("/goals/{goal_id}", status_code=status.HTTP_200_OK)
def delete_student_goal(
    goal_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    goal = db.query(StudentGoal).filter(StudentGoal.id == goal_id).first()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    if goal.user_id != user.id:
        raise HTTPException(status_code=403, detail="Access denied to this goal")

    db.delete(goal)
    db.commit()
    return {"message": "Goal deleted successfully", "id": goal_id}
