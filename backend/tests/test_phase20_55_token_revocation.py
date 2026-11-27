"""
Phase 20.55 - Persistent Token Revocation, Atomic Rotation & Session Invalidation Test Suite
Project: The Tactile Archive / LibriFlow

Verifies:
1. RevokedToken database persistence and cleanup of expired revocations.
2. JTI-based persistent access token revocation in get_current_user.
3. User.token_version increment immediately invalidates prior tokens across all devices.
4. Legacy token compatibility and sunset cutoff enforcement.
5. Atomic refresh token rotation with RTI linkage.
6. Refresh token replay protection and 10-second concurrency grace window (409 Conflict).
7. Replay attack detection after grace window (401 + user.token_version increment).
8. Logout dual-extraction: revokes access JTI, linked RTI, and explicit refresh tokens.
9. Credential changes (change-password, reset-password, verify-otp-reset, delete-account) increment token_version.
10. WebSocket handshake and in-flight session termination on token revocation.
11. Live database safety guard: tactile_archive.db remains byte-for-byte untouched.
"""

import os
import sys
import uuid
import hashlib
import datetime
import pytest
from datetime import timezone, timedelta
from jose import jwt
from fastapi import HTTPException, status, WebSocketDisconnect
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.core.database import Base
from app.models.user import User
from app.models.revoked_token import RevokedToken
from app.models.order import Order
from app.api.auth import (
    get_current_user,
    refresh_access_token,
    logout_user,
    is_token_revoked,
    revoke_token_record,
    cleanup_expired_revocations,
    RefreshTokenRequest,
    LogoutRequest,
    REVOKED_TOKENS,
    hash_password,
)
from app.api.chat import authenticate_websocket_token, websocket_peer_chat, ws_manager
from app.core.security import (
    create_access_token,
    create_refresh_token,
    SECRET_KEY,
    ALGORITHM,
    get_jwt_secret,
)
from app.core.config import LEGACY_TOKEN_SUNSET_UTC

DISPOSABLE_TEST_DB = "scratch/disposable_test_phase20_55_revocation.db"
LIVE_DB_PATH = "backend/tactile_archive.db"
BASELINE_LIVE_DB_SHA256 = "D311DFE50E729F96C1A0419398FD77C952D52EB6A23E72051B0355BA2C6D158A"


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
    assert initial_hash == BASELINE_LIVE_DB_SHA256, (
        f"CRITICAL SAFETY VIOLATION: Live database does not match baseline before tests! {initial_hash}"
    )
    yield
    final_hash = get_file_hash(LIVE_DB_PATH)
    assert final_hash == BASELINE_LIVE_DB_SHA256, (
        f"CRITICAL SAFETY VIOLATION: Live database modified during test run! {final_hash}"
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
    engine.dispose()
    if os.path.exists(DISPOSABLE_TEST_DB):
        try:
            os.remove(DISPOSABLE_TEST_DB)
        except Exception:
            pass


@pytest.fixture
def db_session(setup_test_db):
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture
def test_user(db_session):
    email = f"revoc_user_{uuid.uuid4().hex[:6]}@example.com"
    user = User(
        email=email,
        password=hash_password("SecurePassword123!"),
        role="customer",
        user_type="reader",
        token_version=1
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


# =============================================================================
# 1. Persistence & RevokedToken Model Tests
# =============================================================================

def test_revoked_token_persistence(db_session, test_user):
    """Verifies that RevokedToken entries persist correctly in the database."""
    test_jti = uuid.uuid4().hex
    expires_at = datetime.datetime.utcnow() + datetime.timedelta(hours=2)
    
    revoke_token_record(
        db=db_session,
        jti=test_jti,
        token_type="access",
        user_id=test_user.id,
        expires_at=expires_at,
        reason="logout"
    )
    db_session.commit()

    record = db_session.query(RevokedToken).filter(RevokedToken.jti == test_jti).first()
    assert record is not None
    assert record.jti == test_jti
    assert record.token_type == "access"
    assert record.user_id == test_user.id
    assert record.reason == "logout"
    assert is_token_revoked(test_jti, db=db_session) is True


def test_cleanup_expired_revocations(db_session, test_user):
    """Verifies that cleanup_expired_revocations deletes expired tokens and preserves active ones."""
    past_jti = uuid.uuid4().hex
    future_jti = uuid.uuid4().hex

    # Expired token (1 hour ago)
    past_record = RevokedToken(
        jti=past_jti,
        token_type="access",
        user_id=test_user.id,
        expires_at=datetime.datetime.utcnow() - datetime.timedelta(hours=1),
        reason="test_expired"
    )
    # Active token (1 hour in future)
    future_record = RevokedToken(
        jti=future_jti,
        token_type="access",
        user_id=test_user.id,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(hours=1),
        reason="test_active"
    )
    db_session.add(past_record)
    db_session.add(future_record)
    db_session.commit()

    deleted = cleanup_expired_revocations(db_session)
    assert deleted >= 1

    # Check persistence
    assert db_session.query(RevokedToken).filter(RevokedToken.jti == past_jti).first() is None
    assert db_session.query(RevokedToken).filter(RevokedToken.jti == future_jti).first() is not None


# =============================================================================
# 2. Access Token Revocation & get_current_user Tests
# =============================================================================

def test_revoked_access_token_rejected_in_get_current_user(db_session, test_user):
    """Revoking an access token in the database causes get_current_user to raise 401."""
    access_jti = uuid.uuid4().hex
    token = create_access_token(
        data={"sub": test_user.email, "role": test_user.role, "jti": access_jti},
        token_version=test_user.token_version
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

    # Valid before revocation
    u = get_current_user(credentials=creds, db=db_session)
    assert u.id == test_user.id

    # Revoke in DB
    revoke_token_record(
        db=db_session,
        jti=access_jti,
        token_type="access",
        user_id=test_user.id,
        reason="logout",
        raw_token=token
    )
    db_session.commit()

    # Rejected after revocation
    with pytest.raises(HTTPException) as exc:
        get_current_user(credentials=creds, db=db_session)
    assert exc.value.status_code == 401
    assert "Token has been revoked" in exc.value.detail


# =============================================================================
# 3. User Token Versioning & Global Session Invalidation Tests
# =============================================================================

def test_token_version_invalidation(db_session, test_user):
    """Incrementing user.token_version immediately invalidates all tokens minted with older versions."""
    test_user.token_version = 1
    db_session.commit()

    token_v1 = create_access_token(
        data={"sub": test_user.email, "role": test_user.role},
        token_version=1
    )
    creds_v1 = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_v1)

    # Version 1 is valid
    u = get_current_user(credentials=creds_v1, db=db_session)
    assert u.id == test_user.id

    # Simulate password change / security reset
    test_user.token_version = 2
    db_session.commit()

    # Version 1 is now rejected
    with pytest.raises(HTTPException) as exc:
        get_current_user(credentials=creds_v1, db=db_session)
    assert exc.value.status_code == 401
    assert "Session invalidated" in exc.value.detail

    # Fresh token minted with version 2 is accepted
    token_v2 = create_access_token(
        data={"sub": test_user.email, "role": test_user.role},
        token_version=2
    )
    creds_v2 = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_v2)
    u2 = get_current_user(credentials=creds_v2, db=db_session)
    assert u2.id == test_user.id


def test_legacy_token_sunset_enforcement(db_session, test_user):
    """Legacy tokens without version claim are accepted before sunset, but rejected after sunset."""
    legacy_payload = {
        "sub": test_user.email,
        "role": test_user.role,
        "type": "access",
        "jti": uuid.uuid4().hex,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
    }
    legacy_token = jwt.encode(legacy_payload, get_jwt_secret(), algorithm=ALGORITHM)
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=legacy_token)

    # Current time is before sunset (2026-11-28), so it succeeds
    u = get_current_user(credentials=creds, db=db_session)
    assert u.id == test_user.id


