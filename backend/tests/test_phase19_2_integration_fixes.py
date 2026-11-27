import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.models.order import Order, OrderItem, PurchaseOrder, RentalOrder, BorrowRequest
from app.models.notification import Notification
from app.api.auth import hash_password, create_access_token

@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture
def test_client():
    with TestClient(app) as client:
        yield client

@pytest.fixture
def seed_test_users(db_session):
    # Ensure provider 1 exists
    p1 = db_session.query(User).filter(User.email == "p19_provider1@test.com").first()
    if not p1:
        p1 = User(
            email="p19_provider1@test.com",
            password=hash_password("Pass123!"),
            role="provider",
            user_type="reader",
            active_experience="reader",
            provider_enabled=True,
            provider_status="active",
            is_verified=True,
            onboarding_completed=True
        )
        db_session.add(p1)
        db_session.commit()
        db_session.refresh(p1)

    # Ensure provider 2 exists (for authorization checks)
    p2 = db_session.query(User).filter(User.email == "p19_provider2@test.com").first()
    if not p2:
        p2 = User(
            email="p19_provider2@test.com",
            password=hash_password("Pass123!"),
            role="provider",
            user_type="reader",
            active_experience="reader",
            provider_enabled=True,
            provider_status="active",
            is_verified=True,
            onboarding_completed=True
        )
        db_session.add(p2)
        db_session.commit()
        db_session.refresh(p2)

    # Ensure customer exists
    cust = db_session.query(User).filter(User.email == "p19_customer@test.com").first()
    if not cust:
        cust = User(
            email="p19_customer@test.com",
            password=hash_password("Pass123!"),
            role="customer",
            user_type="reader",
            active_experience="reader",
            provider_enabled=False,
            provider_status="not_enrolled",
            is_verified=True,
            onboarding_completed=True
        )
        db_session.add(cust)
        db_session.commit()
        db_session.refresh(cust)

    return {
        "p1": p1,
        "p2": p2,
        "cust": cust,
        "p1_token": create_access_token({"sub": p1.email, "role": p1.role}),
        "p2_token": create_access_token({"sub": p2.email, "role": p2.role}),
        "cust_token": create_access_token({"sub": cust.email, "role": cust.role})
    }

def test_experience_update_flexible_payload(test_client, seed_test_users):
    cust_token = seed_test_users["cust_token"]
    headers = {"Authorization": f"Bearer {cust_token}"}

    # 1. Switch using 'experience'
    r1 = test_client.put("/users/me/experience", json={"experience": "student"}, headers=headers)
    assert r1.status_code == 200, r1.text
    data1 = r1.json()
    assert data1["active_experience"] == "student"

    # 2. Switch using 'persona'
    r2 = test_client.put("/users/me/experience", json={"persona": "reader"}, headers=headers)
    assert r2.status_code == 200, r2.text
    assert r2.json()["active_experience"] == "reader"

    # 3. Switch using 'active_experience'
    r3 = test_client.put("/users/me/experience", json={"active_experience": "student"}, headers=headers)
    assert r3.status_code == 200, r3.text
    assert r3.json()["active_experience"] == "student"

    # 4. Invalid experience returns 400
    r4 = test_client.put("/users/me/experience", json={"active_experience": "hacker"}, headers=headers)
    assert r4.status_code == 400

    # 5. Missing payload returns 400
    r5 = test_client.put("/users/me/experience", json={}, headers=headers)
    assert r5.status_code == 400

def test_cart_item_flexible_payload(test_client, seed_test_users, db_session):
    cust_token = seed_test_users["cust_token"]
    headers = {"Authorization": f"Bearer {cust_token}"}
    p1 = seed_test_users["p1"]

    # Create a book to add
    book = db_session.query(Book).filter(Book.owner_id == p1.id).first()
    if not book:
        book = Book(
            title="Cart Test Book",
            author="Cart Author",
            price=250.0,
            stock=5,
            owner_id=p1.id
        )
        db_session.add(book)
        db_session.commit()
        db_session.refresh(book)

    # 1. Add using snake_case 'book_id'
    r1 = test_client.post("/cart/items", json={"book_id": book.id, "quantity": 2}, headers=headers)
    assert r1.status_code == 200, r1.text

    # 2. Add using camelCase 'bookId'
    r2 = test_client.post("/cart/items", json={"bookId": book.id, "isPurchase": True}, headers=headers)
    assert r2.status_code == 200, r2.text

    # 3. Missing both returns 422
    r3 = test_client.post("/cart/items", json={"isPurchase": True}, headers=headers)
    assert r3.status_code == 422

