import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from unittest.mock import MagicMock
from fastapi import HTTPException
from starlette.requests import Request
from app.core.rate_limit import limiter
from app.core.database import SessionLocal
from app.models.user import User
from app.models.book import Book
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.schemas.user import UserCreate
from app.api.auth import register, hash_password
from app.api.admin import (
    require_admin, get_dashboard_stats, get_users, update_user_role,
    get_admin_providers, update_provider_status, get_admin_activity_logs,
    approve_book, reject_book, AdminRoleUpdate, ProviderStatusUpdate,
    AdminBookApprovalRequest
)
from app.api.provider import (
    require_provider, get_provider_dashboard, get_provider_inventory,
    get_provider_requests, get_provider_earnings, update_provider_book,
    delete_provider_book, update_provider_order_status,
    approve_request, reject_request, EditListingPayload, StatusUpdatePayload
)

@pytest.fixture(scope="module")
def setup_test_users():
    limiter.enabled = False
    db = SessionLocal()
    
    # Clean up test records
    test_emails = [
        "admin_phase18_5@example.com",
        "provider_phase18_5@example.com",
        "customer_phase18_5@example.com"
    ]
    for email in test_emails:
        u = db.query(User).filter(User.email == email).first()
        if u:
            # delete books
            db.query(Book).filter(Book.owner_id == u.id).delete()
            db.delete(u)
    db.commit()

    # Create Admin User
    admin = User(
        name="Marketplace Admin",
        email="admin_phase18_5@example.com",
        password=hash_password("AdminPass123!"),
        role="admin",
        is_admin=True,
        provider_enabled=True,
        is_verified=True
    )
    db.add(admin)

    # Create Provider User
    provider = User(
        name="Bookstore Provider",
        email="provider_phase18_5@example.com",
        password=hash_password("ProviderPass123!"),
        role="provider",
        is_admin=False,
        provider_enabled=True,
        provider_status="approved",
        is_verified=True
    )
    db.add(provider)

    # Create Normal Customer
    customer = User(
        name="Normal Reader",
        email="customer_phase18_5@example.com",
        password=hash_password("CustomerPass123!"),
        role="customer",
        is_admin=False,
        provider_enabled=False,
        provider_status="not_enrolled",
        is_verified=True
    )
    db.add(customer)
    db.commit()
    db.refresh(admin)
    db.refresh(provider)
    db.refresh(customer)

    # Add a test book owned by provider
    test_book = Book(
        title="Archival Typography & Design",
        author="Jan Tschichold",
        price=450.0,
        stock=5,
        condition="Like New",
        category="Design",
        description="A foundational work on editorial typography.",
        cover_url="https://images.unsplash.com/photo-1544947950-fa07a98d237f",
        owner_id=provider.id,
        condition_verification="verified"
    )
    db.add(test_book)
    db.commit()
    db.refresh(test_book)

    yield {
        "admin": admin,
        "provider": provider,
        "customer": customer,
        "book": test_book
    }

    # Teardown
    db = SessionLocal()
    for email in test_emails:
        u = db.query(User).filter(User.email == email).first()
        if u:
            db.query(Book).filter(Book.owner_id == u.id).delete()
            db.delete(u)
    db.commit()
    db.close()


def test_admin_authorization_gate(setup_test_users):
    """GATE 2: Enforce strict admin RBAC. Non-admins must be rejected with HTTP 403."""
    admin = setup_test_users["admin"]
    customer = setup_test_users["customer"]
    provider = setup_test_users["provider"]

    # 1. Admin passes require_admin check
    verified_admin = require_admin(admin)
    assert verified_admin.id == admin.id
    assert verified_admin.is_admin is True

    # 2. Customer fails require_admin check with 403
    with pytest.raises(HTTPException) as exc_info:
        require_admin(customer)
    assert exc_info.value.status_code == 403

    # 3. Provider (non-admin) fails require_admin check with 403
    with pytest.raises(HTTPException) as exc_info:
        require_admin(provider)
    assert exc_info.value.status_code == 403


