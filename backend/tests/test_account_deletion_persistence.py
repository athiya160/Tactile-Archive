"""
Phase 20.28 — Account Deletion Request Persistence Test Suite
Project: The Tactile Archive / LibriFlow

Verifies transactional persistence, duplicate suppression, administrative queue management,
status transitions, session isolation, transaction rollback, and live database immutability.
Executes strictly against an isolated disposable SQLite test database.
"""

import os
import sys
import uuid
import hashlib
import pytest
from datetime import datetime
from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

# Ensure backend in path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.core.database import Base
from app.api.auth import (
    request_account_deletion_external,
    hash_password,
    create_access_token,
    delete_user_account,
    REVOKED_TOKENS,
)
from app.api.admin import (
    get_deletion_requests,
    update_deletion_request_status,
)
from app.schemas.user import (
    PublicAccountDeletionRequest,
    AccountDeletionStatusUpdate,
    AccountDeleteRequest,
)
from app.models.user import User
from app.models.account_deletion_request import AccountDeletionRequest
from scripts.migrate_phase20_28_account_deletion_requests import run_migration

DISPOSABLE_TEST_DB = "scratch/disposable_test_deletion_persistence.db"
LIVE_DB_PATH = "backend/tactile_archive.db"


def get_file_sha256(path):
    if not os.path.exists(path):
        return None
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


# Setup disposable test engine
engine = create_engine(f"sqlite:///{DISPOSABLE_TEST_DB}", connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="module", autouse=True)
def live_db_safety_sentinel():
    """Confirms live database hash is identical before and after entire test execution."""
    initial_hash = get_file_sha256(LIVE_DB_PATH)
    yield
    final_hash = get_file_sha256(LIVE_DB_PATH)
    assert initial_hash == final_hash, f"CRITICAL SAFETY VIOLATION: Live database modified during test run! {initial_hash} != {final_hash}"


@pytest.fixture(scope="function")
def db_session():
    os.makedirs("scratch", exist_ok=True)
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        # Clean test tables for function isolation
        Base.metadata.drop_all(bind=engine)


def test_successful_request_creation_and_persistence(db_session):
    """1. External deletion request persists durably to account_deletion_requests."""
    payload = PublicAccountDeletionRequest(
        email="testuser@example.com",
        reason="I no longer need this service"
    )
    res = request_account_deletion_external(payload=payload, db=db_session)

    assert res["success"] is True
    assert res["is_duplicate"] is False
    assert res["request_id"].startswith("del_")
    assert "received and queued for review" in res["message"].lower()

    # Verify persistence in database
    row = db_session.query(AccountDeletionRequest).filter(
        AccountDeletionRequest.request_id == res["request_id"]
    ).first()

    assert row is not None
    assert row.email == "testuser@example.com"
    assert row.reason == "I no longer need this service"
    assert row.status == "pending"
    assert row.created_at is not None
    assert row.updated_at is not None
    assert row.mask_email() == "t******r@example.com"


def test_invalid_email_rejected_without_persistence(db_session):
    """2. Invalid and empty emails are rejected with HTTP 400 and zero persistence."""
    for invalid_email in ["", "notanemail", "plainaddress", "   "]:
        payload = PublicAccountDeletionRequest(email=invalid_email)
        with pytest.raises(HTTPException) as exc_info:
            request_account_deletion_external(payload=payload, db=db_session)
        assert exc_info.value.status_code == 400
        assert "valid email" in exc_info.value.detail.lower()

    # Verify table has zero records
    count = db_session.query(AccountDeletionRequest).count()
    assert count == 0


def test_duplicate_submission_suppression(db_session):
    """3. Duplicate requests within active status window refresh timestamp without creating new rows."""
    payload1 = PublicAccountDeletionRequest(email="duplicate_check@example.com", reason="First attempt")
    res1 = request_account_deletion_external(payload=payload1, db=db_session)
    assert res1["success"] is True
    assert res1["is_duplicate"] is False

    # Second submission for same email
    payload2 = PublicAccountDeletionRequest(email="duplicate_check@example.com", reason="Second attempt with updated reason")
    res2 = request_account_deletion_external(payload=payload2, db=db_session)
    assert res2["success"] is True
    assert res2["is_duplicate"] is True
    assert res2["request_id"] == res1["request_id"]
    assert "already been received and is currently queued" in res2["message"].lower()

    # Verify exact count remains 1
    rows = db_session.query(AccountDeletionRequest).filter(
        AccountDeletionRequest.email == "duplicate_check@example.com"
    ).all()
    assert len(rows) == 1
    assert rows[0].request_id == res1["request_id"]


def test_persistence_across_separate_sessions(db_session):
    """4. Data persists across distinct database sessions and connection closures."""
    payload = PublicAccountDeletionRequest(email="persisted_session@example.com", reason="Session persistence check")
    res = request_account_deletion_external(payload=payload, db=db_session)
    req_id = res["request_id"]

    # Close the current session
    db_session.close()

    # Open a completely fresh session from engine
    new_session = TestingSessionLocal()
    try:
        loaded = new_session.query(AccountDeletionRequest).filter(
            AccountDeletionRequest.request_id == req_id
        ).first()
        assert loaded is not None
        assert loaded.email == "persisted_session@example.com"
        assert loaded.status == "pending"
    finally:
        new_session.close()


