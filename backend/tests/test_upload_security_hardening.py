import io
import os
import sys
import uuid
import pytest
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from app.core.database import Base
from app.models.user import User
from app.api.auth import get_db, hash_password
from app.core.security import create_access_token
from app.core.upload_security import (
    MAX_FILE_SIZE,
    detect_file_signature,
    validate_image_bytes,
    generate_secure_storage_filename,
    resolve_safe_local_path,
    get_storage_status,
)
from fastapi import HTTPException

# Disposable test database in scratch/
TEST_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "scratch", "disposable_upload_test.db"))
TEST_DB_URL = f"sqlite:///{TEST_DB_PATH.replace(os.sep, '/')}"

test_engine = create_engine(TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    os.makedirs(os.path.dirname(TEST_DB_PATH), exist_ok=True)
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass

    Base.metadata.create_all(bind=test_engine)
    yield
    test_engine.dispose()
    if os.path.exists(TEST_DB_PATH):
        try:
            os.remove(TEST_DB_PATH)
        except Exception:
            pass


@pytest.fixture
def db():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def auth_user(db):
    email = f"upload_test_{uuid.uuid4().hex[:8]}@example.com"
    user = User(
        email=email,
        password=hash_password("SecurePassword123!"),
        name="Upload Tester",
        role="provider",
        user_type="reader",
        is_verified=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token({"sub": user.email, "role": user.role})
    return {"user": user, "token": token, "email": email}


@pytest.fixture
def client(db):
    def override_get_db():
        try:
            yield db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.pop(get_db, None)


def create_test_image_bytes(format_name: str, width: int = 10, height: int = 10) -> bytes:
    """Helper to generate authentic, structurally valid in-memory images."""
    img = Image.new("RGB", (width, height), color=(73, 109, 137))
    buf = io.BytesIO()
    save_format = format_name.upper()
    if save_format == "JPG":
        save_format = "JPEG"
    img.save(buf, format=save_format)
    return buf.getvalue()


# ─── 1. VALID SUPPORTED IMAGES ───────────────────────────────────────────────

def test_valid_supported_images():
    """Requirement 2, 3, 9: Valid JPEG, PNG, WEBP, GIF, and HEIC files pass validation."""
    for fmt, ext, expected_mime in [
        ("JPEG", "jpg", "image/jpeg"),
        ("PNG", "png", "image/png"),
        ("WEBP", "webp", "image/webp"),
        ("GIF", "gif", "image/gif"),
    ]:
        data = create_test_image_bytes(fmt)
        sig, canonical_ext, mime = validate_image_bytes(data, client_filename=f"photo.{ext}", client_mime_type=expected_mime)
        assert sig == fmt
        assert canonical_ext == ext
        assert mime == expected_mime

    # Minimal valid HEIC structure
    heic_bytes = (
        b"\x00\x00\x00\x1c"      # box size 28
        b"ftypheic"              # type ftyp, brand heic
        b"\x00\x00\x00\x00"      # minor version
        b"heixmif1msf1"          # compatible brands
        b"\x00" * 8              # trailing data
    )
    sig, canonical_ext, mime = validate_image_bytes(heic_bytes, client_filename="photo.heic", client_mime_type="image/heic")
    assert sig == "HEIC"
    assert canonical_ext == "heic"
    assert mime == "image/heic"


# ─── 2. INVALID FILE SIGNATURES & UNSUPPORTED FORMATS ────────────────────────

def test_invalid_magic_bytes():
    """Requirement 2, 4, 9: Random bytes and invalid signatures are strictly rejected."""
    junk_data = b"This is just arbitrary plain text data that is not an image."
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(junk_data, client_filename="test.jpg")
    assert exc_info.value.status_code == 400
    assert "Unsupported or invalid file signature" in exc_info.value.detail


def test_unsupported_formats_rejected():
    """Requirement 3, 4, 9: Disallowed formats (PDF, EXE, ZIP, SVG, HTML) are rejected."""
    payloads = [
        (b"%PDF-1.4\n%...\n%%EOF", "document.pdf", "application/pdf"),
        (b"MZ\x90\x00\x03\x00\x00\x00", "program.exe", "application/x-dosexec"),
        (b"\x7fELF\x02\x01\x01\x00", "binary.elf", "application/x-executable"),
        (b"PK\x03\x04\x14\x00\x00\x00", "archive.zip", "application/zip"),
        (b"<svg xmlns='http://www.w3.org/2000/svg'><script>alert(1)</script></svg>", "icon.svg", "image/svg+xml"),
        (b"<!DOCTYPE html><html><body><h1>Evil</h1></body></html>", "page.html", "text/html"),
    ]
    for data, fname, mime in payloads:
        with pytest.raises(HTTPException) as exc_info:
            validate_image_bytes(data, client_filename=fname, client_mime_type=mime)
        assert exc_info.value.status_code == 400
        assert "Unsupported or invalid file signature" in exc_info.value.detail


# ─── 3. EXTENSION & CONTENT MISMATCHES ───────────────────────────────────────

def test_extension_mismatches_rejected():
    """Requirement 4, 9: Valid image content with mismatched extension is rejected."""
    # Real PNG disguised as .jpg
    png_data = create_test_image_bytes("PNG")
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(png_data, client_filename="disguised.jpg")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

    # Real JPEG disguised as .png
    jpeg_data = create_test_image_bytes("JPEG")
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(jpeg_data, client_filename="disguised.png")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail


# ─── 4. MIME TYPE MISMATCHES ─────────────────────────────────────────────────

def test_mime_mismatches_rejected():
    """Requirement 4, 9: Contradictory client-provided MIME types are rejected."""
    jpeg_data = create_test_image_bytes("JPEG")

    # Provided MIME is image/png for JPEG content
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(jpeg_data, client_filename="photo.jpg", client_mime_type="image/png")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

    # Provided MIME is application/pdf for JPEG content
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(jpeg_data, client_filename="photo.jpg", client_mime_type="application/pdf")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

    # Generic octet-stream is safely accepted without mismatch failure
    sig, ext, mime = validate_image_bytes(jpeg_data, client_filename="photo.jpg", client_mime_type="application/octet-stream")
    assert sig == "JPEG"


@pytest.mark.asyncio
async def test_oversized_and_empty_file_bounds():
    """Requirement 5, 9: Files exceeding max size are aborted early, and empty files rejected."""
    from app.core.upload_security import read_bounded_file
    from starlette.datastructures import UploadFile

    # 1. Empty file
    empty_uf = UploadFile(filename="empty.png", file=io.BytesIO(b""))
    with pytest.raises(HTTPException) as exc_empty:
        await read_bounded_file(empty_uf, max_size=1024)
    assert exc_empty.value.status_code == 400
    assert "empty" in exc_empty.value.detail.lower()

    # 2. Oversized file (simulated with small threshold)
    oversized_data = b"X" * 2048
    oversized_uf = UploadFile(filename="large.png", file=io.BytesIO(oversized_data))
    with pytest.raises(HTTPException) as exc_large:
        await read_bounded_file(oversized_uf, max_size=1024)
    assert exc_large.value.status_code == 413
    assert "exceeds maximum allowed size" in exc_large.value.detail.lower()


# ─── 5. MALFORMED & CORRUPTED IMAGES ─────────────────────────────────────────

def test_malformed_images_rejected():
    """Requirement 4, 9: Files with valid magic bytes but corrupted bodies fail Pillow verification."""
    # JPEG magic bytes followed by garbage
    fake_jpeg = b"\xff\xd8\xff\xe0" + b"\x00" * 50
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(fake_jpeg, client_filename="broken.jpg")
    assert exc_info.value.status_code == 400
    assert "Malformed or corrupted image file" in exc_info.value.detail

    # PNG magic bytes followed by garbage
    fake_png = b"\x89PNG\r\n\x1a\n" + b"\x00" * 30
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(fake_png, client_filename="broken.png")
    assert exc_info.value.status_code == 400
    assert "Malformed or corrupted image file" in exc_info.value.detail

    # Truncated HEIC (20 bytes: valid ftyp + brand, but incomplete box < 24 bytes)
    truncated_heic = b"\x00\x00\x00\x14ftypheic\x00\x00\x00\x00"
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(truncated_heic, client_filename="broken.heic")
    assert exc_info.value.status_code == 400
    assert "Malformed or truncated HEIC" in exc_info.value.detail


# ─── 6. PATH TRAVERSAL ATTEMPTS ──────────────────────────────────────────────

def test_path_traversal_in_filename_rejected():
    """Requirement 4, 6, 9: Directory traversal characters in client filenames are rejected."""
    png_data = create_test_image_bytes("PNG")

    for traversal_name in [
        "../../etc/passwd.png",
        "..\\..\\windows\\system32\\evil.png",
        "nested/path/photo.png",
        "nested\\path\\photo.png",
    ]:
        with pytest.raises(HTTPException) as exc_info:
            validate_image_bytes(png_data, client_filename=traversal_name)
        assert exc_info.value.status_code == 400
        assert "Path traversal attempt detected" in exc_info.value.detail


def test_path_traversal_in_local_storage_resolution():
    """Requirement 4, 6: resolve_safe_local_path prevents escaping base upload directory."""
    base_dir = "images"

    for dangerous in [
        "../../secret.txt",
        "..\\secret.txt",
        "sub/file.jpg",
        "sub\\file.jpg",
        "/etc/passwd",
        "C:\\Windows\\System32\\cmd.exe",
    ]:
        with pytest.raises(HTTPException) as exc_info:
            resolve_safe_local_path(dangerous, base_dir)
        assert exc_info.value.status_code == 400
        assert "Path traversal" in exc_info.value.detail or "Invalid" in exc_info.value.detail


# ─── 7. SERVER-CONTROLLED SAFE FILENAMES ─────────────────────────────────────

def test_server_controlled_filenames():
    """Requirement 6: Storage filenames use UUID hex without client-controlled names."""
    for ext in ["jpg", "png", "webp", "gif", "heic"]:
        name = generate_secure_storage_filename(ext)
        assert name.endswith(f".{ext}")
        basename = name[:-len(ext) - 1]
        assert len(basename) == 32
        # Verify valid hex
        int(basename, 16)
        assert "/" not in name
        assert "\\" not in name
        assert ".." not in name


# ─── 8. ENDPOINT INTEGRATION: AUTHENTICATION & SINGLE UPLOAD ─────────────────

def test_upload_image_endpoint_unauthenticated(client):
    """Requirement 4: Unauthenticated upload requests are rejected with 401 or 403."""
    png_data = create_test_image_bytes("PNG")
    res = client.post(
        "/uploads/image",
        files={"file": ("test.png", png_data, "image/png")}
    )
    assert res.status_code in (401, 403)


def test_upload_image_endpoint_authenticated(client, auth_user):
    """Requirement 7, 9: Authenticated user can upload a valid image."""
    png_data = create_test_image_bytes("PNG", 20, 20)
    headers = {"Authorization": f"Bearer {auth_user['token']}"}

    res = client.post(
        "/uploads/image",
        files={"file": ("cover.png", png_data, "image/png")},
        headers=headers
    )
    assert res.status_code == 200
    body = res.json()
    assert "url" in body
    assert "/images/" in body["url"] or "s3" in body["url"]


def test_upload_book_images_batch_endpoint(client, auth_user):
    """Requirement 7, 9: Batch book image upload succeeds for legitimate images."""
    img1 = create_test_image_bytes("JPEG", 15, 15)
    img2 = create_test_image_bytes("PNG", 15, 15)
    headers = {"Authorization": f"Bearer {auth_user['token']}"}

    res = client.post(
        "/uploads/book-images",
        files=[
            ("files", ("front.jpg", img1, "image/jpeg")),
            ("files", ("back.png", img2, "image/png")),
        ],
        headers=headers
    )
    assert res.status_code == 200
    body = res.json()
    assert "urls" in body
    assert len(body["urls"]) == 2


def test_upload_endpoint_rejects_extension_mismatch(client, auth_user):
    """Requirement 4, 9: HTTP endpoint rejects extension mismatch."""
    png_data = create_test_image_bytes("PNG")
    headers = {"Authorization": f"Bearer {auth_user['token']}"}

    res = client.post(
        "/uploads/image",
        files={"file": ("fake_jpeg.jpg", png_data, "image/jpeg")},
        headers=headers
    )
    assert res.status_code == 400
    assert "does not match verified image content" in res.json()["detail"]


def test_upload_endpoint_rejects_mime_mismatch(client, auth_user):
    """Requirement 4, 9: HTTP endpoint rejects MIME mismatch."""
    jpeg_data = create_test_image_bytes("JPEG")
    headers = {"Authorization": f"Bearer {auth_user['token']}"}

    res = client.post(
        "/uploads/image",
        files={"file": ("valid.jpg", jpeg_data, "application/pdf")},
        headers=headers
    )
    assert res.status_code == 400
    assert "does not match verified image content" in res.json()["detail"]


def test_upload_endpoint_rejects_unsupported_format(client, auth_user):
    """Requirement 4, 9: HTTP endpoint rejects unsupported format (PDF)."""
    headers = {"Authorization": f"Bearer {auth_user['token']}"}
    pdf_bytes = b"%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF"

    res = client.post(
        "/uploads/image",
        files={"file": ("contract.pdf", pdf_bytes, "application/pdf")},
        headers=headers
    )
    assert res.status_code == 400
    assert "Unsupported or invalid file signature" in res.json()["detail"]


# ─── 9. STORAGE STATUS DIAGNOSTICS & EPHEMERAL STORAGE AUDIT ─────────────────

def test_storage_status_diagnostics(client, auth_user):
    """Requirement 8: Diagnostics accurately report storage mode (S3 vs LOCAL_DISK) and persistence."""
    headers = {"Authorization": f"Bearer {auth_user['token']}"}
    res = client.get("/uploads/storage-status", headers=headers)
    assert res.status_code == 200
    status = res.json()
    assert "backend" in status
    assert status["backend"] in ("AWS_S3", "LOCAL_DISK")
    assert "is_durable" in status
    if status["backend"] == "LOCAL_DISK":
        assert status["is_durable"] is False
        assert "EPHEMERAL" in status["ephemeral_warning"]
    else:
        assert status["is_durable"] is True
