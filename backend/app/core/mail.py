import os
import logging
from urllib.parse import urlparse
from jinja2 import Environment, FileSystemLoader
import resend
from dotenv import load_dotenv

logger = logging.getLogger("app.core.mail")

from app.core.config import load_environment
load_environment()

def mask_email(email: str) -> str:
    """Masks email address for secure logging (e.g. j***e@example.com)."""
    if not email or "@" not in email:
        return "***"
    local, domain = email.split("@", 1)
    if len(local) <= 2:
        masked_local = local[0] + "*"
    else:
        masked_local = local[0] + "*" * (len(local) - 2) + local[-1]
    return f"{masked_local}@{domain}"

def _get_resend_key():
    load_environment()
    return os.getenv("RESEND_API_KEY")

def _get_resend_from():
    return os.getenv("RESEND_FROM_EMAIL") or os.getenv("MAIL_FROM") or "The Tactile Archive <onboarding@resend.dev>"

def _get_smtp_config():
    load_environment()
    host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    port = int(os.getenv("SMTP_PORT", 465))
    user = os.getenv("SMTP_USER") or os.getenv("GMAIL_USER")
    pwd = os.getenv("SMTP_PASSWORD") or os.getenv("GMAIL_APP_PASSWORD")
    return host, port, user, pwd

# Setup Jinja2 Environment for templates
TEMPLATES_BASE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "templates")
email_env = Environment(loader=FileSystemLoader(os.path.join(TEMPLATES_BASE_DIR, "emails")))
page_env = Environment(loader=FileSystemLoader(os.path.join(TEMPLATES_BASE_DIR, "pages")))

def render_template(template_name: str, **context) -> str:
    if template_name in ["forgot_password.html", "message.html", "reset_password.html"]:
        template = page_env.get_template(template_name)
    else:
        if template_name.startswith("emails/"):
            template_name = template_name[7:]
        template = email_env.get_template(template_name)
    return template.render(**context)

def send_transactional_email_detailed(to_email: str, subject: str, body_html: str, body_text: str = "") -> tuple[bool, str]:
    """
    Sends a transactional email to the user's specific email address.
    Returns (True, '') on success, or (False, error_reason) on failure.
    Never fakes success when all providers fail.
    """
    masked_to = mask_email(to_email)
    resend_key = _get_resend_key()
    smtp_host, smtp_port, smtp_user, smtp_pwd = _get_smtp_config()
    last_error = ""

    # 1. Primary: Resend API
    from_sender = _get_resend_from() if resend_key else ""
    # In Resend sandbox (resend.dev), delivery to non-registered emails is rejected by Resend.
    # If SMTP is configured, directly use SMTP to avoid 4-5 second network timeout.
    skip_resend_sandbox = bool(
        resend_key and "resend.dev" in from_sender.lower() and smtp_user and smtp_pwd
        and to_email.strip().lower() != (smtp_user or "").strip().lower()
    )

    if resend_key and not skip_resend_sandbox:
        try:
            resend.api_key = resend_key
            params = {
                "from": from_sender,
                "to": [to_email],
                "subject": subject,
                "html": body_html,
            }
            if body_text:
                params["text"] = body_text
            res = resend.Emails.send(params)
            msg_id = res.get("id") if isinstance(res, dict) else getattr(res, "id", str(res))
            logger.info(f"[MAIL] Transactional email successfully dispatched to {masked_to} via Resend. From: {from_sender}, Msg ID: {msg_id}")
            return True, ""
        except Exception as e:
            err_str = str(e)
            logger.warning(f"[MAIL] Resend delivery to {masked_to} failed: {err_str}")
            if "testing emails" in err_str.lower() or "domains" in err_str.lower() or "validation" in err_str.lower():
                last_error = "EXTERNAL CONFIGURATION REQUIRED: Mail provider permits delivery only to verified domain/test address. Verify domain at resend.com/domains."
            else:
                last_error = f"EXTERNAL CONFIGURATION REQUIRED: Mail provider error: {err_str}"

    # 2. Fallback: Standard SMTP if configured
    if smtp_user and smtp_pwd:
        try:
            import smtplib
            from email.mime.text import MIMEText
            from email.mime.multipart import MIMEMultipart

            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"The Tactile Archive <{smtp_user}>"
            msg["To"] = to_email

            if body_text:
                msg.attach(MIMEText(body_text, "plain"))
            msg.attach(MIMEText(body_html, "html"))

            if smtp_port == 465:
                with smtplib.SMTP_SSL(smtp_host, smtp_port, timeout=15) as server:
                    server.login(smtp_user, smtp_pwd)
                    server.sendmail(smtp_user, [to_email], msg.as_string())
            else:
                try:
                    with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
                        server.ehlo()
                        server.starttls()
                        server.ehlo()
                        server.login(smtp_user, smtp_pwd)
                        server.sendmail(smtp_user, [to_email], msg.as_string())
                except Exception as starttls_err:
                    if "gmail.com" in smtp_host.lower():
                        logger.warning(f"[MAIL] SMTP port {smtp_port} failed ({starttls_err}). Retrying via Gmail port 465 SSL...")
                        with smtplib.SMTP_SSL(smtp_host, 465, timeout=15) as server:
                            server.login(smtp_user, smtp_pwd)
                            server.sendmail(smtp_user, [to_email], msg.as_string())
                    else:
                        raise starttls_err
            logger.info(f"[MAIL] Transactional email successfully dispatched to {masked_to} via SMTP.")
            return True, ""
        except Exception as e:
            err_str = str(e)
            logger.error(f"[MAIL] SMTP delivery to {masked_to} failed: {err_str}")
            last_error = f"EXTERNAL CONFIGURATION REQUIRED: SMTP authentication failed ({err_str})."

    if not resend_key and not (smtp_user and smtp_pwd):
        last_error = "EXTERNAL CONFIGURATION REQUIRED: No active email provider configured."

    logger.error(f"[MAIL] Failed to deliver email to {masked_to}. {last_error}")
    return False, last_error

