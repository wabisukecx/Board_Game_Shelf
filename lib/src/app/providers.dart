import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/backup/backup_service.dart';
import '../data/bgg/bgg_api_client.dart';
import '../data/bgg/bgg_transport.dart';
import '../data/bgg/bgg_xml_parser.dart';
import '../data/db/app_database.dart';
import '../data/export/yaml_exporter.dart';
import '../data/gameupc/game_upc_client.dart';
import '../data/repo/barcode_map_repository.dart';
import '../data/repo/bgg_collection_importer.dart';
import '../data/repo/bgg_collection_repository.dart';
import '../data/repo/bgg_registration_repository.dart';
import '../data/repo/box_recognition_repository.dart';
import '../data/repo/collection_repository.dart';
import '../data/repo/information_update_repository.dart';
import '../data/repo/local_game_repository.dart';
import '../data/repo/play_session_repository.dart';
import '../data/repo/shelf_recognition_repository.dart';
import '../data/settings/secret_store.dart';
import '../data/settings/secure_settings_repository.dart';
import '../data/translation/gemini_translation_service.dart';
import '../data/vision/gemini_vision_service.dart';
import '../domain/collection_analytics.dart';
import '../domain/complexity_tables.dart';
import '../domain/learning_curve.dart';
import '../domain/play_analytics.dart';
import '../i18n/i18n.dart';

/// Overridden in [main] (and in tests) with the loaded locale bundle.
final i18nProvider = Provider<I18n>((ref) {
  throw UnimplementedError('i18nProvider must be overridden');
});

/// Single application database instance. Overridden with an in-memory database
/// in widget tests.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());
final sleeperProvider = Provider<Sleeper>((ref) => const RealSleeper());
final jitterProvider = Provider<Jitter>((ref) => RandomJitter());

final secretStoreProvider = Provider<SecretStore>(
  (ref) => FlutterSecureSecretStore(),
);

final secureSettingsProvider = Provider<SecureSettingsRepository>(
  (ref) =>
      SecureSettingsRepository(secretStore: ref.watch(secretStoreProvider)),
);

final gameUpcClientProvider = Provider<GameUpcClient>(
  (ref) => DioGameUpcClient(),
);

final tokenGuideProvider = Provider<TokenAcquisitionGuide>(
  (ref) => const TokenAcquisitionGuide(),
);

final bggTransportProvider = Provider<BggTransport>((ref) => DioBggTransport());

final bggParserProvider = Provider<BggXmlParser>((ref) => const BggXmlParser());

final bggApiProvider = Provider<BggApi>((ref) {
  return BggApiClient(
    database: ref.watch(appDatabaseProvider),
    transport: ref.watch(bggTransportProvider),
    clock: ref.watch(clockProvider),
    sleeper: ref.watch(sleeperProvider),
    jitter: ref.watch(jitterProvider),
    tokenProvider: ref.watch(secureSettingsProvider),
  );
});

final bggRegistrationRepositoryProvider = Provider<BggRegistrationRepository>((
  ref,
) {
  return BggRegistrationRepository(
    database: ref.watch(appDatabaseProvider),
    api: ref.watch(bggApiProvider),
    parser: ref.watch(bggParserProvider),
    tokenProvider: ref.watch(secureSettingsProvider),
  );
});

final bggCollectionRepositoryProvider = Provider<BggCollectionRepository>((
  ref,
) {
  return BggCollectionRepository(
    api: ref.watch(bggApiProvider),
    parser: ref.watch(bggParserProvider),
  );
});

final bggCollectionImporterProvider = Provider<BggCollectionImporter>((ref) {
  return BggCollectionImporter(
    database: ref.watch(appDatabaseProvider),
    registrationRepository: ref.watch(bggRegistrationRepositoryProvider),
  );
});

final localGameRepositoryProvider = Provider<LocalGameRepository>(
  (ref) => LocalGameRepository(database: ref.watch(appDatabaseProvider)),
);

final collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => CollectionRepository(
    database: ref.watch(appDatabaseProvider),
    playSessions: ref.watch(playSessionRepositoryProvider),
  ),
);

final playSessionRepositoryProvider = Provider<PlaySessionRepository>(
  (ref) => PlaySessionRepository(database: ref.watch(appDatabaseProvider)),
);

final playSessionListProvider = FutureProvider.autoDispose
    .family<List<PlaySessionRecord>, String>((ref, gameKey) {
      return ref.watch(playSessionRepositoryProvider).listForGame(gameKey);
    });

final playSessionListAllProvider =
    FutureProvider.autoDispose<List<PlaySessionRecord>>((ref) {
      return ref.watch(playSessionRepositoryProvider).listAll();
    });

