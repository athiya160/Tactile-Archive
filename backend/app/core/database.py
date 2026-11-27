from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from app.core.config import load_environment

load_environment()

current_env = os.getenv("ENV", "development").strip().lower()
raw_db_url = os.getenv("DATABASE_URL")

if current_env == "production":
    if not raw_db_url or not raw_db_url.strip():
        raise RuntimeError(
            "[DATABASE STARTUP ERROR] DATABASE_URL is not configured for production environment. "
            "Production strictly requires a persistent managed PostgreSQL connection string "
            "(e.g. postgresql://user:password@host:port/dbname). Ephemeral local SQLite fallback is prohibited."
        )
    if raw_db_url.strip().lower().startswith("sqlite"):
        raise RuntimeError(
            "[DATABASE STARTUP ERROR] SQLite database is not permitted in production environment. "
            "Production strictly requires a persistent managed PostgreSQL connection string."
        )
    DATABASE_URL = raw_db_url.strip()
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
else:
    DATABASE_URL = raw_db_url or "sqlite:///./tactile_archive.db"
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
    elif DATABASE_URL.startswith("sqlite:///") and not DATABASE_URL.startswith("sqlite:////"):
        rel = DATABASE_URL.replace("sqlite:///", "")
        if not os.path.isabs(rel):
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            clean_rel = rel.lstrip("./").lstrip(".\\")
            abs_path = os.path.join(base_dir, clean_rel)
            DATABASE_URL = f"sqlite:///{abs_path.replace(os.sep, '/')}"

from sqlalchemy import event

if DATABASE_URL.startswith("sqlite"):
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.close()
else:
    # Production-ready connection pooling for PostgreSQL (recycling, liveness ping, pool size limits)
    engine = create_engine(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_recycle=300,
        pool_size=10,
        max_overflow=20
    )

SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()