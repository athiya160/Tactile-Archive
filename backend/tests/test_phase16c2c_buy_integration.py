import os
import hmac
import hashlib
import uuid
import pytest
import razorpay
from fastapi.testclient import TestClient
from app.main import app
from app.api.auth import create_access_token
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.order import Order, OrderItem, PurchaseOrder, RentalOrder
from app.models.payment import Payment
from app.models.cart import Cart, CartItem
from app.models.inventory_reservation import InventoryReservation
from app.services.inventory_service import (
    ARCHIVE_FEE_PAISE,
    SHIPPING_FEE_PAISE,
    create_reservation,
    claim_order_inventory,
)

@pytest.fixture(autouse=True)
def mock_razorpay_gateway(monkeypatch):
    """
    Test-only mock for external Razorpay API order creation.
    Intercepts rzp.order.create() without making external DNS/network calls.
    Preserves real HMAC signature verification logic.
    """
    def fake_order_create(self, data=None, **kwargs):
        suffix = uuid.uuid4().hex[:10]
        amount = (data or {}).get("amount", 99900)
        currency = (data or {}).get("currency", "INR")
        receipt = (data or {}).get("receipt", f"receipt_order_{suffix}")
        notes = (data or {}).get("notes", {})
        return {
            "id": f"order_buy_{suffix}",
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
def buy_test_user():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.email == "buy_test_user@libri.test").first()
        if not user:
            user = User(
                email="buy_test_user@libri.test",
                name="Ananya Roy",
                role="user",
                password="fake_hashed_password"
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        return {"id": user.id, "email": user.email, "name": user.name}
    finally:
        db.close()

@pytest.fixture(scope="module")
def auth_headers(buy_test_user):
    token = create_access_token(data={"sub": buy_test_user["email"]})
    return {"Authorization": f"Bearer {token}"}

@pytest.fixture(scope="module")
def buy_test_book():
    db = SessionLocal()
    try:
        book = db.query(Book).filter(Book.title == "Phase 16C2C Buy Journey Volume").first()
        if not book:
            book = Book(
                title="Phase 16C2C Buy Journey Volume",
                author="Bibliophile Kumar",
                price=250.0,
                stock=10,
                cover_url="https://example.com/buy_journey.jpg"
            )
            db.add(book)
            db.commit()
            db.refresh(book)
        else:
            book.stock = 10
            db.commit()
            db.refresh(book)
        return {"id": book.id, "title": book.title, "price": book.price}
    finally:
        db.close()

def generate_valid_signature(order_id: str, payment_id: str, secret: str = None) -> str:
    if secret is None:
        secret = os.getenv("RAZORPAY_KEY_SECRET", "ddwv2TgG1Y6n9gfBc3S37eaw")
    msg = f"{order_id}|{payment_id}".encode("utf-8")
    return hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()

def test_01_add_to_cart_and_quantity_management(client, auth_headers, buy_test_book, buy_test_user):
    """
    Step 2.1 & 2.2: Add item to cart with isPurchase=True and update quantity.
    """
    # 1. Clear cart specifically for buy_test_user
    db = SessionLocal()
    try:
        cart = db.query(Cart).filter(Cart.user_id == buy_test_user["id"]).first()
        if cart:
            db.query(CartItem).filter(CartItem.cart_id == cart.id).delete()
            db.commit()
    finally:
        db.close()

    # 2. Add to cart with isPurchase=True
    res = client.post(
        "/cart/items",
        json={"bookId": buy_test_book["id"], "isPurchase": True, "rentalDays": None},
        headers=auth_headers
    )
    assert res.status_code in [200, 201], f"Add to cart failed: {res.text}"

    # 3. Fetch cart and verify
    res_get = client.get("/cart", headers=auth_headers)
    assert res_get.status_code == 200
    cart_data = res_get.json()
    assert len(cart_data["items"]) >= 1
    cart_item = next(i for i in cart_data["items"] if int(i["bookId"]) == buy_test_book["id"])
    assert cart_item["isPurchase"] is True
    assert cart_item["quantity"] == 1
    assert cart_data["archiveFee"] == 1.20
    assert cart_data["shippingFee"] == 0.0

    # 4. Update quantity to 2
    item_id = int(cart_item["id"])
    res_update = client.put(
        f"/cart/items/{item_id}",
        json={"quantity": 2},
        headers=auth_headers
    )
    assert res_update.status_code == 200, f"Update quantity failed: {res_update.text}"

    # 5. Verify quantity is 2
    res_get2 = client.get("/cart", headers=auth_headers)
    assert res_get2.status_code == 200
    cart_item2 = next(i for i in res_get2.json()["items"] if int(i["id"]) == item_id)
    assert cart_item2["quantity"] == 2

def test_02_online_payment_order_creation_with_reservation(client, auth_headers, buy_test_book):
    """
    Step 2.3 & 2.6: Create online payment order for cart with inventory reservation.
    """
    res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "upi",
            "shipping_address": "402 Palm Heights, Whitefield, Bangalore - 560066",
            "mode": "cart"
        },
        headers=auth_headers
    )
    assert res.status_code == 200, f"Create payment order failed: {res.text}"
    data = res.json()
    assert data["is_cod"] is False
    assert "razorpay_order_id" in data
    assert data["currency"] == "INR"
    assert data["amount"] == int(250.0 * 2 * 100)  # 50000 paise

    # Verify inventory reservation exists in database
    db = SessionLocal()
    try:
        payment = db.query(Payment).filter(Payment.razorpay_order_id == data["razorpay_order_id"]).first()
        assert payment is not None
        assert payment.order_id is not None

        reservation = db.query(InventoryReservation).filter(
            InventoryReservation.order_id == payment.order_id,
            InventoryReservation.book_id == buy_test_book["id"],
            InventoryReservation.status == "active"
        ).first()
        assert reservation is not None
        assert reservation.quantity == 2

        # Verify Order additive paise fields
        order = db.query(Order).filter(Order.id == payment.order_id).first()
        assert order.items_total_paise == 50000
        assert order.platform_fee_paise == ARCHIVE_FEE_PAISE
        assert order.shipping_fee_paise == SHIPPING_FEE_PAISE
        assert order.status == "pending"
    finally:
        db.close()

