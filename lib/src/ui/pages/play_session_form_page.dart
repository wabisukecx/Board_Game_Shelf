import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/app_database.dart';
import '../../data/repo/collection_repository.dart';
import '../../data/repo/play_session_repository.dart';
import '../../i18n/i18n.dart';

class PlaySessionFormPage extends ConsumerStatefulWidget {
  const PlaySessionFormPage({super.key, required this.gameKey});

  final String gameKey;

  @override
  ConsumerState<PlaySessionFormPage> createState() =>
      _PlaySessionFormPageState();
}

class _PlaySessionFormPageState extends ConsumerState<PlaySessionFormPage> {
  late DateTime _playedDate;
  final _playerCount = TextEditingController();
  final _actualPlayingTime = TextEditingController();
  final _notes = TextEditingController();
  final _winnerMemo = TextEditingController();
  final _selectedExpansionKeys = <String>{};
  int? _rating;
  int? _replayDesire;
  double? _perceivedWeight;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _playedDate = DateTime.now();
  }

  @override
  void dispose() {
    _playerCount.dispose();
    _actualPlayingTime.dispose();
    _notes.dispose();
    _winnerMemo.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _playedDate,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _playedDate = picked);
    }
  }

  Future<void> _save() async {
    final t = ref.read(i18nProvider);
    setState(() => _saving = true);
    try {
      await ref
          .read(playSessionRepositoryProvider)
          .recordSession(
            PlaySessionInput(
              gameKey: widget.gameKey,
              playedDate: _formatDate(_playedDate),
              playerCount: _parsePositiveInt(_playerCount.text),
              actualPlayingTime: _parsePositiveInt(_actualPlayingTime.text),
              notes: _nullableText(_notes.text),
              rating: _rating,
              replayDesire: _replayDesire,
              perceivedWeight: _perceivedWeight,
              winnerMemo: _nullableText(_winnerMemo.text),
              expansionGameKeys: _selectedExpansionKeys.toList(),
            ),
          );
      ref.invalidate(playSessionListProvider(widget.gameKey));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.t('play_session.saved'))));
      Navigator.of(context).pop();
    } on PlaySessionValidationException catch (error) {
      if (!mounted) return;
      final key = error.message.toLowerCase().contains('date')
          ? 'play_session.invalidDate'
          : 'play_session.validationError';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.t(key))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('play_session.validationError'))),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('play_session.formTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(t.t('play_session.date')),
            subtitle: Text(_formatDate(_playedDate)),
            onTap: _saving ? null : _pickDate,
          ),
          const SizedBox(height: 8),
          _numberField(_playerCount, t.t('play_session.playerCount')),
          const SizedBox(height: 12),
          _numberField(
            _actualPlayingTime,
            t.t('play_session.actualPlayingTime'),
          ),
          const SizedBox(height: 16),
          _ExpansionCheckboxes(
            gameKey: widget.gameKey,
            selectedKeys: _selectedExpansionKeys,
            onChanged: (gameKey, selected) {
              setState(() {
                if (selected) {
                  _selectedExpansionKeys.add(gameKey);
                } else {
                  _selectedExpansionKeys.remove(gameKey);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          _intDropdown(
            label: t.t('play_session.rating'),
            value: _rating,
            min: AppConstants.playRatingMin,
            max: AppConstants.playRatingMax,
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 12),
          _intDropdown(
            label: t.t('play_session.replayDesire'),
            value: _replayDesire,
            min: AppConstants.playReplayDesireMin,
            max: AppConstants.playReplayDesireMax,
            onChanged: (value) => setState(() => _replayDesire = value),
          ),
          const SizedBox(height: 12),
          _weightDropdown(t),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: t.t('play_session.notes'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _winnerMemo,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: t.t('play_session.winnerMemo'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(t.t('play_session.save')),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _intDropdown({
    required String label,
    required int? value,
    required int min,
    required int max,
    required ValueChanged<int?> onChanged,
  }) {
    final t = ref.watch(i18nProvider);
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(t.t('play_session.unset')),
        ),
        for (var number = min; number <= max; number++)
          DropdownMenuItem<int?>(value: number, child: Text('$number')),
      ],
      onChanged: _saving ? null : onChanged,
    );
  }

  Widget _weightDropdown(I18n t) {
    final values = <double>[];
    for (
      var value = AppConstants.playPerceivedWeightMin;
      value <= AppConstants.playPerceivedWeightMax + 0.001;
      value += AppConstants.playPerceivedWeightStep
    ) {
      values.add(double.parse(value.toStringAsFixed(1)));
    }
    return DropdownButtonFormField<double?>(
      initialValue: _perceivedWeight,
      decoration: InputDecoration(
        labelText: t.t('play_session.perceivedWeight'),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<double?>(
          value: null,
          child: Text(t.t('play_session.unset')),
        ),
        for (final value in values)
          DropdownMenuItem<double?>(
            value: value,
            child: Text(value.toStringAsFixed(1)),
          ),
      ],
      onChanged: _saving
          ? null
          : (value) => setState(() => _perceivedWeight = value),
    );
  }
}

class _ExpansionCheckboxes extends ConsumerWidget {
  const _ExpansionCheckboxes({
    required this.gameKey,
    required this.selectedKeys,
    required this.onChanged,
  });

  final String gameKey;
  final Set<String> selectedKeys;
  final void Function(String gameKey, bool selected) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final database = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<Game>>(
      future: database.findExpansions(gameKey),
      builder: (context, snapshot) {
        final expansions = snapshot.data ?? const <Game>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('play_session.expansionsUsed'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (snapshot.connectionState != ConnectionState.done)
              const LinearProgressIndicator()
            else if (expansions.isEmpty)
              Text(t.t('play_session.expansionsUsedNone'))
            else
              for (final expansion in expansions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: selectedKeys.contains(expansion.gameKey),
                  title: Text(resolveJapaneseDisplayName(expansion)),
                  onChanged: (value) =>
                      onChanged(expansion.gameKey, value ?? false),
                ),
          ],
        );
      },
    );
  }
}

String? _nullableText(String text) {
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _parsePositiveInt(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
