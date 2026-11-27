from sqlalchemy import Column, Integer, String, DateTime, Boolean
import datetime
from app.core.database import Base

class OTPCode(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, index=True)
    identifier = Column(String, index=True, nullable=False) # Email or Phone number
    code = Column(String(6), nullable=False) # 6-digit OTP
    purpose = Column(String, nullable=False, default="password_reset") # 'password_reset' or 'login_otp'
    expires_at = Column(DateTime, nullable=False)
    used = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
