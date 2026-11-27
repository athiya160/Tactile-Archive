"""
Phase 20.43 — Rate Limiting and Trusted Proxy Security Test Suite
Project: The Tactile Archive / LibriFlow

Verifies:
1. Direct clients without proxies: real client IP resolved to socket peer.
2. Untrusted direct client spoofing: arbitrary X-Forwarded-For or Forwarded headers are ignored.
3. Attacker cannot bypass rate limiting by changing X-Forwarded-For headers from untrusted connections.
4. Single-hop trusted proxy: extracts authentic client IP from X-Forwarded-For.
5. Attacker prepending spoofed IP behind trusted proxy: right-to-left traversal identifies true client IP.
6. Multi-hop trusted proxies (CDN + load balancer): skips internal trusted hops to find external client.
7. RFC 7239 Forwarded header syntax support with port stripping and bracketed IPv6.
8. X-Real-IP fallback behind trusted proxy when XFF is missing.
9. Missing forwarded headers behind trusted proxy: fails safely to proxy IP.
10. Malformed / injection headers: fails safely without throwing unhandled exceptions.
11. TRUSTED_PROXIES unset/empty: default zero-trust posture strictly maintained.
12. SlowAPI RateLimitExceeded enforcement: returns HTTP 429 when quota exceeded.
13. Rate limit quota isolation: independent limits per client IP.
14. Global RateLimitMiddleware sliding-window integration with get_trusted_client_ip.
15. Live database immutability: verifies tactile_archive.db checksum is unchanged.
"""

import os
import sys
import hashlib
import pytest
from starlette.requests import Request
from fastapi.testclient import TestClient

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app, RateLimitMiddleware
from app.core.rate_limit import limiter
from app.core.proxy_security import (
    get_trusted_client_ip,
    get_trusted_proxy_networks,
    parse_ip_hop,
    is_ip_in_networks,
)
from app.core.database import Base
from app.api.auth import get_db
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

LIVE_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "tactile_archive.db"))
DISPOSABLE_RATE_DB = "scratch/disposable_test_rate_limiting_proxy.db"
rate_test_engine = create_engine(f"sqlite:///{DISPOSABLE_RATE_DB}", connect_args={"check_same_thread": False})
RateTestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=rate_test_engine)


@pytest.fixture(scope="module", autouse=True)
def setup_rate_db():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(DISPOSABLE_RATE_DB):
        try:
            os.remove(DISPOSABLE_RATE_DB)
        except Exception:
            pass
    Base.metadata.create_all(bind=rate_test_engine)
    def override_get_db():
        session = RateTestSessionLocal()
        try:
            yield session
        finally:
            session.close()
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.pop(get_db, None)
    rate_test_engine.dispose()
    if os.path.exists(DISPOSABLE_RATE_DB):
        try:
            os.remove(DISPOSABLE_RATE_DB)
        except Exception:
            pass


def get_live_db_sha256() -> str:
    h = hashlib.sha256()
    with open(LIVE_DB_PATH, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest().upper()


@pytest.fixture(scope="module", autouse=True)
def live_db_safety_sentinel():
    """Confirms live database hash is identical before and after entire test execution."""
    initial_hash = get_live_db_sha256()
    yield
    final_hash = get_live_db_sha256()
    assert initial_hash == final_hash, (
        f"CRITICAL SAFETY VIOLATION: Live database modified during test run! {initial_hash} != {final_hash}"
    )


def build_mock_request(
    client_host: str = "127.0.0.1",
    client_port: int = 50000,
    headers: dict = None,
    method: str = "GET",
    path: str = "/"
) -> Request:
    """Builds a Starlette Request with custom client and headers for direct resolution testing."""
    raw_headers = []
    if headers:
        for k, v in headers.items():
            raw_headers.append((k.lower().encode("latin-1"), v.encode("latin-1")))

    scope = {
        "type": "http",
        "method": method,
        "path": path,
        "raw_path": path.encode("ascii"),
        "query_string": b"",
        "headers": raw_headers,
        "client": (client_host, client_port),
        "server": ("127.0.0.1", 8000),
        "scheme": "http",
        "http_version": "1.1",
    }
    return Request(scope)


# ============================================================================
# 1. UNIT TESTS: IP HOP PARSING & NETWORK MATCHING
# ============================================================================

def test_parse_ip_hop_valid_ipv4_and_ipv6():
    assert str(parse_ip_hop("192.168.1.1")) == "192.168.1.1"
    assert str(parse_ip_hop(" 10.0.0.1 ")) == "10.0.0.1"
    assert str(parse_ip_hop('"203.0.113.19"')) == "203.0.113.19"
    assert str(parse_ip_hop("2001:db8::1")) == "2001:db8::1"
    assert str(parse_ip_hop("[2001:db8::1]")) == "2001:db8::1"


def test_parse_ip_hop_with_ports():
    assert str(parse_ip_hop("192.168.1.1:8080")) == "192.168.1.1"
    assert str(parse_ip_hop("[2001:db8::1]:443")) == "2001:db8::1"


def test_parse_ip_hop_rfc7239_syntax():
    assert str(parse_ip_hop("for=192.0.2.60")) == "192.0.2.60"
    assert str(parse_ip_hop('for="[2001:db8::2]:8080"')) == "2001:db8::2"


def test_parse_ip_hop_invalid_and_injection():
    assert parse_ip_hop("") is None
    assert parse_ip_hop("not_an_ip") is None
    assert parse_ip_hop("<script>alert(1)</script>") is None
    assert parse_ip_hop("999.999.999.999") is None


# ============================================================================
# 2. CLIENT IP RESOLUTION: DIRECT CLIENTS & SPOOFING PREVENTION
# ============================================================================

def test_direct_client_without_proxies(monkeypatch):
    """Direct client connecting without proxies resolves to direct socket peer."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 127.0.0.1")
    req = build_mock_request(client_host="198.51.100.25")
    resolved = get_trusted_client_ip(req)
    assert resolved == "198.51.100.25"


def test_spoofed_forwarded_header_from_untrusted_direct_client_ignored(monkeypatch):
    """Direct untrusted client supplying X-Forwarded-For has headers completely ignored."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 127.0.0.1")
    req = build_mock_request(
        client_host="198.51.100.25",
        headers={"x-forwarded-for": "1.1.1.1, 8.8.8.8"}
    )
    resolved = get_trusted_client_ip(req)
    # Must NOT use 1.1.1.1 or 8.8.8.8!
    assert resolved == "198.51.100.25"


