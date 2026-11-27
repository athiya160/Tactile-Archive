import pytest
from fastapi.testclient import TestClient
import datetime
import hashlib
from urllib.parse import urlparse, parse_qs
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.password_reset import PasswordReset
from app.models.otp_code import OTPCode
from app.api.auth import hash_password, verify_password

@pytest.fixture
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

def test_reset_password_rejects_old_password_json(monkeypatch, db):
    client = TestClient(app)
    email = "old_pwd_tester@example.com"
    old_password = "CurrentPassword123!"

    u = db.query(User).filter(User.email == email).first()
    if not u:
        u = User(
            email=email,
            name="Old Pwd Tester",
            password=hash_password(old_password),
            role="customer",
            user_type="reader",
            is_verified=True
        )
        db.add(u)
    else:
        u.password = hash_password(old_password)
    db.commit()

    dispatched = {}
    def mock_send(to_email, reset_link):
        dispatched[to_email] = reset_link
        return True, ""

    monkeypatch.setattr("app.api.auth.send_reset_password_email", mock_send)

    # Request reset link
    res = client.post("/auth/forgot-password", json={"email": email})
    assert res.status_code == 200

    link = dispatched[email]
    token = parse_qs(urlparse(link).query).get("token", [""])[0]
    assert token != ""

    # Attempt to reset using the EXACT same old password
    reject_res = client.post("/auth/reset-password", json={
        "token": token,
        "new_password": old_password
    })
    assert reject_res.status_code == 400
    assert "New password cannot be the same as your old password." in reject_res.json()["detail"]

    # Password in DB should still be old password
    db.refresh(u)
    assert verify_password(old_password, u.password) is True

    # Now reset with a NEW valid password
    new_password = "BrandNewPassword123!"
    success_res = client.post("/auth/reset-password", json={
        "token": token,
        "new_password": new_password
    })
    assert success_res.status_code == 200
    assert "updated successfully" in success_res.json()["message"]

    # Verify password has now changed
    db.refresh(u)
    assert verify_password(new_password, u.password) is True

def test_reset_password_rejects_old_password_form(monkeypatch, db):
    client = TestClient(app)
    email = "form_old_pwd_tester@example.com"
    old_password = "FormCurrentPassword123!"

    u = db.query(User).filter(User.email == email).first()
    if not u:
        u = User(
            email=email,
            name="Form Old Pwd Tester",
            password=hash_password(old_password),
            role="customer",
            user_type="reader",
            is_verified=True
        )
        db.add(u)
    else:
        u.password = hash_password(old_password)
    db.commit()

    dispatched = {}
    def mock_send(to_email, reset_link):
        dispatched[to_email] = reset_link
        return True, ""

    monkeypatch.setattr("app.api.auth.send_reset_password_email", mock_send)

    client.post("/auth/forgot-password", json={"email": email})
    link = dispatched[email]
    token = parse_qs(urlparse(link).query).get("token", [""])[0]

    # Post via form urlencoded with the old password
    form_res = client.post("/reset-password", data={
        "token": token,
        "new_password": old_password
    })
    assert form_res.status_code == 400
    assert "New password cannot be the same as your old password." in form_res.text

def test_otp_reset_rejects_old_password(db):
    client = TestClient(app)
    email = "otp_old_pwd@example.com"
    old_password = "OtpPassword123!"

    u = db.query(User).filter(User.email == email).first()
    if not u:
        u = User(
            email=email,
            name="OTP Tester",
            password=hash_password(old_password),
            role="customer",
            is_verified=True
        )
        db.add(u)
    else:
        u.password = hash_password(old_password)
    db.commit()

    # Create active OTP
    otp = OTPCode(
        identifier=email,
        code="654321",
        purpose="password_reset",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10)
    )
    db.add(otp)
    db.commit()

    # Try resetting via OTP with old password
    res = client.post("/auth/verify-otp-reset", json={
        "identifier": email,
        "otp_code": "654321",
        "new_password": old_password
    })
    assert res.status_code == 400
    assert "New password cannot be the same as your old password." in res.json()["detail"]
