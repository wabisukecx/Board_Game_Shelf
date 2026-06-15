import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_collection_repository.dart';

void main() {
  test('parses empty and multiple collection items', () {
    const parser = BggXmlParser();

    expect(parser.parseCollection('<items totalitems="0"></items>'), isEmpty);

    final items = parser.parseCollection('''
<items totalitems="2">
  <item objectid="13">
    <name>CATAN</name>
    <yearpublished>1995</yearpublished>
  </item>
  <item objectid="822">
    <name>Carcassonne</name>
  </item>
  <item>
    <name>Broken</name>
  </item>
</items>
''');

    expect(items, hasLength(2));
    expect(items.first.objectId, '13');
    expect(items.first.name, 'CATAN');
    expect(items.first.yearPublished, '1995');
    expect(items.last.objectId, '822');
    expect(items.last.yearPublished, isNull);
  });

  test(
    'repository validates username and returns parsed owned collection',
    () async {
      final api = FakeCollectionApi(
        collectionSource:
            '<items><item objectid="1"><name>One</name></item></items>',
      );
      final repository = BggCollectionRepository(
        api: api,
        parser: const BggXmlParser(),
      );

      await expectLater(
        repository.fetchOwned('  '),
        throwsA(isA<BggCollectionUsernameRequiredException>()),
      );

      final items = await repository.fetchOwned(' player ');

      expect(api.lastUsername, 'player');
      expect(items.single.objectId, '1');
      expect(items.single.name, 'One');
    },
  );

  test(
    'repository propagates API failures in a distinguishable form',
    () async {
      final repository = BggCollectionRepository(
        api: FakeCollectionApi(error: const BggApiException('offline')),
        parser: const BggXmlParser(),
      );

      await expectLater(
        repository.fetchOwned('player'),
        throwsA(isA<BggApiException>()),
      );
    },
  );
}

class FakeCollectionApi implements BggApi {
  FakeCollectionApi({this.collectionSource = '<items/>', this.error});

  final String collectionSource;
  final Object? error;
  String? lastUsername;

  @override
  Future<String> collection({
    required String username,
    bool own = true,
    String subtype = 'boardgame',
  }) async {
    lastUsername = username;
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return collectionSource;
  }

  @override
  Future<String> fetchThing({required String id, bool stats = true}) {
    throw UnimplementedError();
  }

  @override
  Future<String> searchGames({required String query, bool exact = false}) {
    throw UnimplementedError();
  }
}
