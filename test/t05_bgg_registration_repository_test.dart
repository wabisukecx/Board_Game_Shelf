import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_token_provider.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_registration_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late FakeBggApi api;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = FakeBggApi();
  });

  tearDown(() async {
    await database.close();
  });

  BggRegistrationRepository repository({String? token = 'token'}) {
    return BggRegistrationRepository(
      database: database,
      api: api,
      parser: const BggXmlParser(),
      tokenProvider: FixedTokenProvider(token),
    );
  }

  test('search returns parsed BGG candidates and passes exact flag', () async {
    api.searchXml = '''
<items>
  <item type="boardgame" id="13">
    <name type="primary" value="CATAN" />
    <yearpublished value="1995" />
  </item>
</items>
''';

    final results = await repository().search('Catan', exact: true);

    expect(results, hasLength(1));
    expect(results.single.bggId, '13');
    expect(results.single.name, 'CATAN');
    expect(results.single.yearPublished, '1995');
    expect(api.lastSearchExact, isTrue);
  });

  test(
    'token missing blocks search before network call for settings redirect',
    () async {
      await expectLater(
        repository(token: null).search('Catan'),
        throwsA(isA<BggTokenRequiredException>()),
      );

      expect(api.searchCalls, 0);
    },
  );

  test(
    'registering an existing game returns existing result without new row',
    () async {
      await database.upsertBggGame(
        bggId: '13',
        names: const GameNames(primary: 'CATAN'),
      );

      final result = await repository().registerBggId('13');

      expect(result, isA<BggRegistrationAlreadyExists>());
      expect(result.game.gameKey, '13');
      expect(api.fetchThingCalls, 0);
    },
  );

  test(
    'registering BGG details creates game and owned collection row',
    () async {
      api.thingXml = _thingXml(
        id: '13',
        primary: 'CATAN',
        japanese: 'カタンの開拓者たち',
      );

      final result = await repository().registerBggId('13');

      expect(result, isA<BggRegistrationCreated>());
      expect(result.game.gameKey, '13');
      expect(result.game.name, 'CATAN');
      expect(result.game.japaneseName, 'カタンの開拓者たち');
      expect(result.game.yearPublished, '1995');
      expect(result.game.publisherMinPlayers, 3);
      expect(result.game.publisherMaxPlayers, 4);
      expect(result.game.playingTime, 120);
      expect(result.game.weight, 2.31);
      expect(result.game.thumbnailUrl, 'https://example.test/catan.jpg');

      final collection = await database.findCollection('13');
      expect(collection, isNotNull);
      expect(collection?.owned, isTrue);
    },
  );

  test('empty title details are rejected and not registered', () async {
    api.thingXml = _thingXml(id: '99', primary: '');

    await expectLater(
      repository().registerBggId('99'),
      throwsA(isA<InvalidBggGameException>()),
    );

    expect(await database.findGame('99'), isNull);
  });

  test('placeholder title details are rejected and not registered', () async {
    api.thingXml = _thingXml(id: '100', primary: '不明なゲーム');

    await expectLater(
      repository().registerBggId('100'),
      throwsA(isA<InvalidBggGameException>()),
    );

    expect(await database.findGame('100'), isNull);
  });
}

String _thingXml({
  required String id,
  required String primary,
  String? japanese,
}) {
  return '''
<items>
  <item type="boardgame" id="$id">
    <name type="primary" value="$primary" />
    ${japanese == null ? '' : '<name type="alternate" language="ja" value="$japanese" />'}
    <yearpublished value="1995" />
    <thumbnail>https://example.test/catan.jpg</thumbnail>
    <minplayers value="3" />
    <maxplayers value="4" />
    <playingtime value="120" />
    <statistics>
      <ratings>
        <averageweight value="2.31" />
      </ratings>
    </statistics>
  </item>
</items>
''';
}

class FakeBggApi implements BggApi {
  String searchXml = '<items />';
  String thingXml = '<items />';
  int searchCalls = 0;
  int fetchThingCalls = 0;
  bool? lastSearchExact;

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
  Future<String> searchGames({
    required String query,
    bool exact = false,
  }) async {
    searchCalls += 1;
    lastSearchExact = exact;
    return searchXml;
  }
}

class FixedTokenProvider implements BggTokenProvider {
  const FixedTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}
