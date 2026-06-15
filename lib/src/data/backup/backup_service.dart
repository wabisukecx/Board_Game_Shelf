import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/clock.dart';
import '../../core/constants.dart';

class BackupService {
  const BackupService({Clock clock = const SystemClock()}) : _clock = clock;

  final Clock _clock;

  String automaticBackupName({String extension = '.sqlite'}) {
    return '${_formatAutomatic(_clock.now())}$extension';
  }

  String manualBackupName({String extension = '.sqlite'}) {
    return '${AppConstants.manualBackupPrefix}'
        '${_formatManual(_clock.now())}$extension';
  }

  Future<File> copyDatabaseBackup({
    required File databaseFile,
    required Directory backupDirectory,
    required BackupKind kind,
  }) async {
    if (!await backupDirectory.exists()) {
      await backupDirectory.create(recursive: true);
    }
    final filename = switch (kind) {
      BackupKind.automatic => automaticBackupName(),
      BackupKind.manual => manualBackupName(),
    };
    return databaseFile.copy(p.join(backupDirectory.path, filename));
  }

  String _formatAutomatic(DateTime value) {
    final year = (value.year % 100).toString().padLeft(2, '0');
    return '$year${_two(value.month)}${_two(value.day)}';
  }

  String _formatManual(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}'
        '${_two(value.month)}'
        '${_two(value.day)}_'
        '${_two(value.hour)}'
        '${_two(value.minute)}'
        '${_two(value.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

enum BackupKind { automatic, manual }
