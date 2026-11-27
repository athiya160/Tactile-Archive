import sqlite3
import sys

def upgrade_user(email):
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect('library.db')
        cursor = conn.cursor()

        # Check if the user exists
        cursor.execute("SELECT id, email, role FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()

        if user:
            print(f"Found user: {user[1]} with role: {user[2]}")
            
            # Update the role to 'provider' (or 'admin' if your system uses admin)
            cursor.execute("UPDATE users SET role = 'provider' WHERE email = ?", (email,))
            conn.commit()
            
            print(f"Success! User {email} has been upgraded to a provider.")
            print("You can now list books without seeing the error.")
        else:
            print(f"Error: Could not find a user with email '{email}'.")
            print("Please make sure you registered this email address first.")

    except sqlite3.Error as error:
        print("Failed to update database:", error)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python upgrade_user.py <your_email@example.com>")
    else:
        target_email = sys.argv[1]
        upgrade_user(target_email)
