import io
import os
import uuid
import pytest
from PIL import Image
from fastapi import HTTPException
from starlette.requests import Request
from starlette.datastructures import UploadFile

from app.models.user import User
from app.core.upload_security import (
    MAX_FILE_SIZE,
    detect_file_signature,
    validate_image_bytes,
    generate_secure_storage_filename,
    resolve_safe_local_path,
    get_storage_status,
    read_bounded_file_sync,
)
import app.core.storage as storage_mod
from app.api.uploads import upload_image, upload_book_images, check_storage_status
from app.api.shelf_scan import scan_bookshelf_image
from app.api.ai import inspect_book_damage

# --- Helper: Sync Coroutine Runner ---
def run_endpoint(coro):
    """Executes a coroutine without requiring an asyncio event loop or loopback sockets."""
    try:
        coro.send(None)
    except StopIteration as e:
        return e.value

# --- Mock User and Request Fixtures ---
@pytest.fixture
def mock_user():
    return User(
        id=999,
        email="security_test@tactilearchive.com",
        name="Security Tester",
        user_type="student",
    )

@pytest.fixture
def mock_request():
    scope = {
        "type": "http",
        "method": "POST",
        "path": "/uploads/image",
        "headers": [(b"host", b"localhost:8000")],
        "client": ("127.0.0.1", 12345),
    }
    return Request(scope)

# --- Image Generator Helpers ---
def create_valid_jpeg(width: int = 50, height: int = 50) -> bytes:
    buf = io.BytesIO()
    img = Image.new("RGB", (width, height), color=(50, 100, 150))
    img.save(buf, format="JPEG")
    return buf.getvalue()

def create_valid_png(width: int = 50, height: int = 50) -> bytes:
    buf = io.BytesIO()
    img = Image.new("RGBA", (width, height), color=(200, 50, 50, 255))
    img.save(buf, format="PNG")
    return buf.getvalue()

def create_valid_webp(width: int = 50, height: int = 50) -> bytes:
    buf = io.BytesIO()
    img = Image.new("RGB", (width, height), color=(30, 180, 80))
    img.save(buf, format="WEBP")
    return buf.getvalue()

def create_valid_gif(width: int = 50, height: int = 50) -> bytes:
    buf = io.BytesIO()
    img = Image.new("P", (width, height))
    img.save(buf, format="GIF")
    return buf.getvalue()

def create_valid_heic() -> bytes:
    # Minimal valid ISOBMFF HEIC header (length=28, box=ftyp, major=heic, compatible=heic,mif1,msf1)
    box_len = (28).to_bytes(4, byteorder="big")
    box_type = b"ftyp"
    major_brand = b"heic"
    minor_ver = b"\x00\x00\x00\x00"
    compat = b"heicmif1msf1"
    payload = b"\x00" * 32
    return box_len + box_type + major_brand + minor_ver + compat + payload

def make_upload_file(filename: str, data: bytes) -> UploadFile:
    return UploadFile(filename=filename, file=io.BytesIO(data), size=len(data))

# Cleanup helper for test images in UPLOAD_DIR
@pytest.fixture(autouse=True)
def cleanup_test_images():
    upload_dir = "images"
    before_files = set(os.listdir(upload_dir)) if os.path.exists(upload_dir) else set()
    yield
    if os.path.exists(upload_dir):
        after_files = set(os.listdir(upload_dir))
        new_files = after_files - before_files
        for f in new_files:
            try:
                os.remove(os.path.join(upload_dir, f))
            except Exception:
                pass


# ============================================================================
# 1. UNIT TESTS: FILE SIGNATURE & MAGIC BYTE DETECTION
# ============================================================================

def test_detect_file_signature_jpeg():
    data = create_valid_jpeg()
    assert detect_file_signature(data) == "JPEG"

def test_detect_file_signature_png():
    data = create_valid_png()
    assert detect_file_signature(data) == "PNG"

def test_detect_file_signature_webp():
    data = create_valid_webp()
    assert detect_file_signature(data) == "WEBP"

def test_detect_file_signature_gif():
    data = create_valid_gif()
    assert detect_file_signature(data) == "GIF"

def test_detect_file_signature_heic():
    data = create_valid_heic()
    assert detect_file_signature(data) == "HEIC"

def test_detect_file_signature_invalid_and_empty():
    assert detect_file_signature(b"") is None
    assert detect_file_signature(b"abc") is None
    assert detect_file_signature(b"%PDF-1.5 fake document") is None
    assert detect_file_signature(b"MZ\x90\x00\x03\x00\x00\x00") is None
    assert detect_file_signature(b"PK\x03\x04\x14\x00\x00\x00") is None
    assert detect_file_signature(b"<!DOCTYPE html><html>") is None


