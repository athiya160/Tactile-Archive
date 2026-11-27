from app.core.config import load_environment
# Initialize Environment variables from dev/prod configs
load_environment()

import os
import time
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware
from app.core.database import engine, Base
from app.core.logging_config import setup_logging

# Initialize Structured Logging
setup_logging()

# Startup Security Assertions: verify JWT secret configuration for environment
from app.core.security import get_jwt_secret
get_jwt_secret()

# 🔥 IMPORT MODELS FIRST (So SQLalchemy registers tables correctly)
from app.models.user import User
from app.models.book import Book
from app.models.cart import Cart, CartItem
from app.models.favorite import Favorite
from app.models.order import Order, OrderItem, BorrowRequest, RentalOrder, PurchaseOrder
from app.models.address import Address
from app.models.notification import Notification, FCMToken
from app.models.review import Review
from app.models.password_reset import PasswordReset
from app.models.payment import Payment
from app.models.otp_code import OTPCode
from app.models.badge import Badge, UserBadge
from app.models.subscription import NeighborhoodSubscription
from app.models.student_profile import StudentProfile
from app.models.reader_profile import ReaderProfile
from app.models.student_data import StudentSubject, StudentScheduleItem, StudentAssignment, StudentGoal
from app.models.reader_data import BookshelfItem, ReadingGoal
from app.models.account_deletion_request import AccountDeletionRequest
from app.models.revoked_token import RevokedToken

# 🔥 IMPORT ROUTERS
from app.api import auth
from app.api import books
from app.api import cart
from app.api import orders
from app.api import activity
from app.api import uploads
from app.api import library
from app.api import addresses
from app.api import notifications
from app.api import admin
from app.api import payments
from app.api import reviews
from app.api import newsletter
from app.api import drafts
from app.api import chat
from app.api import favorites
from app.api import profile
from app.api import student
from app.api import reader
from app.api import recommendations
from app.api import mood_recommendations
from app.api import meetups
from app.api import ai
from app.api import shelf_scan
from app.api import gamification
from app.api import provider
from app.api import support

from app.core.proxy_security import get_trusted_client_ip

# 🔥 CUSTOM SLIDING WINDOW RATE LIMITING MIDDLEWARE
class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limit: int = 150, window: int = 60):
        super().__init__(app)
        self.limit = limit
        self.window = window
        self.requests = {} # IP -> list of timestamps

    async def dispatch(self, request: Request, call_next):
        # Allow pre-flight OPTIONS requests or testing without limiting
        if os.getenv("TESTING") == "true" or request.method == "OPTIONS":
            return await call_next(request)
            
        client_ip = get_trusted_client_ip(request)
        now = time.time()
        
        # Initialize IP request bucket
        if client_ip not in self.requests:
            self.requests[client_ip] = []
            
        # Clean timestamps older than window
        self.requests[client_ip] = [t for t in self.requests[client_ip] if now - t < self.window]
        
        # Check limit threshold
        if len(self.requests[client_ip]) >= self.limit:
            raise HTTPException(status_code=429, detail="Too Many Requests. Please slow down.")
            
        self.requests[client_ip].append(now)
        response = await call_next(request)
        return response

from app.core.rate_limit import limiter
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler

import uuid
import logging
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.responses import JSONResponse
from app.core.logging_config import request_id_ctx, get_current_request_id
from app.core.cors_config import resolve_cors_configuration, is_websocket_origin_allowed
from app.core.security_headers import SecurityHeadersMiddleware

logger = logging.getLogger(__name__)

class CorrelationIdMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        req_id = request.headers.get("X-Request-ID") or request.headers.get("x-request-id")
        if not req_id or not req_id.strip():
            req_id = str(uuid.uuid4())
        else:
            req_id = req_id.strip()
        request.state.request_id = req_id
        token = request_id_ctx.set(req_id)
        try:
            response = await call_next(request)
            response.headers["X-Request-ID"] = req_id
            return response
        finally:
            request_id_ctx.reset(token)

app = FastAPI()

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    req_id = getattr(request.state, "request_id", None) or request.headers.get("x-request-id") or get_current_request_id() or str(uuid.uuid4())
    headers = {"X-Request-ID": req_id}
    origin = request.headers.get("origin")
    if origin and is_websocket_origin_allowed(origin):
        headers["Access-Control-Allow-Origin"] = origin
        headers["Access-Control-Allow-Credentials"] = "true"
        headers["Access-Control-Allow-Headers"] = "*"
        headers["Access-Control-Allow-Methods"] = "*"

    if isinstance(exc, (HTTPException, StarletteHTTPException)):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail},
            headers=headers
        )
    logger.error(
        f"Unhandled exception processing {request.method} {request.url.path} (request_id={req_id}): {exc}",
        exc_info=True
    )
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": "An unexpected server error occurred.",
            "request_id": req_id
        },
        headers=headers
    )

# 1. Apply Rate Limiter Middleware
app.add_middleware(RateLimitMiddleware, limit=150, window=60)

# 2. Apply Correlation ID Middleware
app.add_middleware(CorrelationIdMiddleware)

# 3. Apply CORS Middleware with environment-safe resolution and strict regex
cors_origins, cors_regex = resolve_cors_configuration()
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_origin_regex=cors_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. Apply Security Headers Middleware (outermost HTTP response wrapper)
app.add_middleware(SecurityHeadersMiddleware)

# Static & Media Files
os.makedirs("images", exist_ok=True)
os.makedirs("static", exist_ok=True)

app.mount(
    "/images",
    StaticFiles(directory="images"),
    name="images",
)

app.mount(
    "/static",
    StaticFiles(directory="static"),
    name="static",
)

# Include Routers
app.include_router(auth.router)
app.include_router(books.router)
app.include_router(cart.router)
app.include_router(orders.router)
app.include_router(activity.router)
app.include_router(uploads.router)
app.include_router(library.router)
app.include_router(addresses.router)
app.include_router(notifications.router)
app.include_router(admin.router)
app.include_router(payments.router)
app.include_router(reviews.router)
app.include_router(newsletter.router, prefix="/newsletter", tags=["Newsletter"])
app.include_router(drafts.router)
app.include_router(chat.router)
app.include_router(favorites.router)
app.include_router(profile.router)
app.include_router(student.router)
app.include_router(reader.router)
app.include_router(recommendations.router)
app.include_router(mood_recommendations.router)
app.include_router(meetups.router)
app.include_router(ai.router)
app.include_router(shelf_scan.router)
app.include_router(gamification.router)
app.include_router(provider.router)
app.include_router(support.router)

@app.get("/")
def read_root():
    return {"message": "Backend is working good 🚀"}

# Database Schema Initialization Guard
# Automatic table creation (create_all) is restricted strictly to local development and test environments.
# In production, schema changes must be applied exclusively via explicit Alembic migrations (alembic upgrade head).
current_env = os.getenv("ENV", "development").strip().lower()
if current_env in ["development", "dev", "test"]:
    Base.metadata.create_all(bind=engine)
else:
    import logging
    logging.getLogger("uvicorn.error").info(
        "[DATABASE] Production environment detected. Automatic Base.metadata.create_all() skipped. "
        "Schema management requires explicit Alembic migration (alembic upgrade head)."
    )