def send_transactional_email(to_email: str, subject: str, body_html: str, body_text: str = "") -> bool:
    success, _ = send_transactional_email_detailed(to_email, subject, body_html, body_text)
    return success

# Specific Email Senders
def send_welcome_email(to_email: str, name: str):
    html = render_template("emails/welcome.html", subject="Welcome to The Tactile Archive", name=name)
    send_transactional_email(to_email, "Welcome to The Tactile Archive", html)

def send_verification_email(to_email: str, verify_link: str):
    html = render_template("emails/verify.html", subject="Verify your email address", verify_link=verify_link)
    send_transactional_email(to_email, "Verify your email address", html)

def send_login_alert_email(to_email: str, login_time: str, browser: str, os_info: str, ip_address: str):
    html = render_template("emails/login_alert.html", subject="New Login Detected", 
                           login_time=login_time, browser=browser, os_info=os_info, ip_address=ip_address)
    send_transactional_email(to_email, "New Login Detected", html)

def send_reset_password_email(to_email: str, reset_link: str) -> tuple[bool, str]:
    masked = mask_email(to_email)
    parsed = urlparse(reset_link)
    logger.info(f"[MAIL] Sending password reset email to {masked} for URL host {parsed.scheme}://{parsed.netloc}{parsed.path}")
    html = render_template("emails/reset_request.html", subject="Reset Your Password", reset_link=reset_link)
    return send_transactional_email_detailed(to_email, "Reset Your Password", html)

def send_password_changed_email(to_email: str):
    html = render_template("emails/password_changed.html", subject="Your Password Was Changed")
    send_transactional_email(to_email, "Your Password Was Changed", html)

def send_book_purchase_email(to_email: str, book_title: str, price: float):
    html = render_template("emails/book_purchase.html", subject="Order Placed Successfully", book_title=book_title, price=price)
    send_transactional_email(to_email, f"Order Placed: {book_title}", html)

def send_book_sold_email(to_email: str, book_title: str, price: float, buyer_name: str):
    html = render_template("emails/book_sold.html", subject="Your Book Sold!", book_title=book_title, price=price, buyer_name=buyer_name)
    send_transactional_email(to_email, f"Your book sold: {book_title}", html)

def send_order_confirmation_email(to_email: str, total_items: int, total_price: float):
    html = render_template("emails/order_confirmation.html", subject="Order Confirmation", total_items=total_items, total_price=total_price)
    send_transactional_email(to_email, "Order Confirmation", html)

def send_newsletter_subscription_email(to_email: str):
    html = render_template("emails/newsletter_subscription.html", subject="Welcome to our Newsletter")
    send_transactional_email(to_email, "Welcome to our Newsletter", html)

def send_otp_email(to_email: str, otp_code: str, action_text: str = "Verification"):
    masked = mask_email(to_email)
    logger.info(f"[MAIL] Sending OTP email ({action_text}) to {masked}")
    html = render_template("emails/otp.html", subject=f"Your {action_text} Code", otp_code=otp_code, action_text=action_text)
    send_transactional_email(to_email, f"Your {action_text} Code: {otp_code}", html)
