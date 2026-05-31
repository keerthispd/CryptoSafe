import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _useridController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _passcodeController = TextEditingController();
  String? _question;
  bool _loading = false;
  bool _hasPasscode = false;
  String _method = 'passcode';
  String? _error;

  @override
  void dispose() {
    _useridController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await AppSession.instance.client.forgotContext(_useridController.text.trim());
      setState(() {
        _question = info.backupQuestion;
        _hasPasscode = info.hasPasscode;
        _method = info.hasPasscode ? 'passcode' : 'biometric';
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_method == 'biometric') {
        Navigator.of(context).pushNamed(
          '/biometric-bridge',
          arguments: {
            'mode': 'forgot',
            'userid': _useridController.text.trim(),
            'backup_answer': _answerController.text.trim(),
            'new_password': _newPasswordController.text,
            'confirm_password': _newPasswordController.text,
            'passcode': _passcodeController.text,
            'method': 'biometric',
          },
        );
        return;
      }

      await AppSession.instance.client.forgotReset(
        method: 'passcode',
        backupAnswer: _answerController.text.trim(),
        newPassword: _newPasswordController.text,
        passcode: _passcodeController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful.')));
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Recover your CryptoSafe account.',
      body: 'Use your backup question plus biometric or passcode recovery to regain access without leaving the app.',
      cards: const [
        NativeInfoCard(
          title: 'Recovery question',
          body: 'Answer the security question you configured during registration.',
          icon: Icons.question_answer_outlined,
        ),
        NativeInfoCard(
          title: 'Two recovery paths',
          body: 'Choose biometric verification or a numeric passcode when the account supports it.',
          icon: Icons.switch_access_shortcut,
          tint: Color(0xFF38BDF8),
        ),
      ],
      panelMaxWidth: 640,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Forgot Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Recover your account', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
          const SizedBox(height: 20),
          TextField(controller: _useridController, decoration: const InputDecoration(labelText: 'User ID')),
          const SizedBox(height: 12),
          if (_question == null) ...[
            FilledButton(onPressed: _loading ? null : _loadContext, child: const Text('Load recovery question')),
          ] else ...[
            Text('Security question: $_question'),
            const SizedBox(height: 12),
            TextField(controller: _answerController, decoration: const InputDecoration(labelText: 'Backup answer'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _newPasswordController, decoration: const InputDecoration(labelText: 'New password'), obscureText: true),
            const SizedBox(height: 12),
            if (_hasPasscode)
              TextField(controller: _passcodeController, decoration: const InputDecoration(labelText: 'Passcode'), obscureText: true),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'passcode', label: Text('Passcode')),
                const ButtonSegment(value: 'biometric', label: Text('Biometric')),
              ],
              selected: {_method},
              onSelectionChanged: (value) {
                setState(() => _method = value.first);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loading ? null : _reset, child: const Text('Reset password')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
      ],
    );
  }
}
