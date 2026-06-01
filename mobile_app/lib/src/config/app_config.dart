import 'dart:io';

class AppConfig {
  static const String defaultAndroidEmulatorBaseUrl = 'http://localhost:5000';
  static const String defaultDesktopBaseUrl = 'http://127.0.0.1:5000';

  static String defaultBaseUrl() {
    return Platform.isAndroid ? defaultAndroidEmulatorBaseUrl : defaultDesktopBaseUrl;
  }

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl();
    }
    var normalized = trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (!normalized.contains('://')) {
      normalized = 'http://$normalized';
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed == null) {
      return defaultBaseUrl();
    }

    // On Android emulators prefer localhost (use with `adb reverse tcp:5000 tcp:5000`).
    // Do not rewrite to 10.0.2.2 here because WebAuthn requires the browser host
    // to match the RP ID (often 'localhost') for local testing.
    if (Platform.isAndroid && (parsed.host == 'localhost' || parsed.host == '127.0.0.1' || parsed.host == '::1')) {
      return parsed.toString();
    }

    return parsed.scheme.isEmpty ? defaultBaseUrl() : parsed.toString();
  }

  static Uri loginUri(String baseUrl) => Uri.parse('${normalizeBaseUrl(baseUrl)}/login.html');

  static Uri registrationUri(String baseUrl) => Uri.parse('${normalizeBaseUrl(baseUrl)}/registration.html');
}
