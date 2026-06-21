import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_relationship_source.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_token_provider.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_registration_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';

void main() {
  late AppDatabase database;
  late _FakeBggApi api;
  late _FakeRelationshipSource relationshipSource;
  late BggRegistrationRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    api = _FakeBggApi();
    relationshipSource = _FakeRelationshipSource();
    repository = BggRegistrationRepository(
      database: database,
      api: api,
      parser: const BggXmlParser(),
      relationshipSource: relationshipSource,
      tokenProvider: const _FixedTokenProvider('token'),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'registers expansion with parent key even when parent is missing',
    () async {
      api.thingXml = _thingXml(
        id: '111',
        title: 'Seafarers',
        itemType: AppConstants.bggExpansionLinkType,
        parentId: '13',
        parentName: 'CATAN',
      );

      final result = await repository.registerBggId('111');

      expect(result.game.gameKind, AppConstants.gameKindExpansion);
      expect(result.game.parentGameKey, '13');
      expect(await database.findGame('13'), isNull);
    },
  );

  test('fetches only unregistered expansion candidates on demand', () async {
    await database.upsertBggGame(
      bggId: '222',
      names: const GameNames(primary: 'Already Registered Expansion'),
    );
    api.thingXml = _thingXml(id: '13', title: 'CATAN');
    relationshipSource.candidates = const [
      NamedBggValue(name: 'Seafarers', bggId: '111'),
      NamedBggValue(name: 'Already Registered Expansion', bggId: '222'),
    ];

    final result = await repository.registerBggId('13');
    final candidates = await repository.fetchExpansionCandidates('13');

    expect(result.game.gameKind, AppConstants.gameKindBase);
    expect(result.game.parentGameKey, isNull);
    expect(candidates, hasLength(1));
    expect(candidates.single.bggId, '111');
    expect(relationshipSource.calls, 1);
  });

  test(
    'uses the explicit relationship source instead of XML link direction',
    () async {
      api.thingXml = '''
<items>
  <item type="boardgameexpansion" id="355958">
    <name type="primary" value="Dominion: Seaside (Second Edition)" />
    <link type="boardgameexpansion" id="36218" value="Dominion" inbound="true" />
  </item>
</items>
''';
      relationshipSource.candidates = const [
        NamedBggValue(name: 'Dominion', bggId: '36218'),
        NamedBggValue(name: 'Dominion: Second Edition', bggId: '209418'),
      ];
      api.responses['36218'] = _thingXml(id: '36218', title: 'Dominion');
      api.responses['209418'] = _thingXml(
        id: '209418',
        title: 'Dominion: Second Edition',
      );

      final result = await repository.registerBggId('355958');

      final created = result as BggRegistrationCreated;
      expect(created.game.parentGameKey, isNull);
      expect(created.parentCandidates.map((candidate) => candidate.bggId), [
        '36218',
        '209418',
      ]);
      final candidates = await repository.fetchExpansionCandidates('355958');
      expect(candidates.map((candidate) => candidate.bggId), [
        '36218',
        '209418',
      ]);
    },
  );

  test('automatically selects the only confirmed parent candidate', () async {
    api.thingXml = _thingXml(
      id: '111',
      title: 'Expansion',
      itemType: AppConstants.bggExpansionLinkType,
    );
    relationshipSource.candidates = const [
      NamedBggValue(name: 'Base game', bggId: '13'),
    ];
    api.responses['13'] = _thingXml(id: '13', title: 'Base game');

    final result = await repository.registerBggId('111');

    expect(result.game.parentGameKey, '13');
    expect((result as BggRegistrationCreated).parentCandidates, isEmpty);
  });

  test(
    'already existing registration does not fetch thing or expose candidates',
    () async {
      await database.upsertBggGame(
        bggId: '13',
        names: const GameNames(primary: 'CATAN'),
      );

      final result = await repository.registerBggId('13');

      expect(result, isA<BggRegistrationAlreadyExists>());
      expect(api.fetchThingCalls, 0);
    },
  );

  test(
    'filters self duplicate empty and already registered candidates',
    () async {
      await database.upsertBggGame(
        bggId: '222',
        names: const GameNames(primary: 'Already registered'),
      );
      relationshipSource.candidates = const [
        NamedBggValue(name: 'Self', bggId: '13'),
        NamedBggValue(name: 'Candidate', bggId: '111'),
        NamedBggValue(name: 'Duplicate', bggId: '111'),
        NamedBggValue(name: 'Registered', bggId: '222'),
        NamedBggValue(name: 'Empty', bggId: ''),
        NamedBggValue(name: 'Missing ID'),
      ];

      final candidates = await repository.fetchExpansionCandidates('13');

      expect(candidates.map((candidate) => candidate.bggId), ['111']);
    },
  );

  test(
    'base game registration does not fetch relationship candidates',
    () async {
      api.thingXml = _thingXml(id: '13', title: 'CATAN');
      relationshipSource.candidates = const [
        NamedBggValue(name: 'Seafarers', bggId: '111'),
      ];

      await repository.registerBggId('13');

      expect(relationshipSource.calls, 0);
    },
  );

  test(
    'keeps boardgame item as base even with expansion relationship links',
    () async {
      api.thingXml = _thingXml(
        id: '41002',
        title: 'Architects of the West Kingdom',
        itemType: 'boardgame',
        expansions: const {'41003': 'German edition'},
      );

      final details = const BggXmlParser().parseThing(api.thingXml);
      final kind = resolveGameKind(details);

      expect(kind.gameKind, AppConstants.gameKindBase);
      expect(kind.parentGameKey, isNull);

      final result = await repository.registerBggId('41002');

      expect(result.game.gameKind, AppConstants.gameKindBase);
      expect(result.game.parentGameKey, isNull);
    },
  );

  test('resolves boardgameexpansion item with parent as expansion', () {
    final details = const BggXmlParser().parseThing(
      _thingXml(
        id: '111',
        title: 'Seafarers',
        itemType: AppConstants.bggExpansionLinkType,
        parentId: '13',
        parentName: 'CATAN',
      ),
    );

    final kind = resolveGameKind(details);

    expect(kind.gameKind, AppConstants.gameKindExpansion);
    expect(kind.parentGameKey, '13');
  });

  test(
    'prefers fetched boardgame candidate as parent for ambiguous expansion links',
    () async {
      api.responses['455953'] = _thingXml(
        id: '455953',
        title: 'Nucleum: Gibraltar',
        itemType: AppConstants.bggExpansionLinkType,
        parentId: '468319',
        parentName: 'Nucleum: New Military Technologies Promo',
        expansions: const {'396790': 'Nucleum'},
      );
      api.responses['468319'] = _thingXml(
        id: '468319',
        title: 'Nucleum: New Military Technologies Promo',
        itemType: AppConstants.bggExpansionLinkType,
        parentId: '455953',
        parentName: 'Nucleum: Gibraltar',
      );
      api.responses['396790'] = _thingXml(id: '396790', title: 'Nucleum');

      final result = await repository.registerBggId('455953');

      expect(result.game.gameKind, AppConstants.gameKindExpansion);
      expect(result.game.parentGameKey, '396790');
    },
  );
}

