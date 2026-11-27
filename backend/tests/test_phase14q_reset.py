import pytest
from fastapi.testclient import TestClient
import datetime
import hashlib
from urllib.parse import urlparse, parse_qs
from app.main import app
from app.core.database import SessionLocal
from app.models.user import User
from app.models.password_reset import PasswordReset
from app.models.otp_code import OTPCode
from app.api.auth import hash_password, verify_password

@pytest.fixture
def db_session():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def test_user_specific_recipient_isolation(monkeypatch, db_session):
    client = TestClient(app)

    user_a_email = 'user_a_phase14q@example.com'
    user_b_email = 'user_b_phase14q@example.com'

    # Create User A & User B
    for email, name in [(user_a_email, 'User A'), (user_b_email, 'User B')]:
        u = db_session.query(User).filter(User.email == email).first()
        if not u:
            u = User(
                email=email,
                name=name,
                password=hash_password('OriginalPassword123!'),
                role='customer',
                user_type='reader',
                is_verified=True
            )
            db_session.add(u)
        else:
            u.password = hash_password('OriginalPassword123!')
    db_session.commit()

    dispatched = {}
    def mock_send(to_email, reset_link):
        dispatched[to_email] = reset_link
        return True, ''

    monkeypatch.setattr('app.api.auth.send_reset_password_email', mock_send)

    # 1. User A requests reset
    res_a = client.post('/auth/forgot-password', json={'email': user_a_email.upper()})
    assert res_a.status_code == 200
    assert user_a_email in dispatched
    assert user_b_email not in dispatched

    link_a = dispatched[user_a_email]
    token_a = parse_qs(urlparse(link_a).query).get('token', [''])[0]
    assert token_a != ''

    # 2. User B requests reset
    res_b = client.post('/auth/forgot-password', json={'email': user_b_email})
    assert res_b.status_code == 200
    assert user_b_email in dispatched

    link_b = dispatched[user_b_email]
    token_b = parse_qs(urlparse(link_b).query).get('token', [''])[0]
    assert token_b != ''
    assert token_a != token_b

    # 3. Database stores SHA-256 hash (never raw token)
    hash_a = hashlib.sha256(token_a.encode('utf-8')).hexdigest()
    hash_b = hashlib.sha256(token_b.encode('utf-8')).hexdigest()

    entry_a = db_session.query(PasswordReset).filter(PasswordReset.token == hash_a).first()
    assert entry_a is not None
    assert entry_a.token != token_a
    assert len(entry_a.token) == 64

    entry_b = db_session.query(PasswordReset).filter(PasswordReset.token == hash_b).first()
    assert entry_b is not None
    assert entry_b.token != token_b

    # 4. User A resets password using token A
    reset_res_a = client.post('/auth/reset-password', json={
        'token': token_a,
        'new_password': 'NewPasswordA123!'
    })
    assert reset_res_a.status_code == 200

    # Verify User A password changed, User B password unchanged
    db_session.refresh(entry_a)
    assert entry_a.used is True
    user_a = db_session.query(User).filter(User.email == user_a_email).first()
    user_b = db_session.query(User).filter(User.email == user_b_email).first()
    assert verify_password('NewPasswordA123!', user_a.password) is True
    assert verify_password('OriginalPassword123!', user_b.password) is True

    # 5. Token A cannot be reused (Single use)
    reuse_res = client.post('/auth/reset-password', json={
        'token': token_a,
        'new_password': 'AnotherPassword123!'
    })
    assert reuse_res.status_code == 400
    assert 'already been used' in reuse_res.json()['detail']

def test_token_expiration(monkeypatch, db_session):
    client = TestClient(app)
    test_email = 'expired_user_14q@example.com'
    u = db_session.query(User).filter(User.email == test_email).first()
    if not u:
        u = User(email=test_email, name='Expired User', password=hash_password('Pass123!'), role='customer', is_verified=True)
        db_session.add(u)
        db_session.commit()

    dispatched = {}
    def mock_send(to_email, reset_link):
        dispatched['link'] = reset_link
        return True, ''

    monkeypatch.setattr('app.api.auth.send_reset_password_email', mock_send)
    client.post('/auth/forgot-password', json={'email': test_email})

    token = parse_qs(urlparse(dispatched['link']).query).get('token', [''])[0]
    token_hash = hashlib.sha256(token.encode('utf-8')).hexdigest()

    # Artificially expire the token in DB
    entry = db_session.query(PasswordReset).filter(PasswordReset.token == token_hash).first()
    entry.expires_at = datetime.datetime.utcnow() - datetime.timedelta(minutes=1)
    db_session.commit()

    # Attempt reset with expired token
    res = client.post('/auth/reset-password', json={'token': token, 'new_password': 'NewPassword123!'})
    assert res.status_code == 400
    assert 'expired' in res.json()['detail']

def test_dev_token_bypass_eliminated(client_app=None):
    client = TestClient(app)
    res_get = client.get('/reset-password?token=dev_token')
    assert res_get.status_code == 400

    res_post = client.post('/auth/reset-password', json={'token': 'dev_token', 'new_password': 'Password123!'})
    assert res_post.status_code == 400
    assert 'Invalid reset token' in res_post.json()['detail']

def test_dev_otp_bypass_eliminated():
    client = TestClient(app)
    res = client.post('/auth/verify-otp-reset', json={
        'identifier': 'someone@example.com',
        'otp_code': '123456',
        'new_password': 'NewPassword123!'
    })
    assert res.status_code == 400
    assert 'Invalid OTP code' in res.json()['detail']

def test_provider_error_reported_accurately(monkeypatch, db_session):
    client = TestClient(app)
    test_email = 'provider_err_user@example.com'
    u = db_session.query(User).filter(User.email == test_email).first()
    if not u:
        u = User(email=test_email, name='Err User', password=hash_password('Pass123!'), role='customer', is_verified=True)
        db_session.add(u)
        db_session.commit()

    def mock_failing_send(to_email, reset_link):
        return False, 'EXTERNAL CONFIGURATION REQUIRED: Mail provider permits delivery only to verified domain/test address.'

    monkeypatch.setattr('app.api.auth.send_reset_password_email', mock_failing_send)

    res = client.post('/auth/forgot-password', json={'email': test_email})
    assert res.status_code == 502
    assert 'EXTERNAL CONFIGURATION REQUIRED' in res.json()['detail']