def test_admin_queue_inspection_and_masking(db_session):
    """5. Admin endpoint lists deletion requests with privacy-safe email masking."""
    # Seed admin user
    admin_user = User(
        email="admin_officer@tactilearchive.org",
        name="Admin Officer",
        is_admin=True,
        role="admin"
    )
    db_session.add(admin_user)
    db_session.commit()

    # Seed 3 deletion requests
    for i in range(3):
        req = AccountDeletionRequest(
            email=f"user_{i}@example.com",
            reason=f"Reason {i}",
            status="pending"
        )
        db_session.add(req)
    db_session.commit()

    # Query admin queue
    data = get_deletion_requests(db=db_session, admin=admin_user)
    assert data["total"] >= 3
    assert len(data["items"]) >= 3

    # Check masking: full email should not be exposed in admin queue view
    for item in data["items"]:
        assert "@" in item["masked_email"]
        assert "*" in item["masked_email"]
        assert item["status"] == "pending"


def test_admin_status_transition_lifecycle(db_session):
    """6. Admin can transition status through lifecycle (in_review -> completed / rejected)."""
    admin_user = User(
        email="compliance_lead@tactilearchive.org",
        name="Compliance Lead",
        is_admin=True,
        role="admin"
    )
    db_session.add(admin_user)
    db_session.commit()

    req = AccountDeletionRequest(
        email="target_deletion@example.com",
        reason="GDPR right to erasure",
        status="pending"
    )
    db_session.add(req)
    db_session.commit()
    db_session.refresh(req)

    # 1. Update to in_review
    upd1 = AccountDeletionStatusUpdate(status="in_review", resolution_notes="Investigating past rentals")
    res1 = update_deletion_request_status(request_id=req.request_id, payload=upd1, db=db_session, admin=admin_user)
    assert res1["success"] is True
    assert res1["request"]["status"] == "in_review"
    assert res1["request"]["resolution_notes"] == "Investigating past rentals"

    # 2. Update to completed
    upd2 = AccountDeletionStatusUpdate(status="completed", resolution_notes="All PII successfully scrubbed")
    res2 = update_deletion_request_status(request_id=req.request_id, payload=upd2, db=db_session, admin=admin_user)
    assert res2["success"] is True
    assert res2["request"]["status"] == "completed"

    # 3. Reject invalid status
    with pytest.raises(HTTPException) as exc_info:
        update_deletion_request_status(
            request_id=req.request_id,
            payload=AccountDeletionStatusUpdate(status="invalid_bogus_status"),
            db=db_session,
            admin=admin_user
        )
    assert exc_info.value.status_code == 400


def test_database_rollback_on_failure(db_session):
    """7. Transaction failure triggers rollback without leaving partial or corrupted records."""
    req1 = AccountDeletionRequest(
        request_id="del_unique_fixed_123",
        email="first@example.com",
        status="pending"
    )
    db_session.add(req1)
    db_session.commit()

    count_before = db_session.query(AccountDeletionRequest).count()
    assert count_before == 1

    try:
        # Duplicate unique request_id violation
        req2 = AccountDeletionRequest(
            request_id="del_unique_fixed_123",  # UNIQUE constraint violation
            email="second@example.com",
            status="pending"
        )
        db_session.add(req2)
        db_session.commit()
        assert False, "Should have failed due to UNIQUE constraint on request_id"
    except Exception:
        db_session.rollback()

    count_after = db_session.query(AccountDeletionRequest).count()
    assert count_before == count_after, "Rollback failed: row count altered after failed transaction"
    rem = db_session.query(AccountDeletionRequest).first()
    assert rem.email == "first@example.com"


def test_linked_user_id_resolution(db_session):
    """8. Request automatically links user_id when email matches an existing account."""
    existing_user = User(
        email="registered_user@example.com",
        password=hash_password("Pass123!"),
        name="Registered User",
        role="customer"
    )
    db_session.add(existing_user)
    db_session.commit()
    db_session.refresh(existing_user)

    payload = PublicAccountDeletionRequest(email="registered_user@example.com", reason="Closing profile")
    res = request_account_deletion_external(payload=payload, db=db_session)

    persisted = db_session.query(AccountDeletionRequest).filter(
        AccountDeletionRequest.request_id == res["request_id"]
    ).first()

    assert persisted is not None
    assert persisted.user_id == existing_user.id


def test_already_deleted_user_auto_completed(db_session):
    """9. External requests for already-deleted users are registered and marked completed."""
    deleted_user = User(
        email="deleted_42_abcdef@deleted.tactilearchive.org",
        name="[Deleted User]",
        role="deleted"
    )
    db_session.add(deleted_user)
    db_session.commit()

    payload = PublicAccountDeletionRequest(email="deleted_42_abcdef@deleted.tactilearchive.org")
    res = request_account_deletion_external(payload=payload, db=db_session)

    assert res["success"] is True
    persisted = db_session.query(AccountDeletionRequest).filter(
        AccountDeletionRequest.request_id == res["request_id"]
    ).first()

    assert persisted is not None
    assert persisted.status == "completed"
    assert "already deleted" in persisted.resolution_notes.lower()


def test_standalone_migration_script_idempotent():
    """10. Standalone additive migration script runs safely and idempotently on disposable DB."""
    mig_db = "scratch/test_mig_idempotent.db"
    if os.path.exists(mig_db):
        try:
            os.remove(mig_db)
        except Exception:
            pass

    # Create dummy SQLite DB with users table
    conn = sqlite3.connect(mig_db)
    conn.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT, name TEXT)")
    conn.execute("CREATE TABLE orders (id INTEGER PRIMARY KEY, total_amount REAL)")
    conn.execute("CREATE TABLE payments (id INTEGER PRIMARY KEY, amount REAL)")
    conn.commit()
    conn.close()

    # First migration run
    res1 = run_migration(mig_db, verbose=False)
    assert res1["status"] == "SUCCESS"
    assert res1["table_created"] is True

    # Second migration run (idempotent)
    res2 = run_migration(mig_db, verbose=False)
    assert res2["status"] == "SUCCESS"

    if os.path.exists(mig_db):
        try:
            os.remove(mig_db)
        except Exception:
            pass


import sqlite3
