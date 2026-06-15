import '../../core/barcode.dart';
import '../../core/clock.dart';
import '../../core/constants.dart';
import '../db/app_database.dart';

class BarcodeMapRepository {
  BarcodeMapRepository({
    required AppDatabase database,
    Clock clock = const SystemClock(),
    BarcodeNormalizer normalizer = const BarcodeNormalizer(),
  }) : _database = database,
       _clock = clock,
       _normalizer = normalizer;

  final AppDatabase _database;
  final Clock _clock;
  final BarcodeNormalizer _normalizer;

  Future<BarcodeResolution> resolve(String rawJan) async {
    final normalized = _normalizer.normalize(rawJan);
    if (!normalized.isValid) {
      return BarcodeResolution.invalid(
        raw: rawJan,
        reason: normalized.reason ?? BarcodeInvalidReason.unsupportedLength,
      );
    }

    final jan = normalized.ean13!;
    final mapping = await _database.findBarcodeByJan(jan);
    if (mapping == null) {
      return BarcodeResolution.miss(jan: jan);
    }
    final game = await _database.findGame(mapping.gameKey);
    if (game == null) {
      return BarcodeResolution.miss(jan: jan);
    }
    return BarcodeResolution.hit(jan: jan, game: game, mapping: mapping);
  }

  Future<void> learn({
    required String rawJan,
    required String gameKey,
    required String source,
  }) async {
    final normalized = _normalizer.normalize(rawJan);
    if (!normalized.isValid) {
      throw BarcodeMapException(
        'Invalid JAN: '
        '${normalized.reason ?? BarcodeInvalidReason.unsupportedLength}',
      );
    }
    if (source != AppConstants.barcodeSourceScan &&
        source != AppConstants.barcodeSourceManual) {
      throw BarcodeMapException('Invalid barcode source: $source');
    }
    if (await _database.findGame(gameKey) == null) {
      throw BarcodeMapException('Game not found: $gameKey');
    }
    await _database.upsertBarcode(
      janCode: normalized.ean13!,
      gameKey: gameKey,
      resolvedAt: _clock.now(),
      source: source,
    );
  }
}

class BarcodeResolution {
  const BarcodeResolution._({
    required this.status,
    required this.jan,
    required this.game,
    required this.mapping,
    required this.invalidReason,
  });

  factory BarcodeResolution.hit({
    required String jan,
    required Game game,
    required BarcodeMapEntry mapping,
  }) {
    return BarcodeResolution._(
      status: BarcodeResolutionStatus.hit,
      jan: jan,
      game: game,
      mapping: mapping,
      invalidReason: null,
    );
  }

  factory BarcodeResolution.miss({required String jan}) {
    return BarcodeResolution._(
      status: BarcodeResolutionStatus.miss,
      jan: jan,
      game: null,
      mapping: null,
      invalidReason: null,
    );
  }

  factory BarcodeResolution.invalid({
    required String raw,
    required BarcodeInvalidReason reason,
  }) {
    return BarcodeResolution._(
      status: BarcodeResolutionStatus.invalid,
      jan: raw,
      game: null,
      mapping: null,
      invalidReason: reason,
    );
  }

  final BarcodeResolutionStatus status;
  final String jan;
  final Game? game;
  final BarcodeMapEntry? mapping;
  final BarcodeInvalidReason? invalidReason;
}

enum BarcodeResolutionStatus { hit, miss, invalid }

class BarcodeMapException implements Exception {
  const BarcodeMapException(this.message);

  final String message;

  @override
  String toString() => 'BarcodeMapException: $message';
}
