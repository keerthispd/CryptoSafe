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
- `web_app/cryptosafe.db` is the SQLCipher-encrypted database file.

### Deployment Notes
- The app writes to `DATABASE_PATH` when that environment variable is set.
- The app also reads `SQLCIPHER_KEY` for the database encryption key. Set it to a stable secret before deploying.
- On Render, set a persistent disk and point `DATABASE_PATH` to that mounted path, for example `/opt/render/project/src/data/cryptosafe.db`.
- If `DATABASE_PATH` is not set, the app falls back to a local SQLite file for development, and that file will be recreated when the container restarts.
- You can also set `RENDER_DISK_PATH` to the mounted folder, and the app will use `<mounted-folder>/cryptosafe.db` automatically.
- Set the same `DATABASE_PATH` value before running the inspection or wipe scripts so they target the same database file as the app.
- Keep the same `SQLCIPHER_KEY` value across restarts and deployments, or the encrypted database will not open.

## SQLCipher notes (status and how to enable)

- Current development state: the application will attempt to use Python SQLCipher bindings (pysqlcipher3/sqlcipher3) to open an encrypted database when available. If those bindings are not present at runtime the app falls back to opening a plain SQLite database and prints a runtime warning. This fallback keeps the demo usable for development on platforms where SQLCipher bindings are hard to install (for example, some Windows + newer-Python combinations).

- Recommendation for production: deploy the app in an environment that provides the SQLCipher C library and Python bindings. Two practical options:

	1. Docker (recommended): build and run a Linux container that installs libsqlcipher, then installs the Python bindings wheel or builds pysqlcipher3 against the system library. Example Dockerfile snippet:

		 ```Dockerfile
		 FROM python:3.11-slim
		 RUN apt-get update && apt-get install -y build-essential libsqlcipher-dev pkg-config && rm -rf /var/lib/apt/lists/*
		 WORKDIR /app
		 COPY web_app/requirements.txt ./
		 # install requirements (pysqlcipher3 may build against libsqlcipher-dev)
		 RUN pip install --no-cache-dir -r web_app/requirements.txt
		 COPY . .
		 ENV SQLCIPHER_KEY="replace-with-secure-key"
		 CMD ["python", "run.py"]
		 ```

	2. VM or host with package manager: install system `sqlcipher` (or libsqlcipher-dev) and then install the Python binding `pysqlcipher3` in the app's Python environment. On Debian/Ubuntu this is typically `apt-get install libsqlcipher-dev` then `pip install pysqlcipher3` (may require build tools).

- If you cannot install SQLCipher in a target environment, continue using the app with the plaintext fallback and rely on the existing field-level AES/GCM encryption already implemented for sensitive fields (the code encrypts certain payloads at the application layer). However, plaintext SQLite files will not be encrypted at rest — ensure the host disk is protected (encrypted disk, restricted permissions) if this is unacceptable.

- Migration: the project includes migration helpers to move data from an existing plaintext SQLite database into an SQLCipher-encrypted file when the bindings are available. To perform migration, provision an environment with SQLCipher bindings, set `SQLCIPHER_KEY`, and restart the app; the migration will run automatically if it detects a plaintext DB and available bindings. Always back up the plaintext DB before attempting migration.

If you want, I can add a Docker Compose setup and a `docker/` folder with a production-ready Dockerfile and an env.example file for `SQLCIPHER_KEY` and `DATABASE_PATH`.

### Biometric Notes
- A browser/device with WebAuthn passkey support is required for registration and login.
- For local testing, use `localhost` or `127.0.0.1` consistently from registration through login.
- Do not switch hostnames/IPs mid-flow (for example `localhost` -> `127.0.0.1` or LAN IP). WebAuthn binds credentials to RP ID/origin.
- If you are behind a proxy/tunnel or need fixed values, set:
	- `WEBAUTHN_RP_ID` (example: `localhost`)
	- `WEBAUTHN_ORIGIN` (example: `http://localhost:5000`)
