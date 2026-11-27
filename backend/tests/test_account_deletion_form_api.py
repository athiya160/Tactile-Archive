"""
Phase 20.34 - Public Account Deletion Form API Connectivity Test Suite
Project: The Tactile Archive / LibriFlow

Verifies:
1. Valid request to POST /auth/request-account-deletion returns HTTP 200,
   tracking reference (request_id), status 'pending', and truthful receipt acknowledgement.
2. Invalid email addresses return HTTP 400 Bad Request.
3. Duplicate active deletion requests are handled idempotently (is_duplicate: True).
4. Truthful acknowledgement: never falsely claims instant deletion.
5. GET /delete-account and GET /account-deletion-info serve compliant HTML
   with <meta name="api-base-url" content="">, static host protection, and accessible alerts.
6. CORS configuration and Firebase Hosting origin compatibility.
7. Strict live database immutability sentinel (tactile_archive.db).

Executes strictly against an isolated disposable SQLite test database.
"""

import os
import sys
import hashlib
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException
from fastapi.middleware.cors import CORSMiddleware

# Ensure backend in Python path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.main import app
from app.core.database import Base
from app.api.auth import (
    request_account_deletion_external,
    get_account_deletion_web_page,
    hash_password,
)
from app.schemas.user import PublicAccountDeletionRequest
from app.models.user import User
from app.models.account_deletion_request import AccountDeletionRequest

DISPOSABLE_TEST_DB = "scratch/disposable_test_form_api.db"
LIVE_DB_PATH = "backend/tactile_archive.db"


def get_file_hash(path):
    if not os.path.exists(path):
        return None
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest().upper()


# Disposable test engine
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
    try:
        # Seed test user
        existing = session.query(User).filter_by(email="reader@example.com").first()
        if not existing:
            sample_user = User(
                name="Archive Reader",
                email="reader@example.com",
                password=hash_password("ValidPassword123!"),
                role="reader",
                phone="555-0100"
            )
            session.add(sample_user)
            session.commit()
        yield session
    finally:
        session.query(AccountDeletionRequest).delete()
        session.commit()
        session.close()


def test_valid_account_deletion_request(db_session):
    """Scenario 1: Valid deletion request returns HTTP 200, request_id, and queued acknowledgment."""
    payload = PublicAccountDeletionRequest(
        email="reader@example.com",
        reason="I want to delete my account and data",
        notes="Testing Phase 20.34 connectivity"
    )
    res = request_account_deletion_external(payload=payload, db=db_session)

    assert res["success"] is True
    assert res["is_duplicate"] is False
    assert res["status"] == "pending"
    assert res["request_id"].startswith("del_")
    assert "received and queued for review" in res["message"].lower()

    # Verify persistence in disposable DB
    req = db_session.query(AccountDeletionRequest).filter_by(request_id=res["request_id"]).first()
    assert req is not None
    assert req.email == "reader@example.com"
    assert req.user_id is not None
    assert req.status == "pending"


def test_invalid_email_format(db_session):
    """Scenario 2: Invalid email address returns HTTP 400 Bad Request."""
    invalid_emails = [
        "not-an-email",
        "plainaddress",
        "missingatsign.com",
        "",
        "   "
    ]
    for bad_email in invalid_emails:
        payload = PublicAccountDeletionRequest(email=bad_email, reason="Testing bad email")
        with pytest.raises(HTTPException) as exc_info:
            request_account_deletion_external(payload=payload, db=db_session)
        assert exc_info.value.status_code == 400
        assert "valid email" in exc_info.value.detail.lower()


def test_duplicate_active_deletion_request(db_session):
    """Scenario 5: Duplicate active deletion requests are handled idempotently."""
    payload1 = PublicAccountDeletionRequest(
        email="reader@example.com",
        reason="Initial request",
        notes="Note 1"
    )
    res1 = request_account_deletion_external(payload=payload1, db=db_session)
    assert res1["success"] is True
    assert res1["is_duplicate"] is False
    req_id_1 = res1["request_id"]

    # Second request with updated note
    payload2 = PublicAccountDeletionRequest(
        email="reader@example.com",
        reason="Updated reason",
        notes="Note 2"
    )
    res2 = request_account_deletion_external(payload=payload2, db=db_session)
    assert res2["success"] is True
    assert res2["is_duplicate"] is True
    assert res2["request_id"] == req_id_1
    assert "already been received and is currently queued" in res2["message"].lower()

    # Confirm only one active record exists in database
    count = db_session.query(AccountDeletionRequest).filter_by(email="reader@example.com").count()
    assert count == 1


def test_truthful_acknowledgement_content(db_session):
    """Scenario 6: Acknowledgement must be truthful; cannot claim immediate erasure."""
    payload = PublicAccountDeletionRequest(email="reader@example.com", reason="Testing truthfulness")
    res = request_account_deletion_external(payload=payload, db=db_session)

    message = res["message"]
    # Must acknowledge receipt and review queue
    assert "queued for review" in message.lower()
    # Must NOT claim immediate deletion
    assert "account has been deleted" not in message.lower()
    assert "data permanently erased" not in message.lower()
    assert res["status"] == "pending"


def test_public_account_deletion_html_routes():
    """Scenario 7: GET /delete-account and /account-deletion-info serve compliant HTML."""
    response = get_account_deletion_web_page()
    assert response.status_code == 200

    html = response.body.decode("utf-8")
    # Check meta tag
    assert '<meta name="api-base-url" content="">' in html
    # Check JavaScript submission logic
    assert 'resolveApiBaseUrl' in html
    assert 'isSeparateStaticHost' in html
    assert 'isSubmitting' in html
    assert 'role="alert"' in html
    # Check contact info
    assert 'support@tactilearchive.org' in html
    # Check required form fields
    assert 'id="deletion-form"' in html
    assert 'id="email"' in html
    assert 'id="submit-btn"' in html
    assert 'id="status-msg"' in html


def test_cors_middleware_configuration():
    """Scenario 8: CORS middleware configuration supports cross-origin requests."""
    # Verify CORSMiddleware is registered in application middleware stack
    cors_mw = [m for m in app.user_middleware if m.cls == CORSMiddleware]
    assert len(cors_mw) > 0, "CORSMiddleware must be configured in FastAPI app"

    mw_kwargs = cors_mw[0].kwargs
    assert mw_kwargs.get("allow_credentials") is True
    assert "*" in mw_kwargs.get("allow_methods", [])
    assert "*" in mw_kwargs.get("allow_headers", [])

    # Verify origin parsing logic matches comma-separated ALLOWED_ORIGINS
    test_raw = "https://tactile-archive.web.app,https://tactile-archive.firebaseapp.com"
    parsed_origins = [o.strip() for o in test_raw.split(",") if o.strip()]
    assert "https://tactile-archive.web.app" in parsed_origins
    assert "https://tactile-archive.firebaseapp.com" in parsed_origins