def test_03_payment_verification_and_stock_claim(client, auth_headers, buy_test_book):
    """
    Step 2.6 & 2.8: Verify valid payment signature, claim reservation, deduct stock, create PurchaseOrder.
    """
    # 1. Fetch latest pending payment
    db = SessionLocal()
    try:
        payment = db.query(Payment).order_by(Payment.id.desc()).first()
        assert payment is not None
        order_id = payment.order_id
        rzp_order_id = payment.razorpay_order_id
    finally:
        db.close()

    payment_id = f"pay_valid_phase16c2c_{uuid.uuid4().hex[:10]}"
    valid_sig = generate_valid_signature(rzp_order_id, payment_id)

    # 2. Call verify endpoint
    res = client.post(
        "/payments/verify",
        json={
            "razorpay_order_id": rzp_order_id,
            "razorpay_payment_id": payment_id,
            "razorpay_signature": valid_sig
        },
        headers=auth_headers
    )
    assert res.status_code == 200, f"Payment verify failed: {res.text}"
    res_data = res.json()
    assert "Payment verified successfully" in res_data.get("message", "")
    assert res_data.get("order_id") == order_id

    # 3. Verify in database: stock deducted, order status processing/paid, purchase orders created, cart empty
    db = SessionLocal()
    try:
        order = db.query(Order).filter(Order.id == order_id).first()
        assert order.payment_status == "paid"
        assert order.status == "processing"
        assert order.stock_deducted is True

        # Verify PurchaseOrder created
        po = db.query(PurchaseOrder).filter(PurchaseOrder.order_id == order_id).first()
        assert po is not None
        assert po.book_id == buy_test_book["id"]
        assert po.status == "completed"

        # Verify Reservation fulfilled
        reservation = db.query(InventoryReservation).filter(InventoryReservation.order_id == order_id).first()
        assert reservation is not None
        assert reservation.status == "fulfilled"
    finally:
        db.close()

