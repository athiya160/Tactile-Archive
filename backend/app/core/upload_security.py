"""
upload_security.py — Phase 20.41
=================================
Server-side upload validation and secure storage helpers for LibriFlow /
The Tactile Archive.

Security model
--------------
1. File-size is bounded BEFORE full reads (streaming check up to max_size+1 bytes).
2. Magic bytes / file signatures are verified independently of client-supplied
   filename or Content-Type.
3. The verified signature is cross-checked against the file extension and
   (when non-generic) the client-supplied MIME type.
4. Only structurally valid images pass the Pillow pixel-verify step.
5. Storage filenames are always server-generated UUIDs — the client filename is
   never used in the final path.
6. resolve_safe_local_path() ensures no generated path escapes UPLOAD_DIR, even
   if future callers pass unusual strings.
7. Storage durability is reported honestly: local disk is flagged EPHEMERAL.
"""

from __future__ import annotations

import io
import os
import uuid
import struct
from typing import Optional, Tuple

from fastapi import HTTPException, UploadFile
from PIL import Image

import app.core.storage as _storage_mod

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# 5 MiB — applies to every upload path.
MAX_FILE_SIZE: int = 5 * 1024 * 1024  # 5 MB

# Mapping: detected format → (canonical extension, canonical MIME, accepted client extensions)
_FORMAT_MAP: dict[str, tuple[str, str, set[str]]] = {
    "JPEG": ("jpg",  "image/jpeg", {"jpg", "jpeg"}),
    "PNG":  ("png",  "image/png",  {"png"}),
    "WEBP": ("webp", "image/webp", {"webp"}),
    "GIF":  ("gif",  "image/gif",  {"gif"}),
    "HEIC": ("heic", "image/heic", {"heic", "heif"}),
}

# Accepted client MIME types that must agree with detected format.
# "application/octet-stream" and "binary/octet-stream" are accepted generically.
_GENERIC_MIMES = {"application/octet-stream", "binary/octet-stream"}

# Mapping: detected format → set of accepted client MIME types
_MIME_ALIASES: dict[str, set[str]] = {
    "JPEG": {"image/jpeg", "image/jpg"},
    "PNG":  {"image/png"},
    "WEBP": {"image/webp"},
    "GIF":  {"image/gif"},
    "HEIC": {"image/heic", "image/heif"},
}

# Minimum HEIC box size is 24 bytes (4 size + 4 type + 4 brand + 4 version + >=8 compat)
_HEIC_MIN_BOX_BYTES = 24


# ---------------------------------------------------------------------------
# 1. Magic-byte / signature detection
# ---------------------------------------------------------------------------

def detect_file_signature(data: bytes) -> Optional[str]:
    """
    Inspect the first few bytes of *data* and return the detected image format
    name, or None if unrecognised.

    Returned strings: "JPEG", "PNG", "WEBP", "GIF", "HEIC"
    """
    if not data or len(data) < 4:
        return None

    # JPEG — FF D8 FF
    if data[:3] == b"\xff\xd8\xff":
        return "JPEG"

    # PNG — 89 50 4E 47 0D 0A 1A 0A
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "PNG"

    # WEBP — RIFF????WEBP
    if data[:4] == b"RIFF" and len(data) >= 12 and data[8:12] == b"WEBP":
        return "WEBP"

    # GIF — GIF87a or GIF89a
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "GIF"

    # HEIC / HEIF — ISO Base Media File Format (ftyp box)
    # Layout: [4-byte big-endian box size][4-byte "ftyp"][4-byte major brand][...]
    if len(data) >= 12:
        try:
            box_size = struct.unpack(">I", data[:4])[0]
            box_type = data[4:8]
            major_brand = data[8:12]
            if box_type == b"ftyp" and major_brand in (b"heic", b"heix", b"hevc", b"mif1", b"msf1"):
                return "HEIC"
        except struct.error:
            pass

    return None


# ---------------------------------------------------------------------------
# 2. Full image validation
# ---------------------------------------------------------------------------

