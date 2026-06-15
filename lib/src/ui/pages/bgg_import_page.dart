import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/bgg/bgg_api_client.dart';
import '../../data/repo/bgg_collection_importer.dart';
import '../../data/repo/bgg_collection_repository.dart';
import '../../data/repo/bgg_registration_repository.dart';
import 'settings_page.dart';

class BggImportPage extends ConsumerStatefulWidget {
  const BggImportPage({super.key});

  @override
  ConsumerState<BggImportPage> createState() => _BggImportPageState();
}

class _BggImportPageState extends ConsumerState<BggImportPage> {
  bool _loadingSettings = true;
  bool _fetching = false;
  bool _importing = false;
  bool _cancelRequested = false;
  String? _username;
  bool _tokenSet = false;
  String? _message;
  BggImportPreview? _preview;
  BggImportProgress? _progress;
  BggImportSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(secureSettingsProvider);
    String? username;
    String? token;
    try {
      username = await settings.readBggUsername();
      token = await settings.readToken();
    } catch (_) {
      // Some test/desktop environments do not provide secure storage.
    }
    if (!mounted) return;
    setState(() {
      _username = username?.trim();
      _tokenSet = token != null && token.isNotEmpty;
      _loadingSettings = false;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
    await _loadSettings();
  }

  Future<void> _fetchCollection() async {
    final username = _username;
    if (username == null || username.isEmpty || _fetching) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() {
      _fetching = true;
      _message = t.t('bggImport.fetching');
      _preview = null;
      _summary = null;
      _progress = null;
    });
    try {
      final items = await ref
          .read(bggCollectionRepositoryProvider)
          .fetchOwned(username);
      final preview = await ref
          .read(bggCollectionImporterProvider)
          .preview(items);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _message = preview.totalCount == 0 ? t.t('bggImport.empty') : null;
      });
    } on BggCollectionUsernameRequiredException {
      if (mounted) setState(() => _message = t.t('bggImport.usernameMissing'));
    } on BggApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.statusCode == 202
            ? t.t('bggImport.collectionQueued')
            : t.t('bggImport.fetchFailed');
      });
    } catch (_) {
      if (mounted) setState(() => _message = t.t('bggImport.fetchFailed'));
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  Future<void> _startImport() async {
    final preview = _preview;
    if (preview == null || preview.newCount == 0 || _importing) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() {
      _importing = true;
      _cancelRequested = false;
      _summary = null;
      _message = null;
      _progress = BggImportProgress(done: 0, total: preview.newCount);
    });
    try {
      final summary = await ref
          .read(bggCollectionImporterProvider)
          .importItems(
            preview,
            shouldCancel: () => _cancelRequested,
            onProgress: (progress) {
              if (mounted) setState(() => _progress = progress);
            },
          );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _message = summary.stoppedByFailureLimit
            ? t.t('bggImport.stoppedByFailures')
            : summary.canceled
            ? t.t('bggImport.canceled')
            : t.t('bggImport.completed');
      });
      ref.invalidate(collectionListProvider);
      ref.invalidate(analyticsProvider);
    } on BggTokenRequiredException {
      if (mounted) setState(() => _message = t.t('bggImport.tokenMissing'));
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final username = _username;
    final settingsMissing = username == null || username.isEmpty || !_tokenSet;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('bggImport.title'))),
      body: _loadingSettings
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(
                      settingsMissing
                          ? Icons.error_outline
                          : Icons.check_circle,
                    ),
                    title: Text(t.t('bggImport.settingsTitle')),
                    subtitle: Text(
                      username == null || username.isEmpty
                          ? t.t('bggImport.usernameMissing')
                          : _tokenSet
                          ? t.t('bggImport.usernameReady', {
                              'username': username,
                            })
                          : t.t('bggImport.tokenMissing'),
                    ),
                    trailing: OutlinedButton(
                      onPressed: _openSettings,
                      child: Text(t.t('bggImport.openSettings')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: settingsMissing || _fetching || _importing
                      ? null
                      : _fetchCollection,
                  icon: _fetching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(t.t('bggImport.fetch')),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!),
                ],
                if (_preview != null) ...[
                  const SizedBox(height: 16),
                  _PreviewCard(preview: _preview!),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _preview!.newCount == 0 || _importing
                        ? null
                        : _startImport,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(t.t('bggImport.start')),
                  ),
                ],
                if (_importing || _progress != null) ...[
                  const SizedBox(height: 16),
                  _ProgressCard(
                    progress: _progress,
                    onCancel: _importing
                        ? () => setState(() => _cancelRequested = true)
                        : null,
                  ),
                ],
                if (_summary != null) ...[
                  const SizedBox(height: 16),
                  _SummaryCard(summary: _summary!),
                ],
              ],
            ),
    );
  }
}

class _PreviewCard extends ConsumerWidget {
  const _PreviewCard({required this.preview});

  final BggImportPreview preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('bggImport.preview'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.t('bggImport.previewCounts', {
                'total': preview.totalCount,
                'new': preview.newCount,
                'existing': preview.existingCount,
              }),
            ),
            const SizedBox(height: 8),
            for (final entry in preview.entries.take(20))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.item.displayTitle),
                subtitle: Text(entry.item.objectId),
                trailing: entry.alreadyRegistered
                    ? Text(t.t('bggImport.existing'))
                    : Text(t.t('bggImport.newItem')),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.progress, required this.onCancel});

  final BggImportProgress? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final value = progress;
    final done = value?.done ?? 0;
    final total = value?.total ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('bggImport.progress', {'done': done, 'total': total}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: total == 0 ? null : done / total),
            if (value?.currentTitle != null) ...[
              const SizedBox(height: 8),
              Text(t.t('bggImport.current', {'title': value!.currentTitle!})),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(t.t('common.cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.summary});

  final BggImportSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('bggImport.summary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.t('bggImport.summaryCounts', {
                'registered': summary.registered,
                'skipped': summary.skipped,
                'failed': summary.failed,
              }),
            ),
            if (summary.failures.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final failure in summary.failures.take(10))
                Text('${failure.objectId}: ${failure.title}'),
            ],
          ],
        ),
      ),
    );
  }
}
