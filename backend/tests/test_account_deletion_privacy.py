"""
Phase 20.13 — Comprehensive Account Deletion & Privacy Compliance Test Suite

Safety & Integrity Enforcements:
- Executes strictly on an isolated disposable test database (scratch/disposable_test_deletion.db).
- Verifies that the live database (backend/tactile_archive.db) is never touched.
- Verifies authorization, password re-authentication, OAuth confirmation tokens,
  active fulfillment guards, ancillary PII purging, financial transaction preservation,
  anonymization scrubbing, immediate token revocation, and repeat deletion rejections.
"""

import os
import sys
import hashlib
import uuid
import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend in path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.main import app
from app.core.database import Base
from app.api.auth import get_db, hash_password, create_access_token
from app.models.user import User
from app.models.book import Book
from app.models.order import Order, OrderItem, RentalOrder, BorrowRequest, PurchaseOrder
from app.models.payment import Payment
from app.models.address import Address
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.notification import Notification

DISPOSABLE_TEST_DB = "scratch/disposable_test_deletion.db"
LIVE_DB_PATH = "backend/tactile_archive.db"

def get_file_hash(path):
    if not os.path.exists(path):
        return None
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

# Setup test engine for disposable database
engine = create_engine(f"sqlite:///{DISPOSABLE_TEST_DB}", connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="module", autouse=True)
def live_database_safety_guard():
    """Confirms live database hash is identical before and after entire test execution."""
    initial_hash = get_file_hash(LIVE_DB_PATH)
    yield
    final_hash = get_file_hash(LIVE_DB_PATH)
    assert initial_hash == final_hash, f"CRITICAL SAFETY VIOLATION: Live database modified during test run! {initial_hash} != {final_hash}"

@pytest.fixture(scope="module")
def setup_test_db():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(DISPOSABLE_TEST_DB):
        try:
            os.remove(DISPOSABLE_TEST_DB)
        except Exception:
            pass
    Base.metadata.create_all(bind=engine)
    yield
    # Cleanup after test suite
    if os.path.exists(DISPOSABLE_TEST_DB):
        try:
            os.remove(DISPOSABLE_TEST_DB)
        except Exception:
            pass

@pytest.fixture(scope="function")
def db_session(setup_test_db):
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

@pytest.fixture(scope="function")
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    test_client = TestClient(app)
    yield test_client
    app.dependency_overrides.clear()

def create_test_user(db, email, password="TestPassword123!", role="customer", user_type="reader", name="Test User"):
    user = User(
        email=email,
        password=hash_password(password) if password else None,
        name=name,
        role=role,
        user_type=user_type,
        is_verified=True,
        phone="+919876543210",
        address="123 Test Street, Bengaluru",
        bio="Test reader bio"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

# =============================================================================
# 1. Authorization & Re-authentication Tests
# =============================================================================

def test_unauthenticated_deletion_rejected(client):
    """Calling DELETE /users/me without Authorization header returns HTTP 401/403."""
    res = client.delete("/users/me")
    assert res.status_code in [401, 403]

def test_invalid_password_rejection(client, db_session):
    """Calling DELETE /users/me with an invalid password returns HTTP 400."""
    user = create_test_user(db_session, "user_pwd_test@example.com", password="RealPassword123!")
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    res = client.request(
        "DELETE",
        "/users/me",
        headers=headers,
        json={"password": "WrongPassword999!"}
    )
    assert res.status_code == 400
    assert "Invalid password" in res.json().get("detail", "")

def test_oauth_missing_confirmation_rejected(client, db_session):
    """Passwordless / OAuth accounts must provide explicit confirmation 'DELETE'."""
    oauth_user = create_test_user(db_session, "oauth_test@example.com", password=None, name="OAuth User")
    token = create_access_token({"sub": oauth_user.email, "role": oauth_user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # No confirmation
    res = client.request("DELETE", "/users/me", headers=headers, json={})
    assert res.status_code == 400
    assert "Confirmation required" in res.json().get("detail", "")

    # Invalid confirmation
    res2 = client.request("DELETE", "/users/me", headers=headers, json={"confirmation": "NO"})
    assert res2.status_code == 400

# =============================================================================
# 2. Active Fulfillment Protection Tests
# =============================================================================

def test_active_order_blocks_deletion(client, db_session):
    """Users with active/unfulfilled delivery orders cannot delete their account."""
    user = create_test_user(db_session, "active_order_user@example.com", password="Pass123!Active")
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Create active pending order
    order = Order(
        user_id=user.id,
        status="processing",
        total_amount=499.0,
        delivery_address="123 Test St",
        delivery_method="standard"
    )
    db_session.add(order)
    db_session.commit()

    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "Pass123!Active"})
    assert res.status_code == 400
    assert "active or unfulfilled orders" in res.json().get("detail", "").lower()

def test_active_rental_blocks_deletion(client, db_session):
    """Users with an active book rental cannot delete their account until returned."""
    user = create_test_user(db_session, "active_rental_user@example.com", password="Pass123!Rental")
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Create test book & active rental order
    book = Book(title="Sample Rental Book", author="Author", price=100.0, stock=5, owner_id=user.id)
    db_session.add(book)
    db_session.commit()

    rental = RentalOrder(
        user_id=user.id,
        book_id=book.id,
        rental_days=14,
        rental_fee=50.0,
        status="active"
    )
    db_session.add(rental)
    db_session.commit()

    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "Pass123!Rental"})
    assert res.status_code == 400
    assert "active or unfulfilled orders, rentals" in res.json().get("detail", "").lower()