# ============================================================================
# 2. UNIT TESTS: VALIDATION LOGIC & INTEGRITY CHECKS
# ============================================================================

def test_validate_image_bytes_valid_formats():
    for gen, ext_list in [
        (create_valid_jpeg, ["photo.jpg", "image.jpeg", "CAPS.JPG"]),
        (create_valid_png, ["photo.png", "TEST.PNG"]),
        (create_valid_webp, ["photo.webp", "cover.WEBP"]),
        (create_valid_gif, ["animation.gif", "badge.GIF"]),
        (create_valid_heic, ["shot.heic", "camera.heif", "PHOTO.HEIC"]),
    ]:
        data = gen()
        for filename in ext_list:
            sig_format, canonical_ext, mime = validate_image_bytes(data, client_filename=filename)
            assert sig_format in {"JPEG", "PNG", "WEBP", "GIF", "HEIC"}
            assert canonical_ext in {"jpg", "png", "webp", "gif", "heic"}
            assert mime.startswith("image/")

def test_validate_image_bytes_empty_rejected():
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(b"", "empty.jpg")
    assert exc_info.value.status_code == 400
    assert "empty" in exc_info.value.detail.lower()

def test_validate_image_bytes_unsupported_signature_rejected():
    pdf_bytes = b"%PDF-1.5\n%test pdf content"
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(pdf_bytes, "document.pdf")
    assert exc_info.value.status_code == 400
    assert "unsupported or invalid file signature" in exc_info.value.detail.lower()

def test_validate_image_bytes_extension_content_mismatch_rejected():
    jpeg_bytes = create_valid_jpeg()
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(jpeg_bytes, "disguised.png")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

    png_bytes = create_valid_png()
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(png_bytes, "photo.jpg")
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(png_bytes, "payload.exe")
    assert exc_info.value.status_code == 400
    assert "does not match" in exc_info.value.detail

def test_validate_image_bytes_malformed_image_rejected():
    corrupt_jpeg = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00" + b"\xff" * 200 + b"BROKEN_DATA"
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(corrupt_jpeg, "corrupt.jpg")
    assert exc_info.value.status_code == 400
    assert "malformed or corrupted" in exc_info.value.detail.lower()

    corrupt_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR" + b"\x00" * 8
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(corrupt_png, "corrupt.png")
    assert exc_info.value.status_code == 400
    assert "malformed or corrupted" in exc_info.value.detail.lower()

def test_validate_image_bytes_null_byte_in_filename_rejected():
    jpeg_bytes = create_valid_jpeg()
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(jpeg_bytes, "avatar\x00.jpg")
    assert exc_info.value.status_code == 400
    assert "null byte" in exc_info.value.detail.lower()

def test_validate_image_bytes_malformed_heic_rejected():
    bad_heic = b"\x00\x00\x00\x04ftypheic"
    with pytest.raises(HTTPException) as exc_info:
        validate_image_bytes(bad_heic, "test.heic")
    assert exc_info.value.status_code == 400


# ============================================================================
# 3. UNIT TESTS: SECURE FILENAME GENERATION & PATH TRAVERSAL MITIGATION
# ============================================================================

def test_generate_secure_storage_filename():
    fn1 = generate_secure_storage_filename("jpg")
    fn2 = generate_secure_storage_filename("jpg")
    assert fn1 != fn2
    assert fn1.endswith(".jpg")
    assert len(fn1) == 36
    assert "/" not in fn1 and "\\" not in fn1 and ".." not in fn1

def test_resolve_safe_local_path():
    base_dir = "images"
    safe_name = "abcdef0123456789abcdef0123456789.png"
    target = resolve_safe_local_path(safe_name, base_dir)
    assert os.path.isabs(target)
    assert target.endswith(safe_name)

def test_resolve_safe_local_path_traversal_attempts():
    base_dir = "images"
    traversal_attacks = [
        "../../etc/passwd",
        "..\\..\\windows\\system32\\cmd.exe",
        "/absolute/path/file.jpg",
        "nested/subfolder/file.jpg",
        "images/../other.jpg",
    ]
    for attack in traversal_attacks:
        with pytest.raises(HTTPException) as exc_info:
            resolve_safe_local_path(attack, base_dir)
        assert exc_info.value.status_code == 400


# ============================================================================
# 4. STORAGE STATUS & DURABILITY CHECKS
# ============================================================================

