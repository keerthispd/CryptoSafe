import json
from urllib import request

url = 'http://127.0.0.1:5000/api/biometric/register/options'
data = json.dumps({'userid':'auto_test_user'}).encode()
req = request.Request(url, data=data, headers={'Content-Type':'application/json'})
try:
    resp = request.urlopen(req, timeout=10)
    body = resp.read().decode()
    print('Status:', resp.getcode())
    print('Body:', body)
except Exception as e:
    print('Request failed:', e)
