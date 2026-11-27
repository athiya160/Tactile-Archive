"""
Phase 20.39 - JWT Secret and Authentication Configuration Hardening Test Suite
Project: The Tactile Archive / LibriFlow

Verifies:
1. Production environment strictly refuses to start when JWT_SECRET_KEY is:
   - Missing or empty
   - A known placeholder or insecure default string
   - Shorter than 32 characters (256 bits for HS256)
2. Production environment accepts valid high-entropy cryptographically secure secrets (>= 32 chars).
3. Development mode allows fallback with security warning, while test mode isolates test secrets.
4. Token creation, claims packaging (type='access', jti, exp), and roundtrip verification.
5. Invalidation on signature mismatch (tampered secret key).
6. Invalidation on expired token.
7. Algorithm confusion protection: rejects 'none' algorithm.
8. Type separation enforcement: refresh token cannot be used as an access token in get_current_user.
9. Access token cannot be used at /auth/refresh endpoint.
10. Token revocation enforcement in get_current_user and refresh_access_token.
11. Live database safety sentinel: tactile_archive.db remains byte-for-byte immutable.
"""

import os
import sys
import uuid
import hashlib
import pytest
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.core.database import Base
from app.models.user import User
from app.api.auth import (
    get_current_user,
    refresh_access_token,
    REVOKED_TOKENS,
    RefreshTokenRequest,
    hash_password,
)
from app.core.security import (
    validate_jwt_secret,
    get_jwt_secret,
    create_access_token,
    create_refresh_token,
    create_verification_token,
    verify_verification_token,
    ALGORITHM,
    MIN_JWT_SECRET_LENGTH,
    INSECURE_JWT_SECRET_PATTERNS,
    DEV_FALLBACK_SECRET,
    TEST_DEFAULT_SECRET,
)

DISPOSABLE_TEST_DB = "scratch/disposable_test_jwt_hardening.db"
LIVE_DB_PATH = "backend/tactile_archive.db"


def get_file_hash(path):
    if not os.path.exists(path):
        return None
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest().upper()


engine = create_engine(f"sqlite:///{DISPOSABLE_TEST_DB}", connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="module", autouse=True)
def live_database_safety_guard():
    """Confirms live database hash is identical before and after entire test execution."""
    initial_hash = get_file_hash(LIVE_DB_PATH)
    assert initial_hash is not None, "Live database file missing!"
    yield
    final_hash = get_file_hash(LIVE_DB_PATH)
    assert initial_hash == final_hash, (
        f"CRITICAL SAFETY VIOLATION: Live database modified during test run! {initial_hash} != {final_hash}"
    )


@pytest.fixture(scope="module")
def setup_test_db():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(DISPOSABLE_TEST_DB):
        try:
            os.remove(DISPOSABLE_TEST_DB)
        except Exception:
            pass
    Base.metadata.create_all(bind=engine)
    yield
    if os.path.exists(DISPOSABLE_TEST_DB):
        try:
            os.remove(DISPOSABLE_TEST_DB)
        except Exception:
            pass


@pytest.fixture(scope="function")
def db_session(setup_test_db):
    session = TestingSessionLocal()
    # Seed sample user for auth lookups
    user = session.query(User).filter_by(email="auth_user@example.com").first()
    if not user:
        user = User(
            name="Auth Test User",
            email="auth_user@example.com",
            password=hash_password("ValidPassword123!"),
            role="reader",
            phone="555-0199"
        )
        session.add(user)
        session.commit()
    try:
        yield session
    finally:
        session.close()


# =============================================================================
# 1. Production Startup Refusal & Validation Tests
# =============================================================================

def test_production_rejects_missing_or_empty_secret():
    """Production must refuse to start when JWT_SECRET_KEY is missing or empty."""
    for empty_val in [None, "", "   "]:
        with pytest.raises(RuntimeError) as exc_info:
            validate_jwt_secret(empty_val, env="production")
        assert "JWT_SECRET_KEY is not configured for production" in str(exc_info.value)
        # Ensure secret value is never printed
        assert "None" not in str(exc_info.value) or "characters" in str(exc_info.value)


