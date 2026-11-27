from pydantic import BaseModel, Field
from typing import Optional, List, Any
import datetime

# --- Subject Schemas ---
class StudentSubjectBase(BaseModel):
    name: str
    code: Optional[str] = None
    progress: float = Field(default=0.0, ge=0.0, le=1.0)
    target: float = Field(default=1.0, ge=0.0, le=1.0)
    is_lagging: bool = False
    color: str = "#006644"
    instructor: Optional[str] = None
    credits: int = 3
    hours_per_week: int = 4
    syllabus: Optional[str] = None
    textbook_ids: Optional[List[int]] = []

class StudentSubjectCreate(StudentSubjectBase):
    pass

class StudentSubjectUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    target: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    is_lagging: Optional[bool] = None
    color: Optional[str] = None
    instructor: Optional[str] = None
    credits: Optional[int] = None
    hours_per_week: Optional[int] = None
    syllabus: Optional[str] = None
    textbook_ids: Optional[List[int]] = None

class StudentSubjectResponse(StudentSubjectBase):
    id: int
    user_id: int
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Schedule Item Schemas ---
class StudentScheduleItemBase(BaseModel):
    subject_name: str
    topic: str
    time_slot: str
    subject_id: Optional[int] = None
    date: Optional[str] = None # YYYY-MM-DD
    duration_minutes: int = 60
    status: str = "Pending"
    color: str = "#006644"
    is_boosted: bool = False
    notes: Optional[str] = None

class StudentScheduleItemCreate(StudentScheduleItemBase):
    pass

class StudentScheduleItemUpdate(BaseModel):
    subject_name: Optional[str] = None
    topic: Optional[str] = None
    time_slot: Optional[str] = None
    subject_id: Optional[int] = None
    date: Optional[str] = None
    duration_minutes: Optional[int] = None
    status: Optional[str] = None
    color: Optional[str] = None
    is_boosted: Optional[bool] = None
    notes: Optional[str] = None

class StudentScheduleItemResponse(StudentScheduleItemBase):
    id: int
    user_id: int
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Assignment Schemas ---
class StudentAssignmentBase(BaseModel):
    title: str
    subject_id: Optional[int] = None
    description: Optional[str] = None
    due_date: Optional[str] = None
    priority: str = "Medium"
    status: str = "Pending"

class StudentAssignmentCreate(StudentAssignmentBase):
    pass

class StudentAssignmentUpdate(BaseModel):
    title: Optional[str] = None
    subject_id: Optional[int] = None
    description: Optional[str] = None
    due_date: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None

class StudentAssignmentResponse(StudentAssignmentBase):
    id: int
    user_id: int
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Goal Schemas ---
class StudentGoalBase(BaseModel):
    title: str
    target_date: Optional[str] = None
    progress: float = Field(default=0.0, ge=0.0, le=1.0)
    category: str = "Academic"
    status: str = "Active"

class StudentGoalCreate(StudentGoalBase):
    pass

class StudentGoalUpdate(BaseModel):
    title: Optional[str] = None
    target_date: Optional[str] = None
    progress: Optional[float] = Field(default=None, ge=0.0, le=1.0)
    category: Optional[str] = None
    status: Optional[str] = None

class StudentGoalResponse(StudentGoalBase):
    id: int
    user_id: int
    created_at: Optional[datetime.datetime] = None
    updated_at: Optional[datetime.datetime] = None

    class Config:
        from_attributes = True


# --- Student Dashboard Summary Schema ---
class StudentDashboardSummary(BaseModel):
    education_level: Optional[str] = None
    course: Optional[str] = None
    college: Optional[str] = None
    semester: Optional[str] = None
    graduation_year: Optional[str] = None
    total_subjects: int = 0
    overall_progress: float = 0.0
    lagging_subjects_count: int = 0
    upcoming_tasks_count: int = 0
    subjects: List[StudentSubjectResponse] = []
    schedule: List[StudentScheduleItemResponse] = []
    assignments: List[StudentAssignmentResponse] = []
    goals: List[StudentGoalResponse] = []