def test_get_storage_status_local_ephemeral(monkeypatch):
    monkeypatch.setattr(storage_mod, "check_s3_configured", lambda: False)
    status = get_storage_status()
    assert status["backend"] == "LOCAL_DISK"
    assert status["is_durable"] is False
    assert status["bucket"] is None
    assert "WARNING" in status["ephemeral_warning"]
    assert "EPHEMERAL" in status["ephemeral_warning"]

def test_get_storage_status_durable_s3(monkeypatch):
    monkeypatch.setattr(storage_mod, "check_s3_configured", lambda: True)
    monkeypatch.setattr(storage_mod, "AWS_STORAGE_BUCKET_NAME", "tactile-archive-prod")
    monkeypatch.setattr(storage_mod, "AWS_S3_REGION", "ap-south-1")
    status = get_storage_status()
    assert status["backend"] == "AWS_S3"
    assert status["is_durable"] is True
    assert status["bucket"] == "tactile-archive-prod"
    assert status["ephemeral_warning"] is None


# ============================================================================
# 5. ENDPOINT INTEGRATION TESTS: /uploads/image
# ============================================================================

def test_api_upload_valid_jpeg(mock_request, mock_user):
    data = create_valid_jpeg()
    uf = make_upload_file("cover.jpg", data)
    res = run_endpoint(upload_image(mock_request, uf, mock_user))
    assert "url" in res
    assert res["url"].endswith(".jpg")

def test_api_upload_valid_png(mock_request, mock_user):
    data = create_valid_png()
    uf = make_upload_file("profile.png", data)
    res = run_endpoint(upload_image(mock_request, uf, mock_user))
    assert res["url"].endswith(".png")

def test_api_upload_valid_webp(mock_request, mock_user):
    data = create_valid_webp()
    uf = make_upload_file("banner.webp", data)
    res = run_endpoint(upload_image(mock_request, uf, mock_user))
    assert res["url"].endswith(".webp")

def test_api_upload_valid_gif(mock_request, mock_user):
    data = create_valid_gif()
    uf = make_upload_file("sticker.gif", data)
    res = run_endpoint(upload_image(mock_request, uf, mock_user))
    assert res["url"].endswith(".gif")

def test_api_upload_valid_heic(mock_request, mock_user):
    data = create_valid_heic()
    uf = make_upload_file("iphone_photo.heic", data)
    res = run_endpoint(upload_image(mock_request, uf, mock_user))
    assert res["url"].endswith(".heic")

def test_api_upload_invalid_signature_rejected(mock_request, mock_user):
    fake_image = b"Hello, I am a plain text file pretending to be a JPG!"
    uf = make_upload_file("malicious.jpg", fake_image)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "unsupported or invalid file signature" in exc_info.value.detail.lower()

def test_api_upload_pe_executable_rejected(mock_request, mock_user):
    pe_binary = b"MZ\x90\x00\x03\x00\x00\x00\x04\x00\x00\x00\xff\xff\x00\x00"
    uf = make_upload_file("backdoor.png", pe_binary)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "unsupported or invalid file signature" in exc_info.value.detail.lower()

def test_api_upload_extension_mismatch_rejected(mock_request, mock_user):
    jpeg_data = create_valid_jpeg()
    uf = make_upload_file("fake_png.png", jpeg_data)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "does not match verified image content" in exc_info.value.detail

def test_api_upload_malformed_image_rejected(mock_request, mock_user):
    corrupt_data = b"\xff\xd8\xff\xe0" + b"\x00" * 100 + b"BROKEN"
    uf = make_upload_file("broken.jpg", corrupt_data)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "malformed or corrupted" in exc_info.value.detail.lower()

def test_api_upload_oversized_rejected(mock_request, mock_user):
    oversized_size = MAX_FILE_SIZE + (64 * 1024)
    oversized_data = b"\xff\xd8\xff\xe0" + b"\x00" * (oversized_size - 4)
    uf = make_upload_file("huge.jpg", oversized_data)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 413
    assert "exceeds maximum allowed size" in exc_info.value.detail.lower()

def test_api_upload_path_traversal_rejected(mock_request, mock_user):
    data = create_valid_jpeg()
    uf = make_upload_file("../../../../etc/passwd.jpg", data)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "path traversal" in exc_info.value.detail.lower()

