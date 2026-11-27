import sqlite3
import os

db_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tactile_archive.db")
print(f"Connecting to database: {db_path}")

conn = sqlite3.connect(db_path)
c = conn.cursor()

def add_column_if_missing(table, col, col_type):
    cols = [r[1] for r in c.execute(f"PRAGMA table_info({table})").fetchall()]
    if col not in cols:
        print(f"Adding {col} ({col_type}) to {table}...")
        c.execute(f"ALTER TABLE {table} ADD COLUMN {col} {col_type}")
        conn.commit()
    else:
        print(f"Column {col} already exists in {table}.")

# Users table columns
add_column_if_missing("users", "active_experience", "TEXT")
add_column_if_missing("users", "provider_enabled", "BOOLEAN DEFAULT 0")
add_column_if_missing("users", "provider_status", "TEXT DEFAULT 'not_enrolled'")

# Student profiles table columns
add_column_if_missing("student_profiles", "college", "TEXT")
add_column_if_missing("student_profiles", "semester", "TEXT")
add_column_if_missing("student_profiles", "graduation_year", "TEXT")
add_column_if_missing("student_profiles", "syllabus_details", "TEXT")

# Backfill existing users:
# 1. Existing providers have provider_enabled = 1, provider_status = 'active'
c.execute("UPDATE users SET provider_enabled = 1, provider_status = 'active' WHERE role = 'provider'")

# 2. Backfill active_experience to match user_type or 'reader'
c.execute("UPDATE users SET active_experience = user_type WHERE active_experience IS NULL AND user_type IS NOT NULL")
c.execute("UPDATE users SET active_experience = 'reader' WHERE active_experience IS NULL")
c.execute("UPDATE users SET provider_status = 'not_enrolled' WHERE provider_status IS NULL")
c.execute("UPDATE users SET provider_enabled = 0 WHERE provider_enabled IS NULL")

conn.commit()

rows = c.execute("SELECT id, email, role, user_type, active_experience, provider_enabled, provider_status FROM users LIMIT 10").fetchall()
print("\nMigration complete! Sample users:")
for r in rows:
    print(r)

conn.close()
