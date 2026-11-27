"""
uploads.py — Phase 20.41
=========================
Secure image upload endpoints for LibriFlow / The Tactile Archive.

Security enforced (via app.core.upload_security):
  • File-size bounded before full read (streaming guard, 5 MiB max).
  • Magic-byte / file signature verified independently of client claims.
  • Filename extension and client MIME cross-checked against verified format.
  • Server-generated UUID storage filenames (client filenames never used).
  • Path traversal prevention on local fallback writes.
  • Storage durability status endpoint for operator visibility.
"""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from sqlalchemy.orm import Session

from app.api.auth import get_current_user
from app.core.database import SessionLocal
from app.core.storage import upload_image_to_s3
from app.core.upload_security import (
    MAX_FILE_SIZE,
    generate_secure_storage_filename,
    get_storage_status,
    read_bounded_file,
    resolve_safe_local_path,
    validate_image_bytes,
)
from app.models.user import User

import os

router = APIRouter()

# ---------------------------------------------------------------------------
# DB dependency
# ---------------------------------------------------------------------------

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ---------------------------------------------------------------------------
# Local storage bootstrap
# ---------------------------------------------------------------------------

UPLOAD_DIR = "images"
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Internal: validated write helper
# ---------------------------------------------------------------------------

async def _process_and_store(
    request: Request,
    file: UploadFile,
) -> str:
    """
    Read, validate and store a single uploaded image file.

    1. Bounded read (rejects oversized/empty files early).
    2. Magic byte validation + extension/MIME cross-check.
    3. Server-controlled UUID filename.
    4. Try S3; fall back to local disk with path-traversal guard.

    Returns the public URL string.
    """
    # 1. Bounded read — size enforced BEFORE validation
    contents = await read_bounded_file(file, max_size=MAX_FILE_SIZE)

    # 2. Validate: magic bytes, structural integrity, extension & MIME
    _detected_format, canonical_ext, canonical_mime = validate_image_bytes(
        contents,
        client_filename=file.filename,
        client_mime_type=file.content_type,
    )

    # 3. Server-generated filename — client filename is never used
    storage_filename = generate_secure_storage_filename(canonical_ext)

    # 4a. Attempt S3 upload
    s3_url = upload_image_to_s3(contents, storage_filename, canonical_mime)
    if s3_url:
        return s3_url

    # 4b. Local-disk fallback with path traversal guard
    safe_path = resolve_safe_local_path(storage_filename, UPLOAD_DIR)
    with open(safe_path, "wb") as fh:
        fh.write(contents)

    base_url = str(request.base_url).rstrip("/")
    return f"{base_url}/images/{storage_filename}"


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post("/uploads/image")
async def upload_image(
    request: Request,
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
):
    """
    Upload a single image (book cover, profile photo, etc.).

    Accepts: JPEG, PNG, WEBP, GIF, HEIC/HEIF.
    Max size: 5 MiB.
    Returns: { "url": "<public image URL>" }
    """
    url = await _process_and_store(request, file)
    return {"url": url}


@router.post("/uploads/book-images")
async def upload_book_images(
    request: Request,
    files: List[UploadFile] = File(...),
    user: User = Depends(get_current_user),
):
    """
    Upload multiple book cover images in one request.

    Each file is validated independently.  If any file fails validation the
    entire batch is rejected and no files are stored.

    Accepts: JPEG, PNG, WEBP, GIF, HEIC/HEIF per file.
    Max size per file: 5 MiB.
    Returns: { "urls": ["<url1>", "<url2>", ...] }
    """
    urls: List[str] = []
    for file in files:
        url = await _process_and_store(request, file)
        urls.append(url)
    return {"urls": urls}


@router.get("/uploads/storage-status")
def check_storage_status(
    user: User = Depends(get_current_user),
):
    """
    Diagnostics: report active storage backend and durability.

    Returns:
      backend          — "AWS_S3" | "LOCAL_DISK"
      is_durable       — True when S3 is configured
      bucket           — S3 bucket name (or null)
      region           — AWS region (or null)
      ephemeral_warning — Warning string when using local disk, null otherwise

    LOCAL_DISK is EPHEMERAL on cloud deployments (Railway, Render, Fly.io).
    Files stored locally will be lost on container restart or redeploy.
    Provision AWS S3 before production launch.
    """
    return get_storage_status()