final barcodeMapRepositoryProvider = Provider<BarcodeMapRepository>((ref) {
  return BarcodeMapRepository(
    database: ref.watch(appDatabaseProvider),
    clock: ref.watch(clockProvider),
  );
});

final informationUpdateRepositoryProvider =
    Provider<InformationUpdateRepository>((ref) {
      return InformationUpdateRepository(
        database: ref.watch(appDatabaseProvider),
        api: ref.watch(bggApiProvider),
        parser: ref.watch(bggParserProvider),
        clock: ref.watch(clockProvider),
      );
    });

final translationClientProvider = Provider<TranslationClient>(
  (ref) => GeminiTranslationClient(),
);

final descriptionTranslationRepositoryProvider =
    Provider<DescriptionTranslationRepository>((ref) {
      return DescriptionTranslationRepository(
        database: ref.watch(appDatabaseProvider),
        settings: ref.watch(secureSettingsProvider),
        client: ref.watch(translationClientProvider),
      );
    });

final visionClientProvider = Provider<VisionClient>(
  (ref) => GeminiVisionClient(),
);

final boxRecognitionRepositoryProvider = Provider<BoxRecognitionRepository>(
  (ref) => BoxRecognitionRepository(
    settings: ref.watch(secureSettingsProvider),
    client: ref.watch(visionClientProvider),
  ),
);

final shelfRecognitionRepositoryProvider = Provider<ShelfRecognitionRepository>(
  (ref) => ShelfRecognitionRepository(
    settings: ref.watch(secureSettingsProvider),
    client: ref.watch(visionClientProvider),
  ),
);

final yamlExporterProvider = Provider<YamlExporter>(
  (ref) => YamlExporter(database: ref.watch(appDatabaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(clock: ref.watch(clockProvider)),
);

final complexityTablesProvider = FutureProvider<ComplexityTables>(
  (ref) => ComplexityTables.load(),
);

final learningCurveAnalyzerProvider = FutureProvider<LearningCurveAnalyzer>((
  ref,
) async {
  return LearningCurveAnalyzer(
    tables: await ref.watch(complexityTablesProvider.future),
    clock: ref.watch(clockProvider),
  );
});

/// Current collection list filter (S-01). Editing it re-runs
/// [collectionListProvider].
final collectionFilterProvider = StateProvider<CollectionFilter>(
  (ref) => const CollectionFilter(),
);

final collectionSortOrderProvider = StateProvider<CollectionSortOrder>(
  (ref) => CollectionSortOrder.name,
);

final collectionListProvider =
    FutureProvider.autoDispose<List<CollectionListItem>>((ref) {
      final filter = ref.watch(collectionFilterProvider);
      final sortOrder = ref.watch(collectionSortOrderProvider);
      return ref
          .watch(collectionRepositoryProvider)
          .list(filter: filter, sortOrder: sortOrder);
    });

final collectionFacetsProvider = FutureProvider.autoDispose<CollectionFacets>((
  ref,
) {
  return ref.watch(collectionRepositoryProvider).facets();
});

final analyticsIncludeNotOwnedProvider = StateProvider<bool>((ref) => false);

final analyticsProvider = FutureProvider.autoDispose<AnalyticsSummary>((
  ref,
) async {
  final includeNotOwned = ref.watch(analyticsIncludeNotOwnedProvider);
  final analyzer = await ref.watch(learningCurveAnalyzerProvider.future);
  final items = await ref
      .watch(collectionRepositoryProvider)
      .list(filter: const CollectionFilter());
  return const CollectionAnalytics().summarize(
    items,
    includeNotOwned: includeNotOwned,
    analyzer: analyzer,
  );
});

final playAnalyticsProvider = FutureProvider.autoDispose<PlayAnalyticsSummary>((
  ref,
) async {
  final items = await ref
      .watch(collectionRepositoryProvider)
      .list(filter: const CollectionFilter());
  final sessions = await ref.watch(playSessionListAllProvider.future);
  return const PlayAnalytics().summarize(items, sessions);
});

/// Read model for the detail screen (S-04): the BGG-derived game plus its
/// collection metadata row.
class GameDetail {
  const GameDetail({required this.game, required this.collection});

  final Game game;
  final CollectionEntry? collection;
}

final gameDetailProvider = FutureProvider.autoDispose
    .family<GameDetail, String>((ref, gameKey) async {
      final database = ref.watch(appDatabaseProvider);
      final game = await database.findGame(gameKey);
      if (game == null) {
        throw StateError('Game not found: $gameKey');
      }
      final collection = await database.findCollection(gameKey);
      return GameDetail(game: game, collection: collection);
    });