def test_04_direct_buy_cod_order(client, auth_headers, buy_test_book):
    """
    Step 2.7: Direct Buy via Cash on Delivery (COD) without Razorpay.
    """
    res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "cod",
            "shipping_address": "Flat 102, Green Glen Layout, Bellandur, Bangalore - 560103",
            "mode": "purchase",
            "book_id": buy_test_book["id"]
        },
        headers=auth_headers
    )
    assert res.status_code == 200, f"COD create order failed: {res.text}"
    data = res.json()
    assert data["success"] is True
    assert data["is_cod"] is True
    assert "order_id" in data
    order_id = data["order_id"]

    # Verify order state in DB
    db = SessionLocal()
    try:
        order = db.query(Order).filter(Order.id == order_id).first()
        assert order is not None
        assert order.payment_method == "cod"
        assert order.payment_status == "cod_pending"
        assert order.status == "placed"
        assert order.stock_deducted is True

        po = db.query(PurchaseOrder).filter(PurchaseOrder.order_id == order_id).first()
        assert po is not None
        assert po.status == "completed"
    finally:
        db.close()

def test_05_out_of_stock_validation(client, auth_headers):
    """
    Step 2.4 & 2.9: Rejection when book has insufficient stock.
    """
    # Create temporary out of stock book
    db = SessionLocal()
    try:
        oos_book = Book(
            title="Out Of Stock Test Book",
            author="Empty Shelves",
            price=199.0,
            stock=0
        )
        db.add(oos_book)
        db.commit()
        db.refresh(oos_book)
        oos_id = oos_book.id
    finally:
        db.close()

    # Attempt to create COD order on out-of-stock book
    res = client.post(
        "/payments/create-order",
        json={
            "payment_method": "cod",
            "shipping_address": "Test Address",
            "mode": "purchase",
            "book_id": oos_id
        },
        headers=auth_headers
    )
    assert res.status_code == 400
    assert "out of stock" in res.text.lower()

def test_06_order_history_endpoint_integration(client, auth_headers):
    """
    Step 2.8: Fetch orders list and verify additive paise fields and order items.
    """
    res = client.get("/orders", headers=auth_headers)
    assert res.status_code == 200, f"Get orders failed: {res.text}"
    orders = res.json()
    assert len(orders) >= 1

    latest_order = orders[0]
    assert "items" in latest_order
    assert "items_total_paise" in latest_order
    assert "platform_fee_paise" in latest_order
    assert "shipping_fee_paise" in latest_order
    assert "total_amount_paise" in latest_order

    first_item = latest_order["items"][0]
    assert "transaction_type" in first_item
    assert first_item["transaction_type"] in ["buy", "rent"]

def test_07_rent_and_borrow_workflows_preserved(client, auth_headers, buy_test_book):
    """
    Step 3: Verify Rent and Borrow endpoints remain intact.
    """
    # Test Rent order creation
    res_rent = client.post(
        "/payments/create-order",
        json={
            "payment_method": "cod",
            "shipping_address": "Hostel 4, Campus Library Road",
            "mode": "rental",
            "book_id": buy_test_book["id"],
            "rental_days": 14
        },
        headers=auth_headers
    )
    assert res_rent.status_code == 200, f"Rent create order failed: {res_rent.text}"
    assert res_rent.json()["success"] is True

    # Test Borrow request endpoint
    res_borrow = client.post(
        "/orders/borrow",
        json={"book_id": buy_test_book["id"], "duration_days": 14},
        headers=auth_headers
    )
    assert res_borrow.status_code == 200, f"Borrow request failed: {res_borrow.text}"
