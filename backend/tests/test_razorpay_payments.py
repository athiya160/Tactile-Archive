import os
import hmac
import hashlib
import json
import itertools
import uuid
import time
import pytest
import razorpay
from fastapi.testclient import TestClient
from app.main import app
from app.api.auth import create_access_token
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.order import Order
from app.models.payment import Payment
from app.models.cart import Cart, CartItem

_order_counter = itertools.count(1001)

@pytest.fixture(autouse=True)
def mock_razorpay_gateway(monkeypatch):
    """
    Deterministic test-only mock for external Razorpay API order creation.
    Intercepts rzp.order.create() to return realistic order payloads without
    making external HTTP/DNS calls. Preserves local cryptographic signature
    verification, webhook HMAC verification, and complete application logic.
    """
    def fake_order_create(self, data=None, **kwargs):
        count = next(_order_counter)
        unique_token = f"{int(time.time())}_{uuid.uuid4().hex[:8]}_{count}"
        amount = (data or {}).get("amount", 49900)
        currency = (data or {}).get("currency", "INR")
        receipt = (data or {}).get("receipt", f"receipt_{unique_token}")
        notes = (data or {}).get("notes", {})
        return {
            "id": f"order_test_{unique_token}",
            "entity": "order",
            "amount": amount,
            "amount_paid": 0,
            "amount_due": amount,
            "currency": currency,
            "receipt": receipt,
            "status": "created",
            "attempts": 0,
            "notes": notes,
            "created_at": 1700000000,
        }

    monkeypatch.setattr(razorpay.resources.Order, "create", fake_order_create)

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        yield c

@pytest.fixture(scope="module")
def auth_headers():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "test_razorpay_user@libri.test").first()
        if not user:
            user = User(
                email="test_razorpay_user@libri.test",
                name="Razorpay Tester",
                role="customer",
                user_type="reader",
                is_verified=True,
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        # Ensure a test book exists with sufficient stock for test runs
        book = db.query(Book).filter(Book.id == 99991).first()
        if not book:
            book = Book(
                id=99991,
                title="Razorpay Payment Guide",
                author="Fintech Specialist",
                price=499.0,
                rating=4.9,
                stock=100,
                owner_id=user.id,
            )
            db.add(book)
        else:
            book.stock = 100
        db.commit()

        token = create_access_token({"sub": user.email, "role": user.role, "user_type": user.user_type})
        return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    finally:
        db.close()

def test_create_order_invalid_mode(client, auth_headers):
    """Rejects invalid checkout modes with HTTP 400."""
    res = client.post(
        "/payments/create-order",
        json={"payment_method": "card", "shipping_address": "221B Baker St", "mode": "invalid_mode"},
        headers=auth_headers
    )
    assert res.status_code == 400
    assert "Invalid mode" in res.json().get("detail", "")

def test_create_order_direct_buy(client, auth_headers):
    """Creates a real Razorpay test order for direct book purchase in paise (INR)."""
    res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "card",
            "shipping_address": "104 Indiranagar, Bengaluru, KA",
            "mode": "purchase",
            "book_id": 99991
        },
        headers=auth_headers
    )
    assert res.status_code == 200
    data = res.json()
    assert data["is_cod"] is False
    assert data["currency"] == "INR"
    assert data["amount"] == 49900  # 499 * 100 paise
    assert data["razorpay_order_id"].startswith("order_")
    assert "key_id" in data
    assert len(data["key_id"]) > 0

def test_create_order_cod(client, auth_headers):
    """Cash on Delivery orders are placed directly without Razorpay online order."""
    res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "cod",
            "shipping_address": "104 Indiranagar, Bengaluru, KA",
            "mode": "purchase",
            "book_id": 99991
        },
        headers=auth_headers
    )
    assert res.status_code == 200
    data = res.json()
    assert data["is_cod"] is True
    assert "order_id" in data

def test_verify_payment_invalid_signature(client, auth_headers):
    """Rejects tampered or invalid Razorpay signatures with HTTP 400."""
    # First create an order
    order_res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "upi",
            "shipping_address": "12MG Road, Bengaluru",
            "mode": "purchase",
            "book_id": 99991
        },
        headers=auth_headers
    ).json()

    rzp_order_id = order_res["razorpay_order_id"]

    # Attempt verification with bogus signature
    verify_res = client.post(
        "/payments/verify",
        json={
            "razorpay_order_id": rzp_order_id,
            "razorpay_payment_id": "pay_fake_123456",
            "razorpay_signature": "invalid_signature_hash_xyz"
        },
        headers=auth_headers
    )
    assert verify_res.status_code == 400
    assert "Invalid payment signature" in verify_res.json().get("detail", "")

