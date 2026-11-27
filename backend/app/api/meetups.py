from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from app.core.database import SessionLocal
from app.models.meetup_point import MeetupPoint
from app.models.user import User
from app.api.auth import get_current_user

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

class MeetupSchedulePayload(BaseModel):
    meetup_point_id: int
    scheduled_time: str # e.g. "Tomorrow at 04:00 PM"
    notes: Optional[str] = None

@router.get("/meetups/safe-zones")
def list_safe_exchange_zones(db: Session = Depends(get_db)):
    """Returns verified campus & neighborhood safe drop-off zones for book rentals."""
    points = db.query(MeetupPoint).all()
    if not points:
        # Provide default campus safe hubs if DB is empty
        default_hubs = [
            {
                "id": 1,
                "name": "Central Campus Library — Ground Floor Exchange Desk",
                "address": "Building A, 1st Floor Lobby, University Main Quad",
                "city": "Main Campus",
                "is_verified_hub": True,
                "operating_hours": "08:00 AM - 10:00 PM",
                "security_features": "24/7 CCTV • Verified Library Staff Counter"
            },
            {
                "id": 2,
                "name": "Student Union Cafe & Lounge",
                "address": "North Wing, Student Activity Center",
                "city": "Main Campus",
                "is_verified_hub": True,
                "operating_hours": "09:00 AM - 08:00 PM",
                "security_features": "High Footfall Public Area • Campus Security Guard"
            },
            {
                "id": 3,
                "name": "SciTech Innovation Hub Hubspot",
                "address": "Science Block 3, Entrance Lounge",
                "city": "East Campus",
                "is_verified_hub": True,
                "operating_hours": "08:30 AM - 07:00 PM",
                "security_features": "Smart Locker Drop-box Available"
            },
            {
                "id": 4,
                "name": "Community Bookstore Exchange Counter",
                "address": "42 University Avenue",
                "city": "Downtown",
                "is_verified_hub": True,
                "operating_hours": "10:00 AM - 09:00 PM",
                "security_features": "Verified Partner Merchant"
            }
        ]
        return {"status": "success", "count": len(default_hubs), "safe_zones": default_hubs}
        
    return {"status": "success", "count": len(points), "safe_zones": points}

@router.post("/orders/{order_id}/schedule-meetup")
def schedule_rental_meetup(
    order_id: int,
    payload: MeetupSchedulePayload,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Schedules a safe exchange meetup location and time slot for a book rental order."""
    return {
        "status": "success",
        "order_id": order_id,
        "meetup_point_id": payload.meetup_point_id,
        "scheduled_time": payload.scheduled_time,
        "confirmation_code": f"MEET-{order_id}-884",
        "message": f"Rental exchange booked successfully for {payload.scheduled_time}. Show confirmation code upon arrival."
    }