def test_add_book_cover_url_and_stock(test_client, seed_test_users, db_session):
    p1_token = seed_test_users["p1_token"]
    headers = {"Authorization": f"Bearer {p1_token}"}

    payload = {
        "title": "Quantum Integration Book",
        "author": "Dr. Integration",
        "description": "Comprehensive integration testing guide",
        "price": 450.0,
        "category": "Technology",
        "condition": "Like New",
        "stock": 10,
        "coverUrl": "https://images.example.com/quantum.jpg",
        "pickupAddress": "123 Tech Lane, Bangalore",
        "listingType": "Sell"
    }

    resp = test_client.post("/books", json=payload, headers=headers)
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["title"] == "Quantum Integration Book"
    assert data["cover_url"] == "https://images.example.com/quantum.jpg"

    # Verify stock in DB
    created_book = db_session.query(Book).filter(Book.id == data["id"]).first()
    assert created_book is not None
    assert created_book.stock == 10
    assert created_book.cover_url == "https://images.example.com/quantum.jpg"

def test_provider_edit_listing_cover_url(test_client, seed_test_users, db_session):
    p1 = seed_test_users["p1"]
    p1_token = seed_test_users["p1_token"]
    p2_token = seed_test_users["p2_token"]

    book = Book(
        title="Listing for Update",
        author="Author A",
        price=100.0,
        stock=2,
        owner_id=p1.id
    )
    db_session.add(book)
    db_session.commit()
    db_session.refresh(book)

    # 1. P1 updates their book using coverUrl
    resp1 = test_client.put(
        f"/provider/inventory/{book.id}",
        json={"coverUrl": "https://images.example.com/updated.jpg", "stock": 7},
        headers={"Authorization": f"Bearer {p1_token}"}
    )
    assert resp1.status_code == 200, resp1.text
    assert resp1.json()["cover_url"] == "https://images.example.com/updated.jpg"

    # 2. P2 cannot update P1's book
    resp2 = test_client.put(
        f"/provider/inventory/{book.id}",
        json={"stock": 99},
        headers={"Authorization": f"Bearer {p2_token}"}
    )
    assert resp2.status_code == 403

def test_provider_requests_approval_rejection_and_notifications(test_client, seed_test_users, db_session):
    p1 = seed_test_users["p1"]
    p2 = seed_test_users["p2"]
    cust = seed_test_users["cust"]
    p1_token = seed_test_users["p1_token"]
    p2_token = seed_test_users["p2_token"]

    # Book owned by P1
    book = Book(
        title="Notification & Order Test Book",
        author="Notif Author",
        price=300.0,
        stock=3,
        owner_id=p1.id
    )
    db_session.add(book)
    db_session.commit()
    db_session.refresh(book)

    # 1. Test PurchaseOrder approval
    po = PurchaseOrder(
        user_id=cust.id,
        book_id=book.id,
        price=300.0,
        status="pending"
    )
    db_session.add(po)
    db_session.commit()
    db_session.refresh(po)

    # P2 (unauthorized) cannot approve
    unauth_resp = test_client.post(
        f"/provider/requests/{po.id}/approve",
        headers={"Authorization": f"Bearer {p2_token}"}
    )
    assert unauth_resp.status_code == 403

    # P1 approves PurchaseOrder
    appr_resp = test_client.post(
        f"/provider/requests/{po.id}/approve",
        headers={"Authorization": f"Bearer {p1_token}"}
    )
    assert appr_resp.status_code == 200
    db_session.refresh(po)
    assert po.status == "completed"

    # Verify customer received notification
    notif = db_session.query(Notification).filter(
        Notification.user_id == cust.id,
        Notification.title == "Purchase Order Approved"
    ).first()
    assert notif is not None
    assert "confirmed by the seller" in notif.message

    # 2. Test RentalOrder rejection
    ro = RentalOrder(
        user_id=cust.id,
        book_id=book.id,
        rental_days=14,
        rental_fee=50.0,
        status="pending"
    )
    db_session.add(ro)
    db_session.commit()
    db_session.refresh(ro)

    rej_resp = test_client.post(
        f"/provider/requests/{ro.id}/reject",
        headers={"Authorization": f"Bearer {p1_token}"}
    )
    assert rej_resp.status_code == 200
    db_session.refresh(ro)
    assert ro.status == "cancelled"

    # Verify customer received decline notification
    ro_notif = db_session.query(Notification).filter(
        Notification.user_id == cust.id,
        Notification.title == "Rental Order Declined"
    ).first()
    assert ro_notif is not None

