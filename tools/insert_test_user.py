import sqlite3
from werkzeug.security import generate_password_hash
import os
from pathlib import Path

DB = Path(__file__).resolve().parents[1] / 'web_app' / 'cryptosafe.db'
print('DB path', DB)
conn = sqlite3.connect(str(DB))
conn.row_factory = sqlite3.Row
userid = 'testuser'
password = 'password123'
passcode = '1234'
password_hash = generate_password_hash(password)
passcode_hash = generate_password_hash(passcode)

with conn:
    # ensure users table exists
    conn.execute('''CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        failed_attempts INTEGER NOT NULL DEFAULT 0,
        locked_until TEXT,
        last_failed_at TEXT
    )''')
    existing = conn.execute('SELECT userid FROM users WHERE userid = ?', (userid,)).fetchone()
    if existing:
        print('User exists, updating password and passcode')
        conn.execute('UPDATE users SET password_hash = ?, passcode_hash = ? WHERE userid = ?', (password_hash, passcode_hash, userid))
    else:
        from datetime import datetime
        now = datetime.utcnow().isoformat()
        conn.execute('INSERT INTO users (userid, password_hash, created_at, passcode_hash) VALUES (?, ?, ?, ?)', (userid, password_hash, now, passcode_hash))
        print('Inserted user')

print('done')
