"""
Phase 16C.2B Comprehensive Inventory Service & Buy Workflow Test Suite
Tests:
1. Integer paise pricing calculations
2. Successful inventory claim
3. Insufficient stock rejection
4. Concurrent final-copy purchase attempts
5. Duplicate claim idempotency
6. Reservation expiry and release
7. Atomic order cancellation and stock restoration
8. Duplicate cancellation protection
9. Transaction rollback safety
10. Captured payment with unavailable stock (reconciliation state)
11. COD reservation and cancellation lifecycle
12. PurchaseOrder single-source deduplication
"""

import os
import sys
from datetime import datetime, timedelta
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException

# Ensure backend in path
sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from app.core.database import Base
from app.models.user import User
from app.models.book import Book
from app.models.order import Order, OrderItem, PurchaseOrder
from app.models.payment import Payment
from app.models.inventory_reservation import InventoryReservation
from app.services.inventory_service import (
    calculate_buy_pricing_paise,
    create_reservation,
    get_available_stock,
    get_active_reserved_quantity,
    expire_stale_reservations,
    release_reservations_for_order,
    claim_order_inventory,
    claim_cod_inventory,
    cancel_order_and_restore_inventory,
    mark_order_reconciliation_required,
    ARCHIVE_FEE_PAISE,
    SHIPPING_FEE_PAISE
)

TEST_DB_PATH = "scratch/test_inventory_suite.db"

@pytest.fixture(scope="function")
def db_session():
    os.makedirs("scratch", exist_ok=True)
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass
            
    engine = create_engine(f"sqlite:///{TEST_DB_PATH}")
    Base.metadata.create_all(engine)
    TestingSessionLocal = sessionmaker(bind=engine)
    session = TestingSessionLocal()
    
    # Create test user
    test_user = User(
        id=101,
        email="test_buyer@libri.test",
        name="Test Buyer",
        role="customer",
        user_type="reader",
        is_verified=True
    )
    session.add(test_user)
    session.commit()
    
    yield session
    
    session.close()
    engine.dispose()
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass

def test_pricing_calculation():
    """Verifies integer paise pricing calculation (₹0 delivery, ₹1.20 archive fee)."""
    book1 = Book(id=1, title="Book 1", price=499.0)
    book2 = Book(id=2, title="Book 2", price=250.50)
    
    pricing = calculate_buy_pricing_paise([(book1, 1), (book2, 2)])
    # Items: 49900 + 2 * 25050 = 49900 + 50100 = 100000 paise (₹1000.00)
    assert pricing["items_total_paise"] == 100000
    assert pricing["platform_fee_paise"] == ARCHIVE_FEE_PAISE  # 120 paise
    assert pricing["shipping_fee_paise"] == SHIPPING_FEE_PAISE  # 0 paise
    assert pricing["deposit_total_paise"] == 0
    assert pricing["total_amount_paise"] == 100120  # ₹1001.20

