import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/constants.dart';
import '../db/app_database.dart';

class YamlExporter {
  YamlExporter({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  Future<YamlExportFile> exportOne(String gameKey) async {
    final game = await _database.findGame(gameKey);
    if (game == null) {
      throw YamlExportException('Game not found: $gameKey');
    }
    final collection = await _database.findCollection(gameKey);
    return _buildFile(game, collection);
  }

  /// Records hashes only after the complete batch has been saved successfully.
  Future<YamlBatchExportResult> exportAll({
    bool force = false,
    required Future<void> Function(List<YamlExportFile> files) writeFiles,
  }) async {
    final games = await _database.select(_database.games).get();
    final files = <YamlExportFile>[];
    final skipped = <String>[];
    final savedHashes = <String, String>{};

    for (final game in games) {
      final collection = await _database.findCollection(game.gameKey);
      final file = _buildFile(game, collection);
      final hashKey = _hashSettingKey(game.gameKey);
      final oldHash = await _readSetting(hashKey);
      if (!force && oldHash == file.md5) {
        skipped.add(game.gameKey);
        continue;
      }
      files.add(file);
      savedHashes[hashKey] = file.md5;
    }

    if (files.isNotEmpty) {
      await writeFiles(files);
      await _database.transaction(() async {
        for (final entry in savedHashes.entries) {
          await _writeSetting(entry.key, entry.value);
        }
      });
    }
    return YamlBatchExportResult(files: files, skippedGameKeys: skipped);
  }

  YamlExportFile _buildFile(Game game, CollectionEntry? collection) {
    final content = _serialize(game, collection);
    return YamlExportFile(
      filename: exportFilename(game),
      content: content,
      md5: md5.convert(utf8.encode(content)).toString(),
    );
  }

  String _serialize(Game game, CollectionEntry? collection) {
    final buffer = StringBuffer();

    _scalar(buffer, 'type', 'boardgame');
    _scalar(buffer, 'name', game.names.primary);
    _list(buffer, 'alternate_names', game.names.alternates);
    _scalar(buffer, 'japanese_name', game.names.japanese ?? game.japaneseName);
    _scalar(buffer, 'year_published', game.yearPublished);
    _scalar(buffer, 'thumbnail_url', game.thumbnailUrl);
    _scalar(buffer, 'publisher_min_players', game.publisherMinPlayers);
    _scalar(buffer, 'publisher_max_players', game.publisherMaxPlayers);
    _scalar(buffer, 'playing_time', game.playingTime);
    _scalar(buffer, 'publisher_min_age', game.publisherMinAge);
    _scalar(buffer, 'community_best_players', game.communityBestPlayers);
    _scalar(
      buffer,
      'community_recommended_players',
      game.communityRecommendedPlayers,
    );
    _scalar(buffer, 'community_min_age', game.communityMinAge);
    _block(buffer, 'description', game.description);
    _block(buffer, 'description_ja', game.descriptionJa);
    _namedList(buffer, 'mechanics', game.mechanics);
    _namedList(buffer, 'categories', game.categories);
    _namedList(buffer, 'designers', game.designers);
    _namedList(buffer, 'publishers', game.publishers);
    _scalar(buffer, 'average_rating', game.averageRating);
    _scalar(buffer, 'weight', game.weight);
    _ranks(buffer, game);
    _updateHistory(buffer, game);
    _collection(buffer, collection);

    return buffer.toString();
  }

  String exportFilename(Game game) {
    final baseName = _sanitizeFilenameBase(
      game.names.primary.trim().isNotEmpty
          ? game.names.primary
          : game.names.japanese ?? game.name,
    );
    if (game.bggId != null) {
      final id = int.tryParse(
        game.bggId!,
      )?.toString().padLeft(AppConstants.bggIdFilenameDigits, '0');
      return '${id ?? game.bggId}_$baseName.yaml';
    }
    final localId = game.localId ?? game.gameKey;
    return '${localId}_$baseName.yaml';
  }

  String _sanitizeFilenameBase(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      switch (char) {
        case ' ':
        case '/':
        case r'\':
        case ':':
        case ';':
          buffer.write('_');
        case '　':
          buffer.write(' ');
        default:
          buffer.write(char);
      }
    }
    return buffer.toString();
  }

  void _scalar(StringBuffer buffer, String key, Object? value) {
    if (value == null) {
      return;
    }
    final text = '$value';
    if (text.isEmpty) {
      return;
    }
    buffer.writeln('$key: ${_quote(text)}');
  }

  void _block(StringBuffer buffer, String key, String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    buffer.writeln('$key: |-');
    for (final line in value.replaceAll('\r\n', '\n').split('\n')) {
      buffer.writeln('  $line');
    }
  }

  void _list(StringBuffer buffer, String key, List<String> values) {
    if (values.isEmpty) {
      return;
    }
    buffer.writeln('$key:');
    for (final value in values) {
      buffer.writeln('  - ${_quote(value)}');
    }
  }

  void _namedList(StringBuffer buffer, String key, List<String> values) {
    if (values.isEmpty) {
      return;
    }
    buffer.writeln('$key:');
    for (final value in values) {
      buffer.writeln('  - name: ${_quote(value)}');
    }
  }

  void _ranks(StringBuffer buffer, Game game) {
    if (game.ranks.values.isEmpty) {
      return;
    }
    buffer.writeln('ranks:');
    for (final rank in game.ranks.values) {
      buffer.writeln('  - type: ${_quote(rank.type)}');
      buffer.writeln('    rank: ${_quote(rank.rank)}');
    }
  }

  void _updateHistory(StringBuffer buffer, Game game) {
    if (game.updateHistory.entries.isEmpty) {
      return;
    }
    buffer.writeln('update_history:');
    for (final entry in game.updateHistory.entries) {
      buffer.writeln('  - date: ${_quote(entry.date)}');
      if (entry.averageRating != null) {
        buffer.writeln('    average_rating: ${_quote(entry.averageRating!)}');
      }
      if (entry.weight != null) {
        buffer.writeln('    weight: ${_quote(entry.weight!)}');
      }
      if (entry.ranks.isNotEmpty) {
        buffer.writeln('    ranks:');
        for (final rank in entry.ranks) {
          buffer.writeln('      - type: ${_quote(rank.type)}');
          buffer.writeln('        rank: ${_quote(rank.rank)}');
        }
      }
    }
  }

  void _collection(StringBuffer buffer, CollectionEntry? collection) {
    if (collection == null) {
      return;
    }
    buffer.writeln('collection:');
    buffer.writeln('  owned: ${collection.owned}');
    _nestedScalar(buffer, 'acquired_date', collection.acquiredDate);
    _nestedScalar(buffer, 'condition', collection.condition);
    _nestedScalar(buffer, 'storage_location', collection.storageLocation);
    _nestedScalar(buffer, 'memo', collection.memo ?? '');
    if (collection.purchasePrice != null) {
      _nestedScalar(buffer, 'purchase_price', collection.purchasePrice);
    }
  }

  void _nestedScalar(StringBuffer buffer, String key, Object? value) {
    if (value == null) {
      return;
    }
    buffer.writeln('  $key: ${_quote('$value')}');
  }

  String _quote(String value) {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }

  Future<String?> _readSetting(String key) async {
    final entry = await (_database.select(
      _database.settingsEntries,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  Future<void> _writeSetting(String key, String value) {
    return _database
        .into(_database.settingsEntries)
        .insertOnConflictUpdate(
          SettingsEntriesCompanion.insert(key: key, value: Value(value)),
        );
  }

  String _hashSettingKey(String gameKey) => 'export_hash:$gameKey';
}

class YamlExportFile {
  const YamlExportFile({
    required this.filename,
    required this.content,
    required this.md5,
  });

  final String filename;
  final String content;
  final String md5;
}

class YamlBatchExportResult {
  const YamlBatchExportResult({
    required this.files,
    required this.skippedGameKeys,
  });

  final List<YamlExportFile> files;
  final List<String> skippedGameKeys;
}

class YamlExportException implements Exception {
  const YamlExportException(this.message);

  final String message;

  @override
  String toString() => 'YamlExportException: $message';
}
