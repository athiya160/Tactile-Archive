"""
Pytest configuration and shared fixtures for LibriFlow FastAPI Backend.
"""

import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["TESTING"] = "true"
os.environ["ENV"] = "test"
import pytest
from fastapi.testclient import TestClient
from app.main import app

from app.core.rate_limit import limiter

@pytest.fixture(autouse=True)
def disable_rate_limiter():
    """Disable slowapi rate limiting during test executions to prevent 429 flakes."""
    prev = limiter.enabled
    limiter.enabled = False
    yield
    limiter.enabled = prev

@pytest.fixture(scope="module")
def test_client():
    """Fixture providing a FastAPI TestClient instance."""
    with TestClient(app) as client:
        yield client

