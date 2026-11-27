import os
import pytest
from starlette.testclient import TestClient
from jose import jwt
import datetime

# Ensure test environment
os.environ["TESTING"] = "true"
os.environ["ENV"] = "development"

from app.main import app
from app.core.database import Base
from app.api.auth import get_db
from app.core.cors_config import (
    resolve_cors_configuration,
    is_websocket_origin_allowed,
    PROD_ORIGIN_REGEX,
    DEV_ORIGIN_REGEX,
)
from app.core.security import SECRET_KEY, ALGORITHM
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

TEST_DB_PATH = "scratch/disposable_test_phase20_56.db"
test_engine = create_engine(f"sqlite:///{TEST_DB_PATH}", connect_args={"check_same_thread": False})
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass
    Base.metadata.create_all(bind=test_engine)
    yield
    test_engine.dispose()
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass


def override_get_db():
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def client():
    app.dependency_overrides[get_db] = override_get_db
    c = TestClient(app, raise_server_exceptions=False)
    yield c
    app.dependency_overrides.pop(get_db, None)


# ==============================================================================
# 1. CORS Configuration & Regex Security Tests
# ==============================================================================

def test_cors_prod_regex_security():
    """Verify production regex rejects attack patterns and only accepts legitimate domains."""
    import re
    # Valid domains
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://libriflow.app") is not None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://www.libriflow.app") is not None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://api.libriflow.app") is not None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://staging.app.libriflow.app") is not None

    # Invalid / Attack patterns that bypassed previous unanchored regex
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://evil-libriflow.app") is None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://notlibriflow.app") is None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "http://libriflow.app") is None  # Insecure HTTP rejected
    assert re.fullmatch(PROD_ORIGIN_REGEX, "https://libriflow.app.evil.com") is None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "http://localhost:3000") is None
    assert re.fullmatch(PROD_ORIGIN_REGEX, "http://192.168.1.1:8000") is None


def test_cors_dev_regex_acceptance():
    """Verify development regex accepts dev IPs and rejects foreign origins."""
    import re
    # Valid dev origins
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://localhost") is not None
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://localhost:3000") is not None
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://127.0.0.1:8000") is not None
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://192.168.1.50:8080") is not None
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://10.0.2.2:8000") is not None

    # Invalid origins
    assert re.fullmatch(DEV_ORIGIN_REGEX, "http://evil.com") is None
    assert re.fullmatch(DEV_ORIGIN_REGEX, "https://malicious-site.org:8000") is None


def test_cors_resolution_by_environment(monkeypatch):
    """Verify resolve_cors_configuration reacts properly to ENV setting."""
    monkeypatch.setenv("ENV", "production")
    monkeypatch.delenv("ALLOWED_ORIGINS", raising=False)
    prod_origins, prod_regex = resolve_cors_configuration()
    assert "https://libriflow.app" in prod_origins
    assert prod_regex == PROD_ORIGIN_REGEX
    assert "http://localhost" not in prod_origins

    monkeypatch.setenv("ENV", "development")
    dev_origins, dev_regex = resolve_cors_configuration()
    assert "http://localhost" in dev_origins
    assert dev_regex == DEV_ORIGIN_REGEX


# ==============================================================================
# 2. HTTP CORS Headers & OPTIONS Preflight Tests
# ==============================================================================

def test_cors_options_preflight_allowed_origin(client):
    """Options preflight from allowed origin must receive appropriate CORS headers."""
    headers = {
        "Origin": "https://libriflow.app",
        "Access-Control-Request-Method": "GET",
        "Access-Control-Request-Headers": "Authorization,Content-Type",
    }
    response = client.options("/", headers=headers)
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == "https://libriflow.app"
    assert response.headers.get("access-control-allow-credentials") == "true"


def test_cors_options_preflight_rejected_origin(client):
    """Options preflight from unauthorized origin must NOT receive access-control-allow-origin."""
    headers = {
        "Origin": "https://evil-attacker.com",
        "Access-Control-Request-Method": "GET",
    }
    response = client.options("/", headers=headers)
    assert "access-control-allow-origin" not in response.headers


# ==============================================================================
# 3. Global Exception Handler & Correlation ID Tests
# ==============================================================================

def test_request_id_in_normal_response(client):
    """Regular responses should include an X-Request-ID header."""
    response = client.get("/")
    assert response.status_code == 200
    req_id = response.headers.get("X-Request-ID")
    assert req_id is not None
    assert len(req_id) > 10


def test_request_id_propagates_custom_header(client):
    """Client-provided X-Request-ID should be preserved across processing."""
    custom_id = "test-custom-correlation-id-998877"
    response = client.get("/", headers={"X-Request-ID": custom_id})
    assert response.status_code == 200
    assert response.headers.get("X-Request-ID") == custom_id


