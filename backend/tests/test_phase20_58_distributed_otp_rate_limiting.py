"""
Phase 20.58 - Distributed OTP & Rate Limiting Hardening Test Suite
Project: The Tactile Archive / LibriFlow

Verifies:
1. Rate limit storage URI sanitization (masks credentials in logs).
2. Rate limiter initialization and graceful in-memory fallback on connection failure.
3. Thread-safe in-memory OTP attempt store window expiry and clear operations.
4. Distributed Redis OTP attempt store atomic increment and shared worker state simulation.
5. Fail-safe resilience: Primary storage outage never bypasses OTP lockout protection.
6. Zero secret leakage: OTP codes are never logged or exposed in exceptions.
7. Multi-worker brute-force prevention: Worker switching cannot reset failed attempt counters.
8. Live database safety guard: tactile_archive.db remains byte-for-byte immutable.
"""

import os
import sys
import time
import uuid
import hashlib
import datetime
import threading
import logging
import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.core.database import Base
from app.models.otp_code import OTPCode
from app.core.rate_limit import sanitize_storage_uri, init_limiter
from app.core.otp import (
    BaseOTPAttemptStore,
    MemoryOTPAttemptStore,
    RedisOTPAttemptStore,
    ResilientOTPAttemptStore,
    record_failed_attempt,
    get_failed_attempts,
    clear_failed_attempts,
    validate_and_verify_otp,
    MAX_OTP_ATTEMPTS,
    ATTEMPT_WINDOW_SECONDS,
)

DISPOSABLE_TEST_DB = "scratch/disposable_test_phase20_58_otp.db"
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
        f"CRITICAL SAFETY VIOLATION: Live database modified before test run! {initial_hash}"
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


# ==============================================================================
# 1. Rate Limiting URI Sanitization & Fallback Tests
# ==============================================================================

def test_sanitize_storage_uri():
    """Confirms credentials in Redis/Memcached URLs are properly masked."""
    assert sanitize_storage_uri(None) == ""
    assert sanitize_storage_uri("") == ""
    assert sanitize_storage_uri("memory://") == "memory://"
    assert sanitize_storage_uri("redis://localhost:6379/0") == "redis://localhost:6379/0"
    
    # Password masking
    masked = sanitize_storage_uri("redis://default:SuperSecretPassword123@redis.railway.internal:6379/0")
    assert "SuperSecretPassword123" not in masked
    assert "redis://default:***@redis.railway.internal:6379/0" == masked


def test_init_limiter_handles_invalid_uri_safely(monkeypatch):
    """Confirms that an invalid or unreachable distributed storage URL falls back safely to memory."""
    monkeypatch.setenv("RATE_LIMIT_STORAGE_URL", "redis://invalid_user:invalid_pass@999.999.999.999:6379/0")
    lim = init_limiter()
    assert lim is not None
    # Limiter is functional despite unreachable host
    assert hasattr(lim, "limit")


# ==============================================================================
# 2. OTP Attempt Store Thread Safety & Window Expiry Tests
# ==============================================================================

