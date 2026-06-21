import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../domain/community_players.dart';
import '../../domain/game_names.dart';
import '../../domain/game_rank.dart';
import '../../domain/update_history.dart';

part 'app_database.g.dart';

class GameNamesConverter extends TypeConverter<GameNames, String> {
  const GameNamesConverter();

  @override
  GameNames fromSql(String fromDb) => GameNames.fromJsonString(fromDb);

  @override
  String toSql(GameNames value) => value.toJsonString();
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) {
      throw const FormatException('string list column must be a JSON array');
    }
    return [
      for (final value in decoded)
        if (value is String) value,
    ];
  }

  @override
  String toSql(List<String> value) => jsonEncode(_normalize(value));

  static List<String> _normalize(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }
}

class SuggestedPlayerVotesConverter
    extends TypeConverter<SuggestedPlayerVotes, String> {
  const SuggestedPlayerVotesConverter();

  @override
  SuggestedPlayerVotes fromSql(String fromDb) {
    return SuggestedPlayerVotes.fromJsonString(fromDb);
  }

  @override
  String toSql(SuggestedPlayerVotes value) => value.toJsonString();
}

class GameRanksConverter extends TypeConverter<GameRanks, String> {
  const GameRanksConverter();

  @override
  GameRanks fromSql(String fromDb) => GameRanks.fromJsonString(fromDb);

  @override
  String toSql(GameRanks value) => value.toJsonString();
}

class UpdateHistoryConverter extends TypeConverter<UpdateHistory, String> {
  const UpdateHistoryConverter();

  @override
  UpdateHistory fromSql(String fromDb) => UpdateHistory.fromJsonString(fromDb);

  @override
  String toSql(UpdateHistory value) => value.toJsonString();
}

