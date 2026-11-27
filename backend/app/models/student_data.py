from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base

class StudentSubject(Base):
    __tablename__ = "student_subjects"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False)
    code = Column(String, nullable=True)
    progress = Column(Float, default=0.0) # 0.0 to 1.0
    target = Column(Float, default=1.0)
    is_lagging = Column(Boolean, default=False)
    color = Column(String, default="#006644")
    instructor = Column(String, nullable=True)
    credits = Column(Integer, default=3)
    hours_per_week = Column(Integer, default=4)
    syllabus = Column(Text, nullable=True)
    textbook_ids = Column(Text, nullable=True) # JSON array of book IDs
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="student_subjects")
    schedules = relationship("StudentScheduleItem", back_populates="subject", cascade="all, delete-orphan")
    assignments = relationship("StudentAssignment", back_populates="subject", cascade="all, delete-orphan")


class StudentScheduleItem(Base):
    __tablename__ = "student_schedules"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("student_subjects.id", ondelete="SET NULL"), nullable=True)
    subject_name = Column(String, nullable=False)
    topic = Column(String, nullable=False)
    time_slot = Column(String, nullable=False) # e.g. "09:00 AM - 10:30 AM"
    date = Column(String, nullable=True) # YYYY-MM-DD
    duration_minutes = Column(Integer, default=60)
    status = Column(String, default="Pending") # "Pending", "Completed", "In Progress", "Skipped"
    color = Column(String, default="#006644")
    is_boosted = Column(Boolean, default=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="student_schedules")
    subject = relationship("StudentSubject", back_populates="schedules")


class StudentAssignment(Base):
    __tablename__ = "student_assignments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(Integer, ForeignKey("student_subjects.id", ondelete="SET NULL"), nullable=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    due_date = Column(String, nullable=True) # YYYY-MM-DD or ISO
    priority = Column(String, default="Medium") # "Low", "Medium", "High"
    status = Column(String, default="Pending") # "Pending", "In Progress", "Submitted", "Completed"
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="student_assignments")
    subject = relationship("StudentSubject", back_populates="assignments")


class StudentGoal(Base):
    __tablename__ = "student_goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String, nullable=False)
    target_date = Column(String, nullable=True)
    progress = Column(Float, default=0.0) # 0.0 to 1.0
    category = Column(String, default="Academic") # "Academic", "Exam", "Skill", "Project"
    status = Column(String, default="Active") # "Active", "Completed", "Archived"
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="student_goals")