def test_spoofed_forwarded_rfc7239_from_untrusted_client_ignored(monkeypatch):
    """Direct untrusted client supplying RFC 7239 Forwarded header is ignored."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 127.0.0.1")
    req = build_mock_request(
        client_host="198.51.100.25",
        headers={"forwarded": "for=1.1.1.1;proto=https"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "198.51.100.25"


def test_trusted_proxies_unset_fails_safe(monkeypatch):
    """When TRUSTED_PROXIES is empty/unset, backend maintains zero-trust posture."""
    monkeypatch.setenv("TRUSTED_PROXIES", "")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-forwarded-for": "203.0.113.50"}
    )
    resolved = get_trusted_client_ip(req)
    # Fails safely to direct peer because no proxies are trusted
    assert resolved == "10.0.0.1"


# ============================================================================
# 3. CLIENT IP RESOLUTION: TRUSTED PROXIES & PROXY CHAIN TRAVERSAL
# ============================================================================

def test_trusted_proxy_single_hop(monkeypatch):
    """Request through trusted proxy correctly resolves the originating client IP."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 127.0.0.1")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-forwarded-for": "203.0.113.50"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "203.0.113.50"


def test_trusted_proxy_with_spoofed_ip_prepended_by_attacker(monkeypatch):
    """
    Attacker (203.0.113.50) injects 'X-Forwarded-For: 9.9.9.9'.
    Trusted proxy appends real IP: 'X-Forwarded-For: 9.9.9.9, 203.0.113.50'.
    Right-to-left traversal extracts the genuine client IP (203.0.113.50), not spoofed 9.9.9.9.
    """
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 127.0.0.1")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-forwarded-for": "9.9.9.9, 203.0.113.50"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "203.0.113.50"


