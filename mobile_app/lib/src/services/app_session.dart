import '../config/app_config.dart';
import 'backend_client.dart';
import 'local_cipher_store.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  final LocalCipherStore store = LocalCipherStore();

  BackendClient? _client;
  String _baseUrl = AppConfig.defaultBaseUrl();

  String get baseUrl => _baseUrl;

  BackendClient get client {
    _client ??= BackendClient(baseUrl: _baseUrl, store: store);
    return _client!;
  }

  Future<void> initialize() async {
    final savedBaseUrl = await store.loadBaseUrl();
    _baseUrl = AppConfig.normalizeBaseUrl(savedBaseUrl ?? AppConfig.defaultBaseUrl());
    _client = BackendClient(baseUrl: _baseUrl, store: store);
    await _client!.restoreSession();
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = AppConfig.normalizeBaseUrl(value);
    await store.saveBaseUrl(_baseUrl);
    _client = BackendClient(baseUrl: _baseUrl, store: store);
    await _client!.restoreSession();
  }

  Future<void> clearSession() async {
    await store.clearSession();
    _client?.clearCookies();
  }
}
