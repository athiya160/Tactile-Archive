import pytest
import datetime
import hashlib
from urllib.parse import urlparse, parse_qs
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.favorite import Favorite
from app.models.notification import Notification
from app.models.password_reset import PasswordReset
from app.models.order import Order, OrderItem
from app.models.payment import Payment
from app.api.auth import hash_password

client = TestClient(app)

def create_isolated_user(email: str, name: str, role: str = "customer") -> User:
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(
                email=email,
                password=hash_password("SecurePass123!"),
                name=name,
                role=role,
                is_verified=True
            )
            db.add(user)
        else:
            user.password = hash_password("SecurePass123!")
            user.role = role
            if role == "provider":
                user.provider_enabled = True
                user.provider_status = "active"
            else:
                user.provider_enabled = False
                user.provider_status = "not_enrolled"
        db.commit()
        db.refresh(user)
        return user
    finally:
        db.close()

def get_auth_token(email: str, password: str = "SecurePass123!") -> str:
    res = client.post("/login", json={"email": email, "password": password})
    assert res.status_code == 200, f"Login failed: {res.text}"
    return res.json()["access_token"]

# =======================================================
# STEP 3: PASSWORD RESET VERIFICATION (Hashed, Expired, Reused, Invalid)
# =======================================================
def test_password_reset_edge_cases(monkeypatch):
    dispatched_links = []
    def mock_send(to_email, link):
        dispatched_links.append(link)
        return True, ""
    monkeypatch.setattr("app.api.auth.send_reset_password_email", mock_send)

    db = SessionLocal()
    try:
        user = create_isolated_user("reset_edge_case@example.com", "Reset Tester")

        # 1. Forgot password
        res = client.post("/auth/forgot-password", json={"email": user.email})
        assert res.status_code == 200
        raw_url = dispatched_links[-1]
        raw_token = parse_qs(urlparse(raw_url).query).get("token", [""])[0]
        assert raw_token != ""

        # 2. Check DB stores SHA-256 hash
        expected_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
        reset_entry = db.query(PasswordReset).filter(PasswordReset.user_id == user.id, PasswordReset.used == False).order_by(PasswordReset.id.desc()).first()
        assert reset_entry is not None
        assert reset_entry.token == expected_hash

        # 3. Test wrong/invalid token
        invalid_res = client.post("/auth/reset-password", json={
            "token": "completely_invalid_token_9999",
            "new_password": "NewSecretPassword123!"
        })
        assert invalid_res.status_code == 400
        assert "Invalid reset token" in invalid_res.json()["detail"]

        # 4. Test expired token
        reset_entry.expires_at = datetime.datetime.utcnow() - datetime.timedelta(minutes=1)
        db.commit()
        expired_res = client.post("/auth/reset-password", json={
            "token": raw_token,
            "new_password": "NewSecretPassword123!"
        })
        assert expired_res.status_code == 400
        assert "expired" in expired_res.json()["detail"]

        # 5. Restore valid expiry, perform reset
        reset_entry.expires_at = datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
        db.commit()
        valid_res = client.post("/auth/reset-password", json={
            "token": raw_token,
            "new_password": "ValidNewPassword123!"
        })
        assert valid_res.status_code == 200

        # 6. Test already-used token fails
        reused_res = client.post("/auth/reset-password", json={
            "token": raw_token,
            "new_password": "AnotherValidPassword123!"
        })
        assert reused_res.status_code == 400
        assert "already been used" in reused_res.json()["detail"]
    finally:
        db.close()

