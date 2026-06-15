import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import '../ui/pages/collection_list_page.dart';

class BgShelfScannerApp extends ConsumerWidget {
  const BgShelfScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(languageBootstrapProvider);
    final localeCode = ref.watch(currentLocaleCodeProvider);

    return MaterialApp(
      title: 'Board Game Shelf',
      debugShowCheckedModeBanner: false,
      locale: localeCode == null ? null : Locale(localeCode),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
        useMaterial3: true,
      ),
      home: bootstrap.when(
        data: (_) => const CollectionListPage(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(child: Text('Failed to load language: $error')),
        ),
      ),
    );
  }
}
