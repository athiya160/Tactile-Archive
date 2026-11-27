import logging
from fastapi import APIRouter, BackgroundTasks, HTTPException
from pydantic import BaseModel, EmailStr
from app.core.mail import send_newsletter_subscription_email

logger = logging.getLogger(__name__)
router = APIRouter()

class NewsletterSubscription(BaseModel):
    email: EmailStr

@router.post("/subscribe")
async def subscribe_newsletter(data: NewsletterSubscription, background_tasks: BackgroundTasks):
    try:
        # In a real app, you would save the email to a database here
        
        # Send confirmation email in background
        background_tasks.add_task(send_newsletter_subscription_email, data.email)
        return {"status": "success", "message": "Subscription successful. Confirmation email sent."}
    except Exception as e:
        logger.error(f"[NEWSLETTER] Subscription failure for {data.email}: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Unable to process newsletter subscription at this time. Please try again later."
        )
