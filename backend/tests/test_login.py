from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_login_invalid_credentials():
    """Verify login with invalid credentials returns 401."""
    response = client.post("/login", json={"email": "nonexistent_reader@example.com", "password": "wrongpassword123"})
    assert response.status_code in [400, 401], f"Expected 401 or 400, got {response.status_code}: {response.text}"
