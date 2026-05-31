import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text = AppSession.instance.baseUrl;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    await AppSession.instance.setBaseUrl(_baseUrlController.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _message = 'Backend updated.';
      _busy = false;
    });
  }

  Future<void> _clearSession() async {
    await AppSession.instance.clearSession();
    if (!mounted) return;
    setState(() {
      _message = 'Session cleared.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return NativeScreenShell(
      eyebrow: 'Secure access',
      title: 'Tune your CryptoSafe backend.',
      body: 'Point the mobile app at the same backend used by the web version, or clear your saved session state.',
      cards: const [
        NativeInfoCard(
          title: 'Backend URL',
          body: 'Use localhost for desktop testing or the emulator-friendly host mapping.',
          icon: Icons.link_outlined,
        ),
        NativeInfoCard(
          title: 'Session control',
          body: 'Clear stored cookies and restart the sign-in flow when needed.',
          icon: Icons.cookie_outlined,
          tint: Color(0xFF38BDF8),
        ),
      ],
      panelMaxWidth: 640,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Update the backend URL and session state.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
          const SizedBox(height: 20),
          TextField(controller: _baseUrlController, decoration: const InputDecoration(labelText: 'Backend URL')),
          const SizedBox(height: 12),
          if (_message != null) ...[
            Text(_message!),
            const SizedBox(height: 12),
          ],
        ],
      ),
      actions: [
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save backend URL')),
        OutlinedButton(onPressed: _clearSession, child: const Text('Clear session cookies')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
      ],
    );
  }
}