class Games extends Table {
  TextColumn get gameKey => text()();
  TextColumn get bggId => text().nullable()();
  TextColumn get localId => text().nullable()();
  TextColumn get gameKind =>
      text().withDefault(const Constant(AppConstants.gameKindBase))();
  TextColumn get parentGameKey => text().nullable()();
  TextColumn get names => text().map(const GameNamesConverter())();
  TextColumn get name => text()();
  TextColumn get japaneseName => text().nullable()();
  TextColumn get yearPublished => text().nullable()();
  IntColumn get publisherMinPlayers => integer().nullable()();
  IntColumn get publisherMaxPlayers => integer().nullable()();
  IntColumn get playingTime => integer().nullable()();
  IntColumn get publisherMinAge => integer().nullable()();
  TextColumn get communityBestPlayers => text().nullable()();
  TextColumn get communityRecommendedPlayers => text().nullable()();
  TextColumn get communityMinAge => text().nullable()();
  TextColumn get suggestedPlayerVotes => text()
      .map(const SuggestedPlayerVotesConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get description => text().nullable()();
  TextColumn get descriptionJa => text().nullable()();
  TextColumn get mechanics => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get categories => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get designers => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get publishers => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get averageRating => text().nullable()();
  RealColumn get weight => real().nullable()();
  TextColumn get ranks => text()
      .map(const GameRanksConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get updateHistory => text()
      .map(const UpdateHistoryConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get rawYaml => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {gameKey};
}

@TableIndex(name: 'collection_game_key_idx', columns: {#gameKey})
class CollectionEntries extends Table {
  @override
  String get tableName => 'collection';

  TextColumn get gameKey => text().references(Games, #gameKey)();
  BoolColumn get owned => boolean().withDefault(const Constant(true))();
  TextColumn get acquiredDate => text().nullable()();
  TextColumn get condition => text().nullable()();
  TextColumn get storageLocation => text().nullable()();
  TextColumn get memo => text().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {gameKey};
}

class BarcodeMapEntries extends Table {
  @override
  String get tableName => 'barcode_map';

  TextColumn get janCode => text()();
  TextColumn get gameKey => text().references(Games, #gameKey)();
  DateTimeColumn get resolvedAt => dateTime()();
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {janCode};
}

class ApiCacheEntries extends Table {
  @override
  String get tableName => 'api_cache';

  TextColumn get cacheKey => text()();
  TextColumn get payload => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

class SettingsEntries extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@TableIndex(name: 'gameupc_cache_barcode_idx', columns: {#barcode})
class GameUpcCacheEntries extends Table {
  @override
  String get tableName => 'gameupc_cache';

  TextColumn get barcode => text()();
  TextColumn get bggId => text()();
  TextColumn get versionId => text().nullable()();
  TextColumn get name => text()();

  @override
  Set<Column<Object>> get primaryKey => {barcode};
}

@TableIndex(name: 'play_sessions_game_key_idx', columns: {#gameKey})
class PlaySessions extends Table {
  @override
  String get tableName => 'play_sessions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get gameKey => text().references(Games, #gameKey)();
  TextColumn get playedDate => text()();
  IntColumn get playerCount => integer().nullable()();
  IntColumn get actualPlayingTime => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get rating => integer().nullable()();
  IntColumn get replayDesire => integer().nullable()();
  RealColumn get perceivedWeight => real().nullable()();
  TextColumn get winnerMemo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PlaySessionExpansions extends Table {
  @override
  String get tableName => 'play_session_expansions';

  IntColumn get playSessionId => integer().references(PlaySessions, #id)();
  TextColumn get expansionGameKey => text().references(Games, #gameKey)();

  @override
  Set<Column<Object>> get primaryKey => {playSessionId, expansionGameKey};
}

@DriftDatabase(
  tables: [
    Games,
    CollectionEntries,
    BarcodeMapEntries,
    ApiCacheEntries,
    SettingsEntries,
    GameUpcCacheEntries,
    PlaySessions,
    PlaySessionExpansions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(games, games.mechanics);
        await m.addColumn(games, games.categories);
      }
      if (from < 3) {
        await m.addColumn(games, games.communityBestPlayers);
        await m.addColumn(games, games.communityRecommendedPlayers);
        await m.addColumn(games, games.suggestedPlayerVotes);
      }
      if (from < 4) {
        await m.addColumn(games, games.averageRating);
        await m.addColumn(games, games.ranks);
        await m.addColumn(games, games.updateHistory);
      }
      if (from < 5) {
        await m.addColumn(games, games.publisherMinAge);
        await m.addColumn(games, games.communityMinAge);
        await m.addColumn(games, games.description);
        await m.addColumn(games, games.descriptionJa);
        await m.addColumn(games, games.designers);
        await m.addColumn(games, games.publishers);
      }
      if (from < 6) {
        await m.addColumn(games, games.gameKind);
        await m.addColumn(games, games.parentGameKey);
      }
      if (from < 7) {
        await m.createTable(playSessions);
        await m.createTable(playSessionExpansions);
      }
      if (from < 8) {
        await m.createTable(gameUpcCacheEntries);
      }
    },
  );

  Future<void> upsertBggGame({
    required String bggId,
    required GameNames names,
    String? japaneseName,
    String? yearPublished,
    int? publisherMinPlayers,
    int? publisherMaxPlayers,
    int? playingTime,
    int? publisherMinAge,
    String? communityBestPlayers,
    String? communityRecommendedPlayers,
    String? communityMinAge,
    SuggestedPlayerVotes suggestedPlayerVotes = const SuggestedPlayerVotes([]),
    String? description,
    String? descriptionJa,
    List<String> mechanics = const [],
    List<String> categories = const [],
    List<String> designers = const [],
    List<String> publishers = const [],
    String? averageRating,
    double? weight,
    GameRanks ranks = const GameRanks([]),
    UpdateHistory? updateHistory,
    String? thumbnailUrl,
    String? rawYaml,
    String gameKind = AppConstants.gameKindBase,
    String? parentGameKey,
  }) {
    final gameKey = bggId;
    return into(games).insertOnConflictUpdate(
      GamesCompanion(
        gameKey: Value(gameKey),
        bggId: Value(bggId),
        localId: const Value(null),
        gameKind: Value(gameKind),
        parentGameKey: Value(parentGameKey),
        names: Value(names),
        name: Value(names.primary),
        japaneseName: Value(japaneseName ?? names.japanese),
        yearPublished: Value(yearPublished),
        publisherMinPlayers: Value(publisherMinPlayers),
        publisherMaxPlayers: Value(publisherMaxPlayers),
        playingTime: Value(playingTime),
        publisherMinAge: Value(publisherMinAge),
        communityBestPlayers: Value(communityBestPlayers),
        communityRecommendedPlayers: Value(communityRecommendedPlayers),
        communityMinAge: Value(communityMinAge),
        suggestedPlayerVotes: Value(suggestedPlayerVotes),
        description: Value(description),
        descriptionJa: Value(descriptionJa),
        mechanics: Value(mechanics),
        categories: Value(categories),
        designers: Value(designers),
        publishers: Value(publishers),
        averageRating: Value(averageRating),
        weight: Value(weight),
        ranks: Value(ranks),
        updateHistory: updateHistory == null
            ? const Value.absent()
            : Value(updateHistory),
        thumbnailUrl: Value(thumbnailUrl),
        rawYaml: Value(rawYaml),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String> insertLocalGame({
    required String title,
    GameNames? names,
    int? publisherMinPlayers,
    int? publisherMaxPlayers,
    int? playingTime,
    int? publisherMinAge,
    SuggestedPlayerVotes suggestedPlayerVotes = const SuggestedPlayerVotes([]),
    String? description,
    String? descriptionJa,
    List<String> mechanics = const [],
    List<String> categories = const [],
    List<String> designers = const [],
    List<String> publishers = const [],
    String gameKind = AppConstants.gameKindBase,
    String? parentGameKey,
  }) {
    return transaction(() async {
      final localId = await _allocateLocalId();
      await into(games).insert(
        GamesCompanion.insert(
          gameKey: localId,
          localId: Value(localId),
          gameKind: Value(gameKind),
          parentGameKey: Value(parentGameKey),
          names: names ?? GameNames(primary: title, japanese: title),
          name: title,
          japaneseName: Value(names?.japanese ?? title),
          publisherMinPlayers: Value(publisherMinPlayers),
          publisherMaxPlayers: Value(publisherMaxPlayers),
          playingTime: Value(playingTime),
          publisherMinAge: Value(publisherMinAge),
          suggestedPlayerVotes: Value(suggestedPlayerVotes),
          description: Value(description),
          descriptionJa: Value(descriptionJa),
          mechanics: Value(mechanics),
          categories: Value(categories),
          designers: Value(designers),
          publishers: Value(publishers),
        ),
      );
      return localId;
    });
  }

  Future<bool> isBggRefreshTarget(String gameKey) async {
    final game = await findGame(gameKey);
    return game?.bggId != null && game?.localId == null;
  }

  Future<void> upsertCollection(CollectionEntriesCompanion entry) {
    return into(collectionEntries).insertOnConflictUpdate(entry);
  }

  Future<Game?> findGame(String gameKey) {
    return (select(
      games,
    )..where((game) => game.gameKey.equals(gameKey))).getSingleOrNull();
  }

  Future<List<Game>> findExpansions(String parentGameKey) {
    return (select(games)
          ..where(
            (game) =>
                game.gameKind.equals(AppConstants.gameKindExpansion) &
                game.parentGameKey.equals(parentGameKey),
          )
          ..orderBy([(game) => OrderingTerm.asc(game.name)]))
        .get();
  }

  Future<void> updateDescriptionJa(String gameKey, String? descriptionJa) {
    return (update(games)..where((game) => game.gameKey.equals(gameKey))).write(
      GamesCompanion(descriptionJa: Value(descriptionJa)),
    );
  }

  Future<void> updateParentGameKey(String gameKey, String? parentGameKey) {
    return (update(games)..where((game) => game.gameKey.equals(gameKey))).write(
      GamesCompanion(parentGameKey: Value(parentGameKey)),
    );
  }

  Future<CollectionEntry?> findCollection(String gameKey) {
    return (select(
      collectionEntries,
    )..where((entry) => entry.gameKey.equals(gameKey))).getSingleOrNull();
  }

  Future<BarcodeMapEntry?> findBarcodeByJan(String janCode) {
    return (select(
      barcodeMapEntries,
    )..where((entry) => entry.janCode.equals(janCode))).getSingleOrNull();
  }

  Future<GameUpcCacheEntry?> findGameUpcCache(String barcode) {
    return (select(
      gameUpcCacheEntries,
    )..where((entry) => entry.barcode.equals(barcode))).getSingleOrNull();
  }

  Future<int> countGameUpcCacheEntries() async {
    final countExpression = gameUpcCacheEntries.barcode.count();
    final query = selectOnly(gameUpcCacheEntries)
      ..addColumns([countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  Future<String?> readSetting(String key) async {
    final entry = await (select(
      settingsEntries,
    )..where((entry) => entry.key.equals(key))).getSingleOrNull();
    return entry?.value;
  }

  Future<void> upsertBarcode({
    required String janCode,
    required String gameKey,
    required DateTime resolvedAt,
    required String source,
  }) {
    return into(barcodeMapEntries).insertOnConflictUpdate(
      BarcodeMapEntriesCompanion.insert(
        janCode: janCode,
        gameKey: gameKey,
        resolvedAt: resolvedAt,
        source: source,
      ),
    );
  }

  Future<String> _allocateLocalId() async {
    final current = await (select(
      settingsEntries,
    )..where((entry) => entry.key.equals('local_id_last'))).getSingleOrNull();
    var next = (int.tryParse(current?.value ?? '') ?? 0) + 1;

    while (await findGame(_formatLocalId(next)) != null) {
      next += 1;
    }

    await into(settingsEntries).insertOnConflictUpdate(
      SettingsEntriesCompanion.insert(
        key: 'local_id_last',
        value: Value('$next'),
      ),
    );
    return _formatLocalId(next);
  }

  String _formatLocalId(int value) {
    return '${AppConstants.localIdPrefix}'
        '${value.toString().padLeft(AppConstants.localIdDigits, '0')}';
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'bg_shelf_scanner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
