import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/barcode.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';

void main() {
  test('normalizes valid EAN-13 and ignores separators', () {
    final result = const BarcodeNormalizer().normalize('490-1234-567894');

    expect(result.isValid, isTrue);
    expect(result.ean13, '4901234567894');
  });

  test('normalizes UPC-A to EAN-13 with leading zero', () {
    final result = const BarcodeNormalizer().normalize('042100005264');

    expect(result.isValid, isTrue);
    expect(result.ean13, '0042100005264');
  });

  test('rejects unsupported length and invalid check digit', () {
    final normalizer = const BarcodeNormalizer();

    expect(
      normalizer.normalize('12345678901').reason,
      BarcodeInvalidReason.unsupportedLength,
    );
    expect(
      normalizer.normalize('4901234567895').reason,
      BarcodeInvalidReason.invalidCheckDigit,
    );
  });

  test(
    'suppresses repeated detections for the same JAN within 2.5 seconds',
    () {
      final guard = BarcodeRepeatGuard();
      final now = DateTime(2026, 6, 13, 12);

      expect(guard.shouldAccept('4901234567894', now), isTrue);
      expect(
        guard.shouldAccept(
          '4901234567894',
          now.add(const Duration(seconds: 2)),
        ),
        isFalse,
      );
      expect(
        guard.shouldAccept(
          '4901234567894',
          now.add(AppConstants.barcodeRepeatSuppressDuration),
        ),
        isTrue,
      );
      expect(
        guard.shouldAccept(
          '0042100005264',
          now.add(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
    },
  );
}
