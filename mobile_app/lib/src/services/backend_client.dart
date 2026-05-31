import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../models.dart';
import 'local_cipher_store.dart';

class BackendClient {
  BackendClient({required String baseUrl, required this.store})
      : _baseUri = Uri.parse(AppConfig.normalizeBaseUrl(baseUrl));

  final LocalCipherStore store;
  Uri _baseUri;
  List<Map<String, String>> _cookies = <Map<String, String>>[];

  Future<void> restoreSession() async {
    final raw = await store.readValue('session_cookies');
    if (raw == null || raw.trim().isEmpty) {
      _cookies = <Map<String, String>>[];
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      _cookies = decoded
          .whereType<Map>()
          .map((entry) => {
                'name': (entry['name'] ?? '').toString(),
                'value': (entry['value'] ?? '').toString(),
              })
          .where((entry) => entry['name']!.isNotEmpty)
          .toList();
    }
  }

  void clearCookies() {
    _cookies = <Map<String, String>>[];
  }

  Future<void> syncBaseUrl(String baseUrl) async {
    _baseUri = Uri.parse(AppConfig.normalizeBaseUrl(baseUrl));
    await restoreSession();
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return _baseUri.replace(
      path: '${_baseUri.path}$cleanPath',
      queryParameters: query,
    );
  }

  String _cookieHeader() {
    if (_cookies.isEmpty) {
      return '';
    }
    return _cookies.map((entry) => '${entry['name']}=${entry['value']}').join('; ');
  }

  Future<void> _storeResponseCookies(HttpClientResponse response) async {
    final incoming = response.cookies
        .map((cookie) => <String, String>{'name': cookie.name, 'value': cookie.value})
        .where((cookie) => cookie['name']!.isNotEmpty)
        .toList();
    if (incoming.isEmpty) {
      return;
    }

    for (final cookie in incoming) {
      _cookies.removeWhere((existing) => existing['name'] == cookie['name']);
      _cookies.add(cookie);
    }
    await store.writeValue('session_cookies', jsonEncode(_cookies));
  }

