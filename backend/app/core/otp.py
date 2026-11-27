import os
import re
import secrets
import threading
import time
import datetime
import logging
from typing import Optional, Tuple, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException

logger = logging.getLogger("app.core.otp")

# Security configuration
MAX_OTP_ATTEMPTS = 5
ATTEMPT_WINDOW_SECONDS = 600  # 10 minutes window


class BaseOTPAttemptStore:
    """Abstract interface for OTP attempt tracking across local and distributed storage."""
    def record_failed_attempt(self, identifier: str, purpose: str) -> int:
        raise NotImplementedError

    def get_failed_attempts(self, identifier: str, purpose: str) -> int:
        raise NotImplementedError

    def clear_failed_attempts(self, identifier: str, purpose: str) -> None:
        raise NotImplementedError


class MemoryOTPAttemptStore(BaseOTPAttemptStore):
    """Process-local, thread-safe in-memory OTP attempt store."""
    def __init__(self):
        self._lock = threading.Lock()
        self._failed_attempts: Dict[Tuple[str, str], Dict[str, Any]] = {}

    def record_failed_attempt(self, identifier: str, purpose: str) -> int:
        key = (identifier.strip().lower(), purpose.strip().lower())
        now = time.time()
        with self._lock:
            entry = self._failed_attempts.get(key)
            if not entry or (now - entry["last_attempt"] > ATTEMPT_WINDOW_SECONDS):
                entry = {"attempts": 1, "last_attempt": now}
            else:
                entry["attempts"] += 1
                entry["last_attempt"] = now
            self._failed_attempts[key] = entry
            return entry["attempts"]

    def get_failed_attempts(self, identifier: str, purpose: str) -> int:
        key = (identifier.strip().lower(), purpose.strip().lower())
        now = time.time()
        with self._lock:
            entry = self._failed_attempts.get(key)
            if not entry or (now - entry["last_attempt"] > ATTEMPT_WINDOW_SECONDS):
                return 0
            return entry["attempts"]

    def clear_failed_attempts(self, identifier: str, purpose: str) -> None:
        key = (identifier.strip().lower(), purpose.strip().lower())
        with self._lock:
            self._failed_attempts.pop(key, None)


class RedisOTPAttemptStore(BaseOTPAttemptStore):
    """
    Distributed OTP attempt store backed by Redis.
    Uses atomic INCR and TTL expiration to enforce attempts across multiple worker processes.
    """
    def __init__(self, redis_client):
        self._client = redis_client

    def _make_key(self, identifier: str, purpose: str) -> str:
        clean_id = identifier.strip().lower()
        clean_purp = purpose.strip().lower()
        return f"otp_attempts:{clean_purp}:{clean_id}"

    def record_failed_attempt(self, identifier: str, purpose: str) -> int:
        key = self._make_key(identifier, purpose)
        val = self._client.incr(key)
        if val == 1:
            self._client.expire(key, ATTEMPT_WINDOW_SECONDS)
        return int(val)

    def get_failed_attempts(self, identifier: str, purpose: str) -> int:
        key = self._make_key(identifier, purpose)
        val = self._client.get(key)
        return int(val) if val is not None else 0

    def clear_failed_attempts(self, identifier: str, purpose: str) -> None:
        key = self._make_key(identifier, purpose)
        self._client.delete(key)


class ResilientOTPAttemptStore(BaseOTPAttemptStore):
    """
    Resilient OTP Attempt Store that attempts distributed shared storage first,
    and falls back safely to in-memory tracking upon storage disconnection or error.
    CRITICAL: Outages never silently disable lockout protections!
    """
    def __init__(self, primary_store: Optional[BaseOTPAttemptStore], fallback_store: BaseOTPAttemptStore):
        self.primary_store = primary_store
        self.fallback_store = fallback_store

    def record_failed_attempt(self, identifier: str, purpose: str) -> int:
        if self.primary_store:
            try:
                return self.primary_store.record_failed_attempt(identifier, purpose)
            except Exception as e:
                logger.warning(
                    "[OTP SECURITY WARNING] Primary OTP storage error during record_failed_attempt: %s. "
                    "Engaging fallback in-memory enforcement.", e
                )
        return self.fallback_store.record_failed_attempt(identifier, purpose)

    def get_failed_attempts(self, identifier: str, purpose: str) -> int:
        if self.primary_store:
            try:
                return self.primary_store.get_failed_attempts(identifier, purpose)
            except Exception as e:
                logger.warning(
                    "[OTP SECURITY WARNING] Primary OTP storage error during get_failed_attempts: %s. "
                    "Querying fallback in-memory enforcement.", e
                )
        return self.fallback_store.get_failed_attempts(identifier, purpose)

    def clear_failed_attempts(self, identifier: str, purpose: str) -> None:
        if self.primary_store:
            try:
                self.primary_store.clear_failed_attempts(identifier, purpose)
            except Exception as e:
                logger.warning("[OTP SECURITY WARNING] Primary OTP storage error during clear_failed_attempts: %s.", e)
        self.fallback_store.clear_failed_attempts(identifier, purpose)