def test_production_rejects_known_placeholders():
    """Production must refuse to start when JWT_SECRET_KEY is a known placeholder."""
    placeholders = [
        "your_secret_key_development_fallback_1234567",
        "prod_jwt_secret_signing_key_to_be_generated_securely",
        "yoursecretjwtkeyhere_yoursecretjwtkeyhere",
        "changeme_changeme_changeme_changeme_12345",
        "supersecret_supersecret_supersecret_12345",
        "my_insecure_development_fallback_key_12345",
        "this_is_a_placeholder_key_that_is_long_enough",
        "example_secret_key_for_testing_only_32_chars"
    ]
    for placeholder in placeholders:
        with pytest.raises(RuntimeError) as exc_info:
            validate_jwt_secret(placeholder, env="production")
        assert "known placeholder, weak pattern, or default fallback" in str(exc_info.value)
        # Verify secret itself is never leaked in the exception message
        assert placeholder not in str(exc_info.value)


def test_production_rejects_short_secret():
    """Production must refuse secrets below 32 characters (256 bits)."""
    short_secrets = [
        "tiny_secret_123",
        "12345678901234567890",  # 20 chars
        "only_thirty_one_characters_len"  # 30 chars
    ]
    for short_sec in short_secrets:
        with pytest.raises(RuntimeError) as exc_info:
            validate_jwt_secret(short_sec, env="production")
        assert "too short" in str(exc_info.value)
        assert f"{MIN_JWT_SECRET_LENGTH} characters" in str(exc_info.value)
        # Secret itself must never be leaked in exception message
        assert short_sec not in str(exc_info.value)


def test_production_accepts_valid_cryptographic_secret():
    """Production accepts valid, high-entropy secrets of >= 32 characters."""
    valid_secrets = [
        "4f8a7b9c2d1e0f3a5b7c9d1e3f5a7b9c4f8a7b9c2d1e0f3a5b7c9d1e3f5a7b9c",  # 64 hex chars
        "k9#mP$2vL!8xQ@5zR&1wT*4yU^7bN%0cD3fG6hJ9kL2mP5vR8tY1wZ4",          # 56 chars
        "strictly_production_secure_key_over_32_characters_high_entropy_ok"     # 65 chars
    ]
    for valid_sec in valid_secrets:
        result = validate_jwt_secret(valid_sec, env="production")
        assert result == valid_sec


def test_development_and_test_secret_resolution():
    """Development falls back with warning; test mode provides isolated test secret."""
    dev_fallback = validate_jwt_secret(None, env="development")
    assert dev_fallback == DEV_FALLBACK_SECRET

    test_secret = validate_jwt_secret(None, env="test")
    assert test_secret == TEST_DEFAULT_SECRET


# =============================================================================
# 2. Token Creation, Verification, Claims, and Expiry Tests
# =============================================================================

def test_access_token_creation_and_claims():
    """Access token packages sub, role, type='access', jti, and future exp."""
    data = {"sub": "reader@example.com", "role": "reader"}
    token = create_access_token(data)
    assert isinstance(token, str)

    payload = jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])
    assert payload["sub"] == "reader@example.com"
    assert payload["role"] == "reader"
    assert payload["type"] == "access"
    assert "jti" in payload
    assert payload["exp"] > datetime.utcnow().timestamp()


def test_refresh_token_creation_and_claims():
    """Refresh token packages sub, role, type='refresh', jti, and 7-day exp."""
    data = {"sub": "reader@example.com", "role": "reader"}
    token = create_refresh_token(data)
    assert isinstance(token, str)

    payload = jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])
    assert payload["sub"] == "reader@example.com"
    assert payload["role"] == "reader"
    assert payload["type"] == "refresh"
    assert "jti" in payload
    # Expiry should be approximately 7 days in future
    expected_exp = datetime.now(timezone.utc).timestamp() + (7 * 86400)
    assert abs(payload["exp"] - expected_exp) < 120


def test_token_tampered_signature_rejection():
    """Token signed with a different key must be rejected by jwt.decode."""
    token = jwt.encode(
        {"sub": "attacker@example.com", "exp": datetime.now(timezone.utc) + timedelta(hours=1)},
        "foreign_key_different_from_server_key_32bytes_min",
        algorithm=ALGORITHM
    )
    with pytest.raises(JWTError):
        jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])


