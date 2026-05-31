import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _useridController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _useridController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await AppSession.instance.client.login(
        _useridController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      if (result.status == AuthStatus.biometricRequired) {
        await AppSession.instance.store.saveLastUserId(_useridController.text.trim());
        if (!mounted) {
          return;
        }
        final navigator = Navigator.of(context);
        navigator.pushReplacementNamed(
          '/biometric-bridge',
          arguments: {'mode': 'login', 'userid': _useridController.text.trim()},
        );
        return;
      }
      if (result.isSuccess) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed('/password');
        return;
      }
      setState(() => _error = result.message ?? 'Login failed.');
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Sign in to your CryptoSafe dashboard.',
      body: 'Access your secure files, account tools, and recovery flows from one polished native screen.',
      cards: const [
        NativeInfoCard(
          title: 'Encrypted storage',
          body: 'Passwords are hashed before they are stored in the database.',
          icon: Icons.lock_outline,
        ),
        NativeInfoCard(
          title: 'Account safety',
          body: 'Repeated failed logins trigger temporary protection for the account.',
          icon: Icons.shield_outlined,
          tint: Color(0xFFF59E0B),
        ),
      ],
      panelMaxWidth: 520,
      panel: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Login', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Use your CryptoSafe user ID and password to continue.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _useridController,
              decoration: const InputDecoration(labelText: 'User ID'),
              validator: (value) => (value == null || value.trim().length < 3) ? 'Enter a valid user ID' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) => (value == null || value.length < 6) ? 'Enter a valid password' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Login'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/register'),
          child: const Text('Create account'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/forgot'),
          child: const Text('Forgot password'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pushNamed('/settings'),
          child: const Text('Settings'),
        ),
      ],
    );
  }
}
