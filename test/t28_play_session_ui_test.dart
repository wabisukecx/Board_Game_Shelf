import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bg_shelf_scanner/src/app/providers.dart';
import 'package:bg_shelf_scanner/src/core/constants.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_api_client.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_relationship_source.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_token_provider.dart';
import 'package:bg_shelf_scanner/src/data/bgg/bgg_xml_parser.dart';
import 'package:bg_shelf_scanner/src/data/db/app_database.dart';
import 'package:bg_shelf_scanner/src/data/repo/bgg_registration_repository.dart';
import 'package:bg_shelf_scanner/src/data/repo/play_session_repository.dart';
import 'package:bg_shelf_scanner/src/domain/game_names.dart';
import 'package:bg_shelf_scanner/src/i18n/i18n.dart';
import 'package:bg_shelf_scanner/src/ui/pages/game_detail_page.dart';
import 'package:bg_shelf_scanner/src/ui/pages/play_session_form_page.dart';

void main() {
  late AppDatabase database;
  late I18n i18n;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    i18n = I18n.fromJsonString(File('assets/i18n/en.json').readAsStringSync());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('base game detail shows play sessions and add action', (
    tester,
  ) async {
    await _insertGame(database, key: '13', title: 'CATAN');

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const GameDetailPage(gameKey: '13'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play sessions'), findsOneWidget);
    expect(find.text('No play sessions yet'), findsOneWidget);
    expect(find.text('Add play session'), findsOneWidget);
  });

  testWidgets('expansion detail only shows the play session notice', (
    tester,
  ) async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '1301',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const GameDetailPage(gameKey: '1301'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Play sessions'), findsOneWidget);
    expect(
      find.text('Record play sessions from the base game.'),
      findsOneWidget,
    );
    expect(find.text('Add play session'), findsNothing);
  });

  testWidgets('game detail opens expansion candidates on explicit action', (
    tester,
  ) async {
    await _insertGame(database, key: '13', title: 'CATAN');
    final repository = BggRegistrationRepository(
      database: database,
      api: const _UnusedBggApi(),
      parser: const BggXmlParser(),
      relationshipSource: const _FixedRelationshipSource([
        NamedBggValue(name: 'Seafarers', bggId: '111'),
      ]),
      tokenProvider: const _FixedTokenProvider(),
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        registrationRepository: repository,
        child: const GameDetailPage(gameKey: '13'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Check expansion candidates'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Check expansion candidates'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Expansion candidates'), findsOneWidget);
    expect(find.text('Seafarers'), findsOneWidget);
  });

  testWidgets('detail hides descriptions and translation action', (
    tester,
  ) async {
    await _insertGame(
      database,
      key: '13',
      title: 'CATAN',
      description: 'Original BGG description',
      descriptionJa: '日本語の説明',
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const GameDetailPage(gameKey: '13'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Refresh info'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Original BGG description'), findsNothing);
    expect(find.text('日本語の説明'), findsNothing);
    expect(find.text('Translate description'), findsNothing);
    expect(find.text('Refresh info'), findsOneWidget);
    expect(find.text('Check expansion candidates'), findsOneWidget);
  });

  testWidgets('form saves a session with selected expansions', (tester) async {
    await _insertGame(database, key: '13', title: 'CATAN');
    await _insertGame(
      database,
      key: '1301',
      title: 'Seafarers',
      gameKind: AppConstants.gameKindExpansion,
      parentGameKey: '13',
    );

    await tester.pumpWidget(
      _wrap(
        database: database,
        i18n: i18n,
        child: const PlaySessionFormPage(gameKey: '13'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seafarers'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField).at(0), '4');
    await tester.enterText(find.byType(TextField).at(1), '75');
    await tester.scrollUntilVisible(
      find.byType(FilledButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    final records = await PlaySessionRepository(
      database: database,
    ).listForGame('13');
    expect(records, hasLength(1));
    expect(records.single.playerCount, 4);
    expect(records.single.actualPlayingTime, 75);
    expect(records.single.expansionGameKeys, ['1301']);
  });
}

Widget _wrap({
  required AppDatabase database,
  required I18n i18n,
  required Widget child,
  BggRegistrationRepository? registrationRepository,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      i18nProvider.overrideWithValue(i18n),
      if (registrationRepository != null)
        bggRegistrationRepositoryProvider.overrideWithValue(
          registrationRepository,
        ),
    ],
    child: MaterialApp(home: child),
  );
}

class _FixedRelationshipSource implements BggRelationshipSource {
  const _FixedRelationshipSource(this.candidates);

  final List<NamedBggValue> candidates;

  @override
  Future<List<NamedBggValue>> registrationCandidates(String bggId) async {
    return candidates;
  }
}

class _FixedTokenProvider implements BggTokenProvider {
  const _FixedTokenProvider();

  @override
  Future<String?> readToken() async => 'token';
}

class _UnusedBggApi implements BggApi {
  const _UnusedBggApi();

  @override
  Future<String> collection({
    required String username,
    bool own = true,
    String subtype = 'boardgame',
  }) {
    throw UnimplementedError();
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

Future<void> _insertGame(
  AppDatabase database, {
  required String key,
  required String title,
  String gameKind = AppConstants.gameKindBase,
  String? parentGameKey,
  String? description,
  String? descriptionJa,
}) {
  return database.upsertBggGame(
    bggId: key,
    names: GameNames(primary: title),
    gameKind: gameKind,
    parentGameKey: parentGameKey,
    description: description,
    descriptionJa: descriptionJa,
  );
}
