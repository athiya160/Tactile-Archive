import os
from starlette.datastructures import MutableHeaders
from starlette.types import ASGIApp, Scope, Receive, Send
from app.core.proxy_security import is_request_https

class SecurityHeadersMiddleware:
    """
    Production-grade ASGI Security Headers Middleware for The Tactile Archive / LibriFlow.
    
    Applies defense-in-depth HTTP security headers to all HTTP responses:
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - Referrer-Policy: strict-origin-when-cross-origin
    - Permissions-Policy: camera=(), microphone=(), geolocation=()
    - Content-Security-Policy: Permissive, compatible policy allowing required fonts,
      inline scripts for reset/deletion forms, and S3 media storage.
    - Strict-Transport-Security: Conditionally injected ONLY when the request is served
      over HTTPS (direct TLS or via X-Forwarded-Proto from reverse proxies).
      
    WebSocket Safety:
    Explicitly ignores non-HTTP scopes (e.g. scope['type'] == 'websocket')
    to ensure zero interference with WebSocket handshakes, protocols, or framing.
    """
    def __init__(self, app: ASGIApp):
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Securely detect HTTPS using unified trusted proxy validation (RFC 6797 compliant)
        is_https = is_request_https(scope)

        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                headers = MutableHeaders(scope=message)

                headers["X-Content-Type-Options"] = "nosniff"
                headers["X-Frame-Options"] = "DENY"
                headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
                headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"

                # Content Security Policy compatible with Flutter Web, HTML forms, Razorpay, and S3
                headers["Content-Security-Policy"] = (
                    "default-src 'self'; "
                    "script-src 'self' https://checkout.razorpay.com https://www.gstatic.com 'unsafe-inline'; "
                    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
                    "font-src 'self' https://fonts.gstatic.com data:; "
                    "img-src 'self' data: blob: https://*.s3.ap-south-1.amazonaws.com https://*.s3.amazonaws.com https://checkout.razorpay.com https://lh3.googleusercontent.com; "
                    "connect-src 'self' https://api.razorpay.com https://lumberjack.razorpay.com https://accounts.google.com https://oauth2.googleapis.com https://*.s3.ap-south-1.amazonaws.com https://*.s3.amazonaws.com https://www.gstatic.com https://fonts.gstatic.com https://fcm.googleapis.com ws: wss:; "
                    "frame-src 'self' https://api.razorpay.com https://checkout.razorpay.com; "
                    "frame-ancestors 'none'; "
                    "base-uri 'self'; "
                    "form-action 'self';"
                )

                # RFC 6797: Strict-Transport-Security only over HTTPS
                if is_https:
                    headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

            await send(message)

        await self.app(scope, receive, send_wrapper)
