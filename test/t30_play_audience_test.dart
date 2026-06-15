import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/domain/play_audience.dart';

void main() {
  test('classifies play audience from BGG weight boundaries', () {
    expect(classifyPlayAudience(1.99), PlayAudience.beginner);
    expect(classifyPlayAudience(2.0), PlayAudience.advanced);
    expect(classifyPlayAudience(2.99), PlayAudience.advanced);
    expect(classifyPlayAudience(3.0), PlayAudience.advanced);
    expect(classifyPlayAudience(null), PlayAudience.unknown);
  });
}
