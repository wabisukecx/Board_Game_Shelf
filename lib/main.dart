import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/providers.dart';
import 'src/i18n/i18n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final source = await rootBundle.loadString('assets/i18n/ja.json');
  final i18n = I18n.fromJsonString(source);
  runApp(
    ProviderScope(
      overrides: [i18nProvider.overrideWithValue(i18n)],
      child: const BgShelfScannerApp(),
    ),
  );
}