  Future<HttpClientResponse> _sendRequest(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, String>? formFields,
    String? jsonBody,
    List<MultipartPart>? multipartParts,
    bool followRedirects = true,
  }) async {
    final uri = _uri(path, query);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = (_, __, ___) => true;
    final request = await client.openUrl(method, uri);
    request.followRedirects = followRedirects;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json, text/plain, */*');

    final cookieHeader = _cookieHeader();
    if (cookieHeader.isNotEmpty) {
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }

    if (jsonBody != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonBody));
    } else if (multipartParts != null) {
      final boundary = '----CryptoSafeBoundary${DateTime.now().microsecondsSinceEpoch}';
      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      for (final part in multipartParts) {
        request.write('--$boundary\r\n');
        if (part.fileBytes != null) {
          request.write('Content-Disposition: form-data; name="${part.name}"; filename="${part.filename ?? part.name}"\r\n');
          request.write('Content-Type: ${part.contentType ?? 'application/octet-stream'}\r\n\r\n');
          request.add(part.fileBytes!);
          request.write('\r\n');
        } else {
          request.write('Content-Disposition: form-data; name="${part.name}"\r\n\r\n');
          request.write(part.value ?? '');
          request.write('\r\n');
        }
      }
      request.write('--$boundary--\r\n');
    } else if (formFields != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');
      request.write(formFields.entries
          .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
          .join('&'));
    }

    final response = await request.close();
    await _storeResponseCookies(response);
    client.close(force: true);
    return response;
  }

  Future<Map<String, dynamic>> _sendJsonMap(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool followRedirects = true,
  }) async {
    final response = await _sendRequest(
      method,
      path,
      query: query,
      jsonBody: body == null ? null : jsonEncode(body),
      followRedirects: followRedirects,
    );
    final responseBody = await utf8.decoder.bind(response).join();
    final decoded = responseBody.isNotEmpty ? jsonDecode(responseBody) : <String, dynamic>{};
    return <String, dynamic>{
      'statusCode': response.statusCode,
      'body': decoded,
      'rawBody': responseBody,
    };
  }

  Future<AuthResult> login(String userid, String password) async {
    final response = await _sendRequest(
      'POST',
      '/login',
      formFields: {'userid': userid, 'password': password},
      followRedirects: false,
    );
    final location = response.headers.value(HttpHeaders.locationHeader) ?? '';
    if (response.statusCode == HttpStatus.found && location.contains('/biometric.html')) {
      await store.saveLastUserId(userid);
      return AuthResult.biometricRequired();
    }
    if (response.statusCode == HttpStatus.found && location.contains('/login.html')) {
      final error = Uri.tryParse(location)?.queryParameters['error'] ?? 'Login failed.';
      return AuthResult.error(error);
    }
    if (response.statusCode == HttpStatus.found && location.contains('/dashboard.html')) {
      await store.saveLastUserId(userid);
      return AuthResult.success();
    }
    final body = await utf8.decoder.bind(response).join();
    return AuthResult.error(body.isEmpty ? 'Login failed.' : body);
  }

  Future<AuthResult> registerPasscode({
    required String userid,
    required String password,
    required String confirmPassword,
    required String passcode,
    required String passcodeConfirm,
    required String backupQuestion,
    required String backupAnswer,
  }) async {
    final response = await _sendRequest(
      'POST',
      '/register',
      formFields: {
        'userid': userid,
        'password': password,
        'confirm_password': confirmPassword,
        'auth_method': 'passcode',
        'passcode': passcode,
        'passcode_confirm': passcodeConfirm,
        'backup_question': backupQuestion,
        'backup_answer': backupAnswer,
      },
      followRedirects: false,
    );
    final location = response.headers.value(HttpHeaders.locationHeader) ?? '';
    if (response.statusCode == HttpStatus.found && location.contains('/landing.html')) {
      return AuthResult.success(message: 'Account created successfully.');
    }
    final body = await utf8.decoder.bind(response).join();
    return AuthResult.error(location.isNotEmpty ? location : body);
  }

  Future<AuthResult> loginPasswordComplete(String password) async {
    final response = await _sendRequest(
      'POST',
      '/complete_login',
      formFields: {'password': password},
      followRedirects: false,
    );
    final location = response.headers.value(HttpHeaders.locationHeader) ?? '';
    if (response.statusCode == HttpStatus.found && location.contains('/dashboard.html')) {
      return AuthResult.success(message: 'Logged in successfully.');
    }
    if (response.statusCode == HttpStatus.found && location.contains('/login.html')) {
      final error = Uri.tryParse(location)?.queryParameters['error'] ?? 'Password verification failed.';
      return AuthResult.error(error);
    }
    final body = await utf8.decoder.bind(response).join();
    return AuthResult.error(body.isEmpty ? 'Password verification failed.' : body);
  }

  Future<AppAccountInfo> accountInfo() async {
    final data = await _sendJsonMap('GET', '/api/account');
    if (data['statusCode'] == HttpStatus.unauthorized) {
      throw StateError('Not signed in.');
    }
    return AppAccountInfo.fromJson(Map<String, dynamic>.from(data['body'] as Map));
  }

  Future<List<AppFileSummary>> listFiles() async {
    final data = await _sendJsonMap('GET', '/api/files');
    if (data['statusCode'] != HttpStatus.ok) {
      throw StateError((data['body'] as Map?)?['error']?.toString() ?? 'Unable to load files.');
    }
    final body = Map<String, dynamic>.from(data['body'] as Map);
    final files = (body['files'] as List<dynamic>? ?? const [])
        .map((entry) => AppFileSummary.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    return files;
  }

  Future<AppFileDetails> displayFile(int fileId, String password) async {
    final data = await _sendJsonMap('POST', '/api/files/$fileId/display', body: {'password': password});
    if (data['statusCode'] != HttpStatus.ok) {
      final body = data['body'];
      throw StateError(body is Map ? (body['error']?.toString() ?? 'Unable to open file.') : 'Unable to open file.');
    }
    return AppFileDetails.fromJson(Map<String, dynamic>.from(data['body'] as Map));
  }

  Future<Uint8List> downloadAttachment({
    required int fileId,
    required String password,
    int? attachmentId,
  }) async {
    final response = await _sendRequest(
      'POST',
      '/api/files/$fileId/download',
      jsonBody: jsonEncode({'password': password, if (attachmentId != null) 'attachment_id': attachmentId}),
      followRedirects: false,
    );
    if (response.statusCode != HttpStatus.ok) {
      final body = await utf8.decoder.bind(response).join();
      throw StateError(body.isEmpty ? 'Unable to download file.' : body);
    }
    final bytes = await response.fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    return Uint8List.fromList(bytes);
  }

  Future<void> deleteAttachments({
    required int fileId,
    required String password,
    required List<int> attachmentIds,
  }) async {
    final data = await _sendJsonMap(
      'POST',
      '/api/files/$fileId/attachments/delete',
      body: {'password': password, 'attachment_ids': attachmentIds},
    );
    if (data['statusCode'] != HttpStatus.ok) {
      throw StateError(((data['body'] as Map?)?['error'])?.toString() ?? 'Unable to delete attachments.');
    }
  }

  Future<void> createFile({
    required String title,
    required String description,
    required String content,
    required List<MultipartPart> uploads,
  }) async {
    final response = await _sendRequest(
      'POST',
      '/api/files',
      multipartParts: <MultipartPart>[
        MultipartPart.text('title', title),
        MultipartPart.text('description', description),
        MultipartPart.text('content', content),
        ...uploads,
      ],
      followRedirects: false,
    );
    if (response.statusCode != HttpStatus.created && response.statusCode != HttpStatus.ok) {
      final body = await utf8.decoder.bind(response).join();
      throw StateError(body.isEmpty ? 'Unable to create file.' : body);
    }
  }

  Future<void> updateFile({
    required int fileId,
    required String password,
    required String title,
    required String description,
    required String content,
    required List<int> replaceAttachmentIds,
    required List<MultipartPart> uploads,
  }) async {
    final parts = <MultipartPart>[
      MultipartPart.text('password', password),
      MultipartPart.text('title', title),
      MultipartPart.text('description', description),
      MultipartPart.text('content', content),
      for (final id in replaceAttachmentIds) MultipartPart.text('replace_attachment_id', id.toString()),
      ...uploads,
    ];
    final response = await _sendRequest(
      'POST',
      '/api/files/$fileId/update',
      multipartParts: parts,
      followRedirects: false,
    );
    if (response.statusCode != HttpStatus.ok) {
      final body = await utf8.decoder.bind(response).join();
      throw StateError(body.isEmpty ? 'Unable to update file.' : body);
    }
  }

  Future<ForgotContextInfo> forgotContext(String userid) async {
    final data = await _sendJsonMap('POST', '/api/forgot/context', body: {'userid': userid});
    if (data['statusCode'] != HttpStatus.ok) {
      throw StateError(((data['body'] as Map?)?['error'])?.toString() ?? 'Unable to load recovery data.');
    }
    return ForgotContextInfo.fromJson(Map<String, dynamic>.from(data['body'] as Map));
  }

  Future<Map<String, dynamic>> biometricAuthOptions() async {
    final data = await _sendJsonMap('POST', '/api/biometric/auth/options');
    return data['body'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> biometricAuthVerify({String? passcode, Map<String, dynamic>? credential}) async {
    final body = <String, dynamic>{};
    if (passcode != null) body['passcode'] = passcode;
    if (credential != null) body['credential'] = credential;
    final data = await _sendJsonMap('POST', '/api/biometric/auth/verify', body: body);
    return {'statusCode': data['statusCode'], 'body': data['body']};
  }

  Future<void> forgotReset({
    required String method,
    required String backupAnswer,
    required String newPassword,
    String? passcode,
  }) async {
    final body = <String, dynamic>{
      'method': method,
      'backup_answer': backupAnswer,
      'new_password': newPassword,
      if (passcode != null) 'passcode': passcode,
    };
    final data = await _sendJsonMap('POST', '/api/forgot/reset', body: body);
    if (data['statusCode'] != HttpStatus.ok) {
      throw StateError(((data['body'] as Map?)?['error'])?.toString() ?? 'Unable to reset password.');
    }
  }

  Future<void> deleteAccount(String password) async {
    final data = await _sendJsonMap('POST', '/api/account/delete', body: {'password': password});
    if (data['statusCode'] != HttpStatus.ok) {
      throw StateError(((data['body'] as Map?)?['error'])?.toString() ?? 'Unable to delete account.');
    }
  }

  Future<void> logout() async {
    try {
      await _sendRequest('GET', '/logout', followRedirects: false);
    } catch (_) {}
    clearCookies();
    await store.clearSession();
  }

  Future<void> saveBaseUrl(String value) async {
    _baseUri = Uri.parse(AppConfig.normalizeBaseUrl(value));
    await store.saveBaseUrl(_baseUri.toString());
  }

  /// Upload a full audio file (used by recorder) as a single multipart upload.
  Future<void> uploadAudioFile({
    required int fileId,
    required String password,
    required String filename,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    final parts = <MultipartPart>[
      MultipartPart.text('password', password),
      MultipartPart.file('chunk', fileBytes: fileBytes, filename: filename, contentType: contentType),
      MultipartPart.text('final', 'true'),
      MultipartPart.text('filename', filename),
    ];

    final response = await _sendRequest('POST', '/api/files/$fileId/upload_audio_chunk', multipartParts: parts);
    if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.created) {
      final body = await utf8.decoder.bind(response).join();
      throw StateError(body.isEmpty ? 'Unable to upload audio.' : body);
    }
  }
}

class MultipartPart {
  MultipartPart.text(this.name, this.value)
      : fileBytes = null,
        filename = null,
        contentType = null;

  MultipartPart.file(
    this.name, {
    required this.fileBytes,
    required this.filename,
    this.contentType,
  }) : value = null;

  final String name;
  final String? value;
  final Uint8List? fileBytes;
  final String? filename;
  final String? contentType;
}
