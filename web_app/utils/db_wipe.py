from web_app.app import DB_PATH, db_connection

print('Using DB:', DB_PATH)
if not DB_PATH.exists():
    print('Database file not found.')
    raise SystemExit(1)

conn = db_connection()
cur = conn.cursor()

print('Deleting from user_files...')
cur.execute('DELETE FROM user_files')
print('Deleting from users...')
cur.execute('DELETE FROM users')
conn.commit()

# confirm counts
cur.execute('SELECT COUNT(*) FROM users')
users_count = cur.fetchone()[0]
cur.execute('SELECT COUNT(*) FROM user_files')
files_count = cur.fetchone()[0]
print('Users after wipe:', users_count)
print('User files after wipe:', files_count)

conn.close()
print('Wipe complete.')