def test_expired_token_rejection():
    """Expired token must be rejected by jwt.decode."""
    expired_time = datetime.now(timezone.utc) - timedelta(minutes=10)
    token = jwt.encode(
        {"sub": "expired@example.com", "exp": expired_time, "type": "access"},
        get_jwt_secret(),
        algorithm=ALGORITHM
    )
    with pytest.raises(JWTError):
        jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])


def test_algorithm_none_rejected():
    """Unsigned / 'none' algorithm tokens must be rejected."""
    import base64
    raw_header = base64.urlsafe_b64encode(b'{"alg":"none","typ":"JWT"}').decode().rstrip("=")
    raw_payload = base64.urlsafe_b64encode(b'{"sub":"hacker@example.com","type":"access"}').decode().rstrip("=")
    forged_none_token = f"{raw_header}.{raw_payload}."

    with pytest.raises(JWTError):
        jwt.decode(forged_none_token, get_jwt_secret(), algorithms=[ALGORITHM])


# =============================================================================
# 3. Type Separation & Security Enforcement Tests
# =============================================================================

def test_refresh_token_rejected_as_access_token(db_session):
    """Refresh token must not be accepted for authenticated user routes."""
    refresh_tok = create_refresh_token({"sub": "auth_user@example.com", "role": "reader"})
    credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=refresh_tok)

    with pytest.raises(HTTPException) as exc_info:
        get_current_user(credentials=credentials, db=db_session)
    assert exc_info.value.status_code == 401
    assert "Invalid token type" in exc_info.value.detail


def test_verification_token_rejected_as_access_token(db_session):
    """Email verification token must not be accepted as an access token."""
    verify_tok = create_verification_token("auth_user@example.com")
    credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=verify_tok)

    with pytest.raises(HTTPException) as exc_info:
        get_current_user(credentials=credentials, db=db_session)
    assert exc_info.value.status_code == 401
    assert "Invalid token type" in exc_info.value.detail


def test_access_token_rejected_at_refresh_endpoint(db_session):
    """Access token must be rejected at /auth/refresh."""
    access_tok = create_access_token({"sub": "auth_user@example.com", "role": "reader"})
    payload = RefreshTokenRequest(refresh_token=access_tok)

    with pytest.raises(HTTPException) as exc_info:
        refresh_access_token(payload=payload, db=db_session)
    assert exc_info.value.status_code == 401
    assert "Invalid token type" in exc_info.value.detail


def test_revoked_token_rejected_in_auth_and_refresh(db_session):
    """Revoked token must be rejected in both get_current_user and /auth/refresh."""
    access_tok = create_access_token({"sub": "auth_user@example.com", "role": "reader"})
    refresh_tok = create_refresh_token({"sub": "auth_user@example.com", "role": "reader"})

    REVOKED_TOKENS.add(access_tok)
    REVOKED_TOKENS.add(refresh_tok)

    try:
        # Access token in get_current_user
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=access_tok)
        with pytest.raises(HTTPException) as exc1:
            get_current_user(credentials=creds, db=db_session)
        assert exc1.value.status_code == 401
        assert "Token has been revoked" in exc1.value.detail

        # Refresh token at /auth/refresh
        ref_payload = RefreshTokenRequest(refresh_token=refresh_tok)
        with pytest.raises(HTTPException) as exc2:
            refresh_access_token(payload=ref_payload, db=db_session)
        assert exc2.value.status_code == 401
        assert "Token has been revoked" in exc2.value.detail
    finally:
        REVOKED_TOKENS.discard(access_tok)
        REVOKED_TOKENS.discard(refresh_tok)


def test_backward_compatible_token_without_type_accepted(db_session):
    """Existing tokens in circulation that omit 'type' claim continue to be accepted."""
    legacy_payload = {
        "sub": "auth_user@example.com",
        "role": "reader",
        "exp": datetime.utcnow() + timedelta(minutes=30),
        "jti": uuid.uuid4().hex
    }
    legacy_tok = jwt.encode(legacy_payload, get_jwt_secret(), algorithm=ALGORITHM)
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=legacy_tok)

    user = get_current_user(credentials=creds, db=db_session)
    assert user is not None
    assert user.email == "auth_user@example.com"
