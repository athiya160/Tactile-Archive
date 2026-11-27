import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.api.auth import hash_password

client = TestClient(app)

def test_user_model_persona_synonym():
    """Verify SQLAlchemy model persona synonym and default behavior."""
    db = SessionLocal()
    try:
        # Create user without explicit persona
        user = User(
            email="test_model_default@example.com",
            password=hash_password("Password123!"),
            name="Model Default"
        )
        assert user.persona == "reader"
        assert user.user_type == "reader"

        # Change persona via synonym setter
        user.persona = "student"
        assert user.persona == "student"
        assert user.user_type == "student"
    finally:
        db.close()

def test_register_default_reader(monkeypatch):
    """Verify new user defaults to 'reader' when no persona is passed."""
    monkeypatch.setattr("app.api.auth.send_welcome_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_verification_email", lambda *args: True)

    email = "new_reader_default@example.com"
    # Ensure clean state
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    res = client.post("/register", json={
        "email": email,
        "password": "Password123!",
        "name": "Default Reader User"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["persona"] == "reader"
    assert data["user_type"] == "reader"

    # Verify in DB
    db = SessionLocal()
    try:
        user_in_db = db.query(User).filter(User.email == email).first()
        assert user_in_db is not None
        assert user_in_db.persona == "reader"
        assert user_in_db.user_type == "reader"
    finally:
        db.close()

def test_register_student_user(monkeypatch):
    """Verify a new student user can be created via registration."""
    monkeypatch.setattr("app.api.auth.send_welcome_email", lambda *args: True)
    monkeypatch.setattr("app.api.auth.send_verification_email", lambda *args: True)

    email = "new_student_user@example.com"
    # Ensure clean state
    db = SessionLocal()
    try:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.delete(u)
            db.commit()
    finally:
        db.close()

    res = client.post("/register", json={
        "email": email,
        "password": "Password123!",
        "name": "Student Persona User",
        "persona": "student"
    })
    assert res.status_code == 200
    data = res.json()
    assert data["persona"] == "student"
    assert data["user_type"] == "student"

    # Verify in DB
    db = SessionLocal()
    try:
        user_in_db = db.query(User).filter(User.email == email).first()
        assert user_in_db is not None
        assert user_in_db.persona == "student"
        assert user_in_db.user_type == "student"
    finally:
        db.close()

def test_existing_login_and_reader_preservation(monkeypatch):
    """Verify existing reader users remain reader and login returns persona."""
    monkeypatch.setattr("app.api.auth.send_login_alert_email", lambda *args: True)

    email = "existing_reader_verify@example.com"
    password = "ExistingPassword123!"

    # Create an existing reader record directly in DB as would exist prior to migration
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                email=email,
                password=hash_password(password),
                name="Existing Reader",
                role="customer",
                user_type="reader",
                is_verified=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
    finally:
        db.close()

    # Login
    res = client.post("/login", json={"email": email, "password": password})
    assert res.status_code == 200
    data = res.json()
    assert data["persona"] == "reader"
    assert data["user_type"] == "reader"
    token = data["access_token"]

    # Profile (/profile)
    prof_res = client.get("/profile", headers={"Authorization": f"Bearer {token}"})
    assert prof_res.status_code == 200
    prof_data = prof_res.json()
    assert prof_data["persona"] == "reader"
    assert prof_data["user_type"] == "reader"

    # Composite profile (/users/me/profile)
    comp_res = client.get("/users/me/profile", headers={"Authorization": f"Bearer {token}"})
    assert comp_res.status_code == 200
    comp_data = comp_res.json()
    assert comp_data["persona"] == "reader"
    assert comp_data["user_type"] == "reader"

def test_update_persona_endpoint():
    """Verify updating persona from reader to student via /users/me/persona."""
    email = "persona_switcher@example.com"
    password = "SwitchPassword123!"

    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                email=email,
                password=hash_password(password),
                name="Persona Switcher",
                role="customer",
                user_type="reader",
                is_verified=True
            )
            db.add(user)
            db.commit()
    finally:
        db.close()

    login_res = client.post("/login", json={"email": email, "password": password})
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]

    # Update persona to student
    switch_res = client.put(
        "/users/me/persona",
        json={"persona": "student"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert switch_res.status_code == 200
    data = switch_res.json()
    assert data["persona"] == "student"
    assert data["user_type"] == "student"

    # Verify login now returns student
    login_res2 = client.post("/login", json={"email": email, "password": password})
    assert login_res2.status_code == 200
    assert login_res2.json()["persona"] == "student"
