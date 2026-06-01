import requests
import os

BASE = os.environ.get('BASE', 'http://127.0.0.1:5000')
S = requests.Session()

def create_user(userid='testuser', password='password123', passcode='1234'):
    url = BASE + '/register'
    data = {
        'userid': userid,
        'password': password,
        'confirm_password': password,
        'auth_method': 'passcode',
        'passcode': passcode,
        'passcode_confirm': passcode,
        'backup_question': 'q',
        'backup_answer': 'a',
    }
    r = S.post(url, data=data, allow_redirects=False)
    print('register', r.status_code, r.headers.get('Location'))
    if r.status_code in (200, 302):
        try:
            print(r.text[:1000])
        except Exception:
            pass

def login_and_complete(userid='testuser', password='password123', passcode='1234'):
    # login (sets pending_user_id)
    r = S.post(BASE + '/login', data={'userid': userid, 'password': password}, allow_redirects=False)
    print('login', r.status_code, r.headers.get('Location'))
    # verify passcode via biometric auth verify
    r = S.post(BASE + '/api/biometric/auth/verify', json={'passcode': passcode})
    print('biometric verify', r.status_code, r.text)
    # complete login
    r = S.post(BASE + '/complete_login', data={'password': password}, allow_redirects=False)
    print('complete_login', r.status_code, r.headers.get('Location'))

def create_file_with_attachment(file_title='Video Test', password='password123'):
    url = BASE + '/api/files'
    # create a small dummy "mp4" file
    tmp_path = 'tools/sample.mp4'
    with open(tmp_path, 'wb') as f:
        f.write(b'\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42mp41')
    files = [('upload_file', ('sample.mp4', open(tmp_path, 'rb'), 'video/mp4'))]
    data = {'title': file_title, 'description': 'Test upload', 'content': 'Test content', 'password': password}
    r = S.post(url, data=data, files=files)
    print('create file', r.status_code, r.text)
    if r.status_code == 201:
        fid = r.json().get('id')
        return fid
    return None


def preview_attachment(file_id, password='password123'):
    r = S.post(f'{BASE}/api/files/{file_id}/attachment', json={'password': password})
    print('attachment meta', r.status_code)
    if r.ok:
        data = r.json()
        print('meta:', data.get('uploaded_file_name'), data.get('uploaded_file_mime'), data.get('uploaded_file_size'))
        # also try download
        r2 = S.post(f'{BASE}/api/files/{file_id}/download', json={'password': password})
        print('download', r2.status_code, 'content-length', len(r2.content) if r2.ok else None)

if __name__ == '__main__':
    # set session user via dev helper
    r = S.get(BASE + '/__dev/login_as', params={'userid': 'testuser'})
    print('dev login', r.status_code, r.text)
    fid = create_file_with_attachment()
    if fid:
        preview_attachment(fid)
    else:
        print('file creation failed')