def test_global_exception_handler_sanitized_500_with_cors(client):
    """
    When an unhandled exception occurs:
    1. Returns HTTP 500 status code.
    2. Response body is structured JSON with request_id and generic message.
    3. Contains NO internal stack trace or raw exception strings.
    4. Preserves CORS headers for allowed origins.
    5. Includes X-Request-ID response header.
    """
    # Define route if not present
    if not any(getattr(r, "path", None) == "/test-unhandled-exception-for-phase20-56" for r in app.routes):
        @app.get("/test-unhandled-exception-for-phase20-56")
        def trigger_crash():
            raise RuntimeError("SIMULATED_INTERNAL_DATABASE_OR_SECRET_CRASH_XYZ123")

    origin = "https://libriflow.app"
    response = client.get(
        "/test-unhandled-exception-for-phase20-56",
        headers={"Origin": origin, "X-Request-ID": "test-crash-id-001"}
    )
    assert response.status_code == 500
    data = response.json()
    assert data.get("error") == "Internal Server Error"
    assert "SIMULATED_INTERNAL_DATABASE_OR_SECRET_CRASH_XYZ123" not in str(data)
    assert data.get("request_id") == "test-crash-id-001"
    assert response.headers.get("X-Request-ID") == "test-crash-id-001"
    # Verify CORS headers are preserved on 500 responses
    assert response.headers.get("access-control-allow-origin") == origin


# ==============================================================================
# 4. WebSocket Origin Validation & Security Tests
# ==============================================================================

def test_websocket_origin_validation_logic(monkeypatch):
    """Directly test websocket origin validation logic."""
    monkeypatch.setenv("ENV", "production")
    monkeypatch.delenv("ALLOWED_ORIGINS", raising=False)

    # Allowed in production
    assert is_websocket_origin_allowed("https://libriflow.app") is True
    assert is_websocket_origin_allowed("https://www.libriflow.app") is True
    assert is_websocket_origin_allowed(None) is True  # Native app without origin
    assert is_websocket_origin_allowed("") is True    # Native app empty origin

    # Blocked in production
    assert is_websocket_origin_allowed("https://evil-libriflow.app") is False
    assert is_websocket_origin_allowed("https://evil.com") is False
    assert is_websocket_origin_allowed("http://localhost:3000") is False


def test_websocket_rejects_unauthorized_origin(client):
    """WebSocket connection with unauthorized Origin must be closed with WS_1008_POLICY_VIOLATION."""
    from starlette.websockets import WebSocketDisconnect
    with pytest.raises(WebSocketDisconnect) as excinfo:
        with client.websocket_connect(
            "/ws/chat/1",
            headers={"Origin": "https://evil-attacker.com"}
        ):
            pass
    # Starlette raises WebSocketDisconnect with code=1008
    assert excinfo.value.code == 1008


def test_websocket_rejects_refresh_token(client):
    """WebSocket connection with refresh token (type != 'access') must be rejected."""
    refresh_token = jwt.encode(
        {"sub": "test@example.com", "type": "refresh", "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)},
        SECRET_KEY,
        algorithm=ALGORITHM
    )
    from starlette.websockets import WebSocketDisconnect
    with pytest.raises(WebSocketDisconnect) as excinfo:
        with client.websocket_connect(
            "/ws/chat/1",
            headers={"Authorization": f"Bearer {refresh_token}", "Origin": "https://libriflow.app"}
        ):
            pass
    assert excinfo.value.code == 1008


# ==============================================================================
# 5. Sensitive Error Leakage Remediation Tests
# ==============================================================================

def test_forgot_password_uniform_response(client):
    """Forgot password for non-existent account returns uniform 200 without leaking account status."""
    response = client.post("/auth/forgot-password", json={"email": "nonexistent_security_user_99@libriflow.test"})
    assert response.status_code == 200
    assert response.json() == {"message": "If an account exists, a password reset link has been sent."}


def test_newsletter_sanitized_500_response(client, monkeypatch):
    """Newsletter subscription error returns sanitized generic 500 without leaking internal exception."""
    from fastapi import BackgroundTasks

    def broken_add_task(*args, **kwargs):
        raise RuntimeError("CRITICAL_INTERNAL_SMTP_CREDENTIAL_FAILURE_LEAK_XYZ")

    monkeypatch.setattr(BackgroundTasks, "add_task", broken_add_task)

    res = client.post("/newsletter/subscribe", json={"email": "newsletter_subscriber@example.com"})
    assert res.status_code == 500
    assert "CRITICAL_INTERNAL_SMTP_CREDENTIAL_FAILURE_LEAK_XYZ" not in res.text
    assert res.json().get("detail") == "Unable to process newsletter subscription at this time. Please try again later."