def test_admin_dashboard_operations(setup_test_users):
    """GATE 2: Admin stats, user listing, role mutation, provider moderation, and activity log."""
    db = SessionLocal()
    admin = setup_test_users["admin"]
    customer = setup_test_users["customer"]
    provider = setup_test_users["provider"]
    book = setup_test_users["book"]

    try:
        # 1. Admin Stats
        stats = get_dashboard_stats(db=db, admin=admin)
        assert "totalUsers" in stats
        assert "totalBooks" in stats
        assert "totalOrders" in stats
        assert "pendingBooks" in stats
        assert "totalProviders" in stats
        assert stats["totalProviders"] >= 1

        # 2. List Users
        users = get_users(db=db, admin=admin)
        assert len(users) >= 3
        user_ids = [u["id"] for u in users]
        assert customer.id in user_ids

        # 3. Update User Role & Provider Activation
        role_payload = AdminRoleUpdate(
            level="Admin",
            is_admin=False,
            role="provider",
            provider_enabled=True,
            provider_status="approved"
        )
        res = update_user_role(user_id=customer.id, data=role_payload, db=db, admin=admin)
        assert res["message"] == "User roles updated successfully"

        # Verify customer was updated
        updated_customer = db.query(User).filter(User.id == customer.id).first()
        assert updated_customer.role == "provider"
        assert updated_customer.provider_enabled is True
        assert updated_customer.provider_status == "approved"

        # 4. List Providers
        providers = get_admin_providers(db=db, admin=admin)
        prov_ids = [p["id"] for p in providers]
        assert provider.id in prov_ids

        # 5. Update Provider Status
        status_payload = ProviderStatusUpdate(status="suspended")
        res = update_provider_status(user_id=customer.id, data=status_payload, db=db, admin=admin)
        assert "suspended" in res["message"]
        updated_customer = db.query(User).filter(User.id == customer.id).first()
        assert updated_customer.provider_status == "suspended"

        # Reset customer
        updated_customer.provider_enabled = False
        updated_customer.provider_status = "not_enrolled"
        updated_customer.role = "customer"
        db.commit()

        # 6. Moderate Book Listing
        mod_res = approve_book(book_id=book.id, data=AdminBookApprovalRequest(notes="Verified edition"), db=db, admin=admin)
        assert "approved" in mod_res["message"]

        # 7. Admin Activity Logs
        activity = get_admin_activity_logs(db=db, admin=admin)
        assert isinstance(activity, list)

    finally:
        db.close()


def test_seller_provider_authorization_gate(setup_test_users):
    """GATE 1: Enforce provider role checking."""
    provider = setup_test_users["provider"]
    customer = setup_test_users["customer"]

    # 1. Provider passes require_provider
    verified_prov = require_provider(provider)
    assert verified_prov.id == provider.id

    # 2. Unapproved customer fails require_provider with 403
    with pytest.raises(HTTPException) as exc_info:
        require_provider(customer)
    assert exc_info.value.status_code == 403


def test_seller_provider_dashboard_and_inventory(setup_test_users):
    """GATE 1: Provider overview, metrics, inventory retrieval, edit, and delete."""
    db = SessionLocal()
    provider = setup_test_users["provider"]
    book = setup_test_users["book"]

    try:
        # 1. Dashboard Overview
        dash = get_provider_dashboard(db=db, user=provider)
        assert "provider_name" in dash
        assert "metrics" in dash
        assert dash["metrics"]["total_listings"] >= 1
        assert "recent_inventory" in dash

        # 2. Inventory Listing
        inventory = get_provider_inventory(db=db, user=provider)
        assert len(inventory) >= 1
        assert any(b["id"] == book.id for b in inventory)

        # 3. Edit Listing (Price, Stock, Condition, Description)
        edit_payload = EditListingPayload(
            title="Archival Typography & Design (2nd Ed)",
            price=499.0,
            stock=8,
            condition="Like New",
            description="Updated description with collector notes."
        )
        updated_book = update_provider_book(book_id=book.id, payload=edit_payload, db=db, user=provider)
        assert updated_book["title"] == "Archival Typography & Design (2nd Ed)"
        assert updated_book["price"] == 499.0
        assert updated_book["stock"] == 8

        # 4. Provider Earnings
        earnings = get_provider_earnings(db=db, user=provider)
        assert "total_earned" in earnings
        assert "available_for_payout" in earnings
        assert "transactions" in earnings

    finally:
        db.close()


