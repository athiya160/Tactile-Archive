import json
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.api.auth import hash_password

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_emails(monkeypatch):
    monkeypatch.setattr("app.api.auth.send_welcome_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_verification_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_login_alert_email", lambda *args: True)

def test_flow_a_reader():
    """TEST A - READER: Register, Login, Verify Persona, Browse Books, Book Details, Profile, Stats."""
    email = "reader_e2e_test@example.com"
    password = "ReaderPassword123!"

    # Clean up any existing record
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    # 1. Register with persona = reader
    reg_res = client.post("/register", json={
        "name": "Alice Reader",
        "email": email,
        "password": password,
        "persona": "reader"
    })
    assert reg_res.status_code == 200, reg_res.text
    reg_data = reg_res.json()
    assert reg_data["persona"] == "reader"
    assert reg_data["user_type"] == "reader"

    # 2. Login
    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200, login_res.text
    login_data = login_res.json()
    assert login_data["persona"] == "reader"
    token = login_data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 3. Verify profile (/profile & /users/me/profile)
    prof_res = client.get("/profile", headers=headers)
    assert prof_res.status_code == 200
    assert prof_res.json()["persona"] == "reader"

    comp_res = client.get("/users/me/profile", headers=headers)
    assert comp_res.status_code == 200
    comp_data = comp_res.json()
    assert comp_data["persona"] == "reader"
    assert comp_data["role"] == "customer"
    assert "passport" in comp_data
    assert "stats" in comp_data

    # 4. Browse books
    books_res = client.get("/books?limit=5")
    assert books_res.status_code == 200
    raw_books = books_res.json()
    books = raw_books.get("data", raw_books) if isinstance(raw_books, dict) else raw_books
    assert isinstance(books, list)

    # 5. Open single book if available
    if len(books) > 0:
        book_id = books[0]["id"]
        single_res = client.get(f"/books/{book_id}")
        assert single_res.status_code == 200
        assert single_res.json()["id"] == book_id

def test_flow_b_student():
    """TEST B - STUDENT: Register, Login, Verify Persona, Onboarding Profile, Semester Info, Dashboard Readback."""
    email = "student_e2e_test@example.com"
    password = "StudentPassword123!"

    # Clean up any existing record
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    # 1. Register with persona = student
    reg_res = client.post("/register", json={
        "name": "Bob Student",
        "email": email,
        "password": password,
        "persona": "student"
    })
    assert reg_res.status_code == 200, reg_res.text
    assert reg_res.json()["persona"] == "student"

    # 2. Login
    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200, login_res.text
    token = login_res.json()["access_token"]
    assert login_res.json()["persona"] == "student"
    headers = {"Authorization": f"Bearer {token}"}

    # 3. Student Onboarding: enter degree/course, semester, academic year, subjects
    onboarding_payload = {
        "course": "Bachelor of Computer Applications (BCA)",
        "education_level": "Semester 6",
        "exam_goal": "Academic Year 2026-27",
        "subjects": ["Distributed Systems", "Cloud Architectures", "Compiler Design"],
        "academic_interests": ["Computer Science", "Artificial Intelligence"]
    }
    onboard_res = client.put("/users/me/student-profile", json=onboarding_payload, headers=headers)
    assert onboard_res.status_code == 200, onboard_res.text
    assert onboard_res.json()["onboarding_completed"] is True

    # 4. Open Student Dashboard & verify academic profile readback
    dashboard_profile_res = client.get("/users/me/profile", headers=headers)
    assert dashboard_profile_res.status_code == 200
    dash_data = dashboard_profile_res.json()
    assert dash_data["persona"] == "student"
    assert dash_data["onboarding_completed"] is True
    student_profile = dash_data["student_profile"]
    assert student_profile is not None
    assert student_profile["course"] == "Bachelor of Computer Applications (BCA)"
    assert student_profile["education_level"] == "Semester 6"
    assert student_profile["exam_goal"] == "Academic Year 2026-27"
    assert "Distributed Systems" in student_profile["subjects"]

def test_flow_c_existing_user():
    """TEST C - EXISTING USER: Existing reader login, provider role preservation, marketplace access, re-login."""
    email = "existing_provider_e2e@example.com"
    password = "ProviderPassword123!"

    # Pre-populate existing user in DB with role=provider
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                email=email,
                password=hash_password(password),
                name="Existing Provider Pro",
                role="provider",
                user_type="reader",
                is_verified=True,
                onboarding_completed=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
    finally:
        db.close()

    # 1. Login as existing user
    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200
    data = login_res.json()
    assert data["role"] == "provider"
    assert data["persona"] == "reader"
    token = data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 2. Existing profile check
    prof_res = client.get("/profile", headers=headers)
    assert prof_res.status_code == 200
    assert prof_res.json()["role"] == "provider"

    # 3. Existing marketplace check
    market_res = client.get("/books?limit=3")
    assert market_res.status_code == 200

    # 4. Re-login
    relogin_res = client.post("/login", json={"email": email, "password": password})
    assert relogin_res.status_code == 200
    assert relogin_res.json()["role"] == "provider"
    assert relogin_res.json()["persona"] == "reader"

def test_flow_d_security_and_unauthorized():
    """TEST D - ROUTING & SECURITY: Protected endpoints reject unauthenticated or forged tokens."""
    # Protected endpoints without token (HTTPBearer returns 403 without authorization header)
    assert client.get("/profile").status_code in [401, 403]
    assert client.get("/users/me/profile").status_code in [401, 403]
    assert client.put("/users/me/student-profile", json={}).status_code in [401, 403]

    # Protected endpoints with bogus token (returns 401 on decode error)
    bad_headers = {"Authorization": "Bearer invalid_forged_token_xyz"}
    assert client.get("/profile", headers=bad_headers).status_code in [401, 403]
    assert client.get("/users/me/profile", headers=bad_headers).status_code in [401, 403]

    # Public endpoints must succeed without token
    assert client.get("/books?limit=1").status_code == 200
