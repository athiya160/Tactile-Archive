import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from app.core.security import create_access_token
from app.core.database import Base
from app.api.auth import get_db
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DISPOSABLE_HEADERS_DB = "scratch/disposable_test_http_headers.db"
headers_test_engine = create_engine(f"sqlite:///{DISPOSABLE_HEADERS_DB}", connect_args={"check_same_thread": False})
HeadersTestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=headers_test_engine)


@pytest.fixture(scope="module", autouse=True)
def setup_headers_db():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(DISPOSABLE_HEADERS_DB):
        try:
            os.remove(DISPOSABLE_HEADERS_DB)
        except Exception:
            pass
    Base.metadata.create_all(bind=headers_test_engine)
    def override_get_db():
        session = HeadersTestSessionLocal()
        try:
            yield session
        finally:
            session.close()
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.pop(get_db, None)
    headers_test_engine.dispose()
    if os.path.exists(DISPOSABLE_HEADERS_DB):
        try:
            os.remove(DISPOSABLE_HEADERS_DB)
        except Exception:
            pass


@pytest.fixture
def client():
    with TestClient(app) as test_client:
        yield test_client


# ─── 1. CORE HEADERS PRESENCE ON ROOT & JSON API ROUTES ─────────────────────

def test_security_headers_on_root_endpoint(client):
    """Verify all core security headers are present on successful root GET."""
    res = client.get("/")
    assert res.status_code == 200
    headers = res.headers

    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"
    assert "default-src 'self'" in headers.get("Content-Security-Policy", "")
    assert "frame-ancestors 'none'" in headers.get("Content-Security-Policy", "")


def test_security_headers_on_json_api_routes(client):
    """Verify security headers are applied to JSON API endpoints."""
    res = client.get("/")
    assert res.status_code == 200
    assert "application/json" in res.headers.get("content-type", "")
    headers = res.headers

    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"
    assert "Content-Security-Policy" in headers


# ─── 2. HEADERS ON HTML PAGES ────────────────────────────────────────────────

def test_security_headers_on_html_endpoints(client):
    """Verify headers on server-rendered HTML pages (privacy policy & reset password)."""
    # Privacy Policy
    res_privacy = client.get("/privacy-policy")
    assert res_privacy.status_code == 200
    assert "text/html" in res_privacy.headers.get("content-type", "")
    assert res_privacy.headers.get("X-Content-Type-Options") == "nosniff"
    assert res_privacy.headers.get("X-Frame-Options") == "DENY"
    assert res_privacy.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert res_privacy.headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"

    # CSP must permit inline scripts/styles used by HTML forms
    csp = res_privacy.headers.get("Content-Security-Policy", "")
    assert "'unsafe-inline'" in csp
    assert "frame-ancestors 'none'" in csp


# ─── 3. HEADERS APPLIED CONSISTENTLY ON ERROR RESPONSES ──────────────────────

def test_security_headers_on_404_not_found(client):
    """Requirement 4: 404 error responses must carry all security headers."""
    res = client.get("/api/v1/nonexistent-route-for-testing-headers-404")
    assert res.status_code == 404
    headers = res.headers

    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"
    assert "Content-Security-Policy" in headers


def test_security_headers_on_400_bad_request(client):
    """Requirement 4: 400 Bad Request responses must carry all security headers."""
    res = client.post("/auth/login-otp", json={})
    assert res.status_code == 400
    headers = res.headers

    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"
    assert "Content-Security-Policy" in headers


def test_security_headers_on_401_unauthorized(client):
    """Requirement 4: 401 Unauthorized responses must carry all security headers."""
    res = client.get("/profile")
    assert res.status_code in (401, 403)
    headers = res.headers

    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert headers.get("Permissions-Policy") == "camera=(), microphone=(), geolocation=()"
    assert "Content-Security-Policy" in headers


# ─── 4. STRICT-TRANSPORT-SECURITY (HSTS) CONDITIONAL INJECTION ───────────────

def test_hsts_omitted_on_plain_http_request(client):
    """Requirement 3: Strict-Transport-Security must NOT be sent over plain HTTP (RFC 6797)."""
    res = client.get("/")
    assert res.status_code == 200
    assert "Strict-Transport-Security" not in res.headers


def test_hsts_injected_when_forwarded_over_https(client, monkeypatch):
    """Requirement 3: Strict-Transport-Security must be sent when HTTPS proxy termination is detected from a trusted proxy."""
    import app.core.proxy_security as ps
    monkeypatch.setenv("TRUSTED_PROXIES", "testclient")
    ps._CACHED_CONFIG_RAW = None

    res = client.get("/", headers={"x-forwarded-proto": "https"})
    assert res.status_code == 200
    hsts = res.headers.get("Strict-Transport-Security")
    assert hsts is not None
    assert "max-age=31536000" in hsts
    assert "includeSubDomains" in hsts


# ─── 5. CORS PREFLIGHT INTERACTION ───────────────────────────────────────────

def test_cors_preflight_coexistence(client):
    """Verify CORS preflight OPTIONS requests carry both CORS and security headers."""
    res = client.options(
        "/books",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "Authorization,Content-Type",
        }
    )
    assert res.status_code == 200
    headers = res.headers

    # CORS headers
    assert "access-control-allow-origin" in headers
    # Security headers
    assert headers.get("X-Content-Type-Options") == "nosniff"
    assert headers.get("X-Frame-Options") == "DENY"
    assert headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"


# ─── 6. WEBSOCKET HANDSHAKE SAFETY ───────────────────────────────────────────

@pytest.mark.asyncio
async def test_websocket_scope_bypasses_security_headers_middleware():
    """Requirement 5: Non-HTTP scopes (such as websocket) must be passed directly to downstream app."""
    from app.core.security_headers import SecurityHeadersMiddleware

    called = False

    async def dummy_ws_app(scope, receive, send):
        nonlocal called
        called = True
        assert scope["type"] == "websocket"
        assert scope["path"] == "/ws/test"

    middleware = SecurityHeadersMiddleware(dummy_ws_app)
    ws_scope = {
        "type": "websocket",
        "path": "/ws/test",
        "headers": [(b"sec-websocket-key", b"testkey")]
    }

    await middleware(ws_scope, None, None)
    assert called is True


def test_websocket_endpoint_reachable_through_middleware(client):
    """Requirement 5: TestClient connecting to WebSocket endpoint successfully executes handshake logic."""
    from starlette.websockets import WebSocketDisconnect

    # Connect to WebSocket route; confirms the WebSocket route is reached through middleware
    # and properly handled by the chat security handler (closing with policy violation 1008).
    with pytest.raises(WebSocketDisconnect) as exc_info:
        with client.websocket_connect("/ws/chat/999999", headers={"Authorization": "Bearer invalid.token"}):
            pass
    assert exc_info.value.code == 1008
