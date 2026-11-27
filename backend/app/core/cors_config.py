import os
import re
from typing import List, Tuple, Optional

# Default production origins allowed if ALLOWED_ORIGINS environment variable is not explicitly specified
DEFAULT_PROD_ORIGINS = [
    "https://libriflow.app",
    "https://www.libriflow.app",
    "https://the-tactile-archive-production.up.railway.app",
]

# Default development origins
DEFAULT_DEV_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:8080",
    "https://libriflow.app",
    "https://www.libriflow.app",
    "https://the-tactile-archive-production.up.railway.app",
]

# Anchored regex for production: only HTTPS, only libriflow.app apex and subdomains
PROD_ORIGIN_REGEX = r"^https://([a-zA-Z0-9-]+\.)*libriflow\.app$"

# Anchored regex for development: localhost, 127.0.0.1, 10.* and 192.168.* LAN IPs with optional port
DEV_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})(:\d+)?$"


def resolve_cors_configuration() -> Tuple[List[str], str]:
    """
    Resolves CORS allowed origins and regex pattern safely based on the ENV setting.
    In production:
      - Uses explicit allowlist from ALLOWED_ORIGINS env var, or falls back to DEFAULT_PROD_ORIGINS.
      - Uses strictly anchored HTTPS regex for libriflow.app subdomains.
      - Never allows wildcard (*) or dev LAN/localhost in production.
    In development:
      - Allows explicit localhost origins + dev LAN IPs via anchored regex.
    """
    env = os.getenv("ENV", "development").strip().lower()
    raw_origins = os.getenv("ALLOWED_ORIGINS", "")
    explicit_origins = [o.strip() for o in raw_origins.split(",") if o.strip()]

    if env == "production":
        origins = explicit_origins if explicit_origins else list(DEFAULT_PROD_ORIGINS)
        origin_regex = PROD_ORIGIN_REGEX
    else:
        origins = explicit_origins if explicit_origins else list(DEFAULT_DEV_ORIGINS)
        origin_regex = DEV_ORIGIN_REGEX

    return origins, origin_regex


def is_websocket_origin_allowed(origin: Optional[str]) -> bool:
    """
    Validates the Origin header for incoming WebSocket connections.
    - If origin is None or empty:
        Allowed (native mobile Flutter apps on Android/iOS direct connection do not send Origin header).
    - If origin is provided (browser clients):
        Must match the resolved allowed origins list or the anchored regex pattern.
    """
    if not origin or not origin.strip():
        # Non-browser client (native mobile or direct client)
        return True

    cleaned_origin = origin.strip().rstrip("/")
    origins, origin_regex = resolve_cors_configuration()

    # Check exact origins (ignoring trailing slash)
    normalized_allowed = [o.rstrip("/") for o in origins]
    if cleaned_origin in normalized_allowed:
        return True

    # Check regex match
    try:
        if re.fullmatch(origin_regex, cleaned_origin):
            return True
    except Exception:
        pass

    return False
