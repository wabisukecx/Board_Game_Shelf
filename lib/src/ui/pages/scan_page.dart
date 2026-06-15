import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/providers.dart';
import '../../core/barcode.dart' as core_barcode;
import '../../core/constants.dart';
import '../../data/gameupc/game_upc_client.dart';
import '../../data/repo/bgg_registration_repository.dart';
import '../../data/repo/barcode_map_repository.dart';
import 'game_detail_page.dart';
import 'local_game_form_page.dart';
import 'search_registration_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  final _manualJan = TextEditingController();
  final _normalizer = const core_barcode.BarcodeNormalizer();
  final _repeatGuard = core_barcode.BarcodeRepeatGuard();
  late final MobileScannerController _controller;

  bool _resolving = false;
  String? _message;

  bool get _cameraSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.ean13, BarcodeFormat.upcA],
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 300,
    );
  }

  @override
  void dispose() {
    _manualJan.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final normalized = _normalizer.normalize(raw);
      if (!normalized.isValid) {
        setState(() => _message = ref.read(i18nProvider).t('jan.invalid'));
        continue;
      }
      final jan = normalized.ean13!;
      if (!_repeatGuard.shouldAccept(jan, ref.read(clockProvider).now())) {
        return;
      }
      await _resolve(jan, source: AppConstants.barcodeSourceScan);
      return;
    }
  }

  Future<void> _submitManualJan() async {
    final normalized = _normalizer.normalize(_manualJan.text);
    if (!normalized.isValid) {
      setState(() => _message = ref.read(i18nProvider).t('jan.invalid'));
      return;
    }
    await _resolve(normalized.ean13!, source: AppConstants.barcodeSourceManual);
  }

  Future<void> _resolve(String jan, {required String source}) async {
    final t = ref.read(i18nProvider);
    setState(() {
      _resolving = true;
      _message = t.t('scan.resolving', {'jan': jan});
    });

    final resolution = await ref
        .read(barcodeMapRepositoryProvider)
        .resolve(jan);
    if (!mounted) {
      return;
    }
    setState(() => _resolving = false);

    switch (resolution.status) {
      case BarcodeResolutionStatus.hit:
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GameDetailPage(gameKey: resolution.game!.gameKey),
          ),
        );
      case BarcodeResolutionStatus.miss:
        final handled = await _tryGameUpc(jan: resolution.jan, source: source);
        if (handled) {
          return;
        }
        await _showMissActions(jan: resolution.jan, source: source);
      case BarcodeResolutionStatus.invalid:
        setState(() => _message = t.t('jan.invalid'));
    }
  }

  Future<bool> _tryGameUpc({
    required String jan,
    required String source,
  }) async {
    final t = ref.read(i18nProvider);
    setState(() {
      _resolving = true;
      _message = t.t('scan.gameUpcResolving', {'jan': jan});
    });
    try {
      final result = await ref.read(gameUpcClientProvider).lookup(jan);
      if (!mounted) {
        return true;
      }
      if (result.isVerified) {
        await _registerGameUpcCandidate(
          result.candidates.first,
          jan: jan,
          source: source,
          vote: false,
        );
        return true;
      }
      if (result.candidates.isNotEmpty) {
        await _showGameUpcCandidates(jan: jan, source: source, result: result);
        return true;
      }
      setState(() => _message = t.t('scan.gameUpcNoResults'));
      return false;
    } catch (_) {
      if (mounted) {
        setState(() => _message = t.t('scan.gameUpcFailed'));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  Future<void> _registerGameUpcCandidate(
    GameUpcCandidate candidate, {
    required String jan,
    required String source,
    required bool vote,
  }) async {
    final t = ref.read(i18nProvider);
    try {
      if (vote) {
        final userId = await ref
            .read(secureSettingsProvider)
            .readOrCreateGameUpcUserId();
        await ref.read(gameUpcClientProvider).vote(candidate, userId);
      }
      final result = await ref
          .read(bggRegistrationRepositoryProvider)
          .registerBggId(candidate.bggId);
      await ref
          .read(barcodeMapRepositoryProvider)
          .learn(rawJan: jan, gameKey: result.game.gameKey, source: source);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.t('scan.gameUpcRegistered', {'name': candidate.name}),
          ),
        ),
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailPage(gameKey: result.game.gameKey),
        ),
      );
    } on InvalidBggGameException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.t('search.invalidGame'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.t('search.errorGeneric'))));
      }
    }
  }

  Future<void> _showGameUpcCandidates({
    required String jan,
    required String source,
    required GameUpcLookupResult result,
  }) {
    final t = ref.read(i18nProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.t('scan.gameUpcCandidatesTitle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.t('scan.gameUpcCandidatesBody', {
                  'query': result.searchedFor,
                }),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: result.candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final candidate = result.candidates[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          candidate.thumbnailUrl == null ||
                              candidate.thumbnailUrl!.isEmpty
                          ? const Icon(Icons.casino_outlined)
                          : Image.network(
                              candidate.thumbnailUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.casino_outlined),
                            ),
                      title: Text(candidate.name),
                      subtitle: Text(
                        [
                          t.t('scan.gameUpcConfidence', {
                            'value': candidate.confidence,
                          }),
                          if (candidate.preferredVersion != null)
                            t.t('scan.gameUpcVersion', {
                              'name': candidate.preferredVersionLabel,
                            }),
                        ].join(' / '),
                      ),
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _registerGameUpcCandidate(
                          candidate,
                          jan: jan,
                          source: source,
                          vote: true,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: Text(t.t('scan.searchWithJan')),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SearchRegistrationPage(
                        pendingJan: jan,
                        barcodeSource: source,
                        initialQuery: result.searchedFor,
                        autoSearch: result.searchedFor.trim().isNotEmpty,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMissActions({required String jan, required String source}) {
    final t = ref.read(i18nProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.t('scan.unknownTitle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(t.t('scan.unknownBody', {'jan': jan})),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.search),
                label: Text(t.t('scan.searchWithJan')),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SearchRegistrationPage(
                        pendingJan: jan,
                        barcodeSource: source,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: Text(t.t('scan.manualWithJan')),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => LocalGameFormPage(
                        pendingJan: jan,
                        barcodeSource: source,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(i18nProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('scan.title')),
        actions: [
          if (_cameraSupported)
            IconButton(
              tooltip: t.t('scan.torch'),
              icon: const Icon(Icons.flashlight_on_outlined),
              onPressed: () => _controller.toggleTorch(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (_cameraSupported) _buildCamera(context, t) else _fallback(t),
          const SizedBox(height: 16),
          _manualForm(t),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }

  Widget _buildCamera(BuildContext context, dynamic t) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _fallback(t),
            ),
            Center(
              child: Container(
                width: 240,
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    t.t('scan.cameraHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(dynamic t) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 48),
            const SizedBox(height: 8),
            Text(t.t('scan.manualFallback'), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _manualForm(dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _manualJan,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _resolving ? null : _submitManualJan(),
          decoration: InputDecoration(
            labelText: t.t('jan.inputLabel'),
            helperText: t.t('jan.inputHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _resolving ? null : _submitManualJan,
          icon: _resolving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(t.t('jan.resolve')),
        ),
      ],
    );
  }
}
