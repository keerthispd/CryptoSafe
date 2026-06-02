# CryptoSafe

CryptoSafe is a secure data storage platform designed to protect sensitive personal information such as passwords, notes, credentials, and confidential files.

The project provides:

- A Web Application built using Flask
- An Android Application built using Flutter
- Multi-factor authentication
- Biometric authentication using WebAuthn Passkeys
- Secure encryption for stored data
- Cross-device authentication support
- Account recovery mechanisms
- Protection against brute-force attacks

---

## Features

### Secure Authentication

- User ID and Password Login
- Password hashing using secure cryptographic algorithms
- Failed login tracking
- Temporary account lockout after repeated failed attempts

### Biometric Authentication

- WebAuthn Passkey Authentication
- Fingerprint Authentication
- Face Authentication (device dependent)
- Platform Authenticator Support
- Cross-device QR-based Authentication

### Passcode Authentication

For devices without biometric support:

- Numeric Passcode Authentication
- Secure Passcode Hashing
- Passcode Confirmation Validation

### Secure Data Storage

Users can securely store:

- Passwords
- Notes
- Personal Information
- Uploaded Files
- Documents

All sensitive data is encrypted before storage.

### File Management

- Upload Files
- Download Files
- Update Files
- Delete Files
- Encrypted File Storage

### Account Recovery

- Backup Security Question
- Backup Answer Verification
- Recovery Lockout Protection

### Security Features

- Encrypted Storage
- Secure Session Management
- Failed Login Protection
- Biometric Lockout Protection
- Recovery Question Lockout Protection
- Cross-device Authentication Approval

---

## System Architecture

### Web Application

Frontend:

- HTML
- CSS
- JavaScript

Backend:

- Python Flask

Database:

- SQLite
- Optional SQLCipher Support

Authentication:

- WebAuthn
- Passkeys
- Password Authentication

### Android Application

Framework:

- Flutter

Authentication:

- Secure API Integration
- Biometric Authentication Support
- Local Encrypted Storage

Communication:

- REST APIs
- HTTPS

---

## Project Structure

```text
CryptoSafe/
│
├── web_app/
│   ├── app.py
│   ├── templates/
│   ├── static/
│   ├── utils/
│   └── requirements.txt
│
├── mobile_app/
│   ├── lib/
│   ├── android/
│   ├── test/
│   └── pubspec.yaml
│
├── tools/
│
├── README.md
└── requirements.txt
```

---

## Authentication Flow

### Registration

1. User enters:
   - User ID
   - Password
   - Backup Question
   - Backup Answer

2. User selects:
   - Biometric Authentication
   - Passcode Authentication

3. Account is created.

---

### Login

#### Biometric Login

1. User enters User ID.
2. Passkey challenge generated.
3. Biometric verification performed.
4. Server verifies challenge.
5. Access granted.

#### Password Login

1. User enters User ID.
2. Password verification.
3. Access granted.

---

### Cross-Device Authentication

1. User initiates login.
2. QR code generated.
3. Trusted device scans QR.
4. User approves authentication.
5. Login completed on target device.

---

## Encryption

### Stored Data

Sensitive information is encrypted before being written to the database.

Protected data includes:

- User notes
- Password entries
- Uploaded files
- Stored content

### Password Security

Passwords are never stored in plaintext.

Stored as:

- Salted cryptographic hashes

### Optional SQLCipher Support

CryptoSafe supports SQLCipher for full database encryption.

If SQLCipher bindings are unavailable:

- SQLite is used
- Field-level encryption remains active

---

## Installation

### Clone Repository

```bash
git clone https://github.com/keerthispd/Demo_tbp.git

cd Demo_tbp
```

---

## Web Application Setup

### Create Virtual Environment

```bash
python -m venv .venv
```

### Activate Environment

Windows:

```bash
.venv\Scripts\activate
```

Linux:

```bash
source .venv/bin/activate
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Run Application

```bash
python run.py
```

Application runs at:

```text
http://localhost:5000
```

---

## Android Application Setup

### Prerequisites

- Flutter SDK
- Android Studio
- Android Emulator or Physical Device

### Install Dependencies

```bash
cd mobile_app

flutter pub get
```

### Run Application

```bash
flutter run
```

### Build APK

```bash
flutter build apk
```

Generated APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## Database

Default Database:

```text
cryptosafe.db
```

Main Tables:

### users

Stores:

- User ID
- Password Hash
- Passkey Information
- Lockout Information
- Recovery Information

### user_files

Stores:

- User Files
- Metadata
- Encrypted Content

### user_file_attachments

Stores:

- Uploaded Attachments
- Encrypted File Data

### cross_device_auth

Stores:

- QR Authentication Requests
- Verification Status
- Expiration Information

---

## Future Enhancements

- Native Android Biometric Integration
- SQLCipher Full Deployment
- Cloud Backup Support
- Multi-device Credential Management
- End-to-End Encrypted Sync
- Secure Sharing Features
- iOS Application Support

---

## Security Notice

This project is developed for educational and research purposes.

Before production deployment:

- Enable HTTPS
- Use a production-grade database
- Configure secure secrets management
- Enable persistent storage
- Conduct security testing and auditing

---

## Author

Keerthi Patnaik

B.Tech CSE (IoT, Cybersecurity and Blockchain Technology)

MVSR Engineering College

---

## License

This project is released under the MIT License.