def test_verify_payment_valid_signature_and_idempotency(client, auth_headers):
    """Verifies valid HMAC-SHA256 signature and tests duplicate idempotency."""
    order_res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "card",
            "shipping_address": "77 Koramangala, Bengaluru",
            "mode": "purchase",
            "book_id": 99991
        },
        headers=auth_headers
    ).json()

    rzp_order_id = order_res["razorpay_order_id"]
    fake_payment_id = "pay_test_" + rzp_order_id.replace("order_", "")

    # Generate genuine HMAC-SHA256 signature using the test secret loaded in environment
    secret = os.getenv("RAZORPAY_KEY_SECRET", "ddwv2TgG1Y6n9gfBc3S37eaw")
    msg = f"{rzp_order_id}|{fake_payment_id}".encode("utf-8")
    valid_signature = hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()

    # 1. First verification attempt -> Success
    res1 = client.post(
        "/payments/verify",
        json={
            "razorpay_order_id": rzp_order_id,
            "razorpay_payment_id": fake_payment_id,
            "razorpay_signature": valid_signature
        },
        headers=auth_headers
    )
    assert res1.status_code == 200
    assert "Payment verified successfully" in res1.json().get("message", "")

    # 2. Duplicate verification attempt -> Idempotent response
    res2 = client.post(
        "/payments/verify",
        json={
            "razorpay_order_id": rzp_order_id,
            "razorpay_payment_id": fake_payment_id,
            "razorpay_signature": valid_signature
        },
        headers=auth_headers
    )
    assert res2.status_code == 200
    assert "already verified" in res2.json().get("message", "").lower()

def test_webhook_invalid_signature(client, monkeypatch):
    """Rejects Razorpay webhooks with tampered or invalid signatures with HTTP 400."""
    from app.api.payments import get_razorpay_client
    get_razorpay_client()

    test_secret = "test_webhook_secret_key_123"
    monkeypatch.setenv("RAZORPAY_WEBHOOK_SECRET", test_secret)

    payload = json.dumps({"event": "payment.failed", "payload": {}})

    res = client.post(
        "/payments/webhook",
        content=payload,
        headers={"X-Razorpay-Signature": "invalid_signature_hash_xyz", "Content-Type": "application/json"}
    )
    assert res.status_code == 400
    assert "Invalid signature" in res.json().get("detail", "")

def test_webhook_valid_signature_payment_captured(client, auth_headers, monkeypatch):
    """Verifies legitimate HMAC-SHA256 signature on webhook and transitions order/payment status."""
    from app.api.payments import get_razorpay_client
    get_razorpay_client()

    test_secret = "test_webhook_secret_key_123"
    monkeypatch.setenv("RAZORPAY_WEBHOOK_SECRET", test_secret)

    # First create an order
    order_res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "card",
            "shipping_address": "88 Webhook St, Bengaluru",
            "mode": "purchase",
            "book_id": 99991
        },
        headers=auth_headers
    ).json()

    rzp_order_id = order_res["razorpay_order_id"]
    webhook_pid = "pay_hook_" + rzp_order_id.replace("order_", "")

    webhook_payload = json.dumps({
        "event": "payment.captured",
        "payload": {
            "payment": {
                "entity": {
                    "id": webhook_pid,
                    "order_id": rzp_order_id,
                    "amount": 49900,
                    "status": "captured"
                }
            }
        }
    })

    # Compute genuine HMAC-SHA256 signature
    valid_sig = hmac.new(test_secret.encode("utf-8"), webhook_payload.encode("utf-8"), hashlib.sha256).hexdigest()

    res = client.post(
        "/payments/webhook",
        content=webhook_payload,
        headers={"X-Razorpay-Signature": valid_sig, "Content-Type": "application/json"}
    )
    assert res.status_code == 200

    # Verify in database that Payment and Order were updated
    db = SessionLocal()
    try:
        pay = db.query(Payment).filter(Payment.razorpay_order_id == rzp_order_id).first()
        assert pay is not None
        assert pay.status == "paid"
        assert pay.razorpay_payment_id == webhook_pid

        ord_rec = db.query(Order).filter(Order.id == pay.order_id).first()
        assert ord_rec is not None
        assert ord_rec.payment_status == "paid"
        assert ord_rec.status == "processing"
    finally:
        db.close()