def validate_image_bytes(
    data: bytes,
    client_filename: Optional[str] = None,
    client_mime_type: Optional[str] = None,
) -> Tuple[str, str, str]:
    """
    Validate *data* as a supported image file.

    Steps
    -----
    1. Reject empty data.
    2. Reject null bytes in filename (CVE-class bypass attempt).
    3. Reject path traversal characters in filename.
    4. Detect file signature (magic bytes).
    5. Reject unsupported signatures.
    6. Cross-check signature against client extension (if provided).
    7. Cross-check signature against client MIME (unless generic/None).
    8. For JPEG/PNG/WEBP/GIF: run Pillow verify() to catch corrupted files.
    9. For HEIC: verify minimum structural integrity.

    Returns
    -------
    (detected_format, canonical_extension, canonical_mime)
    e.g. ("JPEG", "jpg", "image/jpeg")

    Raises HTTPException (400 / 413) on any failure.
    """
    # 1. Empty
    if not data:
        raise HTTPException(status_code=400, detail="Empty file is not accepted.")

    # 2. Null byte in filename
    fn = client_filename or ""
    if "\x00" in fn:
        raise HTTPException(status_code=400, detail="Null byte detected in filename.")

    # 3. Path traversal in filename
    _reject_path_traversal(fn)

    # 4. Detect signature
    detected = detect_file_signature(data)

    # 5. Unsupported / unknown
    if detected is None or detected not in _FORMAT_MAP:
        raise HTTPException(
            status_code=400,
            detail="Unsupported or invalid file signature. Only JPEG, PNG, WEBP, GIF and HEIC images are accepted.",
        )

    canonical_ext, canonical_mime, accepted_exts = _FORMAT_MAP[detected]

    # 6. Extension mismatch
    if fn:
        client_ext = fn.rsplit(".", 1)[-1].lower() if "." in fn else ""
        if client_ext and client_ext not in accepted_exts:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"File extension '.{client_ext}' does not match verified image content "
                    f"(detected: {detected}). Re-save the file with the correct extension."
                ),
            )

    # 7. MIME mismatch (only reject non-generic, explicit contradictions)
    if client_mime_type and client_mime_type not in _GENERIC_MIMES:
        allowed_mimes = _MIME_ALIASES.get(detected, set())
        if client_mime_type not in allowed_mimes:
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Provided MIME type '{client_mime_type}' does not match verified image content "
                    f"(detected: {detected}). Upload the correct file type."
                ),
            )

    # 8. Structural / pixel-level verification
    if detected == "HEIC":
        _verify_heic_structure(data)
    else:
        _verify_with_pillow(data, detected)

    return detected, canonical_ext, canonical_mime


# ---------------------------------------------------------------------------
# 3. Internal structural validators
# ---------------------------------------------------------------------------

def _reject_path_traversal(filename: str) -> None:
    """Raise 400 if the filename contains path-separator characters."""
    if not filename:
        return
    # Reject any separator or traversal sequence
    for bad in ("/", "\\", "..", "\x00"):
        if bad in filename:
            raise HTTPException(
                status_code=400,
                detail=f"Path traversal attempt detected in filename: '{filename}'",
            )


def _verify_with_pillow(data: bytes, detected_format: str) -> None:
    """Use Pillow to verify structural integrity of JPEG/PNG/WEBP/GIF data."""
    try:
        img = Image.open(io.BytesIO(data))
        img.verify()  # raises on corrupt data
    except Exception:
        raise HTTPException(
            status_code=400,
            detail=f"Malformed or corrupted image file (detected format: {detected_format}). The file cannot be verified.",
        )


def _verify_heic_structure(data: bytes) -> None:
    """Minimal structural sanity check for HEIC/HEIF ISOBMFF container."""
    if len(data) < _HEIC_MIN_BOX_BYTES:
        raise HTTPException(
            status_code=400,
            detail="Malformed or truncated HEIC/HEIF file. Minimum structural size not met.",
        )
    try:
        box_size = struct.unpack(">I", data[:4])[0]
        if box_size < _HEIC_MIN_BOX_BYTES:
            raise HTTPException(
                status_code=400,
                detail="Malformed or truncated HEIC/HEIF file. ftyp box size is below minimum.",
            )
    except struct.error:
        raise HTTPException(
            status_code=400,
            detail="Malformed or truncated HEIC/HEIF file. Cannot parse ftyp box.",
        )


# ---------------------------------------------------------------------------
# 4. Bounded streaming read (enforces size BEFORE full load)
# ---------------------------------------------------------------------------

