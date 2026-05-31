import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models.dart';
import '../services/app_session.dart';
import '../services/backend_client.dart';
import '../widgets/native_screen_shell.dart';

class FileDetailScreen extends StatefulWidget {
  const FileDetailScreen({super.key, required this.fileId});

  final int fileId;

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  final _passwordController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final Set<int> _selectedDeleteIds = <int>{};
  final List<PlatformFile> _uploads = <PlatformFile>[];
  AppFileDetails? _details;
  bool _opening = true;
  bool _editing = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final details = await AppSession.instance.client.displayFile(widget.fileId, _passwordController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = details;
        _titleController.text = details.title;
        _descriptionController.text = details.description;
        _contentController.text = details.content;
        _editing = false;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
    if (result == null) {
      return;
    }
    setState(() => _uploads.addAll(result.files));
  }

  Future<void> _save() async {
    if (_details == null) {
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final parts = <MultipartPart>[];
      for (final file in _uploads) {
        if (file.path == null) {
          continue;
        }
        parts.add(
          MultipartPart.file(
            'upload_file',
            fileBytes: await File(file.path!).readAsBytes(),
            filename: file.name,
            contentType: 'application/octet-stream',
          ),
        );
      }
      await AppSession.instance.client.updateFile(
        fileId: widget.fileId,
        password: _passwordController.text,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text,
        replaceAttachmentIds: _selectedDeleteIds.toList(),
        uploads: parts,
      );
      final refreshed = await AppSession.instance.client.displayFile(widget.fileId, _passwordController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = refreshed;
        _uploads.clear();
        _selectedDeleteIds.clear();
        _editing = false;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedDeleteIds.isEmpty) {
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await AppSession.instance.client.deleteAttachments(
        fileId: widget.fileId,
        password: _passwordController.text,
        attachmentIds: _selectedDeleteIds.toList(),
      );
      final refreshed = await AppSession.instance.client.displayFile(widget.fileId, _passwordController.text);
      if (!mounted) {
        return;
      }
      setState(() {
        _details = refreshed;
        _selectedDeleteIds.clear();
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _preview(AppAttachmentSummary attachment) async {
    final bytes = await AppSession.instance.client.downloadAttachment(
      fileId: widget.fileId,
      password: _passwordController.text,
      attachmentId: attachment.attachmentId,
    );
    final mime = attachment.mime.toLowerCase();
    if (!mounted) return;
    final kind = _attachmentKind(mime);
    if (kind == _AttachmentKind.image) {
      showDialog(
        context: context,
        builder: (_) => _PreviewDialog(
          title: attachment.name,
          subtitle: _attachmentSubtitle(attachment),
          body: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(minScale: 0.9, maxScale: 4, child: Image.memory(bytes, fit: BoxFit.contain)),
          ),
        ),
      );
      return;
    }
    if (kind == _AttachmentKind.audio) {
      final player = AudioPlayer();
      await player.setAudioSource(AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mime)));
      if (!mounted) {
        await player.dispose();
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AudioPreviewDialog(title: attachment.name, subtitle: _attachmentSubtitle(attachment), player: player),
      ).then((_) async {
        await player.dispose();
      });
      return;
    }
    if (kind == _AttachmentKind.text) {
      final text = String.fromCharCodes(bytes);
      showDialog(
        context: context,
        builder: (_) => _PreviewDialog(
          title: attachment.name,
          subtitle: _attachmentSubtitle(attachment),
          body: Container(
            constraints: const BoxConstraints(maxHeight: 420),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: SingleChildScrollView(child: SelectableText(text)),
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _PreviewDialog(
        title: attachment.name,
        subtitle: _attachmentSubtitle(attachment),
        body: Text(
          'Preview unavailable for this file type on mobile. Use the web app for richer inline playback or download the file from the file list.',
          style: TextStyle(color: Colors.white.withOpacity(0.74), height: 1.5),
        ),
      ),
    );
  }

  String _attachmentSubtitle(AppAttachmentSummary attachment) {
    final kind = _attachmentKind(attachment.mime);
    return '${_attachmentBadge(kind)} • ${attachment.mime} • ${_formatFileSize(attachment.size)}';
  }

  _AttachmentKind _attachmentKind(String mime) {
    final lowered = mime.toLowerCase();
    if (lowered.startsWith('image/')) return _AttachmentKind.image;
    if (lowered.startsWith('audio/')) return _AttachmentKind.audio;
    if (lowered.startsWith('video/')) return _AttachmentKind.video;
    if (lowered.startsWith('text/')) return _AttachmentKind.text;
    if (lowered.contains('pdf')) return _AttachmentKind.pdf;
    if (lowered.contains('word') || lowered.contains('document') || lowered.contains('officedocument')) return _AttachmentKind.document;
    return _AttachmentKind.other;
  }

  String _attachmentBadge(_AttachmentKind kind) {
    return switch (kind) {
      _AttachmentKind.image => 'Image',
      _AttachmentKind.audio => 'Audio',
      _AttachmentKind.video => 'Video',
      _AttachmentKind.text => 'Text',
      _AttachmentKind.pdf => 'PDF',
      _AttachmentKind.document => 'Document',
      _AttachmentKind.other => 'File',
    };
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    }
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(size < 10 * 1024 ? 1 : 0)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(size < 10 * 1024 * 1024 ? 1 : 0)} MB';
  }

  IconData _attachmentIcon(_AttachmentKind kind) {
    return switch (kind) {
      _AttachmentKind.image => Icons.image_outlined,
      _AttachmentKind.audio => Icons.graphic_eq,
      _AttachmentKind.video => Icons.smart_display_outlined,
      _AttachmentKind.text => Icons.description_outlined,
      _AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
      _AttachmentKind.document => Icons.feed_outlined,
      _AttachmentKind.other => Icons.attach_file,
    };
  }

  Color _attachmentTint(_AttachmentKind kind) {
    return switch (kind) {
      _AttachmentKind.image => const Color(0xFF38BDF8),
      _AttachmentKind.audio => const Color(0xFF6EE7B7),
      _AttachmentKind.video => const Color(0xFFF59E0B),
      _AttachmentKind.text => const Color(0xFF94A3B8),
      _AttachmentKind.pdf => const Color(0xFFF43F5E),
      _AttachmentKind.document => const Color(0xFF60A5FA),
      _AttachmentKind.other => const Color(0xFF9FB0C2),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_details == null) {
      return NativeScreenShell(
        eyebrow: 'CryptoSafe',
        title: 'Open a secure file.',
        body: 'Unlock a saved file with your password, then review or edit the entry and its attachments.',
        cards: const [
          NativeInfoCard(title: 'Protected content', body: 'The file content is encrypted and hidden until you unlock it.', icon: Icons.lock_outline),
          NativeInfoCard(title: 'Rich attachments', body: 'Preview images, audio, video, PDFs, and documents from the same screen.', icon: Icons.photo_library_outlined, tint: Color(0xFF38BDF8)),
        ],
        panelMaxWidth: 520,
        panel: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Open', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Enter the password once to view the file.', style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.45)),
            const SizedBox(height: 20),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: _opening ? null : _open, child: const Text('Open')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        ],
      );
    }

    final details = _details!;
    final readOnly = !_editing;
    return NativeScreenShell(
      eyebrow: 'CryptoSafe',
      title: details.title,
      body: details.description.isEmpty ? 'Review and edit the file details, content, and attachments.' : details.description,
      cards: [
        NativeInfoCard(title: 'Attachments', body: '${details.attachments.length} item(s) attached to this file.', icon: Icons.attachment_outlined),
        NativeInfoCard(title: 'Editing', body: _editing ? 'Editing is enabled. Save or delete attachments when finished.' : 'Read-only mode. Tap Edit to modify the file.', icon: Icons.edit_outlined, tint: const Color(0xFFF59E0B)),
      ],
      panelMaxWidth: 760,
      panel: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('File details', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Review content and attachments. Use Edit to unlock changes when needed.', style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.45)),
          const SizedBox(height: 20),
          TextField(controller: _titleController, readOnly: readOnly, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, readOnly: readOnly, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 12),
          TextField(controller: _contentController, readOnly: readOnly, maxLines: 8, decoration: const InputDecoration(labelText: 'Content')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text('Attachments (${details.attachments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              TextButton(onPressed: _editing ? () => setState(() => _selectedDeleteIds.clear()) : null, child: const Text('Clear selection')),
            ],
          ),
          ...details.attachments.map((attachment) {
              final kind = _attachmentKind(attachment.mime);
              final tint = _attachmentTint(kind);
              final selected = _selectedDeleteIds.contains(attachment.attachmentId);
              return Card(
                elevation: 0,
                color: const Color(0x0AFFFFFF),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: tint.withOpacity(_editing ? 0.2 : 0.12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: tint.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tint.withOpacity(0.22)),
                        ),
                        child: Icon(_attachmentIcon(kind), color: tint),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  attachment.name.isEmpty ? 'Attachment' : attachment.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: tint.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: tint.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    _attachmentBadge(kind),
                                    style: TextStyle(color: tint, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${attachment.mime} • ${_formatFileSize(attachment.size)}',
                              style: TextStyle(color: Colors.white.withOpacity(0.68), height: 1.45),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _preview(attachment),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Preview'),
                                ),
                                if (_editing)
                                  FilterChip(
                                    selected: selected,
                                    onSelected: (checked) {
                                      setState(() {
                                        if (checked) {
                                          _selectedDeleteIds.add(attachment.attachmentId ?? -1);
                                        } else {
                                          _selectedDeleteIds.remove(attachment.attachmentId ?? -1);
                                        }
                                      });
                                    },
                                    avatar: Icon(Icons.delete_outline, size: 16, color: selected ? const Color(0xFF03111A) : tint),
                                    label: const Text('Mark for delete'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (_editing) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _pickAttachments, icon: const Icon(Icons.add), label: const Text('Add attachment(s)')),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _selectedDeleteIds.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline),
              label: Text('Delete selected (${_selectedDeleteIds.length})'),
            ),
            if (_uploads.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uploads.map((file) => Chip(label: Text(file.name))).toList(),
              ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _editing = !_editing),
          icon: Icon(_editing ? Icons.lock : Icons.edit),
          tooltip: _editing ? 'Lock' : 'Edit',
        ),
        FilledButton(
          onPressed: _editing && !_opening ? _save : null,
          child: _opening ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes'),
        ),
      ],
    );
  }
}

