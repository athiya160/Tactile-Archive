import pytest
from fastapi.testclient import TestClient
import datetime
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.otp_code import OTPCode
from app.models.password_reset import PasswordReset
from app.api.auth import hash_password, verify_password

@pytest.fixture
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

def test_mobile_forgot_password_with_phone_number(monkeypatch, db):
    client = TestClient(app)
    test_phone = "+919876543210"
    test_email = "mobile_user_phone@example.com"
    initial_password = "OldMobilePassword123!"

    # Ensure user exists with phone number
    user = db.query(User).filter(User.email == test_email).first()
    if not user:
        user = User(
            email=test_email,
            phone=test_phone,
            name="Mobile Tester",
            password=hash_password(initial_password),
            role="customer",
            user_type="reader",
            is_verified=True
        )
        db.add(user)
    else:
        user.phone = test_phone
        user.password = hash_password(initial_password)
    db.commit()

    dispatched = {}
    def mock_send(to_email, reset_link):
        dispatched[to_email] = reset_link
        return True, ""

    monkeypatch.setattr("app.api.auth.send_reset_password_email", mock_send)

    # 1. Mobile user requests forgot password using their phone number
    res = client.post("/auth/forgot-password", json={"email": test_phone})
    assert res.status_code == 200
    assert test_email in dispatched
    assert "token=" in dispatched[test_email]

def test_mobile_instant_otp_flow_with_phone_number(monkeypatch, db):
    client = TestClient(app)
    test_phone = "+919876543299"
    test_email = "otp_mobile_user@example.com"
    old_password = "OldPassword999!"
    new_password = "NewStrongPassword456@"

    user = db.query(User).filter(User.email == test_email).first()
    if not user:
        user = User(
            email=test_email,
            phone=test_phone,
            name="OTP Phone Tester",
            password=hash_password(old_password),
            role="customer",
            user_type="reader",
            is_verified=True
        )
        db.add(user)
    else:
        user.phone = test_phone
        user.password = hash_password(old_password)
    db.commit()

    # 1. Send OTP to phone number
    send_res = client.post("/auth/send-otp", json={
        "identifier": test_phone,
        "purpose": "password_reset"
    })
    assert send_res.status_code == 200

    # Retrieve generated OTP from DB
    otp_record = db.query(OTPCode).filter(
        OTPCode.identifier == test_phone.strip().lower(),
        OTPCode.purpose == "password_reset",
        OTPCode.used == False
    ).order_by(OTPCode.id.desc()).first()

    assert otp_record is not None
    otp_code = otp_record.code
    assert len(otp_code) == 6

    # 2. Reject reset if new password is too weak
    weak_res = client.post("/auth/verify-otp-reset", json={
        "identifier": test_phone,
        "otp_code": otp_code,
        "new_password": "weak"
    })
    assert weak_res.status_code == 400

    # 3. Reject reset if using the old password
    same_pwd_res = client.post("/auth/verify-otp-reset", json={
        "identifier": test_phone,
        "otp_code": otp_code,
        "new_password": old_password
    })
    assert same_pwd_res.status_code == 400
    assert "old password" in same_pwd_res.json()["detail"].lower()

    # 4. Successfully reset using phone number identifier & valid OTP
    success_res = client.post("/auth/verify-otp-reset", json={
        "identifier": test_phone,
        "otp_code": otp_code,
        "new_password": new_password
    })
    assert success_res.status_code == 200

    # 5. Verify database password was actually updated and OTP marked as used
    db.refresh(user)
    assert verify_password(new_password, user.password)
    db.refresh(otp_record)
    assert otp_record.used is True

    # 6. Verify user can now log in with the new password
    login_res = client.post("/login", json={
        "email": test_phone,
        "password": new_password
    })
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()
