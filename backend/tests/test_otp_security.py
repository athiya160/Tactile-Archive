import os
import sys
import datetime
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from app.core.database import Base
from app.models.user import User
from app.models.otp_code import OTPCode
from app.api.auth import get_db, hash_password
from app.core.otp import (
    generate_secure_otp,
    is_test_otp_allowed,
    clear_failed_attempts,
    MAX_OTP_ATTEMPTS
)
from app.core.sms import send_otp_sms, mask_phone

# Isolated disposable test database in scratch/
TEST_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scratch", "disposable_otp_test.db"))
TEST_DB_URL = f"sqlite:///{TEST_DB_PATH.replace(os.sep, '/')}"

test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    # Ensure scratch dir exists
    os.makedirs(os.path.dirname(TEST_DB_PATH), exist_ok=True)
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass

    Base.metadata.create_all(bind=test_engine)
    yield
    # Cleanup after test suite
    test_engine.dispose()
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass


@pytest.fixture
def db():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(get_db, None)


def test_hardcoded_otp_rejected_without_record(client, db):
    """
    Requirement 2 & 8: Hardcoded OTP 123456 must be rejected when no OTP record exists.
    """
    identifier = "no_record_user@example.com"
    clear_failed_attempts(identifier, "login_otp")
    clear_failed_attempts(identifier, "password_reset")

    # Login OTP attempt
    res_login = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "123456"
    })
    assert res_login.status_code == 400
    assert "Invalid OTP code" in res_login.json()["detail"]

    # Verify Reset OTP attempt
    res_reset = client.post("/auth/verify-otp-reset", json={
        "identifier": identifier,
        "otp_code": "123456",
        "new_password": "NewSecurePassword123!"
    })
    assert res_reset.status_code == 400
    assert "Invalid OTP code" in res_reset.json()["detail"]


def test_hardcoded_otp_rejected_with_active_record_in_normal_mode(client, db, monkeypatch):
    """
    Requirement 2 & 8: In normal mode (TEST_OTP_ENABLED=false), 123456 must be rejected
    even if an active unexpired OTP record exists with a different code.
    """
    monkeypatch.setenv("ENV", "development")
    monkeypatch.delenv("TEST_OTP_ENABLED", raising=False)

    identifier = "active_otp_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    # Create active OTP record with genuine code
    otp = OTPCode(
        identifier=identifier,
        code="987654",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    # Attempt login with 123456 bypass
    res = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "123456"
    })
    assert res.status_code == 400
    assert "Invalid OTP code" in res.json()["detail"]

    # Record must still be unused
    db.refresh(otp)
    assert otp.used is False


def test_valid_otp_accepted(client, db):
    """
    Requirement 4 & 8: Valid OTP matching the database record must be accepted,
    issue an access token, and mark the record used.
    """
    identifier = "valid_otp_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="654321",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    res = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "654321"
    })
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

    # Confirm OTP marked used
    db.refresh(otp)
    assert otp.used is True


def test_expired_otp_rejected(client, db):
    """
    Requirement 5 & 8: Expired OTP code must be rejected with 400.
    """
    identifier = "expired_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="333444",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() - datetime.timedelta(seconds=10),
        used=False
    )
    db.add(otp)
    db.commit()

    res = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "333444"
    })
    assert res.status_code == 400
    assert "expired" in res.json()["detail"].lower()


def test_incorrect_otp_rejected(client, db):
    """
    Requirement 5 & 8: Incorrect OTP code must be rejected with 400 Invalid OTP code.
    """
    identifier = "incorrect_code_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="777888",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    res = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "111222"
    })
    assert res.status_code == 400
    assert "Invalid OTP code" in res.json()["detail"]


