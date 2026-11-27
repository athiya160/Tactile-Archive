from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, func
from sqlalchemy.orm import relationship
import datetime
from app.core.database import Base


class RevokedToken(Base):
    """
    Persistent cryptographic token revocation entity for The Tactile Archive / LibriFlow.
    Supports individual JTI invalidation, atomic refresh rotation, and replay detection.
    """
    __tablename__ = "revoked_tokens"

    id = Column(Integer, primary_key=True, index=True)
    jti = Column(String(64), unique=True, index=True, nullable=False)
    token_type = Column(String(16), nullable=False)  # 'access' or 'refresh'
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    revoked_at = Column(DateTime(timezone=True), default=datetime.datetime.utcnow, server_default=func.now(), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False, index=True)
    reason = Column(String(64), nullable=True)  # 'logout', 'rotation', 'password_change', 'replay_protection'

    user = relationship("User", backref="revoked_tokens")
