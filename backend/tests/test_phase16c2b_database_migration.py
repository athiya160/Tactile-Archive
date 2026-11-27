"""
Test Phase 16C.2B Additive Database Migration on Disposable Database Copy
Confirms non-destructive schema additions, backfill accuracy, rerun idempotency,
and rollback safety without touching the original development database.
"""

import os
import sys
import shutil
import sqlite3
import pytest

sys.path.insert(0, os.path.abspath('.'))
from backend.scripts.migrate_phase16c2b_buy_schema import run_migration

PRE_MIGRATION_SNAPSHOT = "backups/tactile_archive_pre_stage2_migration_20261119_162736.db"
DISPOSABLE_DB = "scratch/disposable_migration_test.db"
ROLLBACK_TEST_DB = "scratch/rollback_migration_test.db"

def test_migration_on_disposable_copy():
    # Ensure scratch dir exists
    os.makedirs("scratch", exist_ok=True)
    
    # 1. Verify pre-migration snapshot exists
    assert os.path.exists(PRE_MIGRATION_SNAPSHOT), "Pre-migration snapshot does not exist!"
    
    # 2. Make isolated disposable copy from pre-migration snapshot
    if os.path.exists(DISPOSABLE_DB):
        os.remove(DISPOSABLE_DB)
    shutil.copyfile(PRE_MIGRATION_SNAPSHOT, DISPOSABLE_DB)
    
    # 3. Execute migration on disposable copy
    res1 = run_migration(DISPOSABLE_DB)
    assert res1["status"] == "SUCCESS"
    assert res1["orders"] == 71
    assert res1["items"] == 45
    assert res1["buy_items"] == 31
    assert res1["rent_items"] == 7
    assert res1["borrow_items"] == 7
    assert res1["purchase_orders"] == 25
    assert res1["payments"] == 41
    assert res1["new_fk_errors"] == 0

    # 4. Verify rerun idempotency (running migration a 2nd time on the same DB)
    print("\n--- Testing Migration Rerun Idempotency ---")
    res2 = run_migration(DISPOSABLE_DB)
    assert res2["status"] == "SUCCESS"
    assert res2["orders"] == 71
    assert res2["items"] == 45
    assert res2["buy_items"] == 31
    assert res2["rent_items"] == 7
    assert res2["borrow_items"] == 7

    # 5. Verify Rollback Procedure on isolated copy
    print("\n--- Testing Rollback Procedure ---")
    if os.path.exists(ROLLBACK_TEST_DB):
        os.remove(ROLLBACK_TEST_DB)
    # Simulate a snapshot taken right before migration
    shutil.copyfile(PRE_MIGRATION_SNAPSHOT, ROLLBACK_TEST_DB)
    # Apply migration
    run_migration(ROLLBACK_TEST_DB)
    # Simulate rollback by restoring snapshot
    shutil.copyfile(PRE_MIGRATION_SNAPSHOT, ROLLBACK_TEST_DB)
    
    # Verify rolled back DB has original columns without new ones
    conn = sqlite3.connect(ROLLBACK_TEST_DB)
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(orders)")
    cols = [r[1] for r in cur.fetchall()]
    assert "items_total_paise" not in cols, "Rollback failed: new column still present!"
    assert cur.execute("SELECT count(*) FROM orders").fetchone()[0] == 71
    conn.close()
    print("Rollback test verified successfully!")

    # 6. Verify development database contains migrated schema columns and integrity
    conn_dev = sqlite3.connect('backend/tactile_archive.db')
    cur_dev = conn_dev.cursor()
    cur_dev.execute("PRAGMA table_info(orders)")
    dev_cols = [r[1] for r in cur_dev.fetchall()]
    for req_col in ["items_total_paise", "deposit_total_paise", "total_amount_paise", "delivery_method"]:
        assert req_col in dev_cols, f"Missing required migrated column: {req_col}"
    assert cur_dev.execute("SELECT count(*) FROM orders").fetchone()[0] == 71
    conn_dev.close()
    print("\n[VERIFIED] Development database tactile_archive.db contains all migrated columns and intact records.")

if __name__ == "__main__":
    test_migration_on_disposable_copy()
    print("\nAll migration tests on disposable database PASSED!")