def test_memory_otp_attempt_store_concurrency():
    """Confirms that concurrent failed attempts from multiple threads are recorded accurately."""
    store = MemoryOTPAttemptStore()
    ident = "concurrent_user@example.com"
    purpose = "login_otp"

    def worker():
        for _ in range(5):
            store.record_failed_attempt(ident, purpose)

    threads = [threading.Thread(target=worker) for _ in range(4)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    total = store.get_failed_attempts(ident, purpose)
    assert total == 20
    store.clear_failed_attempts(ident, purpose)
    assert store.get_failed_attempts(ident, purpose) == 0


def test_memory_otp_attempt_store_window_expiry():
    """Confirms that failed attempts expire when outside the ATTEMPT_WINDOW_SECONDS."""
    store = MemoryOTPAttemptStore()
    ident = "expired_attempt_user@example.com"
    purpose = "password_reset"

    store.record_failed_attempt(ident, purpose)
    assert store.get_failed_attempts(ident, purpose) == 1

    # Artificially age the entry past the attempt window
    key = (ident.lower(), purpose.lower())
    with store._lock:
        store._failed_attempts[key]["last_attempt"] = time.time() - (ATTEMPT_WINDOW_SECONDS + 10)

    # Should report 0 attempts due to expiration
    assert store.get_failed_attempts(ident, purpose) == 0


# ==============================================================================
# 3. Distributed Redis OTP Attempt Store Simulation
# ==============================================================================

class MockRedisClient:
    """Mock Redis client simulating distributed shared key-value store across workers."""
    def __init__(self):
        self._data = {}
        self._ttls = {}
        self._lock = threading.Lock()

    def incr(self, key: str) -> int:
        with self._lock:
            val = self._data.get(key, 0) + 1
            self._data[key] = val
            return val

    def expire(self, key: str, seconds: int) -> bool:
        with self._lock:
            self._ttls[key] = seconds
            return True

    def get(self, key: str) -> str | None:
        with self._lock:
            return str(self._data.get(key)) if key in self._data else None

    def delete(self, key: str) -> None:
        with self._lock:
            self._data.pop(key, None)
            self._ttls.pop(key, None)


def test_distributed_redis_otp_store_shared_across_workers():
    """
    Simulates multiple independent FastAPI worker processes sharing a Redis backend.
    Confirms that failed attempts in Worker 1 are immediately visible to Worker 2.
    """
    shared_redis = MockRedisClient()

    # Simulate Worker 1 and Worker 2
    worker1_store = RedisOTPAttemptStore(shared_redis)
    worker2_store = RedisOTPAttemptStore(shared_redis)

    ident = "attacker_target@example.com"
    purpose = "password_reset"

    # Attacker sends 3 failed attempts to Worker 1
    worker1_store.record_failed_attempt(ident, purpose)
    worker1_store.record_failed_attempt(ident, purpose)
    worker1_store.record_failed_attempt(ident, purpose)

    # Worker 2 sees exactly 3 attempts
    assert worker2_store.get_failed_attempts(ident, purpose) == 3

    # Attacker sends 2 more attempts to Worker 2
    worker2_store.record_failed_attempt(ident, purpose)
    attempts = worker2_store.record_failed_attempt(ident, purpose)

    assert attempts == 5
    assert worker1_store.get_failed_attempts(ident, purpose) >= MAX_OTP_ATTEMPTS

    # Clear from Worker 1 clears globally
    worker1_store.clear_failed_attempts(ident, purpose)
    assert worker2_store.get_failed_attempts(ident, purpose) == 0


# ==============================================================================
# 4. Storage Outage Fail-Safe & Zero Protection Bypass Tests
# ==============================================================================

class BrokenRedisClient:
    """Simulates an unreachable or crashed Redis storage node."""
    def incr(self, key: str):
        raise ConnectionError("Redis server connection lost!")

    def get(self, key: str):
        raise ConnectionError("Redis server connection lost!")

    def delete(self, key: str):
        raise ConnectionError("Redis server connection lost!")


def test_resilient_store_never_bypasses_lockout_during_storage_outage():
    """
    Confirms that an unexpected Redis storage outage falls back to in-memory store
    and NEVER silently bypasses brute-force lockout protections.
    """
    broken_redis = BrokenRedisClient()
    memory_store = MemoryOTPAttemptStore()
    primary = RedisOTPAttemptStore(broken_redis)
    resilient_store = ResilientOTPAttemptStore(primary_store=primary, fallback_store=memory_store)

    ident = "outage_victim@example.com"
    purpose = "login_otp"

    # Recording attempt during storage outage must NOT raise an unhandled crash
    # and MUST record in the fallback store
    for i in range(MAX_OTP_ATTEMPTS):
        count = resilient_store.record_failed_attempt(ident, purpose)
        assert count == i + 1

    # Lockout count is maintained despite Redis being completely broken
    assert resilient_store.get_failed_attempts(ident, purpose) == MAX_OTP_ATTEMPTS


# ==============================================================================
# 5. OTP Validation & Zero Secret Leakage Tests
# ==============================================================================

def test_otp_validation_lockout_and_zero_secret_leakage(db_session, caplog):
    """
    Validates that:
    1. Reaching MAX_OTP_ATTEMPTS marks the OTP record as used (invalidated).
    2. Subsequent verification attempts are rejected.
    3. The raw OTP code never appears in logs.
    """
    ident = "zero_leak_test@example.com"
    purpose = "password_reset"
    raw_secret_otp = "849201"

    # Create active OTP record in disposable DB
    otp_record = OTPCode(
        identifier=ident,
        code=raw_secret_otp,
        purpose=purpose,
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db_session.add(otp_record)
    db_session.commit()
    db_session.refresh(otp_record)

    clear_failed_attempts(ident, purpose)

    # 4 invalid attempts
    for _ in range(4):
        with pytest.raises(HTTPException) as exc:
            validate_and_verify_otp(
                db=db_session,
                otp_model=OTPCode,
                identifier=ident,
                purpose=purpose,
                submitted_code="000000"
            )
        assert exc.value.status_code == 400
        assert "Invalid OTP code" in exc.value.detail

    # 5th invalid attempt triggers lockout
    with pytest.raises(HTTPException) as exc_lockout:
        validate_and_verify_otp(
            db=db_session,
            otp_model=OTPCode,
            identifier=ident,
            purpose=purpose,
            submitted_code="000000"
        )
    assert exc_lockout.value.status_code == 400
    assert "Too many failed attempts" in exc_lockout.value.detail

    # Check that record is marked used in database
    db_session.refresh(otp_record)
    assert otp_record.used is True

    # Even if attacker submits the correct code on 6th attempt, it is rejected
    with pytest.raises(HTTPException) as exc_blocked:
        validate_and_verify_otp(
            db=db_session,
            otp_model=OTPCode,
            identifier=ident,
            purpose=purpose,
            submitted_code=raw_secret_otp
        )
    assert exc_blocked.value.status_code == 400

    # Verify raw secret OTP was NEVER logged anywhere
    for record in caplog.records:
        assert raw_secret_otp not in record.message