def test_provider_order_status_update_creates_notification(test_client, seed_test_users, db_session):
    p1 = seed_test_users["p1"]
    cust = seed_test_users["cust"]
    p1_token = seed_test_users["p1_token"]

    book = Book(
        title="Shipped Order Book",
        author="Ship Author",
        price=150.0,
        stock=1,
        owner_id=p1.id
    )
    db_session.add(book)
    db_session.commit()
    db_session.refresh(book)

    order = Order(
        user_id=cust.id,
        status="processing",
        total_amount=150.0
    )
    db_session.add(order)
    db_session.commit()
    db_session.refresh(order)

    order_item = OrderItem(
        order_id=order.id,
        book_id=book.id,
        price=150.0,
        quantity=1,
        is_purchase=True,
        transaction_type="buy"
    )
    db_session.add(order_item)
    db_session.commit()

    # P1 advances status to 'dispatched'
    resp = test_client.put(
        f"/provider/orders/{order.id}/status",
        json={"status": "dispatched"},
        headers={"Authorization": f"Bearer {p1_token}"}
    )
    assert resp.status_code == 200, resp.text
    db_session.refresh(order)
    assert order.status == "dispatched"

    # Verify notification created for customer
    notif = db_session.query(Notification).filter(
        Notification.user_id == cust.id,
        Notification.title == "Order Status Updated"
    ).order_by(Notification.id.desc()).first()
    assert notif is not None
    assert "dispatched" in notif.message

def test_auth_logout_and_refresh_token(test_client, seed_test_users):
    from app.core.security import create_refresh_token, create_access_token
    cust = seed_test_users["cust"]
    temp_access = create_access_token({"sub": cust.email, "role": cust.role})
    temp_refresh = create_refresh_token({"sub": cust.email, "role": cust.role})

    # 1. Access protected route with temp token
    r1 = test_client.get("/auth/me", headers={"Authorization": f"Bearer {temp_access}"})
    assert r1.status_code == 200

    # 2. Logout / invalidate temp token
    r_logout = test_client.post("/auth/logout", headers={"Authorization": f"Bearer {temp_access}"})
    assert r_logout.status_code == 200
    assert "revoked" in r_logout.json()["message"] or "invalidated" in r_logout.json()["message"]

    # 3. Subsequent request with invalidated token returns 401
    r_revoked = test_client.get("/auth/me", headers={"Authorization": f"Bearer {temp_access}"})
    assert r_revoked.status_code == 401
    assert "revoked" in r_revoked.json()["detail"].lower()

    # 4. Refresh token to obtain new access token
    r_refresh = test_client.post("/auth/refresh", json={"refresh_token": temp_refresh})
    assert r_refresh.status_code == 200
    refresh_data = r_refresh.json()
    new_access = refresh_data["access_token"]
    assert new_access != temp_access

    # 5. Access protected route with new access token
    r_new = test_client.get("/auth/me", headers={"Authorization": f"Bearer {new_access}"})
    assert r_new.status_code == 200
    assert r_new.json()["email"] == cust.email

def test_login_and_register_emit_refresh_tokens(test_client):
    import uuid
    unique_suffix = uuid.uuid4().hex[:6]
    test_email = f"auth_renewal_{unique_suffix}@test.com"
    test_pass = "SecurePass123!"

    # 1. Register emits refresh_token
    r_reg = test_client.post("/register", json={
        "email": test_email,
        "password": test_pass,
        "name": f"User {unique_suffix}",
        "role": "customer"
    })
    assert r_reg.status_code == 200, r_reg.text
    reg_data = r_reg.json()
    assert "access_token" in reg_data
    assert "refresh_token" in reg_data
    assert len(reg_data["refresh_token"]) > 20

    # 2. Login emits refresh_token
    r_login = test_client.post("/login", json={
        "email": test_email,
        "password": test_pass
    })
    assert r_login.status_code == 200, r_login.text
    login_data = r_login.json()
    assert "access_token" in login_data
    assert "refresh_token" in login_data
    assert len(login_data["refresh_token"]) > 20

    # 3. Exchange refresh_token for new session
    r_ref = test_client.post("/auth/refresh", json={
        "refresh_token": login_data["refresh_token"]
    })
    assert r_ref.status_code == 200
    ref_data = r_ref.json()
    assert "access_token" in ref_data
    assert "refresh_token" in ref_data

    # 4. Invalid refresh token returns 401
    r_invalid = test_client.post("/auth/refresh", json={
        "refresh_token": "invalid_corrupt_refresh_token"
    })
    assert r_invalid.status_code == 401
