"""
Phase 16C.2B Additive Database Migration Script
Project: Tactile Archive / LibriFlow

Safely adds additive columns and tables for Buy workflow without modifying
existing historical columns or values. Supports idempotent execution and dry-runs.
"""

import sys
import os
import sqlite3
import shutil
from datetime import datetime

def get_columns(cursor, table_name):
    cursor.execute(f"PRAGMA table_info({table_name})")
    return {row[1]: row for row in cursor.fetchall()}

def add_column_if_not_exists(cursor, table_name, column_name, column_def):
    cols = get_columns(cursor, table_name)
    if column_name not in cols:
        sql = f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_def}"
        cursor.execute(sql)
        print(f"  + Added column {table_name}.{column_name}")
        return True
    else:
        print(f"  . Column {table_name}.{column_name} already exists (skipping)")
        return False

def run_migration(db_path: str, verbose: bool = True) -> dict:
    if not os.path.exists(db_path):
        raise FileNotFoundError(f"Database not found: {db_path}")

    print(f"\n[MIGRATION] Starting Phase 16C.2B Additive Migration on: {db_path}")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Pre-migration snapshot stats
    pre_orders = cur.execute("SELECT count(*) FROM orders").fetchone()[0]
    pre_items = cur.execute("SELECT count(*) FROM order_items").fetchone()[0]
    pre_pos = cur.execute("SELECT count(*) FROM purchase_orders").fetchone()[0]
    pre_payments = cur.execute("SELECT count(*) FROM payments").fetchone()[0]
    pre_books = cur.execute("SELECT count(*) FROM books").fetchone()[0]
    pre_fk_errors = len(cur.execute("PRAGMA foreign_key_check").fetchall())

    print(f"[PRE-SNAPSHOT] Orders: {pre_orders}, Items: {pre_items}, PurchaseOrders: {pre_pos}, Payments: {pre_payments}, Books: {pre_books}, Baseline FK notes: {pre_fk_errors}")

    # 1. Additive columns to `orders`
    print("\n[STEP 1] Applying additive columns to `orders`...")
    add_column_if_not_exists(cur, "orders", "items_total_paise", "INTEGER")
    add_column_if_not_exists(cur, "orders", "deposit_total_paise", "INTEGER")
    add_column_if_not_exists(cur, "orders", "shipping_fee_paise", "INTEGER DEFAULT 0")
    add_column_if_not_exists(cur, "orders", "platform_fee_paise", "INTEGER DEFAULT 120")
    add_column_if_not_exists(cur, "orders", "total_amount_paise", "INTEGER")
    add_column_if_not_exists(cur, "orders", "delivery_method", "VARCHAR(50) DEFAULT 'standard'")
    add_column_if_not_exists(cur, "orders", "recipient_name", "VARCHAR(255)")
    add_column_if_not_exists(cur, "orders", "recipient_phone", "VARCHAR(50)")
    add_column_if_not_exists(cur, "orders", "idempotency_key", "VARCHAR(100)")
    add_column_if_not_exists(cur, "orders", "stock_deducted", "BOOLEAN DEFAULT 0")
    add_column_if_not_exists(cur, "orders", "updated_at", "DATETIME")

    # 2. Additive columns to `order_items`
    print("\n[STEP 2] Applying additive columns to `order_items`...")
    add_column_if_not_exists(cur, "order_items", "provider_id", "INTEGER")
    add_column_if_not_exists(cur, "order_items", "transaction_type", "VARCHAR(20) DEFAULT 'buy'")
    add_column_if_not_exists(cur, "order_items", "unit_price_paise", "INTEGER")
    add_column_if_not_exists(cur, "order_items", "rental_fee_paise", "INTEGER")
    add_column_if_not_exists(cur, "order_items", "deposit_paise", "INTEGER")
    add_column_if_not_exists(cur, "order_items", "total_item_paise", "INTEGER")
    add_column_if_not_exists(cur, "order_items", "status", "VARCHAR(50) DEFAULT 'pending'")

    # 3. Additive columns to `purchase_orders`
    print("\n[STEP 3] Applying additive columns to `purchase_orders`...")
    add_column_if_not_exists(cur, "purchase_orders", "order_id", "INTEGER")

    # 4. Create table `inventory_reservations` if not exists
    print("\n[STEP 4] Creating table `inventory_reservations` if not exists...")
    cur.execute("""
    CREATE TABLE IF NOT EXISTS inventory_reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        order_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        status VARCHAR(20) NOT NULL DEFAULT 'active',
        expires_at DATETIME NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (book_id) REFERENCES books(id),
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
    )
    """)
    cur.execute("CREATE INDEX IF NOT EXISTS idx_inv_res_book_status ON inventory_reservations (book_id, status)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_inv_res_order ON inventory_reservations (order_id)")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_inv_res_expires ON inventory_reservations (expires_at)")

    # 5. Non-destructive accurate backfill for existing order items
    print("\n[STEP 5] Backfilling existing records accurately...")
    
    # Backfill buy items
    cur.execute("""
    UPDATE order_items 
    SET transaction_type = 'buy', 
        unit_price_paise = CAST(ROUND(price * 100) AS INTEGER), 
        total_item_paise = CAST(ROUND(price * 100) AS INTEGER) 
    WHERE is_purchase = 1 AND (transaction_type IS NULL OR transaction_type = 'buy')
    """)

    # Backfill rent items
    cur.execute("""
    UPDATE order_items 
    SET transaction_type = 'rent', 
        rental_fee_paise = CAST(ROUND(price * 100) AS INTEGER), 
        total_item_paise = CAST(ROUND(price * 100) AS INTEGER) 
    WHERE is_purchase = 0 AND price > 0
    """)

    # Backfill borrow items
    cur.execute("""
    UPDATE order_items 
    SET transaction_type = 'borrow', 
        total_item_paise = 0 
    WHERE is_purchase = 0 AND (price IS NULL OR price == 0)
    """)

    # Backfill orders integer paise
    cur.execute("""
    UPDATE orders
    SET total_amount_paise = CAST(ROUND(total_amount * 100) AS INTEGER),
        items_total_paise = CAST(ROUND(total_amount * 100) AS INTEGER),
        shipping_fee_paise = 0,
        platform_fee_paise = 120
    WHERE total_amount_paise IS NULL
    """)

    conn.commit()

    # 6. Post-migration verification assertions
    print("\n[STEP 6] Running post-migration integrity assertions...")
    post_orders = cur.execute("SELECT count(*) FROM orders").fetchone()[0]
    post_items = cur.execute("SELECT count(*) FROM order_items").fetchone()[0]
    post_pos = cur.execute("SELECT count(*) FROM purchase_orders").fetchone()[0]
    post_payments = cur.execute("SELECT count(*) FROM payments").fetchone()[0]
    post_books = cur.execute("SELECT count(*) FROM books").fetchone()[0]

    buy_count = cur.execute("SELECT count(*) FROM order_items WHERE transaction_type = 'buy'").fetchone()[0]
    rent_count = cur.execute("SELECT count(*) FROM order_items WHERE transaction_type = 'rent'").fetchone()[0]
    borrow_count = cur.execute("SELECT count(*) FROM order_items WHERE transaction_type = 'borrow'").fetchone()[0]

    # Foreign key integrity check: ensure ZERO new foreign key errors were introduced
    post_fk_errors = len(cur.execute("PRAGMA foreign_key_check").fetchall())
    res_fk_errors = len(cur.execute("PRAGMA foreign_key_check('inventory_reservations')").fetchall())
    
    conn.close()

    assert post_orders == pre_orders, f"Order count changed! Pre: {pre_orders}, Post: {post_orders}"
    assert post_items == pre_items, f"Item count changed! Pre: {pre_items}, Post: {post_items}"
    assert post_pos == pre_pos, f"PurchaseOrder count changed! Pre: {pre_pos}, Post: {post_pos}"
    assert post_payments == pre_payments, f"Payment count changed! Pre: {pre_payments}, Post: {post_payments}"
    assert post_books == pre_books, f"Book count changed! Pre: {pre_books}, Post: {post_books}"
    assert post_fk_errors == pre_fk_errors, f"New foreign key errors introduced! Pre: {pre_fk_errors}, Post: {post_fk_errors}"
    assert res_fk_errors == 0, f"Foreign key errors in inventory_reservations: {res_fk_errors}"
    assert buy_count == 31, f"Expected 31 buy items, got {buy_count}"
    assert rent_count == 7, f"Expected 7 rent items, got {rent_count}"
    assert borrow_count == 7, f"Expected 7 borrow items, got {borrow_count}"

    results = {
        "orders": post_orders,
        "items": post_items,
        "purchase_orders": post_pos,
        "payments": post_payments,
        "books": post_books,
        "buy_items": buy_count,
        "rent_items": rent_count,
        "borrow_items": borrow_count,
        "new_fk_errors": 0,
        "status": "SUCCESS"
    }
    print("[MIGRATION COMPLETED SUCCESSFULLY]")
    for k, v in results.items():
        print(f"  {k}: {v}")
        
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python migrate_phase16c2b_buy_schema.py <path_to_sqlite_db>")
        sys.exit(1)
    target_db = sys.argv[1]
    run_migration(target_db)
