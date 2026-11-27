"""
Account Deletion Request Relational Model
Project: The Tactile Archive / LibriFlow

Durable persistence for public web and external account deletion intake requests
under Google Play Store Data Safety & Account Deletion policies.
"""

from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Index
from sqlalchemy.orm import relationship
import datetime
import uuid
from app.core.database import Base


def generate_request_id() -> str:
    """Generate a clean UUID-based tracking identifier for public acknowledgement."""
    return f"del_{uuid.uuid4().hex[:16]}"


class AccountDeletionRequest(Base):
    __tablename__ = "account_deletion_requests"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    request_id = Column(String(32), unique=True, index=True, nullable=False, default=generate_request_id)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    email = Column(String(255), nullable=False, index=True)
    reason = Column(String(500), nullable=True)
    status = Column(String(50), nullable=False, default="pending", index=True)  # pending, in_review, completed, rejected, cancelled
    ip_hash = Column(String(64), nullable=True)  # SHA-256 of client IP, never plaintext IP
    resolution_notes = Column(String(1000), nullable=True)
    processed_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    processed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False, index=True)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", foreign_keys=[user_id])
    processor = relationship("User", foreign_keys=[processed_by])

    def mask_email(self) -> str:
        """Return masked email for privacy-safe administrative viewing (e.g. a***a@example.com)."""
        if not self.email or "@" not in self.email:
            return "***"
        parts = self.email.split("@", 1)
        name, domain = parts[0], parts[1]
        if len(name) <= 2:
            masked_name = name[0] + "*"
        else:
            masked_name = name[0] + ("*" * (len(name) - 2)) + name[-1]
        return f"{masked_name}@{domain}"
