"""
Rate Limiting Subsystem
Project: The Tactile Archive / LibriFlow

Initializes SlowAPI Limiter configured with hardened, spoof-resistant
trusted proxy client IP resolution (get_trusted_client_ip).
Supports distributed storage (Redis) when configured via RATE_LIMIT_STORAGE_URL or REDIS_URL,
with automatic safe fallback to in-memory rate limiting if external storage is unreachable.
Never logs unmasked database or cache credentials.
"""

import os
import re
import logging
from slowapi import Limiter
from app.core.proxy_security import get_trusted_client_ip

logger = logging.getLogger("app.core.rate_limit")


def sanitize_storage_uri(uri: str | None) -> str:
    """Masks credentials from storage URLs to avoid logging sensitive passwords."""
    if not uri:
        return ""
    return re.sub(r'(://[^:]+:)([^@]+)(@)', r'\1***\3', uri)


def init_limiter() -> Limiter:
    storage_uri = os.getenv("RATE_LIMIT_STORAGE_URL") or os.getenv("REDIS_URL")
    
    if storage_uri:
        masked_uri = sanitize_storage_uri(storage_uri)
        try:
            logger.info("Initializing SlowAPI Limiter with distributed storage URI: %s", masked_uri)
            return Limiter(
                key_func=get_trusted_client_ip,
                storage_uri=storage_uri,
                in_memory_fallback_enabled=True,
            )
        except Exception as e:
            logger.warning(
                "Failed to connect to distributed rate limit storage (%s). Falling back safely to in-memory: %s",
                masked_uri, e
            )
            return Limiter(
                key_func=get_trusted_client_ip,
                storage_uri="memory://",
                in_memory_fallback_enabled=True,
            )
    
    # Default fail-safe local storage
    return Limiter(
        key_func=get_trusted_client_ip,
        storage_uri="memory://",
        in_memory_fallback_enabled=True,
    )


limiter = init_limiter()
