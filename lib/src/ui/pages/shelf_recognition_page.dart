import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/app_database.dart';
import '../../data/repo/box_recognition_repository.dart';
import '../../data/repo/shelf_recognition_repository.dart';
import 'local_game_form_page.dart';
import 'search_registration_page.dart';
import 'settings_page.dart';

class ShelfRecognitionPage extends ConsumerStatefulWidget {
  const ShelfRecognitionPage({super.key});

  @override
  ConsumerState<ShelfRecognitionPage> createState() =>
      _ShelfRecognitionPageState();
}

class _ShelfRecognitionPageState extends ConsumerState<ShelfRecognitionPage> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _recognizing = false;
  bool _processing = false;
  ShelfRecognitionResult? _result;
  String? _message;
  List<_ShelfReviewItem> _items = [];

  bool get _androidCameraSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _image = picked;
      _result = null;
      _message = null;
      _items = [];
    });
  }

  Future<void> _recognize() async {
    final image = _image;
    if (image == null || _recognizing) {
      return;
    }
    final t = ref.read(i18nProvider);
    setState(() {
      _recognizing = true;
      _message = null;
      _result = null;
      _items = [];
    });
    try {
      final result = await ref
          .read(shelfRecognitionRepositoryProvider)
          .recognizeShelf(await image.readAsBytes());
      final duplicateTitles = await _loadDuplicateTitles();
      if (!mounted) return;
      setState(() {
        _result = result;
        _message = _messageFor(t, result.status);
        _items = result.detections
            .map(
              (candidate) => _ShelfReviewItem(
                candidate: candidate,
                selected: _isConfident(candidate),
                duplicatePossible: _isDuplicate(candidate, duplicateTitles),
              ),
            )
            .toList(growable: false);
      });
    } finally {
      if (mounted) {
        setState(() => _recognizing = false);
      }
    }
  }

  Future<Set<String>> _loadDuplicateTitles() async {
    final games = await ref
        .read(appDatabaseProvider)
        .select(ref.read(appDatabaseProvider).games)
        .get();
    final titles = <String>{};
    for (final game in games) {
      titles.addAll(_gameTitles(game).map(_normalizeTitle));
    }
    titles.remove('');
    return titles;
  }

  List<String> _gameTitles(Game game) {
    return [
      game.name,
      game.japaneseName,
      game.names.primary,
      game.names.japanese,
      game.names.english,
      ...game.names.alternates,
    ].whereType<String>().toList(growable: false);
  }

  bool _isDuplicate(
    BoxRecognitionCandidate candidate,
    Set<String> duplicateTitles,
  ) {
    final titles = [
      candidate.title,
      candidate.japaneseTitle,
    ].whereType<String>().map(_normalizeTitle);
    return titles.any(duplicateTitles.contains);
  }

  bool _isConfident(BoxRecognitionCandidate candidate) {
    return candidate.confidence >= AppConstants.visionConfidenceThreshold;
  }

  String? _messageFor(dynamic t, ShelfRecognitionStatus status) {
    return switch (status) {
      ShelfRecognitionStatus.detections => null,
      ShelfRecognitionStatus.lowConfidence => t.t('shelf.lowConfidence'),
      ShelfRecognitionStatus.empty => t.t('shelf.empty'),
      ShelfRecognitionStatus.missingApiKey => t.t('shelf.missingApiKey'),
      ShelfRecognitionStatus.noNetwork => t.t('shelf.noNetwork'),
      ShelfRecognitionStatus.failed => t.t('shelf.failed'),
    };
  }

  Future<void> _processSelected() async {
    if (_processing) {
      return;
    }
    setState(() => _processing = true);
    try {
      for (var index = 0; index < _items.length; index++) {
        if (!_canProcess(_items[index])) {
          continue;
        }
        await _openSearchFor(index);
        if (!mounted) {
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  bool _canProcess(_ShelfReviewItem item) {
    return item.selected && item.status == ShelfReviewStatus.unprocessed;
  }

  Future<void> _openSearchFor(int index) async {
    final item = _items[index];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchRegistrationPage(
          initialQuery: searchQueryForCandidate(item.candidate),
          autoSearch: true,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _items[index] = item.copyWith(status: ShelfReviewStatus.registered);
    });
    ref.invalidate(collectionListProvider);
  }

  void _skip(int index) {
    final item = _items[index];
    setState(() {
      _items[index] = item.copyWith(
        status: ShelfReviewStatus.skipped,
        selected: false,
      );
    });
  }

  void _toggle(int index, bool? value) {
    final item = _items[index];
    setState(() {
      _items[index] = item.copyWith(selected: value ?? false);
    });
  }

  void _openManualAdd() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LocalGameFormPage()));
  }

  void _openManualSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SearchRegistrationPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    final result = _result;
    final selectedCount = _items.where(_canProcess).length;
    final registeredCount = _items
        .where((item) => item.status == ShelfReviewStatus.registered)
        .length;
    final skippedCount = _items
        .where((item) => item.status == ShelfReviewStatus.skipped)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('shelf.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _androidCameraSupported
                      ? () => _pick(ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(t.t('shelf.takePhoto')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t.t('shelf.pickGallery')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _preview(t),
          const SizedBox(height: 16),
          Text(t.t('shelf.sendNotice')),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _image == null || _recognizing ? null : _recognize,
            icon: _recognizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(t.t('shelf.recognize')),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _openManualSearch,
                  icon: const Icon(Icons.search),
                  label: Text(t.t('shelf.manualSearch')),
                ),
                OutlinedButton.icon(
                  onPressed: _openManualAdd,
                  icon: const Icon(Icons.edit_note),
                  label: Text(t.t('shelf.manualAdd')),
                ),
                if (result?.status == ShelfRecognitionStatus.missingApiKey)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                    label: Text(t.t('shelf.openSettings')),
                  ),
              ],
            ),
          ],
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.t('shelf.reviewTitle', {'count': _items.length}),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  t.t('shelf.summary', {
                    'registered': registeredCount,
                    'skipped': skippedCount,
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _items.length; index++)
              _ShelfReviewTile(
                item: _items[index],
                onChanged: (value) => _toggle(index, value),
                onSearch: () => _openSearchFor(index),
                onSkip: () => _skip(index),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: selectedCount == 0 || _processing
                  ? null
                  : _processSelected,
              icon: _processing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check),
              label: Text(
                t.t('shelf.processSelected', {'count': selectedCount}),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _preview(dynamic t) {
    final image = _image;
    if (image == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.view_module_outlined, size: 48),
              const SizedBox(height: 8),
              Text(t.t('shelf.noImage')),
            ],
          ),
        ),
      );
    }
    if (kIsWeb) {
      return Image.network(image.path, height: 280, fit: BoxFit.contain);
    }
    return Image.file(File(image.path), height: 280, fit: BoxFit.contain);
  }
}