String _thingXml({
  required String id,
  required String title,
  String itemType = 'boardgame',
  String? parentId,
  String? parentName,
  Map<String, String> expansions = const {},
}) {
  return '''
<items>
  <item type="$itemType" id="$id">
    <name type="primary" value="$title" />
    ${parentId == null ? '' : '<link type="boardgameexpansion" id="$parentId" value="$parentName" />'}
    ${expansions.entries.map((entry) => '<link type="boardgameexpansion" id="${entry.key}" value="${entry.value}" inbound="true" />').join('\n')}
  </item>
</items>
''';
}

class _FakeBggApi implements BggApi {
  String thingXml = '<items />';
  final responses = <String, String>{};
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
    return responses[id] ?? thingXml;
  }

  @override
  Future<String> searchGames({required String query, bool exact = false}) {
    throw UnimplementedError();
  }
}

class _FakeRelationshipSource implements BggRelationshipSource {
  List<NamedBggValue>? candidates;
  int calls = 0;

  @override
  Future<List<NamedBggValue>> registrationCandidates(String bggId) async {
    calls += 1;
    final result = candidates;
    if (result == null) {
      throw const FormatException('unavailable');
    }
    return result;
  }
}

class _FixedTokenProvider implements BggTokenProvider {
  const _FixedTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}
