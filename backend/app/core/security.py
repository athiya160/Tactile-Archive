import os
import uuid
import logging
import secrets
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from app.core.config import load_environment

load_environment()

logger = logging.getLogger("app.core.security")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Minimum key length for HS256 (RFC 7518 Section 3.2: minimum 256 bits / 32 bytes)
MIN_JWT_SECRET_LENGTH = 32

# Known weak, default, or placeholder patterns that must NEVER be accepted in production
INSECURE_JWT_SECRET_PATTERNS = [
    "your_secret_key_development_fallback_1234567",
    "prod_jwt_secret_signing_key_to_be_generated_securely",
    "yoursecretjwtkeyhere",
    "generate_with_openssl_rand_hex_32",
    "replace_with_at_least_32_characters",
    "secret",
    "jwt_secret",
    "changeme",
    "password",
    "supersecret",
    "admin",
    "development_fallback",
    "placeholder",
    "to_be_generated",
    "example",
    "your_secret",
]

DEV_FALLBACK_SECRET = "dev_insecure_jwt_secret_strictly_for_local_development_only_not_for_prod"
TEST_DEFAULT_SECRET = "test_jwt_secret_key_tactile_archive_pytest_suite_minimum_32_bytes_ok"


def validate_jwt_secret(secret: str | None, env: str | None = None) -> str:
    """
    Validates the cryptographic strength of the JWT secret key based on environment.
    Strictly refuses missing, empty, short, or placeholder secrets in production.
    Never prints or logs the secret value.
    """
    if env is None:
        env = os.getenv("ENV", "development")
    clean_env = (env or "development").strip().lower()
    clean_secret = (secret or "").strip()

    if clean_env in ["production", "prod"]:
        if not clean_secret:
            raise RuntimeError(
                "[JWT SECURITY ERROR] JWT_SECRET_KEY is not configured for production environment. "
                f"Production strictly requires a persistent cryptographically secure secret "
                f"(minimum {MIN_JWT_SECRET_LENGTH} characters / 256 bits). "
                "Fallback secrets are strictly prohibited in production."
            )

        if len(clean_secret) < MIN_JWT_SECRET_LENGTH:
            raise RuntimeError(
                f"[JWT SECURITY ERROR] JWT_SECRET_KEY is too short ({len(clean_secret)} chars). "
                f"HS256 signing requires a secret of at least {MIN_JWT_SECRET_LENGTH} characters (256 bits)."
            )

        lower_secret = clean_secret.lower()
        for pattern in INSECURE_JWT_SECRET_PATTERNS:
            if pattern in lower_secret:
                raise RuntimeError(
                    "[JWT SECURITY ERROR] JWT_SECRET_KEY is set to a known placeholder, weak pattern, "
                    "or default fallback string. A cryptographically random secret of at least "
                    f"{MIN_JWT_SECRET_LENGTH} characters must be supplied in production."
                )

        return clean_secret

    elif clean_env in ["test", "testing"]:
        if not clean_secret:
            return TEST_DEFAULT_SECRET
        return clean_secret

    else:
        # Development environment
        if not clean_secret:
            logger.warning(
                "[JWT SECURITY WARNING] JWT_SECRET_KEY not set in development. "
                "Using local development fallback key. This fallback is strictly forbidden in production."
            )
            return DEV_FALLBACK_SECRET

        if len(clean_secret) < MIN_JWT_SECRET_LENGTH:
            logger.warning(
                f"[JWT SECURITY WARNING] Development JWT_SECRET_KEY is under {MIN_JWT_SECRET_LENGTH} characters. "
                "Consider generating a 32+ character key even in development."
            )

        return clean_secret


def get_jwt_secret() -> str:
    """Resolves and validates the JWT secret key from the current environment."""
    current_env = os.getenv("ENV", "development")
    raw_secret = os.getenv("JWT_SECRET_KEY")
    return validate_jwt_secret(raw_secret, current_env)


# Evaluated at module import time
SECRET_KEY = get_jwt_secret()


def create_access_token(
    data: dict,
    refresh_jti: Optional[str] = None,
    token_version: Optional[int] = None
) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    if "jti" not in to_encode:
        to_encode["jti"] = uuid.uuid4().hex
    to_encode["exp"] = expire
    to_encode["type"] = "access"
    
    # Token versioning
    if token_version is not None:
        to_encode["ver"] = token_version
    elif "ver" not in to_encode:
        to_encode["ver"] = 1
        
    # Refresh Token Identifier linkage
    if refresh_jti is not None:
        to_encode["rti"] = refresh_jti
        
    return jwt.encode(to_encode, get_jwt_secret(), algorithm=ALGORITHM)


def create_refresh_token(
    data: dict,
    jti: Optional[str] = None,
    token_version: Optional[int] = None
) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode["exp"] = expire
    to_encode["type"] = "refresh"
    
    if jti is not None:
        to_encode["jti"] = jti
    elif "jti" not in to_encode:
        to_encode["jti"] = uuid.uuid4().hex
        
    # Token versioning
    if token_version is not None:
        to_encode["ver"] = token_version
    elif "ver" not in to_encode:
        to_encode["ver"] = 1
        
    return jwt.encode(to_encode, get_jwt_secret(), algorithm=ALGORITHM)


def create_verification_token(email: str) -> str:
    expire = datetime.utcnow() + timedelta(hours=24)
    to_encode = {"sub": email, "exp": expire, "action": "email_verify", "type": "verification"}
    return jwt.encode(to_encode, get_jwt_secret(), algorithm=ALGORITHM)


def verify_verification_token(token: str) -> str | None:
    try:
        payload = jwt.decode(token, get_jwt_secret(), algorithms=[ALGORITHM])
        if payload.get("action") != "email_verify":
            return None
        return payload.get("sub")
    except Exception:
        return None


def create_reset_token(email: str) -> str:
    # Generates a highly secure URL-safe base64-encoded 32-byte random string
    return secrets.token_urlsafe(32)


def verify_reset_token(token: str) -> str | None:
    # Legacy function; token verification is now handled in the route handler via DB
    pass
