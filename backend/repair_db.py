from app.core.database import engine
from sqlalchemy import text, inspect

print("--- Step 1: Repairing users columns ---")
with engine.connect() as conn:
    trans = conn.begin()
    try:
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS user_type VARCHAR NOT NULL DEFAULT 'reader'"))
        conn.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE"))
        trans.commit()
        print("SUCCESS: users columns repaired")
    except Exception as e:
        trans.rollback()
        print("Column repair note:", e)

print("\n--- Step 2: Inspecting users columns ---")
inspector = inspect(engine)
user_cols = [c['name'] for c in inspector.get_columns('users')]
print("Users table columns:", user_cols)

print("\n--- Step 3: Verifying tables ---")
print('student_profiles:', inspector.has_table('student_profiles'))
print('reader_profiles:', inspector.has_table('reader_profiles'))

print("\n--- Step 4: Data check ---")
with engine.connect() as conn:
    u_count = conn.execute(text('SELECT COUNT(*) FROM users')).scalar()
    b_count = conn.execute(text('SELECT COUNT(*) FROM books')).scalar()
    print('USERS COUNT:', u_count)
    print('BOOKS COUNT:', b_count)