def init_otp_attempt_store() -> BaseOTPAttemptStore:
    memory_store = MemoryOTPAttemptStore()
    storage_url = os.getenv("OTP_STORAGE_URL") or os.getenv("RATE_LIMIT_STORAGE_URL") or os.getenv("REDIS_URL")

    if storage_url and (storage_url.startswith("redis://") or storage_url.startswith("rediss://")):
        try:
            import redis
            masked = re.sub(r'(://[^:]+:)([^@]+)(@)', r'\1***\3', storage_url)
            logger.info("Connecting to distributed OTP attempt storage at %s", masked)
            client = redis.from_url(storage_url, decode_responses=True, socket_connect_timeout=2.0)
            client.ping()
            return ResilientOTPAttemptStore(primary_store=RedisOTPAttemptStore(client), fallback_store=memory_store)
        except Exception as e:
            logger.warning("Could not initialize distributed Redis OTP store (%s). Using fallback in-memory store.", e)
            return ResilientOTPAttemptStore(primary_store=None, fallback_store=memory_store)

    return ResilientOTPAttemptStore(primary_store=None, fallback_store=memory_store)


_otp_store = init_otp_attempt_store()


def record_failed_attempt(identifier: str, purpose: str) -> int:
    return _otp_store.record_failed_attempt(identifier, purpose)


def get_failed_attempts(identifier: str, purpose: str) -> int:
    return _otp_store.get_failed_attempts(identifier, purpose)


def clear_failed_attempts(identifier: str, purpose: str) -> None:
    _otp_store.clear_failed_attempts(identifier, purpose)


def generate_secure_otp() -> str:
    """
    Generates a cryptographically secure 6-digit numeric OTP code (100000 - 999999).
    Uses Python's secrets module (CSPRNG) to prevent predictable pseudorandom generation.
    """
    return f"{secrets.randbelow(900000) + 100000}"


def is_test_otp_allowed() -> bool:
    """
    Returns True ONLY when explicitly enabled via TEST_OTP_ENABLED=true
    AND when the running environment is strictly NOT production.
    In production (ENV or ENVIRONMENT in 'production', 'prod', 'live'),
    test OTP bypass is unconditionally forbidden.
    """
    env = (os.getenv("ENV") or os.getenv("ENVIRONMENT") or "development").strip().lower()
    if env in ("production", "prod", "live"):
        return False

    test_flag = os.getenv("TEST_OTP_ENABLED", "false").strip().lower()
    return test_flag in ("true", "1", "yes")


def validate_and_verify_otp(
    db: Session,
    otp_model,
    identifier: str,
    purpose: str,
    submitted_code: str,
    mark_used: bool = False
):
    """
    Strictly validates and verifies an OTP submission.
    
    Enforces:
    1. Attempt-limit check: rejects if max attempts reached.
    2. Record existence: an active OTP record MUST exist in the database.
       Hardcoded OTP values (e.g. 123456) independently of a valid record are rejected.
    3. Single-use enforcement: rejects previously used OTP records.
    4. Expiry enforcement: rejects expired OTP records.
    5. Constant-time comparison: compares submitted code against stored code using secrets.compare_digest.
    6. Test mode restriction: 123456 is accepted ONLY if TEST_OTP_ENABLED=true,
       ENV != production, and a valid unused, unexpired record exists in the database.
    7. Brute-force lockout: after MAX_OTP_ATTEMPTS failed attempts, the OTP is invalidated.
    8. Zero secret logging.
    
    Returns the matching valid OTP record if successful, or raises HTTPException on failure.
    """
    clean_identifier = identifier.strip().lower()
    clean_code = str(submitted_code).strip()

    # 1. Check attempt limit
    current_failures = get_failed_attempts(clean_identifier, purpose)
    if current_failures >= MAX_OTP_ATTEMPTS:
        raise HTTPException(
            status_code=400,
            detail="Too many failed attempts. This OTP code has been invalidated. Please request a new code."
        )

    # 2. Query the latest OTP entry
    otp_entry = db.query(otp_model).filter(
        otp_model.identifier == clean_identifier,
        otp_model.purpose == purpose
    ).order_by(otp_model.id.desc()).first()

    # 3. If no record exists, record failed attempt and reject
    if not otp_entry:
        record_failed_attempt(clean_identifier, purpose)
        raise HTTPException(status_code=400, detail="Invalid OTP code.")

    # 4. Enforce single-use
    if otp_entry.used:
        raise HTTPException(status_code=400, detail="This OTP code has already been used.")

    # 5. Enforce expiry
    if otp_entry.expires_at < datetime.datetime.utcnow():
        raise HTTPException(status_code=400, detail="This OTP code has expired.")

    # 6. Verify code matching
    code_matches = False
    test_allowed = is_test_otp_allowed()

    if test_allowed and clean_code == "123456":
        code_matches = True
    elif secrets.compare_digest(str(otp_entry.code), clean_code):
        code_matches = True

    if not code_matches:
        attempts = record_failed_attempt(clean_identifier, purpose)
        if attempts >= MAX_OTP_ATTEMPTS:
            otp_entry.used = True
            db.commit()
            raise HTTPException(
                status_code=400,
                detail="Too many failed attempts. This OTP code has been invalidated. Please request a new code."
            )
        raise HTTPException(status_code=400, detail="Invalid OTP code.")

    # 7. Verification succeeded: clear failures and optionally mark used
    clear_failed_attempts(clean_identifier, purpose)
    if mark_used:
        otp_entry.used = True
        db.commit()

    return otp_entry
