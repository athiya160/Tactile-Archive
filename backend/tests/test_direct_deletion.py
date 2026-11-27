import os
import sys
import uuid
import hashlib

sys.path.insert(0, os.path.abspath('.'))
sys.path.insert(0, os.path.abspath('backend'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core.database import Base
from app.api.auth import (
    delete_user_account,
    get_current_user,
    hash_password,
    create_access_token,
    REVOKED_TOKENS,
    render_account_deletion_html,
    render_privacy_policy_html,
    request_account_deletion_external
)
from app.schemas.user import AccountDeleteRequest, PublicAccountDeletionRequest
from app.models.user import User
from app.models.account_deletion_request import AccountDeletionRequest
from app.models.book import Book
from app.models.order import Order, RentalOrder, BorrowRequest
from app.models.payment import Payment
from app.models.address import Address
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.notification import Notification

TEST_DB = "scratch/test_direct_safe.db"
LIVE_DB = "backend/tactile_archive.db"

def sha256_file(p):
    if not os.path.exists(p): return None
    with open(p, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

initial_hash = sha256_file(LIVE_DB)

if os.path.exists(TEST_DB):
    try: os.remove(TEST_DB)
    except Exception: pass

engine = create_engine(f"sqlite:///{TEST_DB}", connect_args={"check_same_thread": False})
Session = sessionmaker(bind=engine)
Base.metadata.create_all(bind=engine)

def run():
    print("--- 1. Testing Unauthenticated Deletion Guard ---")
    db = Session()
    try:
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid_token")
        try:
            get_current_user(credentials=creds, db=db)
            assert False, "Should have raised 401"
        except HTTPException as e:
            assert e.status_code == 401
            print("Passed: unauthenticated rejected with 401")

        print("--- 2. Testing Invalid Password Rejection ---")
        user = User(email="test_pwd@example.com", password=hash_password("RealPass123!"), name="Test", role="customer")
        db.add(user)
        db.commit()
        db.refresh(user)

        token = create_access_token({"sub": user.email, "role": user.role})
        creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        try:
            delete_user_account(payload=AccountDeleteRequest(password="WrongPass!"), credentials=creds, db=db, user=user)
            assert False, "Should have rejected wrong password"
        except HTTPException as e:
            assert e.status_code == 400
            assert "Invalid password" in e.detail
            print("Passed: invalid password rejected with 400")

        print("--- 3. Testing OAuth Missing Confirmation ---")
        oauth_user = User(email="oauth@example.com", password=None, name="OAuth", role="customer")
        db.add(oauth_user)
        db.commit()
        db.refresh(oauth_user)

        token_o = create_access_token({"sub": oauth_user.email, "role": oauth_user.role})
        creds_o = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_o)
        try:
            delete_user_account(payload=AccountDeleteRequest(confirmation="NO"), credentials=creds_o, db=db, user=oauth_user)
            assert False, "Should reject invalid confirmation"
        except HTTPException as e:
            assert e.status_code == 400
            assert "Confirmation required" in e.detail
            print("Passed: missing/invalid OAuth confirmation rejected with 400")

        print("--- 4. Testing Active Fulfillment Safeguard (Active Order) ---")
        active_user = User(email="active_ord@example.com", password=hash_password("Pass123!"), name="Active", role="customer")
        db.add(active_user)
        db.commit()
        db.refresh(active_user)

        active_order = Order(user_id=active_user.id, status="processing", total_amount=100.0)
        db.add(active_order)
        db.commit()

        token_a = create_access_token({"sub": active_user.email, "role": active_user.role})
        creds_a = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_a)
        try:
            delete_user_account(payload=AccountDeleteRequest(password="Pass123!"), credentials=creds_a, db=db, user=active_user)
            assert False, "Should block deletion with active order"
        except HTTPException as e:
            assert e.status_code == 400
            assert "active or unfulfilled orders" in e.detail.lower()
            print("Passed: active order blocks deletion with 400")

        print("--- 5. Testing Zero Transaction Hard Delete ---")
        clean_user = User(email="clean@example.com", password=hash_password("Pass123!"), name="Clean", role="customer")
        db.add(clean_user)
        db.commit()
        db.refresh(clean_user)
        clean_id = clean_user.id

        addr = Address(user_id=clean_id, label="Home", recipient_name="Clean User", phone_number="+919876543210", street="123 Street", city="Bangalore", state="KA", zip_code="560001", is_default=True)
        cart = Cart(user_id=clean_id)
        db.add_all([addr, cart])
        db.commit()

        token_c = create_access_token({"sub": clean_user.email, "role": clean_user.role})
        creds_c = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_c)

        res = delete_user_account(payload=AccountDeleteRequest(password="Pass123!"), credentials=creds_c, db=db, user=clean_user)
        assert res["success"] is True
        assert res["action_taken"] == "hard_deleted"
        assert db.query(User).filter(User.id == clean_id).first() is None
        assert db.query(Address).filter(Address.user_id == clean_id).count() == 0
        assert db.query(Cart).filter(Cart.user_id == clean_id).count() == 0
        assert token_c in REVOKED_TOKENS
        print("Passed: zero transaction user is hard deleted and ancillary PII is purged")

        print("--- 6. Testing Financial Record Retention & PII Anonymization ---")
        hist_user = User(email="hist@example.com", password=hash_password("Pass123!"), name="Historical User", role="customer", phone="+919876543210")
        db.add(hist_user)
        db.commit()
        db.refresh(hist_user)
        hist_id = hist_user.id

        comp_order = Order(
            user_id=hist_id,
            status="completed",
            shipping_status="delivered",
            handoff_status="handoff_completed",
            total_amount=999.0,
            recipient_name="Historical User",
            recipient_phone="+919876543210",
            delivery_address="123 Real Address"
        )
        db.add(comp_order)
        db.commit()
        db.refresh(comp_order)
        pmt = Payment(user_id=hist_id, order_id=comp_order.id, razorpay_order_id="order_fake_123", amount=999.0, status="paid")
        db.add(pmt)
        db.commit()

        token_h = create_access_token({"sub": hist_user.email, "role": hist_user.role})
        creds_h = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token_h)

        res_h = delete_user_account(payload=AccountDeleteRequest(password="Pass123!"), credentials=creds_h, db=db, user=hist_user)
        assert res_h["success"] is True
        assert res_h["action_taken"] == "anonymized_and_scrubbed"
        assert len(res_h["retained_records"]) > 0

        anon_user = db.query(User).filter(User.id == hist_id).first()
        assert anon_user is not None
        assert anon_user.name == "[Deleted User]"
        assert anon_user.email.startswith(f"deleted_{hist_id}_")
        assert anon_user.phone is None
        assert anon_user.role == "deleted"

        ord_db = db.query(Order).filter(Order.id == comp_order.id).first()
        assert ord_db.recipient_name == "[Deleted User]"
        assert ord_db.delivery_address == "[Redacted - Account Deleted]"
        assert ord_db.total_amount == 999.0
        assert db.query(Payment).filter(Payment.user_id == hist_id).count() == 1
        print("Passed: financial history user is anonymized and orders/payments are preserved")

        print("--- 7. Testing Repeat Deletion Guard ---")
        try:
            delete_user_account(payload=AccountDeleteRequest(password="Pass123!"), credentials=creds_h, db=db, user=anon_user)
            assert False, "Should have rejected repeat deletion"
        except HTTPException as e:
            assert e.status_code == 400
            assert "already been deleted" in e.detail.lower()
            print("Passed: repeat deletion request rejected with 400")

        print("--- 8. Testing Public Deletion Request Endpoint & Persistence ---")
        pub_res = request_account_deletion_external(PublicAccountDeletionRequest(email="someone@example.com", reason="test"), db=db)
        assert pub_res["success"] is True
        assert "request_id" in pub_res
        assert pub_res["request_id"].startswith("del_")
        persisted_req = db.query(AccountDeletionRequest).filter(AccountDeletionRequest.request_id == pub_res["request_id"]).first()
        assert persisted_req is not None
        assert persisted_req.email == "someone@example.com"
        assert persisted_req.status == "pending"
        print("Passed: external deletion request endpoint accepted and persisted durably in database")

        print("--- 9. Testing Public Deletion HTML Rendering ---")
        html = render_account_deletion_html()
        assert "Account Deletion Request" in html
        assert "Google Play" in html
        print("Passed: public deletion HTML rendered properly")

        print("--- 10. Testing Public Privacy Policy HTML Rendering ---")
        pp_html = render_privacy_policy_html()
        assert "Privacy Policy" in pp_html
        assert "The Tactile Archive" in pp_html
        assert "Razorpay" in pp_html
        assert "CAMERA" in pp_html
        print("Passed: public privacy policy HTML rendered properly with all disclosures")

        print("\n=============================================")
        print("SUCCESS: ALL 10 BACKEND COMPLIANCE CHECKS PASSED!")
        print("=============================================")

    finally:
        db.close()
        engine.dispose()
        if os.path.exists(TEST_DB):
            try: os.remove(TEST_DB)
            except Exception: pass
        final_hash = sha256_file(LIVE_DB)
        assert initial_hash == final_hash, f"SAFETY VIOLATION: {initial_hash} != {final_hash}"
        print(f"LIVE DB SAFETY CONFIRMED: SHA-256 untouched ({initial_hash})")

if __name__ == "__main__":
    run()
