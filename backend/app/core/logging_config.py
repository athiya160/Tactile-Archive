import logging
import json
import os
import contextvars
from datetime import datetime

# Global request ID context variable for structured log correlation
request_id_ctx: contextvars.ContextVar[str] = contextvars.ContextVar("request_id", default="")

def get_current_request_id() -> str:
    """Returns the current request correlation ID if set, or empty string."""
    return request_id_ctx.get()

class JSONFormatter(logging.Formatter):
    """
    Formats log records into a structured JSON string.
    """
    def format(self, record):
        log_data = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "request_id": get_current_request_id(),
            "message": record.getMessage(),
            "logger": record.name,
            "module": record.module,
            "filename": record.filename,
            "lineno": record.lineno,
        }
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_data)


def setup_logging():
    """
    Initializes structured logging configuration based on execution environment.
    """
    env = os.getenv("ENV", "development")
    root_logger = logging.getLogger()
    
    # Remove existing default handlers
    for h in list(root_logger.handlers):
        root_logger.removeHandler(h)
        
    stream_handler = logging.StreamHandler()
    
    if env == "production":
        stream_handler.setFormatter(JSONFormatter())
        root_logger.setLevel(logging.INFO)
    else:
        # Clean human-readable layout for development
        dev_formatter = logging.Formatter(
            "[%(asctime)s] %(levelname)s in %(module)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        stream_handler.setFormatter(dev_formatter)
        root_logger.setLevel(logging.DEBUG)
        
    root_logger.addHandler(stream_handler)
    
    # Fine-tune third party logger verbosity for clean streams
    logging.getLogger("uvicorn.access").setLevel(logging.INFO)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
    print(f"[LOGGING] Structured logging setup complete (ENV={env}).")
