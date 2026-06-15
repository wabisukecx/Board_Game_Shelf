import '../../core/constants.dart';
import '../bgg/bgg_xml_parser.dart';
import '../db/app_database.dart';
import 'bgg_registration_repository.dart';

class BggCollectionImporter {
  const BggCollectionImporter({
    required AppDatabase database,
    required BggRegistrationRepository registrationRepository,
  }) : _database = database,
       _registrationRepository = registrationRepository;

  final AppDatabase _database;
  final BggRegistrationRepository _registrationRepository;

  Future<BggImportPreview> preview(List<BggCollectionItem> items) async {
    final entries = <BggImportPreviewItem>[];
    for (final item in items) {
      entries.add(
        BggImportPreviewItem(
          item: item,
          alreadyRegistered: await _database.findGame(item.objectId) != null,
        ),
      );
    }
    return BggImportPreview(entries: entries);
  }

  Future<BggImportSummary> importItems(
    BggImportPreview preview, {
    bool Function()? shouldCancel,
    void Function(BggImportProgress progress)? onProgress,
  }) async {
    var registered = 0;
    var skipped = preview.existingCount;
    var failed = 0;
    var consecutiveFailures = 0;
    var processed = 0;
    var canceled = false;
    var stoppedByFailureLimit = false;
    final failures = <BggImportFailure>[];
    final targets = preview.newItems;

    for (final entry in targets) {
      if (shouldCancel?.call() ?? false) {
        canceled = true;
        break;
      }
      onProgress?.call(
        BggImportProgress(
          done: processed,
          total: targets.length,
          currentTitle: entry.item.displayTitle,
        ),
      );
      try {
        final result = await _registrationRepository.registerBggId(
          entry.item.objectId,
        );
        switch (result) {
          case BggRegistrationCreated():
            registered += 1;
          case BggRegistrationAlreadyExists():
            skipped += 1;
        }
        consecutiveFailures = 0;
      } catch (error) {
        failed += 1;
        consecutiveFailures += 1;
        failures.add(
          BggImportFailure(
            objectId: entry.item.objectId,
            title: entry.item.displayTitle,
            message: '$error',
          ),
        );
        if (consecutiveFailures >=
            AppConstants.bggImportConsecutiveFailureLimit) {
          stoppedByFailureLimit = true;
          processed += 1;
          break;
        }
      }
      processed += 1;
    }

    onProgress?.call(BggImportProgress(done: processed, total: targets.length));

    return BggImportSummary(
      registered: registered,
      skipped: skipped,
      failed: failed,
      canceled: canceled,
      stoppedByFailureLimit: stoppedByFailureLimit,
      failures: failures,
    );
  }
}

class BggImportPreview {
  const BggImportPreview({required this.entries});

  final List<BggImportPreviewItem> entries;

  int get totalCount => entries.length;

  int get existingCount =>
      entries.where((entry) => entry.alreadyRegistered).length;

  int get newCount => entries.length - existingCount;

  List<BggImportPreviewItem> get newItems => [
    for (final entry in entries)
      if (!entry.alreadyRegistered) entry,
  ];
}

class BggImportPreviewItem {
  const BggImportPreviewItem({
    required this.item,
    required this.alreadyRegistered,
  });

  final BggCollectionItem item;
  final bool alreadyRegistered;
}

class BggImportProgress {
  const BggImportProgress({
    required this.done,
    required this.total,
    this.currentTitle,
  });

  final int done;
  final int total;
  final String? currentTitle;
}

class BggImportSummary {
  const BggImportSummary({
    required this.registered,
    required this.skipped,
    required this.failed,
    required this.canceled,
    required this.stoppedByFailureLimit,
    required this.failures,
  });

  final int registered;
  final int skipped;
  final int failed;
  final bool canceled;
  final bool stoppedByFailureLimit;
  final List<BggImportFailure> failures;
}

class BggImportFailure {
  const BggImportFailure({
    required this.objectId,
    required this.title,
    required this.message,
  });

  final String objectId;
  final String title;
  final String message;
}

extension BggCollectionItemDisplay on BggCollectionItem {
  String get displayTitle {
    final title = name.trim();
    return title.isEmpty ? objectId : title;
  }
}
