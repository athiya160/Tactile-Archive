import os
import pytest
from starlette.testclient import TestClient
from app.main import app
import app.core.proxy_security as ps

@pytest.fixture
def client():
    return TestClient(app)

def test_csp_header_present_on_all_responses(client):
    """Phase 20.57: Verify Content-Security-Policy is present and well-formed."""
    res = client.get("/")
    assert res.status_code == 200
    csp = res.headers.get("Content-Security-Policy")
    assert csp is not None
    assert "default-src 'self'" in csp

def test_csp_connect_src_no_wildcards(client):
    """Phase 20.57: Verify connect-src contains explicit origins without wildcard *."""
    res = client.get("/")
    assert res.status_code == 200
    csp = res.headers.get("Content-Security-Policy", "")
    assert "connect-src" in csp
    
    # Extract connect-src directive
    for directive in csp.split(";"):
        directive = directive.strip()
        if directive.startswith("connect-src"):
            parts = directive.split()
            # Assert NO standalone wildcard '*'
            assert "*" not in parts, "connect-src must not contain '*'"
            # Assert essential explicit origins
            assert "'self'" in parts
            assert "https://api.razorpay.com" in parts
            assert "https://lumberjack.razorpay.com" in parts
            assert "https://accounts.google.com" in parts
            assert "https://oauth2.googleapis.com" in parts
            assert "https://*.s3.ap-south-1.amazonaws.com" in parts
            assert "ws:" in parts
            assert "wss:" in parts

def test_csp_frame_src_allows_razorpay_checkout_iframe(client):
    """Phase 20.57: Verify frame-src allows Razorpay checkout modal without modifying payments.py."""
    res = client.get("/")
    assert res.status_code == 200
    csp = res.headers.get("Content-Security-Policy", "")
    assert "frame-src" in csp
    assert "https://checkout.razorpay.com" in csp
    assert "https://api.razorpay.com" in csp

def test_csp_clickjacking_protection(client):
    """Phase 20.57: Verify frame-ancestors is 'none' and X-Frame-Options is DENY."""
    res = client.get("/")
    assert res.status_code == 200
    assert res.headers.get("X-Frame-Options") == "DENY"
    csp = res.headers.get("Content-Security-Policy", "")
    assert "frame-ancestors 'none'" in csp

def test_hsts_omitted_on_plain_http(client, monkeypatch):
    """Phase 20.57: HSTS must NEVER be sent over unencrypted HTTP (RFC 6797)."""
    monkeypatch.delenv("TRUSTED_PROXIES", raising=False)
    ps._CACHED_CONFIG_RAW = None
    res = client.get("/")
    assert res.status_code == 200
    assert "Strict-Transport-Security" not in res.headers

def test_hsts_spoofed_forwarded_proto_from_untrusted_client_rejected(client, monkeypatch):
    """Phase 20.57: X-Forwarded-Proto from untrusted direct peer must NOT enable HSTS."""
    monkeypatch.delenv("TRUSTED_PROXIES", raising=False)
    ps._CACHED_CONFIG_RAW = None
    res = client.get("/", headers={"x-forwarded-proto": "https"})
    assert res.status_code == 200
    assert "Strict-Transport-Security" not in res.headers

def test_hsts_trusted_proxy_forwarded_proto_accepted(client, monkeypatch):
    """Phase 20.57: X-Forwarded-Proto from verified trusted proxy properly injects HSTS."""
    monkeypatch.setenv("TRUSTED_PROXIES", "testclient")
    ps._CACHED_CONFIG_RAW = None
    res = client.get("/", headers={"x-forwarded-proto": "https"})
    assert res.status_code == 200
    hsts = res.headers.get("Strict-Transport-Security")
    assert hsts is not None
    assert "max-age=31536000" in hsts
    assert "includeSubDomains" in hsts

def test_hsts_direct_tls_accepted():
    """Phase 20.57: Direct TLS termination (scheme == 'https') injects HSTS."""
    from starlette.datastructures import Headers
    # Use TestClient with https base_url
    https_client = TestClient(app, base_url="https://testserver")
    res = https_client.get("/")
    assert res.status_code == 200
    hsts = res.headers.get("Strict-Transport-Security")
    assert hsts is not None
    assert "max-age=31536000" in hsts
