import 'constants.dart';

class BarcodeNormalizer {
  const BarcodeNormalizer();

  BarcodeNormalizationResult normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12) {
      return _validate('0$digits');
    }
    if (digits.length == 13) {
      return _validate(digits);
    }
    return BarcodeNormalizationResult.invalid(
      raw: raw,
      reason: BarcodeInvalidReason.unsupportedLength,
    );
  }

  BarcodeNormalizationResult _validate(String ean13) {
    if (!_hasValidEan13CheckDigit(ean13)) {
      return BarcodeNormalizationResult.invalid(
        raw: ean13,
        reason: BarcodeInvalidReason.invalidCheckDigit,
      );
    }
    return BarcodeNormalizationResult.valid(ean13);
  }

  bool _hasValidEan13CheckDigit(String value) {
    var sum = 0;
    for (var index = 0; index < 12; index += 1) {
      final digit = int.parse(value[index]);
      sum += index.isEven ? digit : digit * 3;
    }
    final expected = (10 - (sum % 10)) % 10;
    return expected == int.parse(value[12]);
  }
}

class BarcodeRepeatGuard {
  BarcodeRepeatGuard({
    this.suppressionWindow = AppConstants.barcodeRepeatSuppressDuration,
  });

  final Duration suppressionWindow;
  String? _lastJan;
  DateTime? _lastAcceptedAt;

  bool shouldAccept(String jan, DateTime detectedAt) {
    final lastJan = _lastJan;
    final lastAcceptedAt = _lastAcceptedAt;
    if (lastJan == jan &&
        lastAcceptedAt != null &&
        detectedAt.difference(lastAcceptedAt) < suppressionWindow) {
      return false;
    }
    _lastJan = jan;
    _lastAcceptedAt = detectedAt;
    return true;
  }
}

class BarcodeNormalizationResult {
  const BarcodeNormalizationResult._({
    required this.raw,
    required this.ean13,
    required this.reason,
  });

  factory BarcodeNormalizationResult.valid(String ean13) {
    return BarcodeNormalizationResult._(raw: ean13, ean13: ean13, reason: null);
  }

  factory BarcodeNormalizationResult.invalid({
    required String raw,
    required BarcodeInvalidReason reason,
  }) {
    return BarcodeNormalizationResult._(raw: raw, ean13: null, reason: reason);
  }

  final String raw;
  final String? ean13;
  final BarcodeInvalidReason? reason;

  bool get isValid => ean13 != null;
}

enum BarcodeInvalidReason { unsupportedLength, invalidCheckDigit }
