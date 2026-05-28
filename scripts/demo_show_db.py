from pathlib import Path
import sqlite3
import os

# Prefer explicit env var, then common Render-mounted path, then bundled web_app DB
env = os.environ.get('DATABASE_PATH', '').strip()
if env:
    DB = Path(env)
elif os.environ.get('RENDER_DISK_PATH', '').strip():
    DB = Path(os.environ.get('RENDER_DISK_PATH')) / 'cryptosafe.db'
else:
    DB = Path(__file__).resolve().parent.parent / 'web_app' / 'cryptosafe.db'
print('Using DB:', DB)
if not DB.exists():
    print('Database file not found:', DB)
    raise SystemExit(1)

conn = sqlite3.connect(DB)
conn.row_factory = sqlite3.Row
c = conn.cursor()

print('\nUsers (sanitized):')
for r in c.execute("SELECT userid, password_hash, passcode_hash, webauthn_credential_id, created_at FROM users ORDER BY created_at DESC LIMIT 20"):
    ph = r['password_hash']
    pc = r['passcode_hash']
    print(f"- {r['userid']}: password={'yes' if ph else 'no'} (len={len(ph) if ph else 0}), passcode={'yes' if pc else 'no'} (len={len(pc) if pc else 0}), webauthn={'yes' if r['webauthn_credential_id'] else 'no'}, created={r['created_at']}")

print('\nFiles (sanitized):')
for r in c.execute("SELECT id, userid, title, content_encrypted, created_at FROM user_files ORDER BY created_at DESC LIMIT 20"):
    print(f"- id={r['id']} user={r['userid']} title={r['title']!r} encrypted={'yes' if r['content_encrypted'] else 'no'} created={r['created_at']}")

print('\nAttachments (sanitized):')
for r in c.execute("SELECT id, file_id, userid, uploaded_file_name, uploaded_file_mime, uploaded_file_size, created_at FROM user_file_attachments ORDER BY created_at DESC LIMIT 20"):
    print(f"- id={r['id']} file={r['file_id']} user={r['userid']} name={r['uploaded_file_name']!r} mime={r['uploaded_file_mime']} size={r['uploaded_file_size']} created={r['created_at']}")

conn.close()
