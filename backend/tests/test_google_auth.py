import os
import pytest
from unittest.mock import patch
from app.models.user import User
from app.core.database import SessionLocal
from app.api.auth import hash_password

TEST_CLIENT_ID = "tactile-archive-test-client-id.apps.googleusercontent.com"

@pytest.fixture(autouse=True)
def setup_test_google_env(monkeypatch):
    monkeypatch.setenv("GOOGLE_CLIENT_ID", TEST_CLIENT_ID)


def test_missing_token_rejected(test_client):
    """Requests without a Google ID token ('credential') must be rejected with 400 Bad Request."""
    res1 = test_client.post("/auth/google", json={})
    assert res1.status_code == 400
    assert "Google ID token ('credential') is required" in res1.json()["detail"]

    # Even if an email is provided in the body, it must be rejected without token
    res2 = test_client.post("/auth/google", json={"email": "victim@gmail.com"})
    assert res2.status_code == 400
    assert "Google ID token ('credential') is required" in res2.json()["detail"]


def test_missing_google_client_id_configuration(test_client, monkeypatch):
    """If GOOGLE_CLIENT_ID is not configured, the endpoint must fail-closed with 500."""
    monkeypatch.delenv("GOOGLE_CLIENT_ID", raising=False)
    monkeypatch.delenv("GOOGLE_CLIENT_IDS", raising=False)
    res = test_client.post("/auth/google", json={"credential": "mock_id_token"})
    assert res.status_code == 500
    assert "Google OAuth server configuration is missing" in res.json()["detail"]


def test_forged_or_invalid_token_rejected(test_client):
    """Forged or signature-invalid tokens must be rejected with 401 Unauthorized."""
    with patch("google.oauth2.id_token.verify_oauth2_token", side_effect=ValueError("Invalid cryptographic signature")):
        res = test_client.post("/auth/google", json={"credential": "forged_google_token"})
        assert res.status_code == 401
        assert "Google ID token verification failed" in res.json()["detail"]


def test_expired_token_rejected(test_client):
    """Expired Google ID tokens must be rejected with 401 Unauthorized."""
    with patch("google.oauth2.id_token.verify_oauth2_token", side_effect=ValueError("Token used after expiry")):
        res = test_client.post("/auth/google", json={"credential": "expired_google_token"})
        assert res.status_code == 401
        assert "Google ID token verification failed" in res.json()["detail"]


def test_wrong_audience_rejected(test_client):
    """Tokens issued for a different client ID/application must be rejected with 401."""
    with patch("google.oauth2.id_token.verify_oauth2_token", side_effect=ValueError("Token used with wrong audience")):
        res = test_client.post("/auth/google", json={"credential": "wrong_audience_token"})
        assert res.status_code == 401
        assert "Google ID token verification failed" in res.json()["detail"]


def test_unverified_email_rejected(test_client):
    """Tokens where email_verified is not True must be rejected with 401."""
    mock_payload = {
        "email": "unverified_user@gmail.com",
        "sub": "google_sub_unverified_1",
        "email_verified": False,
        "name": "Unverified User",
        "aud": TEST_CLIENT_ID
    }
    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res = test_client.post("/auth/google", json={"credential": "token_with_unverified_email"})
        assert res.status_code == 401
        assert "Google account email is not verified" in res.json()["detail"]