# =============================================================================
# 3. Successful Deletion & Data Erasure Tests
# =============================================================================

def test_zero_transaction_user_hard_deleted(client, db_session):
    """Users with zero financial/order history are completely hard-deleted, purging ancillary data."""
    user = create_test_user(db_session, "zero_tx_user@example.com", password="CleanDelete123!")
    user_id = user.id
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Add book, address, cart, favorite, notification
    book = Book(title="Fav Book", author="Author", price=100.0, stock=1, owner_id=user_id)
    db_session.add(book)
    db_session.commit()
    addr = Address(user_id=user_id, label="Home", recipient_name="Test User", phone_number="+919876543210", street="12 Elm St", city="Bengaluru", state="KA", zip_code="560001", is_default=True)
    cart = Cart(user_id=user_id)
    fav = Favorite(user_id=user_id, book_id=book.id)
    notif = Notification(user_id=user_id, title="Welcome", message="Hello")
    db_session.add_all([addr, cart, fav, notif])
    db_session.commit()

    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "CleanDelete123!"})
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["action_taken"] == "hard_deleted"

    # Verify user record is completely removed from DB
    deleted_user = db_session.query(User).filter(User.id == user_id).first()
    assert deleted_user is None

    # Verify ancillary records are purged
    assert db_session.query(Address).filter(Address.user_id == user_id).count() == 0
    assert db_session.query(Cart).filter(Cart.user_id == user_id).count() == 0
    assert db_session.query(Favorite).filter(Favorite.user_id == user_id).count() == 0
    assert db_session.query(Notification).filter(Notification.user_id == user_id).count() == 0

def test_financial_history_user_anonymized_and_preserved(client, db_session):
    """Users with completed orders are anonymized: PII is scrubbed while order/payment rows are preserved."""
    user = create_test_user(db_session, "financial_user@example.com", password="FinancialPass123!")
    user_id = user.id
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Create historical completed order & payment
    order = Order(
        user_id=user_id,
        status="delivered",
        shipping_status="delivered",
        handoff_status="handoff_completed",
        total_amount=599.0,
        total_amount_paise=59900,
        recipient_name="John Doe",
        recipient_phone="+919876543210",
        delivery_address="742 Evergreen Terrace, Bengaluru"
    )
    db_session.add(order)
    db_session.commit()

    payment = Payment(
        user_id=user_id,
        order_id=order.id,
        amount=599.0,
        status="paid",
        razorpay_order_id="order_test_999888",
        razorpay_payment_id="pay_test_777666"
    )
    db_session.add(payment)
    db_session.commit()

    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "FinancialPass123!"})
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert data["action_taken"] == "anonymized_and_scrubbed"
    assert len(data["retained_records"]) > 0

    # Verify user record still exists but is completely anonymized
    db_user = db_session.query(User).filter(User.id == user_id).first()
    assert db_user is not None
    assert db_user.name == "[Deleted User]"
    assert db_user.email.startswith(f"deleted_{user_id}_")
    assert db_user.email.endswith("@deleted.tactilearchive.org")
    assert db_user.phone is None
    assert db_user.address is None
    assert db_user.bio is None
    assert db_user.avatar_url is None
    assert db_user.role == "deleted"

    # Verify past order recipient info is redacted
    past_order = db_session.query(Order).filter(Order.id == order.id).first()
    assert past_order is not None
    assert past_order.recipient_name == "[Deleted User]"
    assert past_order.recipient_phone is None
    assert past_order.delivery_address == "[Redacted - Account Deleted]"

    # Verify order and payment rows remain intact for statutory audit compliance
    assert past_order.total_amount_paise == 59900
    past_payment = db_session.query(Payment).filter(Payment.id == payment.id).first()
    assert past_payment is not None
    assert past_payment.razorpay_payment_id == "pay_test_777666"
    assert past_payment.status == "paid"

