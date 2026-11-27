import os
from datetime import datetime, timezone
from dotenv import load_dotenv

# Static UTC sunset timestamp for legacy tokens issued without a 'ver' claim (7-day transition window)
LEGACY_TOKEN_SUNSET_UTC = datetime(2026, 11, 28, 0, 0, 0, tzinfo=timezone.utc)

def load_environment():
    """
    Dynamically loads the appropriate .env file based on the ENV environment variable.
    Defaults to development mode (.env.dev).
    Supports test mode (.env.test) for isolated test execution.
    """
    env = os.getenv("ENV", "development").lower()
    
    # Resolve the directory of the backend root (two levels up from app/core/config.py)
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    
    if env == "production":
        env_file = ".env.prod"
    elif env == "test":
        env_file = ".env.test"
    else:
        env_file = ".env.dev"
        
    env_path = os.path.join(base_dir, env_file)
    
    if os.path.exists(env_path):
        print(f"[CONFIG] Loading environment from: {env_path}")
        load_dotenv(dotenv_path=env_path, override=True)
    else:
        # Fallback to standard dotenv loading in current working directory
        print(f"[CONFIG] Environment file {env_file} not found. Falling back to default load_dotenv()")
        load_dotenv()