enum _AttachmentKind { image, audio, video, text, pdf, document, other }

class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({required this.title, required this.subtitle, required this.body});

  final String title;
  final String subtitle;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0B1320),
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.68), height: 1.4)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioPreviewDialog extends StatefulWidget {
  const _AudioPreviewDialog({required this.title, required this.subtitle, required this.player});

  final String title;
  final String subtitle;
  final AudioPlayer player;

  @override
  State<_AudioPreviewDialog> createState() => _AudioPreviewDialogState();
}

class _AudioPreviewDialogState extends State<_AudioPreviewDialog> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    widget.player.positionStream.listen((value) {
      if (mounted) {
        setState(() => _position = value);
      }
    });
    widget.player.durationStream.listen((value) {
      if (mounted) {
        setState(() => _duration = value ?? Duration.zero);
      }
    });
    widget.player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _playing = state.playing);
      }
    });
    widget.player.play();
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _seekBy(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final maxDuration = _duration.inMilliseconds > 0 ? _duration : const Duration(minutes: 9999);
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > maxDuration
            ? maxDuration
            : target;
    await widget.player.seek(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration.inMilliseconds > 0 ? _duration : const Duration(seconds: 1);
    final progress = (_position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return _PreviewDialog(
      title: widget.title,
      subtitle: widget.subtitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(999)),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 10,
                  children: [
                    Text('${_format(_position)} / ${_format(_duration)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(onPressed: () => _seekBy(-15), child: const Text('-15s')),
                        OutlinedButton(onPressed: () => _seekBy(15), child: const Text('+15s')),
                        FilledButton.tonal(
                          onPressed: () async {
                            if (_playing) {
                              await widget.player.pause();
                            } else {
                              await widget.player.play();
                            }
                          },
                          child: Text(_playing ? 'Pause' : 'Play'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This preview keeps playback controls inside the dialog so it behaves more like the web attachment modal.',
            style: TextStyle(color: Colors.white.withOpacity(0.72), height: 1.4),
          ),
        ],
      ),
    );
  }
}
