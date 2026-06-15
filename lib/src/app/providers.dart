import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
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
import '../i18n/language_catalog.dart';
import '../i18n/language_preference_repository.dart';
import '../i18n/language_resolution.dart';
import '../i18n/locale_option.dart';

final _currentI18nProvider = StateProvider<I18n?>((ref) => null);

final currentLocaleCodeProvider = StateProvider<String?>((ref) => null);

/// Current UI strings. Tests can still override this directly.
final i18nProvider = Provider<I18n>((ref) {
  final i18n = ref.watch(_currentI18nProvider);
  if (i18n == null) {
    throw StateError('i18nProvider is not ready yet');
  }
  return i18n;
});

final languageCatalogProvider = Provider<LanguageCatalog>(
  (ref) => LanguageCatalog(),
);

final localeOptionsProvider = FutureProvider<List<LocaleOption>>((ref) {
  return ref.watch(languageCatalogProvider).load();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final languagePreferenceRepositoryProvider =
    FutureProvider<LanguagePreferenceRepository>((ref) async {
      return LanguagePreferenceRepository(
        preferences: await ref.watch(sharedPreferencesProvider.future),
      );
    });

final languagePreferenceProvider =
    AsyncNotifierProvider<LanguagePreferenceController, String>(
      LanguagePreferenceController.new,
    );

final languageBootstrapProvider = FutureProvider<I18n>((ref) async {
  final options = await ref.watch(localeOptionsProvider.future);
  final preference = await ref.watch(languagePreferenceProvider.future);
  final locale = resolveLocaleOption(
    preference: preference,
    options: options,
    systemLocaleCodes: _systemLocaleCodes(),
  );
  final source = await rootBundle.loadString(locale.assetPath);
  final i18n = I18n.fromJsonString(source);
  ref.read(_currentI18nProvider.notifier).state = i18n;
  ref.read(currentLocaleCodeProvider.notifier).state = locale.localeCode;
  return i18n;
});

class LanguagePreferenceController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repository = await ref.watch(
      languagePreferenceRepositoryProvider.future,
    );
    return await repository.read() ?? LanguagePreferenceRepository.systemValue;
  }

  Future<void> select(String localeCode) async {
    state = AsyncData(localeCode);
    final repository = await ref.read(
      languagePreferenceRepositoryProvider.future,
    );
    await repository.save(localeCode);
  }

  Future<void> useSystem() async {
    state = const AsyncData(LanguagePreferenceRepository.systemValue);
    final repository = await ref.read(
      languagePreferenceRepositoryProvider.future,
    );
    await repository.save(LanguagePreferenceRepository.systemValue);
  }
}

List<String> _systemLocaleCodes() {
  return [
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales)
      locale.countryCode == null || locale.countryCode!.isEmpty
          ? locale.languageCode
          : '${locale.languageCode}-${locale.countryCode}',
  ];
}

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
      final localeCode =
          ref.watch(currentLocaleCodeProvider) ??
          AppConstants.fallbackLocaleCode;
      final t = ref.watch(i18nProvider);
      return ref
          .watch(collectionRepositoryProvider)
          .list(
            filter: filter,
            sortOrder: sortOrder,
            displayLocaleCode: localeCode,
            fallbackDisplayName: t.t('game.nameUnknown'),
          );
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
  final localeCode =
      ref.watch(currentLocaleCodeProvider) ?? AppConstants.fallbackLocaleCode;
  final t = ref.watch(i18nProvider);
  final items = await ref
      .watch(collectionRepositoryProvider)
      .list(
        filter: const CollectionFilter(),
        displayLocaleCode: localeCode,
        fallbackDisplayName: t.t('game.nameUnknown'),
      );
  return const CollectionAnalytics().summarize(
    items,
    includeNotOwned: includeNotOwned,
    analyzer: analyzer,
  );
});

final playAnalyticsProvider = FutureProvider.autoDispose<PlayAnalyticsSummary>((
  ref,
) async {
  final localeCode =
      ref.watch(currentLocaleCodeProvider) ?? AppConstants.fallbackLocaleCode;
  final t = ref.watch(i18nProvider);
  final items = await ref
      .watch(collectionRepositoryProvider)
      .list(
        filter: const CollectionFilter(),
        displayLocaleCode: localeCode,
        fallbackDisplayName: t.t('game.nameUnknown'),
      );
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
