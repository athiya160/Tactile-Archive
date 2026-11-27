from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_books_public_endpoint():
    """Verify public books listing endpoint returns 200 with catalog data."""
    response = client.get("/books?limit=10")
    assert response.status_code == 200
    data = response.json()
    assert "data" in data
    assert isinstance(data["data"], list)
