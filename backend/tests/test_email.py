import os
import pytest
from app.core.mail import send_transactional_email, mask_email, send_reset_password_email

def test_mask_email():
    assert mask_email("athiya260@gmail.com") == "a*******0@gmail.com"
    assert mask_email("a@b.com") == "a*@b.com"
    assert mask_email("") == "***"

def test_send_reset_password_email_dispatch(monkeypatch):
    # Verify that email sending invokes transactional email with correct recipient
    dispatched = {}
    def mock_send(to_email, subject, body_html, body_text=""):
        dispatched["to"] = to_email
        dispatched["subject"] = subject
        dispatched["html"] = body_html
        return True, ""

    monkeypatch.setattr("app.core.mail.send_transactional_email_detailed", mock_send)
    send_reset_password_email("user@example.com", "https://tactilearchive.com/reset-password?token=test_tok")
    
    assert dispatched["to"] == "user@example.com"
    assert "Reset Your Password" in dispatched["subject"]
    assert "test_tok" in dispatched["html"]

def test_password_reset_flow_e2e(monkeypatch):
    from fastapi.testclient import TestClient
    import datetime
    import hashlib
    from urllib.parse import urlparse, parse_qs
    from app.main import app
    from app.core.database import SessionLocal
    from app.models.user import User
    from app.models.password_reset import PasswordReset
    from app.api.auth import hash_password

    # Intercept dispatched email to extract the raw token sent to the user
    dispatched_links = []
    def mock_send_reset(to_email, reset_link):
        dispatched_links.append(reset_link)
        return True, ""

    monkeypatch.setattr("app.api.auth.send_reset_password_email", mock_send_reset)

    client = TestClient(app)
    db = SessionLocal()
    try:
        test_email = "audit_user_reset@example.com"
        user = db.query(User).filter(User.email == test_email).first()
        if not user:
            user = User(
                email=test_email,
                password=hash_password("OldPassword123!"),
                name="Audit Reset User",
                role="customer",
                is_verified=True
            )
            db.add(user)
        else:
            user.password = hash_password("OldPassword123!")
        db.commit()
        db.refresh(user)

        # 1. Request forgot password with mixed case
        res = client.post("/auth/forgot-password", json={"email": "AUDIT_USER_RESET@EXAMPLE.COM"})
        assert res.status_code == 200
        assert "password reset link has been sent" in res.json()["message"]
        assert len(dispatched_links) > 0

        # Extract raw token from dispatched link
        raw_reset_url = dispatched_links[-1]
        parsed = urlparse(raw_reset_url)
        raw_token = parse_qs(parsed.query).get("token", [""])[0]
        assert raw_token != ""

        # 2. Check DB token entry - MUST be SHA-256 hash (64 hex characters)
        expected_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
        reset_entry = db.query(PasswordReset).filter(
            PasswordReset.user_id == user.id,
            PasswordReset.used == False
        ).order_by(PasswordReset.id.desc()).first()

        assert reset_entry is not None
        assert reset_entry.token == expected_hash
        assert reset_entry.token != raw_token # Confirms DB does NOT store raw token!
        assert len(reset_entry.token) == 64

        # 3. Perform reset using the raw token from the user's email
        reset_res = client.post("/auth/reset-password", json={
            "token": raw_token,
            "new_password": "NewSecretPassword123!"
        })
        assert reset_res.status_code == 200
        assert "updated successfully" in reset_res.json()["message"]

        # 4. Verify token marked used in DB
        db.refresh(reset_entry)
        assert reset_entry.used is True

        # 5. Attempt reuse fails
        reused_res = client.post("/auth/reset-password", json={
            "token": raw_token,
            "new_password": "AnotherPassword123!"
        })
        assert reused_res.status_code == 400
        assert "already been used" in reused_res.json()["detail"]
    finally:
        db.close()


