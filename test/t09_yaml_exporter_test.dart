import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/export/yaml_exporter.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/domain/game_rank.dart';
import 'package:bg_shelf_scanner/src/domain/update_history.dart';

void main() {
  late AppDatabase database;
  late YamlExporter exporter;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    exporter = YamlExporter(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'exports BGG filename with six digit id and compatible YAML key order',
    () async {
      await _insertCatan(database);

      final file = await exporter.exportOne('13');

      expect(file.filename, '000013_CATAN.yaml');
      expect(RegExp(r'^(\d+)_(.*?)\.yaml$').hasMatch(file.filename), isTrue);
      expect(file.content, _goldenCatanYaml);

      final parsed = loadYaml(file.content) as YamlMap;
      expect(parsed['name'], 'CATAN');
      expect(parsed['description_ja'], '交渉して島を広げます。');
      expect(parsed['collection']['storage_location'], '棚A-2');
    },
  );

  test('keeps description_ja immediately after description', () async {
    await _insertCatan(database);

    final content = (await exporter.exportOne('13')).content;

    expect(
      content.indexOf('description: |-'),
      lessThan(content.indexOf('description_ja: |-')),
    );
    expect(
      content.indexOf('description_ja: |-'),
      lessThan(content.indexOf('mechanics:')),
    );
  });

  test('local filename does not match BGG analyzer regex', () async {
    final localId = await database.insertLocalGame(title: '俺の屍を越えてゆけ風同人ゲーム');
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: localId),
    );

    final file = await exporter.exportOne(localId);

    expect(file.filename, 'L00001_俺の屍を越えてゆけ風同人ゲーム.yaml');
    expect(RegExp(r'^(\d+)_(.*?)\.yaml$').hasMatch(file.filename), isFalse);
  });

  test('sanitizes filename according to compatibility rules', () async {
    await database.upsertBggGame(
      bggId: '7',
      names: const GameNames(primary: 'A/B C:D;E　F'),
    );

    final file = await exporter.exportOne('7');

    expect(file.filename, '000007_A_B_C_D_E F.yaml');
  });

  test('batch export skips unchanged records unless forced', () async {
    await _insertCatan(database);

    final first = await exporter.exportAll();
    final second = await exporter.exportAll();
    final forced = await exporter.exportAll(force: true);

    expect(first.files, hasLength(1));
    expect(first.skippedGameKeys, isEmpty);
    expect(second.files, isEmpty);
    expect(second.skippedGameKeys, ['13']);
    expect(forced.files, hasLength(1));
    expect(forced.skippedGameKeys, isEmpty);
  });
}

Future<void> _insertCatan(AppDatabase database) async {
  await database.upsertBggGame(
    bggId: '13',
    names: const GameNames(
      primary: 'CATAN',
      japanese: 'カタンの開拓者たち',
      english: 'CATAN',
      alternates: ['カタン'],
    ),
    yearPublished: '1995',
    publisherMinPlayers: 3,
    publisherMaxPlayers: 4,
    playingTime: 120,
    publisherMinAge: 10,
    communityBestPlayers: '4',
    communityRecommendedPlayers: '3, 4',
    communityMinAge: '10',
    description: 'Trade resources.\nBuild roads.',
    descriptionJa: '交渉して島を広げます。',
    mechanics: const ['Dice Rolling'],
    categories: const ['Negotiation'],
    designers: const ['Klaus Teuber'],
    publishers: const ['KOSMOS'],
    averageRating: '7.1',
    weight: 2.3,
    ranks: const GameRanks([GameRank(type: 'boardgame', rank: '429')]),
    updateHistory: const UpdateHistory([
      UpdateHistoryEntry(date: '2026-06-13', weight: '2.31'),
    ]),
  );
  await database.upsertCollection(
    CollectionEntriesCompanion.insert(
      gameKey: '13',
      acquiredDate: const Value('2026-06-01'),
      condition: const Value('good'),
      storageLocation: const Value('棚A-2'),
      memo: const Value(''),
    ),
  );
}

const _goldenCatanYaml = '''type: 'boardgame'
name: 'CATAN'
alternate_names:
  - 'カタン'
japanese_name: 'カタンの開拓者たち'
year_published: '1995'
publisher_min_players: '3'
publisher_max_players: '4'
playing_time: '120'
publisher_min_age: '10'
community_best_players: '4'
community_recommended_players: '3, 4'
community_min_age: '10'
description: |-
  Trade resources.
  Build roads.
description_ja: |-
  交渉して島を広げます。
mechanics:
  - name: 'Dice Rolling'
categories:
  - name: 'Negotiation'
designers:
  - name: 'Klaus Teuber'
publishers:
  - name: 'KOSMOS'
average_rating: '7.1'
weight: '2.3'
ranks:
  - type: 'boardgame'
    rank: '429'
update_history:
  - date: '2026-06-13'
    weight: '2.31'
collection:
  owned: true
  acquired_date: '2026-06-01'
  condition: 'good'
  storage_location: '棚A-2'
  memo: ''
''';
