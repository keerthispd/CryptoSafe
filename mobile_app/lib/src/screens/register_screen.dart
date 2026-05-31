import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _useridController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _passcodeConfirmController = TextEditingController();
  final _backupQuestionController = TextEditingController();
  final _backupAnswerController = TextEditingController();
  String _authMethod = 'biometric';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _useridController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passcodeController.dispose();
    _passcodeConfirmController.dispose();
    _backupQuestionController.dispose();
    _backupAnswerController.dispose();
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
      if (_authMethod == 'passcode') {
        final result = await AppSession.instance.client.registerPasscode(
          userid: _useridController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          passcode: _passcodeController.text,
          passcodeConfirm: _passcodeConfirmController.text,
          backupQuestion: _backupQuestionController.text.trim(),
          backupAnswer: _backupAnswerController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created.')));
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        } else {
          setState(() => _error = result.message ?? 'Registration failed.');
        }
        return;
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        '/biometric-bridge',
        arguments: {
          'mode': 'register',
          'userid': _useridController.text.trim(),
          'password': _passwordController.text,
          'confirm_password': _confirmPasswordController.text,
          'backup_question': _backupQuestionController.text.trim(),
          'backup_answer': _backupAnswerController.text.trim(),
          'auth_method': 'biometric',
        },
      );
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
    final showPasscode = _authMethod == 'passcode';

    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Create your CryptoSafe account.',
      body: 'Register once, choose your recovery method, and keep your sensitive information in a protected vault.',
      cards: const [
        NativeInfoCard(
          title: 'Encrypted vault',
          body: 'Stored details are encrypted before they are saved.',
          icon: Icons.lock_outline,
        ),
        NativeInfoCard(
          title: 'Protected login',
          body: 'Secure authentication and failed-login protection keep accounts safer.',
          icon: Icons.shield_outlined,
          tint: Color(0xFFF59E0B),
        ),
      ],
      panelMaxWidth: 640,
      panel: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registration', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Register with a unique user ID and password.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
            const SizedBox(height: 20),
            TextFormField(controller: _useridController, decoration: const InputDecoration(labelText: 'User ID')),
            const SizedBox(height: 12),
            TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password'), obscureText: true),
            const SizedBox(height: 12),
            TextFormField(controller: _backupQuestionController, decoration: const InputDecoration(labelText: 'Backup question')),
            const SizedBox(height: 12),
            TextFormField(controller: _backupAnswerController, decoration: const InputDecoration(labelText: 'Backup answer'), obscureText: true),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'biometric', label: Text('Biometric / Passkey')),
                ButtonSegment(value: 'passcode', label: Text('Passcode')),
              ],
              selected: {_authMethod},
              onSelectionChanged: (set) {
                setState(() => _authMethod = set.first);
              },
            ),
            if (showPasscode) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _passcodeController, decoration: const InputDecoration(labelText: 'Passcode (digits only)'), obscureText: true),
              const SizedBox(height: 12),
              TextFormField(controller: _passcodeConfirmController, decoration: const InputDecoration(labelText: 'Confirm passcode'), obscureText: true),
            ],
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
          child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to login'),
        ),
      ],
    );
  }
}