# =============================================================================
# 4. Token Revocation & Repeat Request Rejection Tests
# =============================================================================

def test_token_revocation_prevents_subsequent_access(client, db_session):
    """After account deletion, the current session JWT is revoked and rejected on reuse."""
    user = create_test_user(db_session, "revoke_token_user@example.com", password="RevokeMe123!")
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Delete account
    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "RevokeMe123!"})
    assert res.status_code == 200

    # Attempt to reuse the exact same token for any authenticated request
    repeat_res = client.request("DELETE", "/users/me", headers=headers, json={"password": "RevokeMe123!"})
    assert repeat_res.status_code == 401
    assert "revoked" in repeat_res.json().get("detail", "").lower()

def test_login_with_deleted_account_rejected(client, db_session):
    """Deleted/anonymized users cannot log in with their old credentials."""
    user = create_test_user(db_session, "login_blocked_user@example.com", password="OldPassword123!")
    token = create_access_token({"sub": user.email, "role": user.role})
    headers = {"Authorization": f"Bearer {token}"}

    # Add historical order so user is anonymized rather than hard-deleted
    order = Order(user_id=user.id, status="delivered", shipping_status="delivered", handoff_status="handoff_completed", total_amount=199.0)
    db_session.add(order)
    db_session.commit()

    # Delete account
    res = client.request("DELETE", "/users/me", headers=headers, json={"password": "OldPassword123!"})
    assert res.status_code == 200

    # Attempt to log in with original credentials
    login_res = client.post("/login", json={"email": "login_blocked_user@example.com", "password": "OldPassword123!"})
    assert login_res.status_code in [400, 401]

def test_oauth_passwordless_deletion_success(client, db_session):
    """Google OAuth users can delete their account by providing confirmation token 'DELETE'."""
    oauth_user = create_test_user(db_session, "oauth_success@example.com", password=None, name="OAuth Reader")
    token = create_access_token({"sub": oauth_user.email, "role": oauth_user.role})
    headers = {"Authorization": f"Bearer {token}"}

    res = client.request("DELETE", "/users/me", headers=headers, json={"confirmation": "DELETE"})
    assert res.status_code == 200
    assert res.json()["success"] is True

# =============================================================================
# 5. Public External Account Deletion Portal Tests
# =============================================================================

def test_public_external_account_deletion_request(client):
    """External web account deletion endpoint registers requests with HTTP 200."""
    res = client.post("/auth/request-account-deletion", json={"email": "external_user@example.com", "reason": "no_longer_using"})
    assert res.status_code == 200
    data = res.json()
    assert data["success"] is True
    assert "received" in data["message"].lower() or "registered" in data["message"].lower()
    assert "request_id" in data

def test_public_external_deletion_invalid_email(client):
    """External deletion request rejects invalid email with HTTP 400."""
    res = client.post("/auth/request-account-deletion", json={"email": "invalid_email_string"})
    assert res.status_code == 400
    assert "valid email" in res.json().get("detail", "").lower()

def test_public_deletion_web_page_serves_html(client):
    """GET /delete-account serves a compliant HTML form page."""
    res = client.get("/delete-account")
    assert res.status_code == 200
    assert "Account Deletion Request" in res.text
    assert "Google Play" in res.text
