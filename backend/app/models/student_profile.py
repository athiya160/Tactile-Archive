from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base

class StudentProfile(Base):
    __tablename__ = "student_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)
    education_level = Column(String, nullable=True) # e.g. Undergraduate, High School, MCA
    course = Column(String, nullable=True) # e.g. Computer Science, Engineering
    college = Column(String, nullable=True) # e.g. Oxford University, MIT, IIT
    semester = Column(String, nullable=True) # e.g. Semester 4
    graduation_year = Column(String, nullable=True) # e.g. 2027
    syllabus_details = Column(Text, nullable=True) # e.g. Syllabus notes or subject syllabus
    subjects = Column(Text, nullable=True) # Stored as JSON string
    exam_goal = Column(String, nullable=True) # e.g. Semester Exams, GRE, GATE
    study_duration = Column(Integer, default=60) # minutes per session
    difficulty_level = Column(String, default="Intermediate")
    academic_interests = Column(Text, nullable=True) # Stored as JSON string
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    user = relationship("User", back_populates="student_profile")
