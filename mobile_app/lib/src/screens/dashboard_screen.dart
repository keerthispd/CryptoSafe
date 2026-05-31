import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_session.dart';
import '../widgets/native_screen_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppAccountInfo? _account;
  List<AppFileSummary> _files = <AppFileSummary>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await AppSession.instance.client.accountInfo();
      final files = await AppSession.instance.client.listFiles();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = account;
        _files = files;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AppSession.instance.client.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return NativeScreenShell(
      eyebrow: 'CryptoSafe',
      title: 'CryptoSafe Vault',
      body: 'Browse, create, and manage your secure files from one place.',
      cards: const [
        NativeInfoCard(
          title: 'Encrypted storage',
          body: 'Data stays protected in the vault and is only shown after password confirmation.',
          icon: Icons.lock_outline,
        ),
        NativeInfoCard(
          title: 'Attachment support',
          body: 'Images, audio, video, PDFs, and documents can be previewed or downloaded.',
          icon: Icons.attachment_outlined,
          tint: Color(0xFF38BDF8),
        ),
      ],
      panelMaxWidth: 720,
      topActions: [
        FilledButton(onPressed: _load, child: const Text('Refresh')),
        OutlinedButton(onPressed: () => Navigator.of(context).pushNamed('/settings'), child: const Text('Settings')),
        OutlinedButton(onPressed: _logout, child: const Text('Logout')),
      ],
      panel: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dashboard',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.96)),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pushNamed('/file-editor'),
                          icon: const Icon(Icons.add),
                          label: const Text('New file'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _account == null ? 'Loading your vault...' : 'Files: ${_files.length} • ${_account!.isAdmin == true ? 'Admin' : 'User'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                    ),
                    const SizedBox(height: 16),
                    ..._files.map(
                      (file) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: ListTile(
                            title: Text(file.title),
                            subtitle: Text(file.description.isEmpty ? 'No description' : file.description),
                            trailing: Text('${file.attachmentCount} attachment(s)'),
                            onTap: () => Navigator.of(context).pushNamed('/file-detail', arguments: file.id),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
