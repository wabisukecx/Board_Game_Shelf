import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/export/yaml_exporter.dart';

/// Writes [YamlExportFile]s to a stable on-device directory so the user can
/// retrieve them, then exposes the written paths for the OS share sheet.
class ExportWriter {
  const ExportWriter();

  static const String directoryName = 'bg_shelf_exports';

  Future<Directory> exportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, directoryName));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<List<File>> write(List<YamlExportFile> files) async {
    final directory = await exportDirectory();
    final written = <File>[];
    for (final file in files) {
      final target = File(p.join(directory.path, file.filename));
      await target.writeAsString(file.content);
      written.add(target);
    }
    return written;
  }
}
