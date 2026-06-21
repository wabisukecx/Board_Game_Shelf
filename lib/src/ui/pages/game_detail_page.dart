import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/app_database.dart';
import '../../data/repo/collection_repository.dart';
import '../../data/repo/information_update_repository.dart';
import '../../data/repo/play_session_repository.dart';
import '../../domain/display_names.dart';
import '../../i18n/i18n.dart';
import '../export_writer.dart';
import '../widgets/expansion_candidate_dialog.dart';
import '../widgets/parent_game_candidate_dialog.dart';
import 'play_session_form_page.dart';

class GameDetailPage extends ConsumerStatefulWidget {
  const GameDetailPage({super.key, required this.gameKey});

  final String gameKey;

  @override
  ConsumerState<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends ConsumerState<GameDetailPage> {
  final _acquiredDate = TextEditingController();
  final _condition = TextEditingController();
  final _storageLocation = TextEditingController();
  final _memo = TextEditingController();
  final _purchasePrice = TextEditingController();
  bool _owned = true;

  bool _loading = true;
  bool _busy = false;
  Game? _game;

  @override
  void initState() {
    super.initState();
    _reload(initial: true);
  }

  @override
  void dispose() {
    _acquiredDate.dispose();
    _condition.dispose();
    _storageLocation.dispose();
    _memo.dispose();
    _purchasePrice.dispose();
    super.dispose();
  }

  Future<void> _reload({bool initial = false}) async {
    final database = ref.read(appDatabaseProvider);
    final game = await database.findGame(widget.gameKey);
    final collection = await database.findCollection(widget.gameKey);
    if (!mounted) return;
    setState(() {
      _game = game;
      _loading = false;
      if (initial && collection != null) {
        _owned = collection.owned;
        _acquiredDate.text = collection.acquiredDate ?? '';
        _condition.text = collection.condition ?? '';
        _storageLocation.text = collection.storageLocation ?? '';
        _memo.text = collection.memo ?? '';
        _purchasePrice.text =
            collection.purchasePrice?.toStringAsFixed(0) ?? '';
      }
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveMetadata() async {
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .updateMetadata(
            gameKey: widget.gameKey,
            owned: _owned,
            acquiredDate: _acquiredDate.text.trim(),
            condition: _condition.text.trim(),
            storageLocation: _storageLocation.text.trim(),
            memo: _memo.text.trim(),
            purchasePrice: double.tryParse(_purchasePrice.text.trim()),
          );
      await _reload();
      _snack(t.t('detail.metadataSaved'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runInfoUpdate() async {
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      final preview = await ref
          .read(informationUpdateRepositoryProvider)
          .preview(widget.gameKey);
      if (!mounted) return;
      switch (preview) {
        case InformationUpdateNoChanges():
          _snack(t.t('detail.infoUpdateNoChanges'));
        case final InformationUpdateChanges changes:
          final confirmed = await _confirmChanges(changes);
          if (confirmed == true) {
            await ref.read(informationUpdateRepositoryProvider).apply(changes);
            await _reload();
            _snack(t.t('detail.infoUpdated'));
          }
      }
    } on InformationUpdateException catch (error) {
      _snack(error.message);
    } catch (_) {
      _snack(t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmChanges(InformationUpdateChanges preview) {
    final t = ref.read(i18nProvider);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('detail.infoUpdateTitle')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final change in preview.changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${change.field}: ${change.displayValue}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.t('detail.infoUpdateApply')),
          ),
        ],
      ),
    );
  }

  Future<void> _exportOne() async {
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      final file = await ref
          .read(yamlExporterProvider)
          .exportOne(widget.gameKey);
      final written = await const ExportWriter().write([file]);
      _snack(t.t('export.savedTo', {'path': written.first.path}));
      await Share.shareXFiles([XFile(written.first.path)]);
    } catch (_) {
      _snack(t.t('export.error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final t = ref.read(i18nProvider);
    final requirement = await ref
        .read(collectionRepositoryProvider)
        .deleteRequirement(widget.gameKey);
    if (!mounted) return;
    if (requirement == DeleteRequirement.confirmationRequired) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.t('detail.deleteConfirmTitle')),
          content: Text(t.t('detail.deleteConfirmBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.t('common.delete')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(collectionRepositoryProvider)
        .deleteGame(widget.gameKey, confirmed: true);
    if (!mounted) return;
    _snack(t.t('detail.deleted'));
    Navigator.of(context).pop();
  }

  Future<void> _registerParent(String parentGameKey) async {
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(bggRegistrationRepositoryProvider)
          .registerBggId(parentGameKey);
      await _reload();
      _snack(t.t('expansion.parentRegistered'));
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailPage(gameKey: result.game.gameKey),
        ),
      );
    } catch (_) {
      _snack(t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseParent() async {
    final game = _game;
    final bggId = game?.bggId;
    if (game == null || bggId == null) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      final repository = ref.read(bggRegistrationRepositoryProvider);
      final candidates = await repository.fetchParentCandidates(bggId);
      if (!mounted) return;
      final selected = await showParentGameCandidateDialog(
        context: context,
        t: t,
        candidates: candidates,
      );
      final parentId = selected?.bggId;
      if (parentId == null || parentId.isEmpty) {
        return;
      }
      await repository.setParentGameKey(game.gameKey, parentId);
      await _reload();
      _snack(t.t('expansion.parentUpdated'));
    } catch (_) {
      _snack(t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkExpansionCandidates() async {
    final bggId = _game?.bggId;
    if (bggId == null) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() => _busy = true);
    try {
      final repository = ref.read(bggRegistrationRepositoryProvider);
      final candidates = await repository.fetchExpansionCandidates(bggId);
      if (!mounted) return;
      await showExpansionCandidateDialog(
        context: context,
        t: t,
        candidates: candidates,
        onRegister: (candidateId) async {
          await repository.registerBggId(candidateId);
        },
      );
      await _reload();
    } catch (_) {
      _snack(t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final localeCode =
        ref.watch(currentLocaleCodeProvider) ?? AppConstants.fallbackLocaleCode;
    final game = _game;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('detail.title')),
        actions: [
          if (game != null)
            IconButton(
              tooltip: t.t('detail.exportOne'),
              icon: const Icon(Icons.ios_share),
              onPressed: _busy ? null : _exportOne,
            ),
          if (game != null)
            IconButton(
              tooltip: t.t('detail.delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : game == null
          ? Center(child: Text(t.t('detail.notFound')))
          : _buildBody(context, t, game, localeCode),
    );
  }

  Widget _buildBody(
    BuildContext context,
    I18n t,
    Game game,
    String localeCode,
  ) {
    final isBgg = game.bggId != null && game.localId == null;
    final badge = resolveBestPlayersBadge(game.suggestedPlayerVotes);
    final displayName = resolveDisplayName(
      game,
      localeCode,
      fallback: t.t('game.nameUnknown'),
    );
    final subtitle = resolveSubtitle(game, localeCode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (game.thumbnailUrl != null && game.thumbnailUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.network(
                  game.thumbnailUrl!,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (subtitle != null) Text(subtitle),
                  if (game.localId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(label: Text(t.t('detail.localRecord'))),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _section(context, t.t('detail.bggInfo')),
        _infoRow(t.t('detail.year'), game.yearPublished),
        _infoRow(
          t.t('detail.players'),
          (game.publisherMinPlayers != null && game.publisherMaxPlayers != null)
              ? '${game.publisherMinPlayers}-${game.publisherMaxPlayers}'
              : null,
        ),
        _infoRow(
          t.t('detail.playingTime'),
          game.playingTime == null ? null : '${game.playingTime}',
        ),
        _infoRow(t.t('detail.weight'), game.weight?.toStringAsFixed(2)),
        _infoRow(t.t('detail.rating'), game.averageRating),
        _infoRow(t.t('detail.bestPlayers'), badge),
        _infoRow(
          t.t('detail.mechanics'),
          game.mechanics.isEmpty ? null : game.mechanics.join(', '),
        ),
        _infoRow(
          t.t('detail.categories'),
          game.categories.isEmpty ? null : game.categories.join(', '),
        ),
        _infoRow(
          t.t('detail.designers'),
          game.designers.isEmpty ? null : game.designers.join(', '),
        ),
        const SizedBox(height: 12),
        _ExpansionInfoSection(
          game: game,
          busy: _busy,
          onOpenGame: (gameKey) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameDetailPage(gameKey: gameKey),
            ),
          ),
          onRegisterParent: _registerParent,
          onChooseParent: _chooseParent,
        ),
        _PlaySessionSection(game: game),
        _AnalysisSection(game: game),
        if (game.updateHistory.entries.isNotEmpty) ...[
          const SizedBox(height: 8),
          _section(context, t.t('detail.updateHistory')),
          for (final entry in game.updateHistory.entries)
            Text(
              '${entry.date}: '
              '${[if (entry.averageRating != null) 'rating ${entry.averageRating}', if (entry.weight != null) 'weight ${entry.weight}', for (final rank in entry.ranks) '${rank.type} #${rank.rank}'].join(', ')}',
            ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            if (isBgg)
              OutlinedButton.icon(
                onPressed: _busy ? null : _runInfoUpdate,
                icon: const Icon(Icons.refresh),
                label: Text(t.t('detail.infoUpdate')),
              ),
            if (isBgg)
              OutlinedButton.icon(
                onPressed: _busy ? null : _checkExpansionCandidates,
                icon: const Icon(Icons.playlist_add),
                label: Text(t.t('expansion.checkCandidates')),
              ),
          ],
        ),
        const Divider(height: 32),
        _section(context, t.t('detail.metadata')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t.t('detail.owned')),
          value: _owned,
          onChanged: (value) => setState(() => _owned = value),
        ),
        _metaField(_acquiredDate, t.t('detail.acquiredDate')),
        _metaField(_condition, t.t('detail.condition')),
        _metaField(_storageLocation, t.t('detail.storageLocation')),
        _metaField(_memo, t.t('detail.memo'), maxLines: 3),
        _metaField(
          _purchasePrice,
          t.t('detail.purchasePrice'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _saveMetadata,
          icon: const Icon(Icons.save),
          label: Text(t.t('detail.saveMetadata')),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _metaField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _AnalysisSection extends ConsumerWidget {
  const _AnalysisSection({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    if (game.gameKind == AppConstants.gameKindExpansion) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('analysis.title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(t.t('analysis.expansionNotice')),
            ],
          ),
        ),
      );
    }
    final analyzerAsync = ref.watch(learningCurveAnalyzerProvider);
    return analyzerAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => const SizedBox.shrink(),
      data: (analyzer) {
        final analysis = analyzer.analyze(game);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('analysis.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('analysis.narrativeLearningCurve', {
                    'type': t.t(
                      'learning_curve.types.${analysis.learningCurveType}',
                    ),
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('analysis.narrativeMasteryTime', {
                    'masteryTime': t.t('mastery_time.${analysis.masteryTime}'),
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  t.t('analysis.narrativeDepthReplay', {
                    'depth': t.t(
                      'analysis.depth.${analysis.strategicDepthLabel}',
                    ),
                    'replay': t.t(
                      'replayability.${analysis.replayabilityLabel}',
                    ),
                  }),
                ),
                const SizedBox(height: 8),
                _MetricBar(
                  label: t.t('analysis.initialBarrier'),
                  value: analysis.initialBarrier,
                ),
                _MetricBar(
                  label: t.t('analysis.strategicDepth'),
                  value: analysis.strategicDepth,
                ),
                _MetricBar(
                  label: t.t('analysis.replayability'),
                  value: analysis.replayability,
                ),
                _MetricBar(
                  label: t.t('analysis.decisionPoints'),
                  value: analysis.decisionPoints,
                ),
                _MetricBar(
                  label: t.t('analysis.interactionComplexity'),
                  value: analysis.interactionComplexity,
                ),
                _MetricBar(
                  label: t.t('analysis.rulesComplexity'),
                  value: analysis.rulesComplexity,
                ),
                _MetricBar(
                  label: t.t('analysis.mechanicComplexity'),
                  value: analysis.mechanicComplexity,
                ),
                _MetricBar(
                  label: t.t('analysis.soloSuitability'),
                  value: analysis.soloSuitability,
                ),
                _MetricBar(
                  label: t.t('analysis.playerScalability'),
                  value: analysis.playerScalability,
                ),
                _MetricBar(
                  label: t.t('analysis.luckDependence'),
                  value: analysis.luckDependence,
                ),
                const SizedBox(height: 8),
                Text(
                  analysis.playerTypes
                      .map((type) => t.t('player_types.$type'))
                      .join(' / '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaySessionSection extends ConsumerWidget {
  const _PlaySessionSection({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    if (game.gameKind == AppConstants.gameKindExpansion) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('detail.playSessionsTitle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(t.t('detail.playSessionExpansionNotice')),
            ],
          ),
        ),
      );
    }

    final sessionsAsync = ref.watch(playSessionListProvider(game.gameKey));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('detail.playSessionsTitle'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            sessionsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(t.t('search.errorGeneric')),
              data: (records) {
                if (records.isEmpty) {
                  return Text(t.t('detail.noPlaySessions'));
                }
                return FutureBuilder<Map<String, String>>(
                  future: _loadExpansionNames(ref, records),
                  builder: (context, snapshot) {
                    final expansionNames =
                        snapshot.data ?? const <String, String>{};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('detail.playSessionCount', {
                            'count': records.length,
                          }),
                        ),
                        const SizedBox(height: 4),
                        for (final record in records)
                          _PlaySessionTile(
                            record: record,
                            expansionNames: expansionNames,
                            onDelete: () => _deleteSession(
                              context: context,
                              ref: ref,
                              record: record,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PlaySessionFormPage(gameKey: game.gameKey),
                    ),
                  );
                  ref.invalidate(playSessionListProvider(game.gameKey));
                },
                icon: const Icon(Icons.add),
                label: Text(t.t('detail.addPlaySession')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>> _loadExpansionNames(
    WidgetRef ref,
    List<PlaySessionRecord> records,
  ) async {
    final database = ref.read(appDatabaseProvider);
    final keys = <String>{
      for (final record in records) ...record.expansionGameKeys,
    };
    final entries = await Future.wait(
      keys.map((key) async {
        final game = await database.findGame(key);
        final t = ref.read(i18nProvider);
        final localeCode =
            ref.read(currentLocaleCodeProvider) ??
            AppConstants.fallbackLocaleCode;
        return MapEntry(
          key,
          game == null
              ? key
              : resolveDisplayName(
                  game,
                  localeCode,
                  fallback: t.t('game.nameUnknown'),
                ),
        );
      }),
    );
    return Map<String, String>.fromEntries(entries);
  }

  Future<void> _deleteSession({
    required BuildContext context,
    required WidgetRef ref,
    required PlaySessionRecord record,
  }) async {
    final t = ref.read(i18nProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('play_session.deleteConfirmTitle')),
        content: Text(t.t('play_session.deleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.t('common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(playSessionRepositoryProvider).deleteSession(record.id);
    ref.invalidate(playSessionListProvider(game.gameKey));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.t('play_session.deleted'))));
  }
}

class _PlaySessionTile extends ConsumerWidget {
  const _PlaySessionTile({
    required this.record,
    required this.expansionNames,
    required this.onDelete,
  });

  final PlaySessionRecord record;
  final Map<String, String> expansionNames;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final detailLines = <String>[
      _joinParts([
        if (record.playerCount != null)
          '${t.t('play_session.playerCount')}: ${record.playerCount}',
        if (record.actualPlayingTime != null)
          '${t.t('play_session.actualPlayingTime')}: ${record.actualPlayingTime}',
      ]),
      _joinParts([
        if (record.rating != null)
          '${t.t('play_session.rating')}: ${record.rating}',
        if (record.replayDesire != null)
          '${t.t('play_session.replayDesire')}: ${record.replayDesire}',
        if (record.perceivedWeight != null)
          '${t.t('play_session.perceivedWeight')}: ${record.perceivedWeight!.toStringAsFixed(1)}',
      ]),
      if (record.expansionGameKeys.isNotEmpty)
        '${t.t('play_session.expansionsUsed')}: '
            '${record.expansionGameKeys.map((key) => expansionNames[key] ?? key).join(', ')}',
      if (record.notes != null && record.notes!.isNotEmpty) record.notes!,
      if (record.winnerMemo != null && record.winnerMemo!.isNotEmpty)
        '${t.t('play_session.winnerMemo')}: ${record.winnerMemo}',
    ].where((line) => line.isNotEmpty).toList();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(record.playedDate),
      subtitle: detailLines.isEmpty ? null : Text(detailLines.join('\n')),
      trailing: IconButton(
        tooltip: t.t('common.delete'),
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }

  String _joinParts(List<String> values) {
    return values.where((value) => value.isNotEmpty).join(' / ');
  }
}

class _ExpansionInfoSection extends ConsumerWidget {
  const _ExpansionInfoSection({
    required this.game,
    required this.busy,
    required this.onOpenGame,
    required this.onRegisterParent,
    required this.onChooseParent,
  });

  final Game game;
  final bool busy;
  final ValueChanged<String> onOpenGame;
  final ValueChanged<String> onRegisterParent;
  final VoidCallback onChooseParent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final localeCode =
        ref.watch(currentLocaleCodeProvider) ?? AppConstants.fallbackLocaleCode;
    final database = ref.watch(appDatabaseProvider);
    if (game.gameKind == AppConstants.gameKindExpansion) {
      final parentKey = game.parentGameKey;
      if (parentKey == null || parentKey.isEmpty) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('expansion.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(t.t('expansion.parentUndetermined')),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : onChooseParent,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(t.t('expansion.changeParent')),
                ),
              ],
            ),
          ),
        );
      }
      return FutureBuilder<Game?>(
        future: database.findGame(parentKey),
        builder: (context, snapshot) {
          final parent = snapshot.data;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('expansion.title'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    parent == null
                        ? t.t('expansion.parentMissing', {'id': parentKey})
                        : t.t('expansion.parent', {
                            'name': resolveDisplayName(
                              parent,
                              localeCode,
                              fallback: t.t('game.nameUnknown'),
                            ),
                          }),
                  ),
                  const SizedBox(height: 8),
                  if (parent == null)
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => onRegisterParent(parentKey),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(t.t('expansion.registerParent')),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onOpenGame(parent.gameKey),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(t.t('expansion.openParent')),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onChooseParent,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(t.t('expansion.changeParent')),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return FutureBuilder<List<Game>>(
      future: database.findExpansions(game.gameKey),
      builder: (context, snapshot) {
        final expansions = snapshot.data ?? const <Game>[];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('expansion.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (expansions.isEmpty)
                  Text(t.t('expansion.noneRegistered'))
                else ...[
                  Text(
                    t.t('expansion.registeredCount', {
                      'count': expansions.length,
                    }),
                  ),
                  const SizedBox(height: 4),
                  for (final expansion in expansions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        resolveDisplayName(
                          expansion,
                          localeCode,
                          fallback: t.t('game.nameUnknown'),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onOpenGame(expansion.gameKey),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final fraction = (value / 5).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(value.toStringAsFixed(2), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