async def read_bounded_file(upload: UploadFile, max_size: int = MAX_FILE_SIZE) -> bytes:
    """
    Read *upload* up to *max_size* bytes.

    Raises HTTPException 400 for empty files, 413 for files exceeding the limit.

    When the underlying file object is a plain ``io.BytesIO`` (as used by unit
    tests via Starlette's ``UploadFile(file=io.BytesIO(...))``), the read is
    done synchronously to avoid Starlette's ``run_in_threadpool`` → anyio path
    which requires a running event loop.  In all other cases (real HTTP uploads)
    the proper async streaming path is used.
    """
    # --- Sync fast-path for BytesIO-backed UploadFile (unit tests) ---
    underlying = getattr(upload, "file", None)
    if isinstance(underlying, io.BytesIO):
        underlying.seek(0)
        data = underlying.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty file is not accepted.")
        if len(data) > max_size:
            raise HTTPException(
                status_code=413,
                detail=(
                    f"File exceeds maximum allowed size of {max_size // (1024 * 1024)} MiB. "
                    "Upload a smaller file."
                ),
            )
        return data

    # --- Async streaming path for real HTTP multipart uploads ---
    chunks: list[bytes] = []
    total = 0
    chunk_size = 65536  # 64 KiB read window

    while True:
        chunk = await upload.read(chunk_size)
        if not chunk:
            break
        total += len(chunk)
        if total > max_size:
            raise HTTPException(
                status_code=413,
                detail=(
                    f"File exceeds maximum allowed size of {max_size // (1024 * 1024)} MiB. "
                    "Upload a smaller file."
                ),
            )
        chunks.append(chunk)

    data = b"".join(chunks)
    if not data:
        raise HTTPException(status_code=400, detail="Empty file is not accepted.")
    return data


# Synchronous variant (for unit-test helpers that cannot await)
def read_bounded_file_sync(data: bytes, max_size: int = MAX_FILE_SIZE) -> bytes:
    """
    Validate already-read bytes against size limit.
    Used by unit tests that call validate_image_bytes directly.
    """
    if len(data) > max_size:
        raise HTTPException(
            status_code=413,
            detail=(
                f"File exceeds maximum allowed size of {max_size // (1024 * 1024)} MiB. "
                "Upload a smaller file."
            ),
        )
    if not data:
        raise HTTPException(status_code=400, detail="Empty file is not accepted.")
    return data


# ---------------------------------------------------------------------------
# 5. Server-controlled filename generation
# ---------------------------------------------------------------------------

def generate_secure_storage_filename(canonical_ext: str) -> str:
    """
    Return a collision-resistant, path-safe storage filename.
    Format: <32-char hex UUID without hyphens>.<ext>
    Example: "a3f7c2e8d1b04f6e9a2c0d3e7f1b5c9a.jpg"
    """
    return f"{uuid.uuid4().hex}.{canonical_ext}"


# ---------------------------------------------------------------------------
# 6. Safe local path resolution (path traversal guard for local fallback)
# ---------------------------------------------------------------------------

def resolve_safe_local_path(filename: str, base_dir: str) -> str:
    """
    Resolve *filename* inside *base_dir* and verify the result is strictly
    contained within *base_dir*.  Raises HTTPException 400 on any traversal.

    Only bare filenames (no path separators) are permitted.
    """
    # Reject any path separator in the filename itself
    for sep in ("/", "\\"):
        if sep in filename:
            raise HTTPException(
                status_code=400,
                detail=f"Path traversal attempt detected: filename contains '{sep}'.",
            )
    if ".." in filename:
        raise HTTPException(
            status_code=400,
            detail="Path traversal attempt detected: '..' is not allowed in filenames.",
        )
    if os.path.isabs(filename):
        raise HTTPException(
            status_code=400,
            detail="Invalid filename: absolute paths are not permitted.",
        )

    abs_base = os.path.realpath(os.path.abspath(base_dir))
    abs_target = os.path.realpath(os.path.join(abs_base, filename))

    if not abs_target.startswith(abs_base + os.sep) and abs_target != abs_base:
        raise HTTPException(
            status_code=400,
            detail=f"Path traversal attempt detected: resolved path escapes upload directory.",
        )

    return abs_target


# ---------------------------------------------------------------------------
# 7. Storage durability status
# ---------------------------------------------------------------------------

def get_storage_status() -> dict:
    """
    Return a diagnostics dict describing the active storage backend and
    whether it is durable.

    LOCAL_DISK storage on Railway / Render / Fly.io is ephemeral — files are
    lost on every deploy or container restart.  This function reports that
    honestly so operators can provision S3 before launch.
    """
    if _storage_mod.check_s3_configured():
        return {
            "backend": "AWS_S3",
            "is_durable": True,
            "bucket": _storage_mod.AWS_STORAGE_BUCKET_NAME,
            "region": _storage_mod.AWS_S3_REGION,
            "ephemeral_warning": None,
        }
    return {
        "backend": "LOCAL_DISK",
        "is_durable": False,
        "bucket": None,
        "region": None,
        "ephemeral_warning": (
            "WARNING: EPHEMERAL LOCAL DISK STORAGE IS ACTIVE. "
            "Uploaded files will be permanently lost on container restart or redeploy. "
            "Provision AWS S3 (or equivalent durable object storage) before production launch."
        ),
    }