class _ShelfReviewTile extends ConsumerWidget {
  const _ShelfReviewTile({
    required this.item,
    required this.onChanged,
    required this.onSearch,
    required this.onSkip,
  });

  final _ShelfReviewItem item;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onSearch;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(i18nProvider);
    final candidate = item.candidate;
    final lowConfidence =
        candidate.confidence < AppConstants.visionConfidenceThreshold;
    final processed = item.status != ShelfReviewStatus.unprocessed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: item.selected,
              onChanged: processed ? null : onChanged,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(candidate.title),
              subtitle: Text(_subtitle(t, candidate)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (lowConfidence)
                    Chip(label: Text(t.t('shelf.lowConfidenceChip'))),
                  if (item.duplicatePossible)
                    Chip(label: Text(t.t('shelf.duplicateChip'))),
                  Chip(label: Text(_statusLabel(t, item.status))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: processed ? null : onSearch,
                    icon: const Icon(Icons.search),
                    label: Text(t.t('shelf.searchOne')),
                  ),
                  TextButton.icon(
                    onPressed: processed ? null : onSkip,
                    icon: const Icon(Icons.skip_next),
                    label: Text(t.t('shelf.skip')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(dynamic t, BoxRecognitionCandidate candidate) {
    final parts = <String>[
      t.t('shelf.confidence', {'value': (candidate.confidence * 100).round()}),
      if (candidate.japaneseTitle != null) candidate.japaneseTitle!,
      if (candidate.publisher != null) candidate.publisher!,
      if (candidate.positionHint != null)
        t.t('shelf.position', {'value': candidate.positionHint!}),
    ];
    return parts.join(' / ');
  }

  String _statusLabel(dynamic t, ShelfReviewStatus status) {
    return switch (status) {
      ShelfReviewStatus.unprocessed => t.t('shelf.statusUnprocessed'),
      ShelfReviewStatus.registered => t.t('shelf.statusRegistered'),
      ShelfReviewStatus.skipped => t.t('shelf.statusSkipped'),
    };
  }
}

class _ShelfReviewItem {
  const _ShelfReviewItem({
    required this.candidate,
    required this.selected,
    required this.duplicatePossible,
    this.status = ShelfReviewStatus.unprocessed,
  });

  final BoxRecognitionCandidate candidate;
  final bool selected;
  final bool duplicatePossible;
  final ShelfReviewStatus status;

  _ShelfReviewItem copyWith({
    bool? selected,
    bool? duplicatePossible,
    ShelfReviewStatus? status,
  }) {
    return _ShelfReviewItem(
      candidate: candidate,
      selected: selected ?? this.selected,
      duplicatePossible: duplicatePossible ?? this.duplicatePossible,
      status: status ?? this.status,
    );
  }
}

enum ShelfReviewStatus { unprocessed, registered, skipped }

String _normalizeTitle(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
