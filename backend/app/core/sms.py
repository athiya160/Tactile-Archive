import os
import logging
import urllib.parse
import urllib.request
import base64
import json

logger = logging.getLogger("app.core.sms")

TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")


def mask_phone(phone: str) -> str:
    """Masks phone number for secure logging (e.g. +91*****1234)."""
    if not phone:
        return "***"
    cleaned = phone.strip()
    if len(cleaned) <= 4:
        return "****"
    if len(cleaned) >= 8:
        return cleaned[:3] + "*" * (len(cleaned) - 7) + cleaned[-4:]
    return cleaned[:2] + "***" + cleaned[-2:]


def send_otp_sms(to_phone: str, otp_code: str, action_text: str = "Verification") -> bool:
    """
    Sends a 6-digit OTP code to a mobile phone number using Twilio SMS API.
    Guarantees that OTP values and authentication secrets are never exposed in log outputs.
    """
    masked_phone = mask_phone(to_phone)
    logger.info(f"[SMS DISPATCH] 6-Digit OTP dispatch requested for {masked_phone} ({action_text})")

    if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN or not TWILIO_PHONE_NUMBER:
        logger.info(f"[SMS] Twilio credentials unconfigured in environment. Simulated SMS dispatch to {masked_phone}.")
        return True

    # Ensure phone number format
    formatted_phone = to_phone.strip()
    if not formatted_phone.startswith("+"):
        formatted_phone = f"+{formatted_phone}"

    url = f"https://api.twilio.com/2010-04-01/Accounts/{TWILIO_ACCOUNT_SID}/Messages.json"
    
    payload = urllib.parse.urlencode({
        "To": formatted_phone,
        "From": TWILIO_PHONE_NUMBER,
        "Body": f"Your Tactile Archive {action_text} code is: {otp_code}. Valid for 10 minutes. Do not share it with anyone."
    }).encode("utf-8")

    auth_header = base64.b64encode(f"{TWILIO_ACCOUNT_SID}:{TWILIO_AUTH_TOKEN}".encode("utf-8")).decode("utf-8")

    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Authorization": f"Basic {auth_header}",
            "Content-Type": "application/x-www-form-urlencoded"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode("utf-8")
            data = json.loads(res_body)
            logger.info(f"[SMS] Twilio SMS dispatched successfully to {masked_phone}. Message SID: {data.get('sid')}")
            return True
    except Exception as e:
        logger.error(f"[SMS] Failed to send Twilio SMS to {masked_phone}: {e}")
        return False