# =======================================================
# STEP 4: ZERO-STATE VERIFICATION (No Mock Fallbacks)
# =======================================================
def test_zero_state_data_integrity():
    user = create_isolated_user("brand_new_zero_state_user@example.com", "Zero State Tester", role="provider")
    token = get_auth_token(user.email)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Profile Zero-State Check
    res = client.get("/users/me/profile", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["stats"]["books_count"] == 0, f"Expected 0 books, got {data['stats']['books_count']}"
    assert data["stats"]["saved_count"] == 0, f"Expected 0 saved, got {data['stats']['saved_count']}"
    assert data["stats"]["exchanges_count"] == 0, f"Expected 0 exchanges, got {data['stats']['exchanges_count']}"
    assert data["stats"]["plans_count"] == 0, f"Expected 0 plans, got {data['stats']['plans_count']}"
    assert data["currently_reading"] is None, f"Expected None for currently_reading, got {data['currently_reading']}"
    assert data["passport"]["books_completed"] == 0
    assert data["passport"]["books_reused"] == 0
    assert data["passport"]["money_saved"] == "₹0"

    # 2. Provider Zero-State Check
    prov_res = client.get("/provider/dashboard", headers=headers)
    assert prov_res.status_code == 200
    prov_data = prov_res.json()
    assert prov_data["metrics"]["total_listings"] == 0
    assert prov_data["metrics"]["available_books"] == 0
    assert prov_data["metrics"]["rentals_count"] == 0
    assert prov_data["metrics"]["sold_count"] == 0
    assert prov_data["metrics"]["total_earnings"] == 0.0
    assert prov_data["action_required"]["rental_requests"] == 0
    assert prov_data["action_required"]["exchange_pending"] == 0
    assert prov_data["action_required"]["awaiting_verification"] == 0
    assert prov_data["recent_inventory"] == []

    # 3. Provider Inventory, Requests, Earnings
    inv_res = client.get("/provider/inventory", headers=headers)
    assert inv_res.status_code == 200
    assert inv_res.json() == []

    req_res = client.get("/provider/requests", headers=headers)
    assert req_res.status_code == 200
    assert req_res.json() == []

    earn_res = client.get("/provider/earnings", headers=headers)
    assert earn_res.status_code == 200
    earn_data = earn_res.json()
    assert earn_data["total_earned"] == 0.0
    assert earn_data["transactions"] == []

# =======================================================
# STEP 5: USER ISOLATION VERIFICATION
# =======================================================
def test_user_isolation():
    user_a = create_isolated_user("user_a_isolation@example.com", "User Alpha", "provider")
    user_b = create_isolated_user("user_b_isolation@example.com", "User Beta", "customer")

    token_a = get_auth_token(user_a.email)
    token_b = get_auth_token(user_b.email)

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    db = SessionLocal()
    try:
        # User A creates a book listing
        book_a = Book(
            title="User A Unique Book",
            author="Author Alpha",
            owner_id=user_a.id,
            price=500.0,
            stock=1
        )
        db.add(book_a)
        db.commit()
        db.refresh(book_a)

        # User A saves a favorite
        fav_a = Favorite(user_id=user_a.id, book_id=book_a.id)
        db.add(fav_a)

        # User A creates a notification
        notif_a = Notification(user_id=user_a.id, title="Secret A", message="Alpha Notification")
        db.add(notif_a)
        db.commit()

        # User B inspects their own favorites (must not see User A's favorite)
        b_favs = client.get("/favorites", headers=headers_b)
        assert b_favs.status_code == 200
        b_fav_items = b_favs.json() if isinstance(b_favs.json(), list) else b_favs.json().get("favorites", [])
        assert not any(f.get("id") == book_a.id or f.get("book_id") == book_a.id for f in b_fav_items)

        # User B inspects provider inventory (customer is rejected with 403 or returns empty list)
        b_inv = client.get("/provider/inventory", headers=headers_b)
        assert b_inv.status_code in [200, 403]
        if b_inv.status_code == 200:
            assert not any(b.get("id") == book_a.id for b in b_inv.json())

        # User B inspects notifications (must not see User A's notification)
        b_notifs = client.get("/notifications", headers=headers_b)
        assert b_notifs.status_code == 200
        assert not any(n.get("title") == "Secret A" for n in b_notifs.json())

        # User B profile stats must not include User A's data
        b_profile = client.get("/users/me/profile", headers=headers_b)
        assert b_profile.status_code == 200
        assert b_profile.json()["email"] == user_b.email
    finally:
        db.close()

# =======================================================
# STEP 8: PAYMENT WEBHOOK & SECURITY VERIFICATION
# =======================================================
def test_payment_security_and_idempotency():
    user = create_isolated_user("payment_security_user@example.com", "Payment Tester")
    token = get_auth_token(user.email)
    headers = {"Authorization": f"Bearer {token}"}

    db = SessionLocal()
    try:
        # Create an internal pending order and payment record
        order = Order(
            user_id=user.id,
            status="pending",
            total_items=1,
            total_amount=350.0,
            delivery_address="456 Safe Way",
            payment_method="UPI",
            payment_status="pending"
        )
        db.add(order)
        db.commit()
        db.refresh(order)

        payment = Payment(
            order_id=order.id,
            user_id=user.id,
            razorpay_order_id=f"order_rzp_{order.id}",
            amount=350.0,
            currency="INR",
            status="pending"
        )
        db.add(payment)
        db.commit()

        # 1. Test duplicate webhook idempotent execution
        webhook_payload = {
            "event": "payment.captured",
            "payload": {
                "payment": {
                    "entity": {
                        "id": f"pay_{order.id}_123",
                        "order_id": f"order_rzp_{order.id}",
                        "amount": 35000,
                        "status": "captured"
                    }
                }
            }
        }

        # First delivery
        res1 = client.post("/payments/webhook", json=webhook_payload)
        assert res1.status_code == 200
        db.refresh(payment)
        db.refresh(order)
        assert payment.status == "paid"
        assert order.status == "processing"

        # Duplicate delivery (idempotency guard)
        res2 = client.post("/payments/webhook", json=webhook_payload)
        assert res2.status_code == 200
        db.refresh(payment)
        assert payment.status == "paid" # Remains paid without error or double transaction

        # 2. Test refund webhook event
        refund_payload = {
            "event": "refund.processed",
            "payload": {
                "refund": {
                    "entity": {
                        "id": f"rfnd_{order.id}_123",
                        "payment_id": f"pay_{order.id}_123",
                        "amount": 35000
                    }
                }
            }
        }
        ref_res = client.post("/payments/webhook", json=refund_payload)
        assert ref_res.status_code == 200
        db.refresh(payment)
        db.refresh(order)
        assert payment.status == "refunded"
        assert order.status == "refunded"

        # 3. Test malformed payload handling
        mal_res = client.post("/payments/webhook", content="invalid json", headers={"Content-Type": "application/json"})
        assert mal_res.status_code == 400
    finally:
        db.close()