def test_otp_reuse_rejected(client, db):
    """
    Requirement 5 & 8: Once consumed, reusing an OTP code must be rejected.
    """
    identifier = "reuse_test_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="555666",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    # First use: success
    res1 = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "555666"
    })
    assert res1.status_code == 200

    # Second use: rejected
    res2 = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "555666"
    })
    assert res2.status_code == 400
    assert "already been used" in res2.json()["detail"].lower()


def test_attempt_limit_enforcement(client, db):
    """
    Requirement 5 & 8: Consecutive failed attempts must hit attempt limit (5 attempts),
    invalidate the OTP record, and reject subsequent attempts.
    """
    identifier = "bruteforce_target@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="890123",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    # Attempts 1 to 4: rejected with "Invalid OTP code"
    for i in range(1, MAX_OTP_ATTEMPTS):
        res = client.post("/auth/login-otp", json={
            "identifier": identifier,
            "otp_code": f"00000{i}"
        })
        assert res.status_code == 400
        assert "Invalid OTP code" in res.json()["detail"]

    # 5th attempt: triggers attempt limit lockout and invalidates code
    res_lockout = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "000005"
    })
    assert res_lockout.status_code == 400
    assert "Too many failed attempts" in res_lockout.json()["detail"]

    # Verify the OTP record was invalidated (used=True)
    db.refresh(otp)
    assert otp.used is True

    # Even submitting the correct code now must be blocked by attempt lockout
    res_correct_after_lockout = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "890123"
    })
    assert res_correct_after_lockout.status_code == 400
    assert "Too many failed attempts" in res_correct_after_lockout.json()["detail"]


def test_production_configuration_refuses_test_bypasses(client, db, monkeypatch):
    """
    Requirement 6 & 8: In production (ENV=production), test OTP bypass must be
    strictly refused even if TEST_OTP_ENABLED=true is present in the environment.
    """
    monkeypatch.setenv("ENV", "production")
    monkeypatch.setenv("TEST_OTP_ENABLED", "true")

    # Confirm is_test_otp_allowed() returns False
    assert is_test_otp_allowed() is False

    identifier = "prod_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    otp = OTPCode(
        identifier=identifier,
        code="456789",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    # Attempt bypass with 123456 in production
    res = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "123456"
    })
    assert res.status_code == 400
    assert "Invalid OTP code" in res.json()["detail"]