def test_new_google_user_created_exactly_once(test_client):
    """First-time sign in creates exactly one account with safe defaults; repeated login reuses it."""
    email = "unique_new_google_user_2026@gmail.com"
    sub = "google_sub_unique_new_9999"
    mock_payload = {
        "email": email,
        "sub": sub,
        "email_verified": True,
        "name": "New Google User",
        "picture": "https://lh3.googleusercontent.com/test_avatar.jpg",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        # 1. First sign-in creates the account
        res1 = test_client.post("/auth/google", json={"credential": "valid_token_1", "persona_hint": "student"})
        assert res1.status_code == 200
        data1 = res1.json()
        assert data1["email"] == email
        assert data1["role"] == "customer"
        assert data1["user_type"] == "student"
        assert data1["is_admin"] is False
        assert data1["provider_enabled"] is False
        assert data1["provider_status"] == "not_enrolled"
        assert data1["onboarding_completed"] is True
        assert "access_token" in data1
        assert "refresh_token" in data1
        user_id = data1["id"]

        # 2. Second sign-in with same token reuses the existing user record
        res2 = test_client.post("/auth/google", json={"credential": "valid_token_1"})
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["id"] == user_id
        assert data2["email"] == email


def test_existing_password_account_linked_without_losing_password(test_client):
    """An existing password-based account is linked to Google sub without modifying password or user ID."""
    db = SessionLocal()
    email = "existing_pwd_user_2026@gmail.com"
    original_pwd = "MySecretPassword123!"
    hashed = hash_password(original_pwd)

    # Clean up if existed
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        db.delete(existing)
        db.commit()

    user = User(
        email=email,
        password=hashed,
        name="Existing Pwd User",
        role="customer",
        user_type="reader",
        is_verified=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    original_user_id = user.id
    original_hash = user.password
    db.close()

    # Now user logs in with Google under that same email
    sub = "google_sub_linked_5555"
    mock_payload = {
        "email": email,
        "sub": sub,
        "email_verified": True,
        "name": "Existing Pwd User",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res = test_client.post("/auth/google", json={"credential": "valid_link_token"})
        assert res.status_code == 200
        data = res.json()
        assert data["id"] == original_user_id
        assert data["email"] == email

    # Verify password hash and google_id in database
    db = SessionLocal()
    updated = db.query(User).filter(User.id == original_user_id).first()
    assert updated.google_id == sub
    assert updated.password == original_hash  # Password hash MUST remain identical!
    db.close()

    # Verify that the user can STILL log in with their original password
    login_res = test_client.post("/login", json={"email": email, "password": original_pwd})
    assert login_res.status_code == 200
    assert login_res.json()["email"] == email


def test_google_subject_lookup_finds_existing_account(test_client):
    """When google_id is already linked, the account is resolved by google_id directly."""
    email = "google_id_lookup_user@gmail.com"
    sub = "google_sub_lookup_7777"
    mock_payload = {
        "email": email,
        "sub": sub,
        "email_verified": True,
        "name": "Subject Lookup User",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        # First login links/creates
        res1 = test_client.post("/auth/google", json={"credential": "token_1"})
        assert res1.status_code == 200
        uid = res1.json()["id"]

        # Subsequent login resolves via google_id
        res2 = test_client.post("/auth/google", json={"credential": "token_2"})
        assert res2.status_code == 200
        assert res2.json()["id"] == uid


def test_admin_role_remains_admin(test_client):
    """An Admin account signing in with Google must NEVER be demoted to customer."""
    db = SessionLocal()
    email = "admin_protected_2026@gmail.com"
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        db.delete(existing)
        db.commit()

    admin = User(
        email=email,
        password=hash_password("AdminPass123!"),
        name="Super Admin",
        role="admin",
        is_admin=True,
        is_verified=True
    )
    db.add(admin)
    db.commit()
    db.refresh(admin)
    admin_id = admin.id
    db.close()

    # Admin clicks Google login which sends persona_hint="reader"
    mock_payload = {
        "email": email,
        "sub": "google_sub_admin_8888",
        "email_verified": True,
        "name": "Super Admin",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res = test_client.post("/auth/google", json={
            "credential": "admin_google_token",
            "persona_hint": "reader"
        })
        assert res.status_code == 200
        data = res.json()
        assert data["id"] == admin_id
        assert data["role"] == "admin"
        assert data["is_admin"] is True

    # Confirm in DB
    db = SessionLocal()
    check_admin = db.query(User).filter(User.id == admin_id).first()
    assert check_admin.role == "admin"
    assert check_admin.is_admin is True
    db.close()


def test_approved_provider_remains_unchanged(test_client):
    """An approved Provider account signing in with Google must NOT have their status or role downgraded."""
    db = SessionLocal()
    email = "provider_protected_2026@gmail.com"
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        db.delete(existing)
        db.commit()

    prov = User(
        email=email,
        password=hash_password("ProviderPass123!"),
        name="Book Emporium",
        role="provider",
        provider_enabled=True,
        provider_status="active",
        is_verified=True
    )
    db.add(prov)
    db.commit()
    db.refresh(prov)
    prov_id = prov.id
    db.close()

    # Provider logs in via default login button (persona_hint="reader")
    mock_payload = {
        "email": email,
        "sub": "google_sub_provider_3333",
        "email_verified": True,
        "name": "Book Emporium",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res = test_client.post("/auth/google", json={
            "credential": "provider_google_token",
            "persona_hint": "reader"
        })
        assert res.status_code == 200
        data = res.json()
        assert data["id"] == prov_id
        assert data["role"] == "provider"
        assert data["provider_enabled"] is True
        assert data["provider_status"] == "active"

    # Confirm in DB
    db = SessionLocal()
    check_prov = db.query(User).filter(User.id == prov_id).first()
    assert check_prov.role == "provider"
    assert check_prov.provider_enabled is True
    assert check_prov.provider_status == "active"
    db.close()


def test_client_persona_hint_cannot_escalate_permissions(test_client):
    """A Google sign-in request cannot grant Provider or Admin privileges through persona_hint."""
    email = "escalation_attempt_user@gmail.com"
    sub = "google_sub_escalation_1111"
    mock_payload = {
        "email": email,
        "sub": sub,
        "email_verified": True,
        "name": "Hacker User",
        "aud": TEST_CLIENT_ID
    }

    # Attempt to claim "provider"
    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res1 = test_client.post("/auth/google", json={
            "credential": "token_esc_1",
            "persona_hint": "provider"
        })
        assert res1.status_code == 200
        data1 = res1.json()
        assert data1["role"] == "customer"  # Escalation to provider BLOCKED!
        assert data1["is_admin"] is False
        assert data1["provider_enabled"] is False

    # Attempt to claim "admin"
    mock_payload2 = {
        "email": "escalation_attempt_2@gmail.com",
        "sub": "google_sub_escalation_2222",
        "email_verified": True,
        "name": "Admin Wannabe",
        "aud": TEST_CLIENT_ID
    }
    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload2):
        res2 = test_client.post("/auth/google", json={
            "credential": "token_esc_2",
            "persona_hint": "admin"
        })
        assert res2.status_code == 200
        data2 = res2.json()
        assert data2["role"] == "customer"  # Escalation to admin BLOCKED!
        assert data2["is_admin"] is False


def test_account_already_linked_conflict_rejected(test_client):
    """If an existing account is already linked to Google ID A, an attempt to link Google ID B is rejected with 409."""
    db = SessionLocal()
    email = "conflict_user_2026@gmail.com"
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        db.delete(existing)
        db.commit()

    user = User(
        email=email,
        password=hash_password("Password123!"),
        name="Conflict User",
        google_id="legitimate_google_sub_AAA",
        role="customer",
        user_type="reader",
        is_verified=True
    )
    db.add(user)
    db.commit()
    db.close()

    # Attacker tries to link with a different Google sub BBB for that email
    mock_payload = {
        "email": email,
        "sub": "attacker_google_sub_BBB",
        "email_verified": True,
        "name": "Conflict User",
        "aud": TEST_CLIENT_ID
    }

    with patch("google.oauth2.id_token.verify_oauth2_token", return_value=mock_payload):
        res = test_client.post("/auth/google", json={"credential": "attacker_token"})
        assert res.status_code == 409
        assert "already linked to a different Google account" in res.json()["detail"]
