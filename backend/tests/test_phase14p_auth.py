import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_emails(monkeypatch):
    monkeypatch.setattr("app.api.auth.send_welcome_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_verification_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_login_alert_email", lambda *args: True)

def test_reader_lifecycle():
    email = "reader_phase14p@example.com"
    phone = "9111111111"
    password = "ReaderPassword123!"

    # Cleanup
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    # 1. Register Reader
    reg_res = client.post("/register", json={
        "name": "Reader Test User",
        "email": email,
        "phone": phone,
        "password": password,
        "role": "customer",
        "customer_type": "reader"
    })
    assert reg_res.status_code == 200, reg_res.text
    reg_data = reg_res.json()
    assert reg_data["role"] == "customer"
    assert reg_data["customer_type"] == "reader"
    assert reg_data["user_type"] == "reader"
    assert reg_data["onboarding_completed"] is False

    # 2. Verify in DB
    db = SessionLocal()
    try:
        user_db = db.query(User).filter(User.email == email).first()
        assert user_db is not None
        assert user_db.role == "customer"
        assert user_db.customer_type == "reader"
        assert user_db.user_type == "reader"
        assert user_db.phone == phone
        assert user_db.onboarding_completed is False
    finally:
        db.close()

    # 3. Login with Email
    login_email_res = client.post("/login", json={"email": email, "password": password})
    assert login_email_res.status_code == 200, login_email_res.text
    login_email_data = login_email_res.json()
    assert login_email_data["role"] == "customer"
    assert login_email_data["customer_type"] == "reader"
    assert login_email_data["access_token"] is not None

    # 4. Login with Phone Number
    login_phone_res = client.post("/login", json={"email": phone, "password": password})
    assert login_phone_res.status_code == 200, login_phone_res.text
    login_phone_data = login_phone_res.json()
    assert login_phone_data["role"] == "customer"
    assert login_phone_data["customer_type"] == "reader"
    assert login_phone_data["email"] == email

def test_student_lifecycle():
    email = "student_phase14p@example.com"
    phone = "9222222222"
    password = "StudentPassword123!"

    # Cleanup
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    # 1. Register Student
    reg_res = client.post("/register", json={
        "name": "Student Test User",
        "email": email,
        "phone": phone,
        "password": password,
        "role": "customer",
        "customer_type": "student"
    })
    assert reg_res.status_code == 200, reg_res.text
    reg_data = reg_res.json()
    assert reg_data["role"] == "customer"
    assert reg_data["customer_type"] == "student"
    assert reg_data["user_type"] == "student"
    assert reg_data["onboarding_completed"] is False

    # 2. Verify in DB
    db = SessionLocal()
    try:
        user_db = db.query(User).filter(User.email == email).first()
        assert user_db is not None
        assert user_db.role == "customer"
        assert user_db.customer_type == "student"
        assert user_db.user_type == "student"
        assert user_db.onboarding_completed is False
    finally:
        db.close()

    # 3. Login with Email
    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200, login_res.text
    login_data = login_res.json()
    assert login_data["role"] == "customer"
    assert login_data["customer_type"] == "student"
    assert login_data["onboarding_completed"] is False

    # 4. Login with Phone
    login_phone_res = client.post("/login", json={"email": phone, "password": password})
    assert login_phone_res.status_code == 200, login_phone_res.text
    assert login_phone_res.json()["customer_type"] == "student"

def test_provider_lifecycle():
    email = "provider_phase14p@example.com"
    phone = "9333333333"
    password = "ProviderPassword123!"

    # Cleanup
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    # 1. Register Provider (customer_type is null)
    reg_res = client.post("/register", json={
        "name": "Provider Test User",
        "email": email,
        "phone": phone,
        "password": password,
        "role": "provider"
    })
    assert reg_res.status_code == 200, reg_res.text
    reg_data = reg_res.json()
    assert reg_data["role"] == "provider"
    assert reg_data["customer_type"] is None
    assert reg_data["user_type"] is None

    # 2. Verify in DB
    db = SessionLocal()
    try:
        user_db = db.query(User).filter(User.email == email).first()
        assert user_db is not None
        assert user_db.role == "provider"
        assert user_db.customer_type is None
        assert user_db.user_type is None
    finally:
        db.close()

    # 3. Login with Email
    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200, login_res.text
    login_data = login_res.json()
    assert login_data["role"] == "provider"
    assert login_data["customer_type"] is None

    # 4. Login with Phone
    login_phone_res = client.post("/login", json={"email": phone, "password": password})
    assert login_phone_res.status_code == 200, login_phone_res.text
    assert login_phone_res.json()["role"] == "provider"
    assert login_phone_res.json()["customer_type"] is None
