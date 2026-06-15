import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'locale_option.dart';

typedef AssetPathLoader = Future<List<String>> Function();
typedef AssetStringLoader = Future<String> Function(String path);

class LanguageCatalog {
  LanguageCatalog({
    AssetBundle? bundle,
    AssetPathLoader? loadAssetPaths,
    AssetStringLoader? loadString,
  }) : _bundle = bundle ?? rootBundle,
       _loadAssetPaths = loadAssetPaths,
       _loadString = loadString;

  final AssetBundle _bundle;
  final AssetPathLoader? _loadAssetPaths;
  final AssetStringLoader? _loadString;

  Future<List<LocaleOption>> load() async {
    final paths = await _i18nJsonAssetPaths();
    final options = <LocaleOption>[];
    for (final path in paths) {
      options.add(await _optionFor(path));
    }
    options.sort((a, b) => a.localeCode.compareTo(b.localeCode));
    return options;
  }

  Future<List<String>> _i18nJsonAssetPaths() async {
    final paths = _loadAssetPaths != null
        ? await _loadAssetPaths()
        : (await AssetManifest.loadFromAssetBundle(_bundle)).listAssets();
    return [
      for (final path in paths)
        if (path.startsWith('assets/i18n/') &&
            path.endsWith('.json') &&
            p.dirname(path).replaceAll(r'\', '/') == 'assets/i18n')
          path,
    ]..sort();
  }

  Future<LocaleOption> _optionFor(String path) async {
    final source = _loadString != null
        ? await _loadString(path)
        : await _bundle.loadString(path);
    final fallbackCode = p.basenameWithoutExtension(path);
    try {
      final decoded = jsonDecode(source);
      final meta = decoded is Map<String, Object?> ? decoded['_meta'] : null;
      if (meta is Map<String, Object?>) {
        final locale = meta['locale'];
        final name = meta['name'];
        return LocaleOption(
          assetPath: path,
          localeCode: locale is String && locale.trim().isNotEmpty
              ? locale.trim()
              : fallbackCode,
          displayName: name is String && name.trim().isNotEmpty
              ? name.trim()
              : fallbackCode,
        );
      }
    } on FormatException {
      // Fall through to filename-based metadata; invalid bundles still appear
      // in the catalog so selecting them can surface the normal load error.
    }
    return LocaleOption(
      assetPath: path,
      localeCode: fallbackCode,
      displayName: fallbackCode,
    );
  }
}
