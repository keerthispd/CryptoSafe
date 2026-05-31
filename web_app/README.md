Demo of our team based project-CryptoSafe, which we plan to deploy as an Android app. This is a web version for demonstration until the app development and deployment is completed.

## Flask Backend (Current)

This demo now uses Flask + SQLite for registration.

### Features
- Register with `userid` and `password`
- Set a backup recovery question and answer during registration
- Biometric passkey enrollment during registration (WebAuthn)
- Password is hashed before storage (not plain text)[temporary hash algorithm only for demo not for deployment]
- Duplicate user IDs are rejected on the registration page with an inline message
- Login with two-phase lock: password first, biometric verification second
- Accounts lock for 24 hours after 3 failed password attempts
- Forgot password is only available before the 24-hour password lock is active
- Forgot password requires the alternate factor (biometric or PIN passcode) and the backup question answer
- Success/failure landing page after account creation
- Retry option on failure
- Dashboard home page after login

### Run Locally
1. Create and activate a virtual environment (recommended).
2. From the repository root, change into the web app folder:
	`cd web_app`
3. Install dependencies:
	`pip install -r requirements.txt`
4. Start the server:
	`python run.py`
5. Open:
	`http://127.0.0.1:5000/registration.html`
	`http://127.0.0.1:5000/login.html`
	`http://127.0.0.1:5000/forgot-password.html`
	`http://127.0.0.1:5000/biometric.html` (phase 2 page, reached automatically after password login)

### Project Layout
- `run.py` is the root launcher you run from the repository root.
- `web_app/app.py` is the Flask entry point.
- `web_app/templates/` contains the HTML pages served by Flask.
- `web_app/utils/` contains the database inspection and wipe scripts.
- `web_app/cryptosafe.db` is the SQLite database file.

### Deployment Notes
- The app writes to `DATABASE_PATH` when that environment variable is set.
- For Render or any other redeploying host, mount persistent storage and point `DATABASE_PATH` at that mounted SQLite file.
- If `DATABASE_PATH` is not set, the app falls back to `web_app/cryptosafe.db`, which will be recreated when the container restarts.
- Set the same `DATABASE_PATH` value before running the inspection or wipe scripts so they target the same database file as the app.

### Biometric Notes
- A browser/device with WebAuthn passkey support is required for registration and login.
- For local testing, use `localhost` or `127.0.0.1` consistently from registration through login.