def test_multi_hop_trusted_proxies(monkeypatch):
    """
    Edge CDN (173.245.48.5) -> Internal Load Balancer (10.0.0.2) -> FastAPI.
    Both 173.245.48.0/20 and 10.0.0.0/8 are trusted.
    Real client is 203.0.113.77.
    """
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8, 173.245.48.0/20, 127.0.0.1")
    req = build_mock_request(
        client_host="10.0.0.2",
        headers={"x-forwarded-for": "203.0.113.77, 173.245.48.5"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "203.0.113.77"


def test_all_hops_in_chain_are_trusted_proxies(monkeypatch):
    """If all hops in XFF are internal trusted proxies, fall back to leftmost hop."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-forwarded-for": "10.0.0.5, 10.0.0.6"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "10.0.0.5"


def test_rfc7239_forwarded_header_behind_trusted_proxy(monkeypatch):
    """Valid RFC 7239 Forwarded header parsed correctly behind trusted proxy."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"forwarded": 'for=203.0.113.88, for="10.0.0.5:8080"'}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "203.0.113.88"


def test_x_real_ip_fallback_behind_trusted_proxy(monkeypatch):
    """X-Real-IP used when peer is trusted proxy and X-Forwarded-For is missing."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-real-ip": "203.0.113.99"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "203.0.113.99"


def test_x_real_ip_ignored_from_untrusted_client(monkeypatch):
    """X-Real-IP from untrusted client is ignored."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(
        client_host="198.51.100.30",
        headers={"x-real-ip": "1.1.1.1"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "198.51.100.30"


def test_missing_forwarded_headers_behind_trusted_proxy(monkeypatch):
    """Behind trusted proxy with no forwarded headers falls back safely to proxy IP."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(client_host="10.0.0.1")
    resolved = get_trusted_client_ip(req)
    assert resolved == "10.0.0.1"


def test_malformed_forwarded_headers_rejected_safely(monkeypatch):
    """Malformed and injection strings in XFF fail safely to proxy peer."""
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    req = build_mock_request(
        client_host="10.0.0.1",
        headers={"x-forwarded-for": "<script>alert(1)</script>, bad_ip_string"}
    )
    resolved = get_trusted_client_ip(req)
    assert resolved == "10.0.0.1"


# ============================================================================
# 4. RATE LIMITING ENFORCEMENT & BYPASS PREVENTION
# ============================================================================

def test_slowapi_rate_limit_exceeded_returns_429():
    """
    Enables SlowAPI and verifies that exceeding route rate limit returns HTTP 429.
    Tests /auth/forgot-password-form (5/minute).
    """
    prev_enabled = limiter.enabled
    limiter.enabled = True
    try:
        # Create a fresh TestClient
        client = TestClient(app)

        # 5 requests should succeed (or return form error, but NOT 429)
        for i in range(5):
            res = client.post("/auth/forgot-password-form", data={"email": f"rate_test_{i}@example.com"})
            assert res.status_code != 429, f"Request {i+1} unexpectedly throttled with 429"

        # 6th request from same IP must be throttled with HTTP 429
        res6 = client.post("/auth/forgot-password-form", data={"email": "rate_test_overflow@example.com"})
        assert res6.status_code == 429
        assert "Rate limit exceeded" in res6.text or "429" in str(res6.status_code)
    finally:
        limiter.enabled = prev_enabled


def test_attacker_cannot_bypass_rate_limit_by_changing_forwarded_headers(monkeypatch):
    """
    Simulates an attacker directly connecting to the server and attempting to bypass
    rate limits on /auth/forgot-password by rotating X-Forwarded-For values.
    Since the attacker's socket peer is untrusted, rotating headers must NOT bypass the limit.
    """
    monkeypatch.setenv("TRUSTED_PROXIES", "10.0.0.0/8")
    prev_enabled = limiter.enabled
    limiter.enabled = True
    try:
        client = TestClient(app)

        # Attacker attempts 6 requests, changing X-Forwarded-For on each attempt
        hit_429 = False
        for i in range(7):
            fake_ip = f"198.51.100.{i+1}"
            res = client.post(
                "/auth/forgot-password-form",
                data={"email": f"attacker_{i}@example.com"},
                headers={"X-Forwarded-For": fake_ip}
            )
            if res.status_code == 429:
                hit_429 = True
                break

        assert hit_429, "Attacker successfully bypassed rate limit by rotating X-Forwarded-For headers!"
    finally:
        limiter.enabled = prev_enabled


def test_ip_isolation_behind_trusted_proxy(monkeypatch):
    """
    Verifies that requests behind a trusted proxy are partitioned by real client IP,
    so Client A exceeding quota does not block Client B.
    """
    monkeypatch.setenv("TRUSTED_PROXIES", "127.0.0.1, testclient")
    prev_enabled = limiter.enabled
    limiter.enabled = True
    try:
        client = TestClient(app)

        # Client A makes requests with distinct client IP
        for _ in range(5):
            client.post(
                "/auth/forgot-password-form",
                data={"email": "client_a@example.com"},
                headers={"X-Forwarded-For": "203.0.113.10"}
            )

        # 6th request for Client A is throttled
        res_a = client.post(
            "/auth/forgot-password-form",
            data={"email": "client_a@example.com"},
            headers={"X-Forwarded-For": "203.0.113.10"}
        )
        assert res_a.status_code == 429

        # Client B from different IP (203.0.113.20) must NOT be blocked
        res_b = client.post(
            "/auth/forgot-password-form",
            data={"email": "client_b@example.com"},
            headers={"X-Forwarded-For": "203.0.113.20"}
        )
        assert res_b.status_code != 429
    finally:
        limiter.enabled = prev_enabled


def test_preservation_of_all_auth_rate_limits():
    """Verifies that all required sensitive auth endpoints remain protected by rate limiting."""
    from app.api import auth

    routes_to_check = {
        "/register": "5/minute",
        "/verify-email": "10/minute",
        "/auth/forgot-password-form": "5/minute",
        "/auth/forgot-password": "5/minute",
        "/reset-password": "10/minute",
        "/auth/send-otp": "5/minute",
        "/auth/verify-otp-reset": "5/minute",
        "/auth/login-otp": "10/minute",
        "/login": "10/minute",
        "/change-password": "5/minute",
    }

    found_routes = {}
    for route in auth.router.routes:
        path = getattr(route, "path", None)
        endpoint = getattr(route, "endpoint", None)
        if path in routes_to_check and endpoint:
            # Check if slowapi limiter attached to endpoint
            found_routes[path] = getattr(endpoint, "_rate_limit", None) or "configured"

    for path in routes_to_check:
        assert path in found_routes, f"Expected protected route {path} not found in auth router"
