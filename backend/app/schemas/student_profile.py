from pydantic import BaseModel
from typing import Optional, List

class StudentProfilePayload(BaseModel):
    education_level: Optional[str] = "Undergraduate"
    course: Optional[str] = "General"
    college: Optional[str] = None
    semester: Optional[str] = None
    graduation_year: Optional[str] = None
    syllabus_details: Optional[str] = None
    subjects: Optional[List[str]] = []
    exam_goal: Optional[str] = "Semester Exams"
    study_duration: Optional[int] = 60
    difficulty_level: Optional[str] = "Intermediate"
    academic_interests: Optional[List[str]] = []

class StudentProfileResponse(BaseModel):
    id: int
    user_id: int
    education_level: Optional[str] = None
    course: Optional[str] = None
    college: Optional[str] = None
    semester: Optional[str] = None
    graduation_year: Optional[str] = None
    syllabus_details: Optional[str] = None
    subjects: Optional[List[str]] = []
    exam_goal: Optional[str] = None
    study_duration: int = 60
    difficulty_level: str = "Intermediate"
    academic_interests: Optional[List[str]] = []

    class Config:
        from_attributes = True
