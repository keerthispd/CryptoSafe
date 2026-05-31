import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await AppSession.instance.client.loginPasswordComplete(_passwordController.text);
      if (!mounted) {
        return;
      }
      if (result.isSuccess) {
        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
      } else {
        setState(() => _error = result.message ?? 'Password verification failed.');
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Confirm your password.',
      body: 'Finish login by confirming the password for this account.',
      cards: const [
        NativeInfoCard(
          title: 'Final check',
          body: 'This screen completes the sign-in flow after the first step succeeds.',
          icon: Icons.verified_user_outlined,
        ),
      ],
      panelMaxWidth: 520,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Confirm Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Enter your password to finish login.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }
}
