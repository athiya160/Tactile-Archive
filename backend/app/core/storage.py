import os
import uuid
import boto3
from botocore.exceptions import NoCredentialsError

# Load S3 Configurations from Environment
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_STORAGE_BUCKET_NAME = os.getenv("AWS_STORAGE_BUCKET_NAME")
AWS_S3_REGION = os.getenv("AWS_S3_REGION", "ap-south-1")

# Check if AWS credentials are fully configured
def check_s3_configured() -> bool:
    """Dynamically checks if production AWS S3 credentials and bucket are configured."""
    key = os.getenv("AWS_ACCESS_KEY_ID")
    secret = os.getenv("AWS_SECRET_ACCESS_KEY")
    bucket = os.getenv("AWS_STORAGE_BUCKET_NAME")
    return bool(
        key and key != "your_aws_access_key_id" and
        secret and secret != "your_aws_secret_access_key" and
        bucket and bucket != "your_s3_bucket_name"
    )

is_s3_configured = check_s3_configured()

def upload_image_to_s3(file_bytes: bytes, filename: str, content_type: str) -> str:
    """
    Uploads a file to AWS S3 and returns the public URL.
    Returns None if test mode is active, if S3 is not configured, or if upload fails, allowing local storage fallback.
    """
    # Strict safeguard: never upload test fixtures or tests payloads to production S3
    if os.getenv("TESTING") == "true" or os.getenv("PYTEST_CURRENT_TEST"):
        print("[STORAGE] Test mode active. Skipping live S3 upload.")
        return None

    if not check_s3_configured():
        print("[STORAGE] AWS S3 is not configured. Falling back to local image storage.")
        return None

    try:
        s3_client = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY_ID,
            aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
            region_name=AWS_S3_REGION
        )
        
        # Upload object
        s3_client.put_object(
            Bucket=AWS_STORAGE_BUCKET_NAME,
            Key=filename,
            Body=file_bytes,
            ContentType=content_type
        )
        
        url = f"https://{AWS_STORAGE_BUCKET_NAME}.s3.{AWS_S3_REGION}.amazonaws.com/{filename}"
        print(f"[STORAGE] Successfully uploaded to AWS S3: {url}")
        return url
        
    except Exception as e:
        print(f"[STORAGE] AWS S3 upload error: {e}. Falling back to local storage.")
        return None
