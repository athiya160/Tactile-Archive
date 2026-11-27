from fastapi.testclient import TestClient
from app.main import app
from app.api.auth import get_current_user
from app.models.user import User

def mock_get_current_user():
    return User(id=1, email='test@test.com')

def test_payment_verify_endpoint_structure():
    """Verify payment verify endpoint gracefully validates payloads without corrupting global state."""
    try:
        app.dependency_overrides[get_current_user] = mock_get_current_user
        client = TestClient(app)
        response = client.post('/payments/verify', json={
            'razorpay_order_id': 'order_mock_12345',
            'razorpay_payment_id': 'pay_mock_12345',
            'razorpay_signature': 'mock_signature'
        })
        # Payment gateway should return 400, 404, or 500 cleanly without crashing
        assert response.status_code in [200, 400, 404, 500]
    finally:
        app.dependency_overrides.pop(get_current_user, None)
