import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/bgg/bgg_api_client.dart';
import '../../data/bgg/bgg_xml_parser.dart';
import '../../data/repo/bgg_registration_repository.dart';
import '../../core/constants.dart';
import 'game_detail_page.dart';
import 'local_game_form_page.dart';
import 'settings_page.dart';

class SearchRegistrationPage extends ConsumerStatefulWidget {
  const SearchRegistrationPage({
    super.key,
    this.pendingJan,
    this.barcodeSource = AppConstants.barcodeSourceManual,
    this.initialQuery,
    this.autoSearch = false,
  });

  final String? pendingJan;
  final String barcodeSource;
  final String? initialQuery;
  final bool autoSearch;

  @override
  ConsumerState<SearchRegistrationPage> createState() =>
      _SearchRegistrationPageState();
}

class _SearchRegistrationPageState
    extends ConsumerState<SearchRegistrationPage> {
  final _queryController = TextEditingController();
  bool _exact = false;
  bool _searching = false;
  String? _registeringId;
  List<BggSearchResult>? _results;
  String? _message;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery;
    if (initialQuery != null && initialQuery.trim().isNotEmpty) {
      _queryController.text = initialQuery.trim();
      if (widget.autoSearch) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
      }
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final t = ref.read(i18nProvider);
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() {
      _searching = true;
      _message = null;
      _results = null;
    });
    try {
      final results = await ref
          .read(bggRegistrationRepositoryProvider)
          .search(query, exact: _exact);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _message = t.t('search.noResults');
        }
      });
    } on BggTokenRequiredException {
      if (!mounted) return;
      await _promptToken();
    } on BggApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _message =
            '${t.t('search.errorGeneric')} (${error.statusCode ?? '-'})',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _promptToken() async {
    final t = ref.read(i18nProvider);
    final goSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.t('search.tokenRequired')),
        content: Text(t.t('settings.tokenGuide')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.t('search.tokenRequiredAction')),
          ),
        ],
      ),
    );
    if (goSettings == true && mounted) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
    }
  }

  Future<void> _register(BggSearchResult result) async {
    final t = ref.read(i18nProvider);
    setState(() => _registeringId = result.bggId);
    try {
      final outcome = await ref
          .read(bggRegistrationRepositoryProvider)
          .registerBggId(result.bggId);
      if (!mounted) return;
      switch (outcome) {
        case BggRegistrationCreated(:final game, :final expansionCandidates):
          await _learnPendingJan(game.gameKey);
          if (expansionCandidates.isNotEmpty) {
            await _showExpansionCandidates(expansionCandidates);
          }
          _snack(t.t('search.registered'));
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => GameDetailPage(gameKey: game.gameKey),
            ),
          );
        case BggRegistrationAlreadyExists(:final game):
          await _learnPendingJan(game.gameKey);
          _snack(t.t('search.alreadyExists'));
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GameDetailPage(gameKey: game.gameKey),
            ),
          );
      }
    } on BggTokenRequiredException {
      if (mounted) await _promptToken();
    } on InvalidBggGameException {
      if (mounted) _snack(t.t('search.invalidGame'));
    } on BggApiException catch (error) {
      if (mounted) {
        _snack('${t.t('search.errorGeneric')} (${error.statusCode ?? '-'})');
      }
    } catch (_) {
      if (mounted) _snack(t.t('search.errorGeneric'));
    } finally {
      if (mounted) setState(() => _registeringId = null);
    }
  }

  Future<void> _showExpansionCandidates(List<NamedBggValue> candidates) {
    final t = ref.read(i18nProvider);
    final remaining = [...candidates];
    String? registeringId;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.t('expansion.candidatesTitle')),
              content: SizedBox(
                width: double.maxFinite,
                child: remaining.isEmpty
                    ? Text(t.t('expansion.candidatesEmpty'))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: remaining.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final candidate = remaining[index];
                          final candidateId = candidate.bggId ?? '';
                          final registering = registeringId == candidateId;
                          return ListTile(
                            title: Text(candidate.name),
                            subtitle: Text('BGG ID: $candidateId'),
                            trailing: registering
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : TextButton(
                                    onPressed:
                                        registeringId != null ||
                                            candidateId.isEmpty
                                        ? null
                                        : () async {
                                            setDialogState(
                                              () => registeringId = candidateId,
                                            );
                                            try {
                                              await ref
                                                  .read(
                                                    bggRegistrationRepositoryProvider,
                                                  )
                                                  .registerBggId(candidateId);
                                              setDialogState(() {
                                                remaining.removeAt(index);
                                                registeringId = null;
                                              });
                                            } catch (_) {
                                              setDialogState(
                                                () => registeringId = null,
                                              );
                                              if (mounted) {
                                                _snack(
                                                  t.t('search.errorGeneric'),
                                                );
                                              }
                                            }
                                          },
                                    child: Text(t.t('expansion.register')),
                                  ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: registeringId == null
                      ? () => Navigator.of(dialogContext).pop()
                      : null,
                  child: Text(t.t('expansion.closeCandidates')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _learnPendingJan(String gameKey) async {
    final pendingJan = widget.pendingJan;
    if (pendingJan == null) {
      return;
    }
    await ref
        .read(barcodeMapRepositoryProvider)
        .learn(
          rawJan: pendingJan,
          gameKey: gameKey,
          source: widget.barcodeSource,
        );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final results = _results;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('search.title'))),
      body: Column(
        children: [
          if (widget.pendingJan != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_2),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.t('jan.pending', {'jan': widget.pendingJan!}),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    labelText: t.t('search.queryLabel'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _exact,
                      onChanged: (value) =>
                          setState(() => _exact = value ?? false),
                    ),
                    Text(t.t('search.exact')),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _searching ? null : _runSearch,
                      icon: _searching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(t.t('search.run')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_message!),
                  if (widget.pendingJan != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: Text(t.t('scan.manualWithJan')),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => LocalGameFormPage(
                            pendingJan: widget.pendingJan,
                            barcodeSource: widget.barcodeSource,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (results != null && results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.t('search.resultCount', {'count': results.length}),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: results == null
                ? const SizedBox.shrink()
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final registering = _registeringId == result.bggId;
                      return ListTile(
                        title: Text(result.name),
                        subtitle: result.yearPublished == null
                            ? null
                            : Text(
                                '${t.t('search.year')}: ${result.yearPublished}',
                              ),
                        trailing: registering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_circle_outline),
                        onTap: _registeringId == null
                            ? () => _register(result)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
