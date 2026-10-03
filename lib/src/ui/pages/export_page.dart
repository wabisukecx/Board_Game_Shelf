import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../export_writer.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _force = false;
  bool _running = false;
  String? _summary;
  List<File> _lastWritten = const [];

  Future<void> _runExport() async {
    final t = ref.read(i18nProvider);
    setState(() {
      _running = true;
      _summary = null;
    });
    try {
      List<File> written = const [];
      final result = await ref
          .read(yamlExporterProvider)
          .exportAll(
            force: _force,
            writeFiles: (files) async {
              written = await const ExportWriter().write(files);
            },
          );
      final directory = await const ExportWriter().exportDirectory();
      if (!mounted) return;
      setState(() {
        _lastWritten = written;
        _summary = [
          t.t('export.exportedCount', {'count': result.files.length}),
          t.t('export.skippedCount', {'count': result.skippedGameKeys.length}),
          t.t('export.savedTo', {'path': directory.path}),
        ].join('\n');
      });
    } catch (_) {
      if (mounted) setState(() => _summary = t.t('export.error'));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _share() async {
    if (_lastWritten.isEmpty) return;
    await Share.shareXFiles([
      for (final file in _lastWritten) XFile(file.path),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('export.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            t.t('export.all'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.t('export.force')),
            subtitle: Text(t.t('export.forceHint')),
            value: _force,
            onChanged: (value) => setState(() => _force = value),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _running ? null : _runExport,
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(t.t('export.run')),
          ),
          if (_summary != null) ...[
            const SizedBox(height: 24),
            Text(_summary!),
            if (_lastWritten.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _share,
                icon: const Icon(Icons.ios_share),
                label: Text(t.t('export.share')),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