def test_seller_provider_requests_and_orders(setup_test_users):
    """GATE 1 & 3: Unified provider requests (Borrow, Rent, Buy) and fulfillment tracking."""
    db = SessionLocal()
    provider = setup_test_users["provider"]
    customer = setup_test_users["customer"]
    book = setup_test_users["book"]

    try:
        # Create a sample BorrowRequest for this provider's book
        borrow_req = BorrowRequest(
            user_id=customer.id,
            book_id=book.id,
            duration_days=14,
            status="pending"
        )
        db.add(borrow_req)

        # Create a sample RentalOrder
        rental_order = RentalOrder(
            user_id=customer.id,
            book_id=book.id,
            rental_fee=85.0,
            rental_days=14,
            status="active"
        )
        db.add(rental_order)

        # Create an Order with OrderItem for provider's book
        test_order = Order(
            user_id=customer.id,
            total_amount=499.0,
            status="confirmed",
            payment_status="paid"
        )
        db.add(test_order)
        db.commit()
        db.refresh(test_order)

        order_item = OrderItem(
            order_id=test_order.id,
            book_id=book.id,
            quantity=1,
            price=499.0
        )
        db.add(order_item)
        db.commit()

        # 1. Fetch Unified Provider Requests
        requests = get_provider_requests(db=db, user=provider)
        assert len(requests) >= 2
        categories = {r["request_category"] for r in requests}
        assert "borrow" in categories or "rental" in categories

        # 2. Approve Request
        app_res = approve_request(request_id=borrow_req.id, db=db, user=provider)
        assert app_res["status"] == "success"
        db.refresh(borrow_req)
        assert borrow_req.status == "approved"

        # 3. Reject Request
        rej_res = reject_request(request_id=borrow_req.id, db=db, user=provider)
        assert rej_res["status"] == "success"
        db.refresh(borrow_req)
        assert borrow_req.status == "rejected"

        # 4. Advance Provider Order Status (e.g. dispatched, delivered)
        status_payload = StatusUpdatePayload(status="dispatched")
        ord_res = update_provider_order_status(
            order_id=test_order.id,
            payload=status_payload,
            db=db,
            user=provider
        )
        assert ord_res["status"] == "success"
        db.refresh(test_order)
        assert test_order.status == "dispatched"

        # Cleanup test orders
        db.delete(order_item)
        db.delete(test_order)
        db.delete(rental_order)
        db.delete(borrow_req)
        db.commit()

    finally:
        db.close()


def test_seller_provider_delete_listing(setup_test_users):
    """GATE 1: Listing deletion with authorization protection."""
    db = SessionLocal()
    provider = setup_test_users["provider"]
    customer = setup_test_users["customer"]

    try:
        # Create temporary book to delete
        temp_book = Book(
            title="Temporary Deletable Book",
            author="Test Author",
            price=150.0,
            stock=2,
            owner_id=provider.id
        )
        db.add(temp_book)
        db.commit()
        db.refresh(temp_book)

        # 1. Customer cannot delete provider's book
        with pytest.raises(HTTPException) as exc_info:
            delete_provider_book(book_id=temp_book.id, db=db, user=customer)
        assert exc_info.value.status_code == 403

        # 2. Provider can delete own book
        del_res = delete_provider_book(book_id=temp_book.id, db=db, user=provider)
        assert del_res["status"] == "success"
        assert db.query(Book).filter(Book.id == temp_book.id).first() is None

    finally:
        db.close()
