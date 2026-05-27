import urllib.request, urllib.parse, sqlite3, time

url = 'http://127.0.0.1:5000/register'
userid = 'auto_test_user'
form = {
    'auth_method': 'passcode',
    'passcode': '1234',
    'passcode_confirm': '1234',
    'userid': userid,
    'password': 'Password1!',
    'confirm_password': 'Password1!',
    'backup_question': 'Test Q',
    'backup_answer': 'Test A'
}

data = urllib.parse.urlencode(form).encode()
req = urllib.request.Request(url, data=data)
print('Posting registration...')
try:
    resp = urllib.request.urlopen(req, timeout=10)
    print('Response status:', resp.getcode())
    print('Final URL (after redirects):', resp.geturl())
except Exception as e:
    print('Request failed:', e)

# wait briefly for DB write
time.sleep(0.5)

db_path = 'web_app/cryptosafe.db'
print('Checking DB at', db_path)
conn = db_connection()
cur = conn.cursor()
try:
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    print('Tables:', cur.fetchall())
    cur.execute("PRAGMA table_info(users)")
    cols = cur.fetchall()
    print('users table schema (PRAGMA table_info):')
    for c in cols:
        print(' ', c)
    cur.execute('SELECT * FROM users WHERE userid=?', (userid,))
    rows = cur.fetchall()
    print('User rows (full):', rows)
    if rows:
        # print column names and values
        col_names = [c[1] for c in cols]
        for r in rows:
            for name, val in zip(col_names, r):
                print(f"  {name}: {val}")
except Exception as e:
    print('DB query error:', e)
finally:
    conn.close()