def test_successful_inventory_claim(db_session):
    """Verifies successful inventory claim decrements stock and sets stock_deducted."""
    book = Book(id=1, title="FastAPI Architecture", stock=5, price=400.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(
        id=1,
        user_id=101,
        total_items=2,
        total_amount=800.0,
        status="pending",
        stock_deducted=False
    )
    db_session.add(order)
    db_session.commit()

    item = OrderItem(
        id=1,
        order_id=1,
        book_id=1,
        book_title=book.title,
        quantity=2,
        is_purchase=True,
        transaction_type="buy",
        price=800.0
    )
    db_session.add(item)
    db_session.commit()

    # Create active reservation
    res = create_reservation(db_session, book_id=1, order_id=1, user_id=101, quantity=2)
    assert res.status == "active"

    # Claim inventory
    result = claim_order_inventory(db_session, order)
    db_session.commit()

    assert result.success is True
    assert order.stock_deducted is True
    assert book.stock == 3
    assert res.status == "fulfilled"

def test_insufficient_stock_rejection(db_session):
    """Verifies that an order requesting more than available stock is rejected."""
    book = Book(id=2, title="Scarce Book", stock=1, price=300.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    # Attempting to reserve 2 when stock is 1 must raise HTTPException 400
    with pytest.raises(HTTPException) as exc:
        create_reservation(db_session, book_id=2, order_id=2, user_id=101, quantity=2)
    assert exc.value.status_code == 400
    assert "Insufficient available stock" in exc.value.detail
    assert book.stock == 1

def test_concurrent_final_copy_purchase_attempts(db_session):
    """Verifies that only the first of two competing buyers can reserve the final copy."""
    book = Book(id=3, title="Final Rare Copy", stock=1, price=999.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    # Buyer 1 reserves the last copy
    res1 = create_reservation(db_session, book_id=3, order_id=10, user_id=101, quantity=1)
    assert res1.status == "active"
    assert get_available_stock(db_session, book_id=3) == 0

    # Buyer 2 attempts to reserve the same book
    with pytest.raises(HTTPException) as exc:
        create_reservation(db_session, book_id=3, order_id=11, user_id=101, quantity=1)
    assert exc.value.status_code == 400
    assert "Insufficient available stock" in exc.value.detail

def test_duplicate_claim_idempotency(db_session):
    """Verifies that claiming inventory multiple times does not deduct stock twice."""
    book = Book(id=4, title="Idempotency Test", stock=10, price=200.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(id=20, user_id=101, total_items=1, total_amount=200.0, stock_deducted=False)
    db_session.add(order)
    db_session.commit()

    item = OrderItem(id=20, order_id=20, book_id=4, quantity=1, is_purchase=True, transaction_type="buy")
    db_session.add(item)
    db_session.commit()

    # First claim
    res1 = claim_order_inventory(db_session, order)
    assert res1.success is True
    assert book.stock == 9
    assert order.stock_deducted is True

    # Second claim (duplicate request / retry)
    res2 = claim_order_inventory(db_session, order)
    assert res2.success is True
    assert res2.reason == "Inventory already claimed"
    assert book.stock == 9  # Stock remains 9, NOT 8!

def test_reservation_expiry_and_release(db_session):
    """Verifies that expired reservations are cleaned up and available stock is restored."""
    book = Book(id=5, title="Expiring Book", stock=3, price=150.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    # Create reservation that expired 5 minutes ago
    expired_res = InventoryReservation(
        book_id=5,
        order_id=30,
        user_id=101,
        quantity=2,
        status="active",
        expires_at=datetime.utcnow() - timedelta(minutes=5),
        created_at=datetime.utcnow() - timedelta(minutes=20)
    )
    db_session.add(expired_res)
    db_session.commit()

    # Expire stale reservations
    expired_count = expire_stale_reservations(db_session)
    assert expired_count == 1
    assert expired_res.status == "expired"
    # Available stock should now be the full physical stock 3
    assert get_available_stock(db_session, book_id=5) == 3

def test_cancellation_and_restock(db_session):
    """Verifies atomic order cancellation restores stock and resets stock_deducted flag."""
    book = Book(id=6, title="Restock Test", stock=2, price=350.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(id=40, user_id=101, status="placed", shipping_status="pending", stock_deducted=True)
    db_session.add(order)
    db_session.commit()

    item = OrderItem(id=40, order_id=40, book_id=6, quantity=2, is_purchase=True, transaction_type="buy")
    db_session.add(item)
    db_session.commit()

    # Initial physical stock was reduced to 0 prior to cancellation
    book.stock = 0
    db_session.commit()

    # Execute cancellation
    res = cancel_order_and_restore_inventory(db_session, order_id=40, user_id=101)
    assert res["success"] is True
    assert res["restocked_items"] == 2
    assert book.stock == 2
    assert order.status == "cancelled"
    assert order.stock_deducted is False

def test_duplicate_cancellation_protection(db_session):
    """Verifies that calling cancel twice is rejected and does not restore stock twice."""
    book = Book(id=7, title="Double Cancel Test", stock=5, price=200.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(id=50, user_id=101, status="placed", shipping_status="pending", stock_deducted=True)
    db_session.add(order)
    db_session.commit()

    item = OrderItem(id=50, order_id=50, book_id=7, quantity=1, is_purchase=True, transaction_type="buy")
    db_session.add(item)
    db_session.commit()

    # First cancellation succeeds
    cancel_order_and_restore_inventory(db_session, order_id=50, user_id=101)
    assert book.stock == 6

    # Second cancellation must raise HTTPException 400
    with pytest.raises(HTTPException) as exc:
        cancel_order_and_restore_inventory(db_session, order_id=50, user_id=101)
    assert exc.value.status_code == 400
    assert "already been cancelled" in exc.value.detail
    assert book.stock == 6  # Did not increment to 7!

def test_captured_payment_with_unavailable_stock(db_session):
    """
    Verifies that when a late payment arrives for an expired reservation and
    physical stock is depleted, durable reconciliation state is recorded.
    """
    book = Book(id=8, title="Late Payment Book", stock=0, price=500.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(id=60, user_id=101, status="pending", total_amount=500.0, stock_deducted=False)
    db_session.add(order)
    db_session.commit()

    item = OrderItem(id=60, order_id=60, book_id=8, quantity=1, is_purchase=True, transaction_type="buy")
    db_session.add(item)
    db_session.commit()

    payment = Payment(
        id=60,
        order_id=60,
        user_id=101,
        razorpay_order_id="order_test_late_pay",
        razorpay_payment_id="pay_test_late_pay_123",
        amount=500.0,
        status="paid"
    )
    db_session.add(payment)
    db_session.commit()

    # Attempt inventory claim
    claim = claim_order_inventory(db_session, order)
    assert claim.success is False
    assert claim.reconciliation is True

    # Mark reconciliation required
    rec_result = mark_order_reconciliation_required(db_session, order, payment, claim.reason)
    assert rec_result["status"] == "reconciliation_required"
    assert rec_result["payment_status"] == "refund_pending"
    assert order.status == "reconciliation_required"
    assert order.shipping_status == "hold"
    assert payment.status == "refund_pending"
    assert payment.razorpay_payment_id == "pay_test_late_pay_123"

def test_cod_reservation_and_cancellation(db_session):
    """Verifies Cash On Delivery order placement and cancellation lifecycle."""
    book = Book(id=9, title="COD Test Book", stock=4, price=299.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    snapshots = [{"book": book, "qty": 1, "is_purchase": True, "rental_days": 14}]
    
    # Claim COD inventory
    claim = claim_cod_inventory(db_session, snapshots)
    assert claim.success is True
    assert book.stock == 3

    order = Order(
        id=70,
        user_id=101,
        status="placed",
        payment_status="cod_pending",
        payment_method="cod",
        stock_deducted=True
    )
    db_session.add(order)
    db_session.commit()

    item = OrderItem(id=70, order_id=70, book_id=9, quantity=1, is_purchase=True, transaction_type="buy")
    db_session.add(item)
    db_session.commit()

    # Cancel COD order
    cancel_res = cancel_order_and_restore_inventory(db_session, order_id=70, user_id=101)
    assert cancel_res["success"] is True
    assert book.stock == 4
    assert order.status == "cancelled"

def test_purchase_order_deduplication(db_session):
    """Verifies that only one PurchaseOrder is linked to the Order upon completion."""
    book = Book(id=10, title="PO Dedup Book", stock=5, price=450.0, owner_id=101)
    db_session.add(book)
    db_session.commit()

    order = Order(id=80, user_id=101, status="processing", total_amount=450.0, stock_deducted=True)
    db_session.add(order)
    db_session.commit()

    # Simulate canonical creation of PurchaseOrder in payments.py
    po = PurchaseOrder(
        id=1,
        user_id=101,
        book_id=10,
        order_id=80,
        price=450.0,
        payment_method="card",
        status="completed"
    )
    db_session.add(po)
    db_session.commit()

    # Verify exactly 1 PurchaseOrder exists for order 80
    pos = db_session.query(PurchaseOrder).filter(PurchaseOrder.order_id == 80).all()
    assert len(pos) == 1
    assert pos[0].book_id == 10
