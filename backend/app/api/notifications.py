from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List
from datetime import datetime
from app.core.database import SessionLocal
from app.models.notification import Notification, FCMToken
from app.models.user import User
from app.api.auth import get_current_user

router = APIRouter()

# Input Schemas
class FCMTokenRegister(BaseModel):
    token: str

class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# DB connection dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 🔓 Get user notifications (Protected)
@router.get("/notifications", response_model=List[NotificationResponse])
def get_notifications(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    notifications = db.query(Notification).filter(
        Notification.user_id == user.id
    ).order_by(Notification.created_at.desc()).all()
    return notifications

# 🔓 Mark notification as read (Protected)
@router.put("/notifications/{notif_id}/read")
def mark_as_read(
    notif_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    notif = db.query(Notification).filter(
        Notification.id == notif_id,
        Notification.user_id == user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    return {"message": "Notification marked as read"}

# 🔓 Register FCM token (Protected)
@router.post("/users/fcm-token")
def register_fcm_token(
    data: FCMTokenRegister,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    existing = db.query(FCMToken).filter(
        FCMToken.token == data.token
    ).first()
    if existing:
        existing.user_id = user.id
        db.commit()
        return {"message": "FCM Token updated successfully"}
    
    new_token = FCMToken(user_id=user.id, token=data.token)
    db.add(new_token)
    db.commit()
    return {"message": "FCM Token registered successfully"}

# Helper service to send notifications programmatically
def send_notification(db: Session, user_id: int, title: str, message: str):
    # 1. Create in-app notification in PostgreSQL
    notif = Notification(user_id=user_id, title=title, message=message)
    db.add(notif)
    db.commit()

    # 2. Mock sending physical push notification via FCM token
    tokens = db.query(FCMToken).filter(FCMToken.user_id == user_id).all()
    for token in tokens:
        print(f"[MOCK FCM] Sending Push Notification to User {user_id} Token {token.token[:12]}...")
        print(f"[MOCK FCM] Title: '{title}' | Message: '{message}'")
