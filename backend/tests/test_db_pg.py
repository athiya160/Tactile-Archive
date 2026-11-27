import os
from sqlalchemy import create_engine, text
from app.core.database import DATABASE_URL

def test_configured_database_connection():
    """Verify configured DATABASE_URL is accessible and can execute queries."""
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT 1")).scalar()
        assert result == 1
