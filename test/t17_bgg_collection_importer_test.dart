import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_token_provider.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_collection_importer.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_registration_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late FakeBggApi api;
  late BggCollectionImporter importer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = FakeBggApi();
    importer = BggCollectionImporter(
      database: database,
      registrationRepository: BggRegistrationRepository(
        database: database,
        api: api,
        parser: const BggXmlParser(),
        tokenProvider: const FixedTokenProvider('token'),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('preview marks existing items and import sends only new ids', () async {
    await database.upsertBggGame(
      bggId: '1',
      names: const GameNames(primary: 'Existing'),
    );
    await database.upsertCollection(
      CollectionEntriesCompanion.insert(gameKey: '1'),
    );
    api.thingXmlById['2'] = _thingXml(id: '2', title: 'New');

    final preview = await importer.preview([
      const BggCollectionItem(objectId: '1', name: 'Existing'),
      const BggCollectionItem(objectId: '2', name: 'New'),
    ]);
    final summary = await importer.importItems(preview);

    expect(preview.totalCount, 2);
    expect(preview.existingCount, 1);
    expect(preview.newCount, 1);
    expect(summary.registered, 1);
    expect(summary.skipped, 1);
    expect(api.fetchThingIds, ['2']);
    expect(await database.findGame('2'), isNotNull);
  });

  test('AlreadyExists during import is counted as skipped', () async {
    final preview = await importer.preview([
      const BggCollectionItem(objectId: '5', name: 'Race'),
    ]);
    await database.upsertBggGame(
      bggId: '5',
      names: const GameNames(primary: 'Race'),
    );
    final summary = await importer.importItems(preview);

    expect(summary.registered, 0);
    expect(summary.skipped, 1);
    expect(api.fetchThingIds, isEmpty);
  });

  test('cancel stops safely with partial results', () async {
    api.thingXmlById['1'] = _thingXml(id: '1', title: 'One');
    api.thingXmlById['2'] = _thingXml(id: '2', title: 'Two');
    var checks = 0;

    final preview = await importer.preview([
      const BggCollectionItem(objectId: '1', name: 'One'),
      const BggCollectionItem(objectId: '2', name: 'Two'),
    ]);
    final summary = await importer.importItems(
      preview,
      shouldCancel: () => checks++ > 0,
    );

    expect(summary.registered, 1);
    expect(summary.canceled, isTrue);
    expect(api.fetchThingIds, ['1']);
  });

  test(
    'five consecutive failures stop the import with partial summary',
    () async {
      for (var id = 1; id <= 6; id += 1) {
        api.errors['$id'] = StateError('boom $id');
      }

      final preview = await importer.preview([
        for (var id = 1; id <= 6; id += 1)
          BggCollectionItem(objectId: '$id', name: 'Game $id'),
      ]);
      final summary = await importer.importItems(preview);

      expect(summary.failed, AppConstants.bggImportConsecutiveFailureLimit);
      expect(summary.stoppedByFailureLimit, isTrue);
      expect(
        summary.failures,
        hasLength(AppConstants.bggImportConsecutiveFailureLimit),
      );
      expect(api.fetchThingIds, ['1', '2', '3', '4', '5']);
    },
  );
}

String _thingXml({required String id, required String title}) {
  return '''
<items>
  <item id="$id">
    <name type="primary" value="$title" />
  </item>
</items>
''';
}

class FakeBggApi implements BggApi {
  final Map<String, String> thingXmlById = {};
  final Map<String, Object> errors = {};
  final List<String> fetchThingIds = [];
  Future<void> Function(String id)? beforeFetch;

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
    await beforeFetch?.call(id);
    fetchThingIds.add(id);
    final error = errors[id];
    if (error != null) {
      throw error;
    }
    return thingXmlById[id] ?? _thingXml(id: id, title: 'Game $id');
  }

  @override
  Future<String> searchGames({required String query, bool exact = false}) {
    throw UnimplementedError();
  }
}

class FixedTokenProvider implements BggTokenProvider {
  const FixedTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}
