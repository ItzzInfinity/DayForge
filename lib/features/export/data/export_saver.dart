import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Gets an exported document out of the app. Same platform-interface pattern
/// as FirestoreGateway: desktop gets a save-as dialog, Android gets the share
/// sheet (a raw file path is useless there), tests get a fake.
abstract class ExportSaver {
  /// Returns where the export went (a path, or 'shared'); null = cancelled.
  Future<String?> save({required String fileName, required String content});
}

/// Linux/Windows: native save-as dialog via file_selector.
class DesktopExportSaver implements ExportSaver {
  @override
  Future<String?> save({
    required String fileName,
    required String content,
  }) async {
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return null;
    await File(location.path).writeAsString(content);
    return location.path;
  }
}

/// Android: write to the app cache and hand the file to the share sheet
/// (Drive, email, Files, …) — the standard way to get data off-device.
class ShareExportSaver implements ExportSaver {
  @override
  Future<String?> save({
    required String fileName,
    required String content,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: fileName),
    );
    if (result.status == ShareResultStatus.dismissed) return null;
    return 'shared';
  }
}
