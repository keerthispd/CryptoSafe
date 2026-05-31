import json, sys
try:
    import requests
except Exception as e:
    print('MODULE_MISSING:', e)
    sys.exit(2)

base = 'http://127.0.0.1:5000'
s = requests.Session()
userid = 'e2euser'
password = 'Pass1234!'
passcode = '2468'

print('POST /login')
r = s.post(base + '/login', data={'userid': userid, 'password': password}, allow_redirects=True)
print('->', r.status_code, r.url)
print(r.text[:400])

print('\nPOST /api/biometric/auth/verify with passcode')
r2 = s.post(base + '/api/biometric/auth/verify', json={'passcode': passcode})
print('->', r2.status_code)
try:
    print('JSON:', r2.json())
except Exception:
    print('BODY:', r2.text[:400])

print('\nGET /password.html')
r3 = s.get(base + '/password.html', allow_redirects=True)
print('->', r3.status_code, r3.url)

print('\nPOST /complete_login')
r4 = s.post(base + '/complete_login', data={'password': password}, allow_redirects=True)
print('->', r4.status_code, r4.url)

print('\nGET /dashboard.html')
r5 = s.get(base + '/dashboard.html')
print('->', r5.status_code, r5.url)
print(r5.text[:400])