def test_api_upload_unsupported_formats_rejected(mock_request, mock_user):
    unsupported = [
        ("doc.pdf", b"%PDF-1.5 test document"),
        ("archive.zip", b"PK\x03\x04\x14\x00\x00\x00"),
        ("vector.svg", b"<svg xmlns='http://www.w3.org/2000/svg'></svg>"),
        ("page.html", b"<html><body>Malicious HTML</body></html>"),
    ]
    for fn, content in unsupported:
        uf = make_upload_file(fn, content)
        with pytest.raises(HTTPException) as exc_info:
            run_endpoint(upload_image(mock_request, uf, mock_user))
        assert exc_info.value.status_code == 400
        assert "unsupported or invalid file signature" in exc_info.value.detail.lower()

def test_api_upload_empty_file_rejected(mock_request, mock_user):
    uf = make_upload_file("empty.jpg", b"")
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_image(mock_request, uf, mock_user))
    assert exc_info.value.status_code == 400
    assert "empty" in exc_info.value.detail.lower()


# ============================================================================
# 6. ENDPOINT INTEGRATION TESTS: /uploads/book-images (BATCH)
# ============================================================================

def test_api_upload_batch_book_images(mock_request, mock_user):
    img1 = create_valid_jpeg()
    img2 = create_valid_png()
    files = [
        make_upload_file("cover1.jpg", img1),
        make_upload_file("cover2.png", img2),
    ]
    res = run_endpoint(upload_book_images(mock_request, files, mock_user))
    urls = res.get("urls", [])
    assert len(urls) == 2
    assert urls[0].endswith(".jpg")
    assert urls[1].endswith(".png")

def test_api_upload_batch_rejects_on_corrupt_file(mock_request, mock_user):
    img1 = create_valid_jpeg()
    corrupt = b"not an image file"
    files = [
        make_upload_file("cover1.jpg", img1),
        make_upload_file("bad.jpg", corrupt),
    ]
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(upload_book_images(mock_request, files, mock_user))
    assert exc_info.value.status_code == 400


# ============================================================================
# 7. ENDPOINT INTEGRATION TESTS: /uploads/storage-status
# ============================================================================

def test_api_storage_status_endpoint(mock_user):
    status = check_storage_status(mock_user)
    assert "backend" in status
    assert "is_durable" in status
    assert "bucket" in status
    assert "ephemeral_warning" in status


# ============================================================================
# 8. CALLER TESTS: /shelf-scan/upload & /ai/inspect-damage
# ============================================================================

from unittest.mock import MagicMock

def test_shelf_scan_upload_valid_image(mock_user):
    data = create_valid_jpeg(100, 100)
    uf = make_upload_file("bookshelf.jpg", data)
    db_mock = MagicMock()
    db_mock.query.return_value.all.return_value = []
    res = run_endpoint(scan_bookshelf_image(uf, mock_user, db_mock))
    assert "detected_books" in res
    assert "shelf_insights" in res

def test_shelf_scan_upload_invalid_signature_rejected(mock_user):
    fake = b"Just plain text pretending to be a shelf photo"
    uf = make_upload_file("bookshelf.jpg", fake)
    db_mock = MagicMock()
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(scan_bookshelf_image(uf, mock_user, db_mock))
    assert exc_info.value.status_code == 400
    assert "unsupported or invalid file signature" in exc_info.value.detail.lower()

def test_shelf_scan_upload_oversized_rejected(mock_user):
    oversized = MAX_FILE_SIZE + (32 * 1024)
    oversized_data = b"\xff\xd8\xff\xe0" + b"\x00" * (oversized - 4)
    uf = make_upload_file("bookshelf.jpg", oversized_data)
    db_mock = MagicMock()
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(scan_bookshelf_image(uf, mock_user, db_mock))
    assert exc_info.value.status_code == 413

def test_ai_inspect_damage_valid_photos(mock_user):
    before_data = create_valid_jpeg(50, 50)
    after_data = create_valid_png(50, 50)
    uf_before = make_upload_file("before.jpg", before_data)
    uf_after = make_upload_file("after.png", after_data)
    res = run_endpoint(inspect_book_damage(uf_before, uf_after, mock_user))
    assert "status" in res
    assert "condition_score" in res

def test_ai_inspect_damage_invalid_photo_rejected(mock_user):
    before_data = create_valid_jpeg(50, 50)
    corrupt_after = b"This is not a photo"
    uf_before = make_upload_file("before.jpg", before_data)
    uf_after = make_upload_file("after.jpg", corrupt_after)
    with pytest.raises(HTTPException) as exc_info:
        run_endpoint(inspect_book_damage(uf_before, uf_after, mock_user))
    assert exc_info.value.status_code == 400
    assert "unsupported or invalid file signature" in exc_info.value.detail.lower()