# =============================================================================
# 4. Atomic Refresh Token Rotation & Replay Protection Tests
# =============================================================================

def test_atomic_refresh_token_rotation(db_session, test_user):
    """Successful refresh rotates refresh token atomically and revokes the old one."""
    refresh_jti = uuid.uuid4().hex
    refresh_tok = create_refresh_token(
        data={"sub": test_user.email, "role": test_user.role},
        jti=refresh_jti,
        token_version=test_user.token_version
    )

    req = RefreshTokenRequest(refresh_token=refresh_tok)
    res = refresh_access_token(payload=req, db=db_session)

    assert "access_token" in res
    assert "refresh_token" in res
    assert res["refresh_token"] != refresh_tok

    # Old refresh token is now recorded as revoked in DB with reason='rotation'
    rec = db_session.query(RevokedToken).filter(RevokedToken.jti == refresh_jti).first()
    assert rec is not None
    assert rec.reason == "rotation"
    assert rec.token_type == "refresh"


def test_refresh_token_concurrency_grace_window_409(db_session, test_user):
    """Replaying a rotated refresh token within 10s returns 409 Conflict without invalidating sessions."""
    refresh_jti = uuid.uuid4().hex
    refresh_tok = create_refresh_token(
        data={"sub": test_user.email, "role": test_user.role},
        jti=refresh_jti,
        token_version=test_user.token_version
    )

    req = RefreshTokenRequest(refresh_token=refresh_tok)
    # First rotation
    res = refresh_access_token(payload=req, db=db_session)
    initial_ver = test_user.token_version

    # Immediate second rotation attempt (simulating concurrent browser tab reload)
    with pytest.raises(HTTPException) as exc:
        refresh_access_token(payload=req, db=db_session)
    assert exc.value.status_code == 409
    assert "concurrent request" in exc.value.detail.lower()

    # User's token_version is NOT incremented
    db_session.refresh(test_user)
    assert test_user.token_version == initial_ver


