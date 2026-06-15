import 'package:flutter/material.dart';

import '../ui/pages/collection_list_page.dart';

class BgShelfScannerApp extends StatelessWidget {
  const BgShelfScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Game Shelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
        useMaterial3: true,
      ),
      home: const CollectionListPage(),
    );
  }
}
