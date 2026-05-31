# CryptoSafe Mobile

Native Flutter Android app for CryptoSafe.

This app mirrors the CryptoSafe backend with separate native screens for login, registration, biometric handoff, forgot password, dashboard, file detail, file creation, and settings. WebAuthn/passkey steps are handled through a dedicated bridge screen that loads the existing backend biometric pages, while the rest of the app is native.

## Storage

The app uses SQLCipher for local encrypted storage of app state such as:

- backend base URL
- session cookies
- last visited page
- last signed-in user ID

The encrypted database is separate from the backend database used by the Flask app.

## Default backend URL

- Android emulator: `http://10.0.2.2:5000`
- Physical Android device: set your machine IP, such as `http://192.168.0.110:5000`

## Notes

- Flutter SDK is required to build the Android app.
- The local backend must be running for the app to authenticate and load files.
- If you are building for Android and using a local HTTP backend, cleartext traffic must be allowed.
- If the Android platform folders are missing, run `flutter create .` once inside `mobile_app/` after installing Flutter to generate the native wrapper files.

## Expected next steps

Once Flutter is installed, run:

```bash
flutter pub get
flutter run
```

## Mobile architecture

- `BootstrapScreen` checks the local encrypted session and routes to login or dashboard.
- `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `DashboardScreen`, `FileDetailScreen`, `FileEditorScreen`, and `SettingsScreen` are native Flutter screens.
- `BiometricBridgeScreen` uses the backend's existing biometric web page to complete passkey enrollment/authentication and then syncs session cookies back into the native client.
