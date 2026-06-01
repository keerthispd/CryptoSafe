import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _initializing = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Start initialization in the background so opening the encrypted
    // database doesn't block the first frame. If initialization completes
    // and an account is available we'll navigate to the dashboard.
    AppSession.instance.initialize().then((_) async {
      try {
        final account = await AppSession.instance.client.accountInfo();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/dashboard', arguments: account);
      } catch (_) {
        // Not signed in or backend unreachable — let the UI remain on the
        // welcome screen so the user can sign in or change settings.
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        final message = error.toString();
        _status = message.contains('Not signed in')
            ? null
            : 'Backend is not reachable at ${AppSession.instance.baseUrl}. Open Settings to check the URL, then retry.';
      });
    });

    // Allow UI to render immediately while initialization continues.
    if (!mounted) return;
    setState(() {
      _initializing = false;
      _status = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Welcome to CryptoSafe.',
      body: _status ?? 'Use the same flow as the web app: sign in, create an account, or recover a password.',
      cards: const [
        NativeInfoCard(
          title: 'Encrypted vault',
          body: 'Store sensitive details with encryption and password protection.',
          icon: Icons.lock_outline,
        ),
        NativeInfoCard(
          title: 'Protected login',
          body: 'Two-phase authentication and account lockouts keep access controlled.',
          icon: Icons.security_outlined,
          tint: Color(0xFFF59E0B),
        ),
      ],
      panelMaxWidth: 520,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Start here', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Open the sign-in flow or adjust the backend connection.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
          const SizedBox(height: 18),
          _ActionButton(label: 'Login', onPressed: () => Navigator.of(context).pushNamed('/login')),
          const SizedBox(height: 10),
          _ActionButton(label: 'Create account', onPressed: () => Navigator.of(context).pushNamed('/register')),
          const SizedBox(height: 10),
          _ActionButton(label: 'Forgot password', onPressed: () => Navigator.of(context).pushNamed('/forgot')),
          const SizedBox(height: 10),
          _ActionButton(label: 'Settings', secondary: true, onPressed: () => Navigator.of(context).pushNamed('/settings')),
          const SizedBox(height: 16),
          Text('Backend: ${AppSession.instance.baseUrl}', style: TextStyle(color: Colors.white.withValues(alpha: 0.56), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed, this.secondary = false});

  final String label;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