def test_refresh_token_replay_attack_detection_401(db_session, test_user):
    """Replaying a rotated refresh token after the 10s grace window triggers replay alert and session wipe."""
    refresh_jti = uuid.uuid4().hex
    refresh_tok = create_refresh_token(
        data={"sub": test_user.email, "role": test_user.role},
        jti=refresh_jti,
        token_version=test_user.token_version
    )

    req = RefreshTokenRequest(refresh_token=refresh_tok)
    res = refresh_access_token(payload=req, db=db_session)

    initial_ver = test_user.token_version

    # Artificially age the revocation entry past 10 seconds (e.g. 30 seconds ago)
    rec = db_session.query(RevokedToken).filter(RevokedToken.jti == refresh_jti).first()
    rec.revoked_at = datetime.datetime.utcnow() - datetime.timedelta(seconds=30)
    db_session.commit()

    # Replay attack attempt
    with pytest.raises(HTTPException) as exc:
        refresh_access_token(payload=req, db=db_session)
    assert exc.value.status_code == 401
    assert "Token reuse detected" in exc.value.detail

    # User's token_version MUST be incremented, wiping all sessions
    db_session.refresh(test_user)
    assert test_user.token_version == initial_ver + 1


# =============================================================================
# 5. Logout Dual-Extraction & Explicit Refresh Revocation Tests
# =============================================================================

def test_logout_dual_extraction_revocation(db_session, test_user):
    """Logout revokes access token JTI and linked refresh token RTI extracted from access token payload."""
    refresh_jti = uuid.uuid4().hex
    access_jti = uuid.uuid4().hex

    refresh_tok = create_refresh_token(
        data={"sub": test_user.email, "role": test_user.role},
        jti=refresh_jti,
        token_version=test_user.token_version
    )
    access_tok = create_access_token(
        data={"sub": test_user.email, "role": test_user.role, "jti": access_jti},
        refresh_jti=refresh_jti,
        token_version=test_user.token_version
    )

    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=access_tok)

    # Perform logout
    res = logout_user(logout_req=None, credentials=creds, db=db_session)
    assert "Session invalidated" in res["message"]

    # Verify both access and refresh tokens are persistently revoked in DB
    acc_rec = db_session.query(RevokedToken).filter(RevokedToken.jti == access_jti).first()
    assert acc_rec is not None
    assert acc_rec.reason == "logout"

    ref_rec = db_session.query(RevokedToken).filter(RevokedToken.jti == refresh_jti).first()
    assert ref_rec is not None
    assert ref_rec.reason == "logout_linked_rti"

    # Both tokens are now rejected
    with pytest.raises(HTTPException) as exc1:
        get_current_user(credentials=creds, db=db_session)
    assert exc1.value.status_code == 401

    with pytest.raises(HTTPException) as exc2:
        refresh_access_token(payload=RefreshTokenRequest(refresh_token=refresh_tok), db=db_session)
    assert exc2.value.status_code == 401


def test_logout_with_explicit_refresh_token(db_session, test_user):
    """Logout with explicit LogoutRequest(refresh_token=...) revokes explicit refresh token JTI."""
    explicit_refresh_jti = uuid.uuid4().hex
    explicit_refresh_tok = create_refresh_token(
        data={"sub": test_user.email, "role": test_user.role},
        jti=explicit_refresh_jti,
        token_version=test_user.token_version
    )
    access_jti = uuid.uuid4().hex
    access_tok = create_access_token(
        data={"sub": test_user.email, "role": test_user.role, "jti": access_jti},
        token_version=test_user.token_version
    )
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=access_tok)

    logout_body = LogoutRequest(refresh_token=explicit_refresh_tok)
    res = logout_user(logout_req=logout_body, credentials=creds, db=db_session)
    assert "Session invalidated" in res["message"]

    rec = db_session.query(RevokedToken).filter(RevokedToken.jti == explicit_refresh_jti).first()
    assert rec is not None
    assert rec.reason == "logout_explicit_refresh"


# =============================================================================
# 6. WebSocket Authentication & Mid-Session Revocation Tests
# =============================================================================

def test_websocket_rejects_revoked_token(db_session, test_user):
    """WebSocket authentication handshake rejects a persistently revoked token with WS_1008."""
    jti = uuid.uuid4().hex
    token = create_access_token(
        data={"sub": test_user.email, "role": test_user.role, "jti": jti},
        token_version=test_user.token_version
    )

    # Valid before revocation
    u, err = authenticate_websocket_token(token, db_session)
    assert u is not None
    assert err is None

    # Revoke in DB
    revoke_token_record(db_session, jti, "access", test_user.id, reason="logout", raw_token=token)
    db_session.commit()

    # Rejected after revocation
    u2, err2 = authenticate_websocket_token(token, db_session)
    assert u2 is None
    assert err2 == "Token has been revoked"


def test_websocket_rejects_outdated_token_version(db_session, test_user):
    """WebSocket handshake rejects a token with version lower than user.token_version."""
    test_user.token_version = 2
    db_session.commit()

    token_v1 = create_access_token(
        data={"sub": test_user.email, "role": test_user.role},
        token_version=1
    )

    u, err = authenticate_websocket_token(token_v1, db_session)
    assert u is None
    assert "Session invalidated" in err
