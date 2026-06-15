import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/repo/local_game_repository.dart';
import 'game_detail_page.dart';

class LocalGameFormPage extends ConsumerStatefulWidget {
  const LocalGameFormPage({
    super.key,
    this.pendingJan,
    this.barcodeSource = AppConstants.barcodeSourceManual,
  });

  final String? pendingJan;
  final String barcodeSource;

  @override
  ConsumerState<LocalGameFormPage> createState() => _LocalGameFormPageState();
}

class _LocalGameFormPageState extends ConsumerState<LocalGameFormPage> {
  final _title = TextEditingController();
  final _minPlayers = TextEditingController();
  final _maxPlayers = TextEditingController();
  final _playingTime = TextEditingController();
  final _mechanics = TextEditingController();
  final _categories = TextEditingController();

  bool _saving = false;
  String? _titleError;

  @override
  void dispose() {
    _title.dispose();
    _minPlayers.dispose();
    _maxPlayers.dispose();
    _playingTime.dispose();
    _mechanics.dispose();
    _categories.dispose();
    super.dispose();
  }

  List<String> _splitList(String value) {
    return [
      for (final part in value.split(RegExp(r'[,\u3001]')))
        if (part.trim().isNotEmpty) part.trim(),
    ];
  }

  Future<void> _save() async {
    final t = ref.read(i18nProvider);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = t.t('manual.titleRequired'));
      return;
    }
    setState(() {
      _titleError = null;
      _saving = true;
    });
    try {
      final result = await ref
          .read(localGameRepositoryProvider)
          .register(
            title: title,
            publisherMinPlayers: int.tryParse(_minPlayers.text.trim()),
            publisherMaxPlayers: int.tryParse(_maxPlayers.text.trim()),
            playingTime: int.tryParse(_playingTime.text.trim()),
            mechanics: _splitList(_mechanics.text),
            categories: _splitList(_categories.text),
          );
      await _learnPendingJan(result.game.gameKey);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.t('manual.registered'))));
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailPage(gameKey: result.game.gameKey),
        ),
      );
    } on InvalidLocalGameException {
      if (mounted) setState(() => _titleError = t.t('manual.titleRequired'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.t('manual.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (widget.pendingJan != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_2),
              title: Text(t.t('jan.pending', {'jan': widget.pendingJan!})),
              subtitle: Text(t.t('manual.pendingJanHint')),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: t.t('manual.titleLabel'),
              border: const OutlineInputBorder(),
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPlayers,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.t('manual.minPlayers'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPlayers,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.t('manual.maxPlayers'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _playingTime,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: t.t('manual.playingTime'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _mechanics,
            decoration: InputDecoration(
              labelText: t.t('manual.mechanics'),
              helperText: t.t('manual.commaHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categories,
            decoration: InputDecoration(
              labelText: t.t('manual.categories'),
              helperText: t.t('manual.commaHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(t.t('manual.register')),
          ),
        ],
      ),
    );
  }
}
