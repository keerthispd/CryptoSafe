import sqlite3, json, urllib.request, urllib.parse, sys

def query_db(db_path, userid):
    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, userid, password_hash, passcode_hash, webauthn_credential_id FROM users WHERE userid=?", (userid,))
        row = cur.fetchone()
        if row:
            print('DB_ROW:', json.dumps({'id': row[0], 'userid': row[1], 'password_hash': row[2], 'passcode_hash': row[3], 'webauthn_credential_id': row[4]}))
        else:
            print('DB_ROW: null')
    except Exception as e:
        print('DB_ERROR:', str(e))


def post_login(url, userid, password):
    data = urllib.parse.urlencode({'userid': userid, 'password': password}).encode('utf-8')
    req = urllib.request.Request(url, data=data, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            print('HTTP_STATUS:', r.status)
            print('HTTP_URL:', r.geturl())
            body = r.read().decode('utf-8', errors='replace')
            print('HTTP_BODY:', body[:2000])
    except urllib.error.HTTPError as he:
        print('HTTP_ERROR_STATUS:', he.code)
        try:
            print('HTTP_ERROR_BODY:', he.read().decode('utf-8', errors='replace')[:2000])
        except Exception:
            pass
    except Exception as e:
        print('HTTP_ERROR:', str(e))


if __name__ == '__main__':
    db_path = 'web_app/cryptosafe.db'
    userid = 'e2euser'
    password = 'Pass1234!'
    query_db(db_path, userid)
    post_login('http://127.0.0.1:5000/login', userid, password)
