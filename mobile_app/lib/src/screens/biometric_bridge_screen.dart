import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../services/app_session.dart';

class BiometricBridgeScreen extends StatefulWidget {
  const BiometricBridgeScreen({super.key, required this.arguments});

  final Map<String, dynamic> arguments;

  @override
  State<BiometricBridgeScreen> createState() => _BiometricBridgeScreenState();
}

class _BiometricBridgeScreenState extends State<BiometricBridgeScreen> {
  InAppWebViewController? _controller;
  String _status = 'Opening secure biometric flow...';
  bool _webViewReady = false;
  String? _preflightError;

  String get _mode => (widget.arguments['mode'] ?? 'login').toString();

  String get _baseUrl => AppSession.instance.baseUrl;

  Uri get _startUri {
    if (_mode == 'register') {
      return Uri.parse('$_baseUrl/registration.html');
    }
    if (_mode == 'forgot') {
      return Uri.parse('$_baseUrl/forgot-password.html');
    }
    return Uri.parse('$_baseUrl/biometric.html');
  }

  Future<String> _sessionCookieHeader() async {
    final raw = await AppSession.instance.store.readValue('session_cookies');
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return '';
    }
    final cookies = decoded
        .whereType<Map>()
        .map((entry) => {
              'name': (entry['name'] ?? '').toString(),
              'value': (entry['value'] ?? '').toString(),
            })
        .where((entry) => entry['name']!.isNotEmpty)
        .map((entry) => '${entry['name']}=${entry['value']}')
        .toList();
    return cookies.join('; ');
  }

  @override
  void initState() {
    super.initState();
    _prepareBridge();
  }

  Future<void> _prepareBridge() async {
    setState(() {
      _status = 'Connecting to backend...';
      _preflightError = null;
      _webViewReady = false;
    });
    try {
      final cookieHeader = await _sessionCookieHeader();
      final client = HttpClient()..badCertificateCallback = (_, __, ___) => true;
      final request = await client.getUrl(_startUri);
      if (cookieHeader.isNotEmpty) {
        request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
      }
      final response = await request.close();
      await response.drain<void>();
      client.close(force: true);
      if (response.statusCode >= 400) {
        throw HttpException('Received ${response.statusCode} from ${_startUri.path}');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Opening secure biometric flow...';
        _webViewReady = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preflightError = 'Backend page is unavailable at $_startUri. Check the backend URL in Settings or start the server.';
        _status = error.toString();
        _webViewReady = false;
      });
    }
  }

  Future<void> _syncCookies() async {
    final cookies = await CookieManager.instance().getCookies(url: WebUri(_baseUrl));
    final encoded = cookies
        .map((cookie) => {'name': cookie.name, 'value': cookie.value})
        .where((cookie) => (cookie['name'] ?? '').toString().isNotEmpty)
        .toList();
    await AppSession.instance.store.writeValue('session_cookies', jsonEncode(encoded));
  }

  Future<void> _restoreCookiesIntoWebView() async {
    final raw = await AppSession.instance.store.readValue('session_cookies');
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return;
    }
    for (final entry in decoded.whereType<Map>()) {
      final name = (entry['name'] ?? '').toString();
      final value = (entry['value'] ?? '').toString();
      if (name.isEmpty) {
        continue;
      }
      await CookieManager.instance().setCookie(
        url: WebUri(_baseUrl),
        name: name,
        value: value,
      );
    }
  }

  Future<String> _registrationScript() async {
    final userid = (widget.arguments['userid'] ?? '').toString();
    final password = (widget.arguments['password'] ?? '').toString();
    final confirmPassword = (widget.arguments['confirm_password'] ?? '').toString();
    final backupQuestion = (widget.arguments['backup_question'] ?? '').toString();
    final backupAnswer = (widget.arguments['backup_answer'] ?? '').toString();
    final authMethod = (widget.arguments['auth_method'] ?? 'biometric').toString();

    String jsEscape(String value) => value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

    final script = '''
      (function() {
        const fill = (id, value) => {
          const el = document.getElementById(id);
          if (el) el.value = value;
        };
        fill('userid', '${jsEscape(userid)}');
        fill('password', '${jsEscape(password)}');
        fill('confirm_password', '${jsEscape(confirmPassword)}');
        fill('backup_question', '${jsEscape(backupQuestion)}');
        fill('backup_answer', '${jsEscape(backupAnswer)}');
        const method = '${jsEscape(authMethod)}';
        const radio = document.querySelector('input[name="auth_method"][value="' + method + '"]');
        if (radio) {
          radio.checked = true;
          radio.dispatchEvent(new Event('change', { bubbles: true }));
        }
        setTimeout(() => {
          const submit = document.getElementById('createAccountBtn');
          if (submit) submit.click();
        }, 500);
      })();
    ''';
    return script;
  }

  Future<String> _forgotScript() async {
    final userid = (widget.arguments['userid'] ?? '').toString();
    final backupAnswer = (widget.arguments['backup_answer'] ?? '').toString();
    final newPassword = (widget.arguments['new_password'] ?? '').toString();
    final confirmPassword = (widget.arguments['confirm_password'] ?? '').toString();
    final passcode = (widget.arguments['passcode'] ?? '').toString();
    final method = (widget.arguments['method'] ?? 'biometric').toString();

    String jsEscape(String value) => value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    return '''
      (function() {
        const fill = (id, value) => {
          const el = document.getElementById(id);
          if (el) el.value = value;
        };
        fill('userid', '${jsEscape(userid)}');
        const load = document.getElementById('loadBtn');
        if (load) load.click();
        setTimeout(() => {
          const chooseBio = document.getElementById('useBiometricBtn');
          const choosePass = document.getElementById('usePasscodeBtn');
          if ('${jsEscape(method)}' === 'passcode' && choosePass) choosePass.click();
          if ('${jsEscape(method)}' === 'biometric' && chooseBio) chooseBio.click();
          fill('backup_answer', '${jsEscape(backupAnswer)}');
          fill('new_password', '${jsEscape(newPassword)}');
          fill('confirm_password', '${jsEscape(confirmPassword)}');
          fill('passcode', '${jsEscape(passcode)}');
          setTimeout(() => {
            const reset = document.getElementById('resetBtn');
            if (reset) reset.click();
          }, 600);
        }, 700);
      })();
    ''';
  }

  Future<void> _onLoadStop(String? url) async {
    if (!mounted || url == null) {
      return;
    }
    setState(() {
      _status = url;
    });

    if (_mode == 'register' && url.contains('/registration.html')) {
      await _controller?.evaluateJavascript(source: await _registrationScript());
    }

    if (_mode == 'forgot' && url.contains('/forgot-password.html')) {
      await _controller?.evaluateJavascript(source: await _forgotScript());
    }

    if ((_mode == 'login' && url.contains('/password.html')) || url.contains('/dashboard.html')) {
      await _syncCookies();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/password', (_) => false);
      }
      return;
    }

    if (_mode == 'register' && url.contains('/landing.html')) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
      return;
    }

    if (_mode == 'forgot' && url.contains('/login.html')) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric bridge')),
      body: _webViewReady
          ? Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFF0B1320),
                  child: Text(_status, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri('about:blank')),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                      useShouldOverrideUrlLoading: true,
                    ),
                    onWebViewCreated: (controller) async {
                      _controller = controller;
                      await _restoreCookiesIntoWebView();
                      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(_startUri.toString())));
                    },
                    onLoadStop: (controller, url) async {
                      await _onLoadStop(url?.toString());
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url?.toString() ?? '';
                      if (_mode == 'login' && url.contains('/password.html')) {
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Biometric bridge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(_preflightError ?? _status, style: const TextStyle(height: 1.45)),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _prepareBridge, child: const Text('Retry')),
                        const SizedBox(height: 8),
                        OutlinedButton(onPressed: () => Navigator.of(context).pushNamed('/settings'), child: const Text('Open Settings')),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