def test_test_configuration_allows_test_code_only_with_valid_record(client, db, monkeypatch):
    """
    Requirement 6: In test mode with explicit TEST_OTP_ENABLED=true and non-production ENV,
    test code 123456 is allowed ONLY if a valid unexpired, unused record exists.
    """
    monkeypatch.setenv("ENV", "test")
    monkeypatch.setenv("TEST_OTP_ENABLED", "true")

    assert is_test_otp_allowed() is True

    identifier = "test_mode_user@example.com"
    clear_failed_attempts(identifier, "login_otp")

    # 1. Without record: 123456 is still rejected!
    res_no_rec = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "123456"
    })
    assert res_no_rec.status_code == 400
    assert "Invalid OTP code" in res_no_rec.json()["detail"]

    # 2. With valid active record: 123456 is accepted and marks record used
    otp = OTPCode(
        identifier=identifier,
        code="999111",
        purpose="login_otp",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    res_with_rec = client.post("/auth/login-otp", json={
        "identifier": identifier,
        "otp_code": "123456"
    })
    assert res_with_rec.status_code == 200
    assert "access_token" in res_with_rec.json()

    db.refresh(otp)
    assert otp.used is True


def test_otp_generation_uses_secrets():
    """
    Requirement 3: OTP generation must use Python's secrets module and yield 6-digit numeric strings.
    """
    codes = set()
    for _ in range(50):
        code = generate_secure_otp()
        assert len(code) == 6
        assert code.isdigit()
        val = int(code)
        assert 100000 <= val <= 999999
        codes.add(code)

    # Cryptographic CSPRNG must produce high entropy (distinct values across 50 samples)
    assert len(codes) >= 48


def test_zero_secret_logging_in_sms(caplog):
    """
    Requirement 7: SMS dispatch must never log raw OTP codes and must mask phone numbers.
    """
    import logging
    secret_code = "789123"
    test_phone = "+919876543210"

    with caplog.at_level(logging.INFO, logger="app.core.sms"):
        send_otp_sms(test_phone, secret_code, "Login")

    # Verify secret_code is NOT present in any log record
    log_text = caplog.text
    assert secret_code not in log_text
    assert "+919876543210" not in log_text  # Phone number must be masked
    assert "****" in log_text  # Masking indicator


def test_prod_env_variants_refuse_test_otp(monkeypatch):
    """
    Requirement 6 & 8: Verify that all production environment variants
    (ENV=prod, ENV=live, ENVIRONMENT=production, ENVIRONMENT=prod)
    unconditionally refuse test OTP bypass even if TEST_OTP_ENABLED=true.
    """
    for env_var, env_val in [
        ("ENV", "production"),
        ("ENV", "prod"),
        ("ENV", "live"),
        ("ENVIRONMENT", "production"),
        ("ENVIRONMENT", "prod"),
        ("ENVIRONMENT", "live"),
    ]:
        monkeypatch.delenv("ENV", raising=False)
        monkeypatch.delenv("ENVIRONMENT", raising=False)
        monkeypatch.setenv(env_var, env_val)
        monkeypatch.setenv("TEST_OTP_ENABLED", "true")
        assert is_test_otp_allowed() is False, f"Failed for {env_var}={env_val}"


def test_zero_secret_logging_in_email(caplog):
    """
    Requirement 7: Email dispatch must never log raw OTP codes in application logs.
    """
    import logging
    from app.core.mail import send_otp_email

    secret_code = "842615"
    test_email = "secret_otp_receiver@example.com"

    with caplog.at_level(logging.INFO, logger="app.core.mail"):
        send_otp_email(test_email, secret_code, "Password Reset")

    log_text = caplog.text
    assert secret_code not in log_text
    assert test_email not in log_text  # Email must be masked in log
    assert "@example.com" in log_text
    assert "*" in log_text


def test_verify_otp_reset_flow_and_reuse_rejection(client, db):
    """
    Requirement 4, 5 & 8: Verify complete OTP password reset flow:
    - User exists
    - Valid OTP submitted with valid new password -> password updated
    - OTP marked used
    - Second attempt to reset password using same OTP code is rejected (single-use)
    """
    identifier = "reset_flow_user@example.com"
    clear_failed_attempts(identifier, "password_reset")

    # Create user in db
    user = User(
        email=identifier,
        password=hash_password("OldPassword123!"),
        name="Reset Flow User",
        is_verified=True,
        role="customer",
        user_type="reader"
    )
    db.add(user)
    db.commit()

    otp = OTPCode(
        identifier=identifier,
        code="619283",
        purpose="password_reset",
        expires_at=datetime.datetime.utcnow() + datetime.timedelta(minutes=10),
        used=False
    )
    db.add(otp)
    db.commit()

    # Step 1: Successful password reset
    res = client.post("/auth/verify-otp-reset", json={
        "identifier": identifier,
        "otp_code": "619283",
        "new_password": "NewStrongPassword456!"
    })
    assert res.status_code == 200
    assert "successfully" in res.json()["message"].lower()

    # Verify OTP marked used
    db.refresh(otp)
    assert otp.used is True

    # Verify user password updated
    db.refresh(user)
    from app.api.auth import verify_password
    assert verify_password("NewStrongPassword456!", user.password) is True

    # Step 2: Attempt reuse of same OTP code -> must be rejected
    res_reuse = client.post("/auth/verify-otp-reset", json={
        "identifier": identifier,
        "otp_code": "619283",
        "new_password": "AnotherNewPassword789!"
    })
    assert res_reuse.status_code == 400
    assert "already been used" in res_reuse.json()["detail"].lower()

