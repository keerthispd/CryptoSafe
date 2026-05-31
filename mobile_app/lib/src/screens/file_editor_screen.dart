import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_session.dart';
import '../services/backend_client.dart';
import '../widgets/native_screen_shell.dart';

class FileEditorScreen extends StatefulWidget {
  const FileEditorScreen({super.key});

  @override
  State<FileEditorScreen> createState() => _FileEditorScreenState();
}

class _FileEditorScreenState extends State<FileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final List<PlatformFile> _uploads = <PlatformFile>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
    if (result == null) {
      return;
    }
    setState(() {
      _uploads.addAll(result.files);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final parts = <MultipartPart>[];
      for (final file in _uploads) {
        final path = file.path;
        if (path == null) {
          continue;
        }
        parts.add(
          MultipartPart.file(
            'upload_file',
            fileBytes: await File(path).readAsBytes(),
            filename: file.name,
            contentType: 'application/octet-stream',
          ),
        );
      }
      await AppSession.instance.client.createFile(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text,
        uploads: parts,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File created.')));
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
      eyebrow: 'CryptoSafe',
      title: 'Create a new secure file.',
      body: 'Add notes and attachments to your vault from a polished native compose screen.',
      cards: const [
        NativeInfoCard(
          title: 'Protected notes',
          body: 'Your content is encrypted before it is saved.',
          icon: Icons.lock_outline,
        ),
        NativeInfoCard(
          title: 'Flexible attachments',
          body: 'Upload images, audio, video, PDFs, and documents with the entry.',
          icon: Icons.attach_file,
          tint: Color(0xFF38BDF8),
        ),
      ],
      panelMaxWidth: 720,
      panel: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New File', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Create a file and attach supporting documents or media.', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), height: 1.45)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  TextFormField(controller: _contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 8),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x0F38BDF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x3338BDF8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('Add files')),
                    ],
                  ),
                  if (_uploads.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._uploads.map((file) => Chip(avatar: const Icon(Icons.insert_drive_file, size: 16), label: Text(file.name))),
                        ],
                      ),
                    ),
                ],
              ),
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
          onPressed: _busy ? null : _save,
          child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create file'),
        ),
      ],
    );
  }
}
