from sqlalchemy import Column, Integer, String, DateTime, Boolean
import datetime
from sqlalchemy.orm import relationship, synonym
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    google_id = Column(String, unique=True, index=True, nullable=True)
    name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)
    level = Column(String, default="Standard Reader")
    is_admin = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=False)
    role = Column(String, default="customer")
    user_type = Column(String, default=None, nullable=True)
    active_experience = Column(String, default="reader", nullable=True)
    provider_enabled = Column(Boolean, default=False)
    provider_status = Column(String, default="not_enrolled")
    onboarding_completed = Column(Boolean, default=False)
    token_version = Column(Integer, default=1, server_default="1", nullable=False)
    join_date = Column(DateTime, default=datetime.datetime.utcnow)

    @property
    def current_experience(self):
        return self.active_experience or self.user_type or "reader"

    @property
    def persona(self):
        return self.user_type or ("reader" if self.role == "customer" else None)

    @persona.setter
    def persona(self, value):
        self.user_type = value

    persona = synonym("user_type", descriptor=persona)

    @property
    def customer_type(self):
        return self.user_type if self.role == "customer" else None

    @customer_type.setter
    def customer_type(self, value):
        self.user_type = value

    customer_type = synonym("user_type", descriptor=customer_type)

    def __init__(self, **kwargs):
        if "customer_type" in kwargs and "user_type" not in kwargs:
            kwargs["user_type"] = kwargs.pop("customer_type")
        if "persona" in kwargs and "user_type" not in kwargs:
            kwargs["user_type"] = kwargs.pop("persona")
        user_role = kwargs.get("role", "customer")
        if user_role == "provider":
            kwargs["provider_enabled"] = kwargs.get("provider_enabled", True)
            kwargs["provider_status"] = kwargs.get("provider_status", "active")
            if "user_type" not in kwargs:
                kwargs["user_type"] = None
        elif "user_type" not in kwargs:
            kwargs["user_type"] = "reader"
        
        if "active_experience" not in kwargs or not kwargs["active_experience"]:
            kwargs["active_experience"] = kwargs.get("user_type") or ("provider" if user_role == "provider" else "reader")
        super().__init__(**kwargs)
    
    # Settings fields
    phone = Column(String, nullable=True)
    address = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    notifications = Column(String, nullable=True) # Stored as JSON string

    books = relationship("Book", back_populates="owner")
    cart = relationship("Cart", back_populates="user", uselist=False)
    favorites = relationship("Favorite", back_populates="user")
    student_profile = relationship("StudentProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    reader_profile = relationship("ReaderProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    student_subjects = relationship("StudentSubject", back_populates="user", cascade="all, delete-orphan")
    student_schedules = relationship("StudentScheduleItem", back_populates="user", cascade="all, delete-orphan")
    student_assignments = relationship("StudentAssignment", back_populates="user", cascade="all, delete-orphan")
    student_goals = relationship("StudentGoal", back_populates="user", cascade="all, delete-orphan")
    bookshelf_items = relationship("BookshelfItem", back_populates="user", cascade="all, delete-orphan")
    reading_goals = relationship("ReadingGoal", back_populates="user", cascade="all, delete-orphan")
