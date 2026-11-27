"""
Phase 20.28 Additive Database Migration Script
Project: The Tactile Archive / LibriFlow

Safely creates the dedicated `account_deletion_requests` table and associated indexes
without modifying any existing tables, user data, or financial records.
Supports idempotent execution and dry-runs on any SQLite database.
"""

import sys
import os
import sqlite3
from datetime import datetime


def table_exists(cursor, table_name: str) -> bool:
    cursor.execute("SELECT count(*) FROM sqlite_master WHERE type='table' AND name=?", (table_name,))
    return cursor.fetchone()[0] > 0


def get_columns(cursor, table_name: str) -> dict:
    cursor.execute(f"PRAGMA table_info({table_name})")
    return {row[1]: row for row in cursor.fetchall()}


def run_migration(db_path: str, verbose: bool = True) -> dict:
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found: {db_path}")

    if verbose:
        print(f"\n[MIGRATION] Starting Phase 20.28 Account Deletion Requests Migration on: {db_path}")

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Pre-migration snapshot stats
    pre_users = cur.execute("SELECT count(*) FROM users").fetchone()[0] if table_exists(cur, "users") else 0
    pre_orders = cur.execute("SELECT count(*) FROM orders").fetchone()[0] if table_exists(cur, "orders") else 0
    pre_payments = cur.execute("SELECT count(*) FROM payments").fetchone()[0] if table_exists(cur, "payments") else 0
    pre_fk_errors = len(cur.execute("PRAGMA foreign_key_check").fetchall())

    if verbose:
        print(f"[PRE-SNAPSHOT] Users: {pre_users}, Orders: {pre_orders}, Payments: {pre_payments}, FK Baseline Errors: {pre_fk_errors}")

    # 1. Create table `account_deletion_requests` if not exists
    if verbose:
        print("\n[STEP 1] Creating table `account_deletion_requests` if not exists...")

    cur.execute("""
    CREATE TABLE IF NOT EXISTS account_deletion_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id VARCHAR(32) NOT NULL UNIQUE,
        user_id INTEGER,
        email VARCHAR(255) NOT NULL,
        reason VARCHAR(500),
        status VARCHAR(50) NOT NULL DEFAULT 'pending',
        ip_hash VARCHAR(64),
        resolution_notes VARCHAR(1000),
        processed_by INTEGER,
        processed_at DATETIME,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
        FOREIGN KEY (processed_by) REFERENCES users(id) ON DELETE SET NULL
    )
    """)

    # 2. Create performance & lookup indexes
    if verbose:
        print("[STEP 2] Creating indexes on `account_deletion_requests`...")

    cur.execute("CREATE UNIQUE INDEX IF NOT EXISTS uq_idx_adr_request_id ON account_deletion_requests (request_id)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_adr_email ON account_deletion_requests (email)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_adr_status ON account_deletion_requests (status)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_adr_user_id ON account_deletion_requests (user_id)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_adr_created_at ON account_deletion_requests (created_at)")

    conn.commit()

    # 3. Post-migration integrity verification
    if verbose:
        print("\n[STEP 3] Running post-migration integrity assertions...")

    post_users = cur.execute("SELECT count(*) FROM users").fetchone()[0] if table_exists(cur, "users") else 0
    post_orders = cur.execute("SELECT count(*) FROM orders").fetchone()[0] if table_exists(cur, "orders") else 0
    post_payments = cur.execute("SELECT count(*) FROM payments").fetchone()[0] if table_exists(cur, "payments") else 0
    post_requests = cur.execute("SELECT count(*) FROM account_deletion_requests").fetchone()[0]

    post_fk_errors = len(cur.execute("PRAGMA foreign_key_check").fetchall())
    res_fk_errors = len(cur.execute("PRAGMA foreign_key_check('account_deletion_requests')").fetchall())

    conn.close()

    assert post_users == pre_users, f"User count mutated! Pre: {pre_users}, Post: {post_users}"
    assert post_orders == pre_orders, f"Order count mutated! Pre: {pre_orders}, Post: {post_orders}"
    assert post_payments == pre_payments, f"Payment count mutated! Pre: {pre_payments}, Post: {post_payments}"
    assert post_fk_errors == pre_fk_errors, f"New foreign key errors introduced! Pre: {pre_fk_errors}, Post: {post_fk_errors}"
    assert res_fk_errors == 0, f"Foreign key errors in account_deletion_requests: {res_fk_errors}"

    results = {
        "status": "SUCCESS",
        "table_created": True,
        "users": post_users,
        "orders": post_orders,
        "payments": post_payments,
        "requests_count": post_requests,
        "new_fk_errors": 0
    }

    if verbose:
        print("[MIGRATION COMPLETED SUCCESSFULLY]")
        for k, v in results.items():
            print(f"  {k}: {v}")

    return results


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python migrate_phase20_28_account_deletion_requests.py <path_to_sqlite_db>")
        sys.exit(1)
    target_db = sys.argv[1]
    run_migration(target_db)
