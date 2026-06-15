import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/clock.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/information_update_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/domain/game_rank.dart';

void main() {
  late AppDatabase database;
  late FakeBggApi api;
  late InformationUpdateRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = FakeBggApi();
    repository = InformationUpdateRepository(
      database: database,
      api: api,
      parser: const BggXmlParser(),
      clock: FixedClock(DateTime.utc(2026, 6, 13)),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'does not append history or save when weight change is below tolerance',
    () async {
      await _insertCurrent(
        database,
        weight: 2.3000000,
        averageRating: '7.10',
        ranks: const GameRanks([
          GameRank(type: 'boardgame', rank: '100'),
          GameRank(type: 'strategygames', rank: '50'),
        ]),
      );
      api.thingXml = _thingXml(
        weight: '2.3000005',
        average: '7.10',
        rank: '100',
      );

      final preview = await repository.preview('13');

      expect(preview, isA<InformationUpdateNoChanges>());
      final game = await database.findGame('13');
      expect(game?.updateHistory.entries, isEmpty);
      expect(game?.weight, 2.3);
    },
  );

  test('records only changed rank types in update history', () async {
    await _insertCurrent(
      database,
      weight: 2.3,
      averageRating: '7.10',
      ranks: const GameRanks([
        GameRank(type: 'boardgame', rank: '100'),
        GameRank(type: 'strategygames', rank: '50'),
      ]),
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(
        gameKey: '13',
        storageLocation: const Value('Shelf A'),
        memo: const Value('collection survives'),
      ),
    );
    api.thingXml = _thingXml(weight: '2.31', average: '7.10', rank: '99');

    final preview = await repository.preview('13');
    expect(preview, isA<InformationUpdateChanges>());
    final changes = preview as InformationUpdateChanges;
    expect(changes.snapshot.weight, '2.31');
    expect(changes.snapshot.ranks, hasLength(1));
    expect(changes.snapshot.ranks.single.type, 'boardgame');
    expect(changes.snapshot.ranks.single.rank, '99');

    await repository.apply(changes);

    final game = await database.findGame('13');
    final collection = await database.findCollection('13');
    expect(game?.weight, 2.31);
    expect(game?.ranks.values.map((rank) => '${rank.type}:${rank.rank}'), [
      'boardgame:99',
      'strategygames:50',
    ]);
    expect(game?.updateHistory.entries, hasLength(1));
    expect(game?.updateHistory.entries.single.date, '2026-06-13');
    expect(game?.updateHistory.entries.single.ranks.single.type, 'boardgame');
    expect(collection?.storageLocation, 'Shelf A');
    expect(collection?.memo, 'collection survives');
  });

  test('zero diff returns no changes and apply is not needed', () async {
    await _insertCurrent(
      database,
      weight: 2.3,
      averageRating: '7.10',
      ranks: const GameRanks([
        GameRank(type: 'boardgame', rank: '100'),
        GameRank(type: 'strategygames', rank: '50'),
      ]),
    );
    api.thingXml = _thingXml(weight: '2.3', average: '7.10', rank: '100');

    final preview = await repository.preview('13');

    expect(preview, isA<InformationUpdateNoChanges>());
    expect(api.fetchThingCalls, 1);
    final game = await database.findGame('13');
    expect(game?.updateHistory.entries, isEmpty);
  });

  test('change display uses two decimal numeric formatting', () async {
    await _insertCurrent(
      database,
      weight: 2.3,
      averageRating: '7.10',
      ranks: const GameRanks([
        GameRank(type: 'boardgame', rank: '100'),
        GameRank(type: 'strategygames', rank: '50'),
      ]),
    );
    api.thingXml = _thingXml(weight: '2.45', average: '7.10', rank: '100');

    final preview = await repository.preview('13') as InformationUpdateChanges;
    final weight = preview.changes.singleWhere(
      (change) => change.field == 'weight',
    );

    expect(weight.displayValue, '2.30 → 2.45');
  });
  test(
    'corrects misclassified boardgame expansion relationship to base game',
    () async {
      await _insertCurrent(
        database,
        weight: 2.3,
        averageRating: '7.10',
        ranks: const GameRanks([
          GameRank(type: 'boardgame', rank: '100'),
          GameRank(type: 'strategygames', rank: '50'),
        ]),
        gameKind: AppConstants.gameKindExpansion,
        parentGameKey: '41003',
      );
      api.thingXml = _thingXml(
        weight: '2.3',
        average: '7.10',
        rank: '100',
        itemType: 'boardgame',
        parentId: '41003',
        parentName: 'German edition',
      );

      final preview = await repository.preview('13');

      expect(preview, isA<InformationUpdateChanges>());
      final changes = preview as InformationUpdateChanges;
      expect(
        changes.changes.map((change) => change.field),
        containsAll(['game_kind', 'parent_game_key']),
      );
      expect(
        changes.changes.singleWhere((change) => change.field == 'game_kind'),
        isA<InformationChange>()
            .having((change) => change.oldValue, 'oldValue', 'expansion')
            .having((change) => change.newValue, 'newValue', 'base'),
      );

      await repository.apply(changes);

      final game = await database.findGame('13');
      expect(game?.gameKind, AppConstants.gameKindBase);
      expect(game?.parentGameKey, isNull);
      expect(game?.updateHistory.entries, isEmpty);
    },
  );
}

Future<void> _insertCurrent(
  AppDatabase database, {
  required double weight,
  required String averageRating,
  required GameRanks ranks,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
}) async {
  await database.upsertBggGame(
    bggId: '13',
    names: const GameNames(primary: 'CATAN'),
    yearPublished: '1995',
    averageRating: averageRating,
    weight: weight,
    ranks: ranks,
    mechanics: const ['Trading'],
    categories: const ['Negotiation'],
    gameKind: gameKind,
    parentGameKey: parentGameKey,
  );
  if (await database.findCollection('13') == null) {
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: '13'),
    );
  }
}

String _thingXml({
  required String weight,
  required String average,
  required String rank,
  String itemType = 'boardgame',
  String? parentId,
  String? parentName,
}) {
  return '''
<items>
  <item type="$itemType" id="13">
    <name type="primary" value="CATAN" />
    <yearpublished value="1995" />
    <link type="boardgamemechanic" id="2008" value="Trading" />
    <link type="boardgamecategory" id="1026" value="Negotiation" />
    ${parentId == null ? '' : '<link type="boardgameexpansion" id="$parentId" value="$parentName" />'}
    <statistics>
      <ratings>
        <average value="$average" />
        <averageweight value="$weight" />
        <ranks>
          <rank name="boardgame" value="$rank" />
          <rank name="strategygames" value="50" />
        </ranks>
      </ratings>
    </statistics>
  </item>
</items>
''';
}

class FakeBggApi implements BggApi {
  String thingXml = '<items />';
  int fetchThingCalls = 0;

  @override
  Future<String> collection({
    required String username,
    bool own = true,
    String subtype = 'boardgame',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> fetchThing({required String id, bool stats = true}) async {
    fetchThingCalls += 1;
    return thingXml;
  }

  @override
  Future<String> searchGames({required String query, bool exact = false}) {
    throw UnimplementedError();
  }
}

class FixedClock implements Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}
