import 'dart:io';

import 'package:beatscratch_flutter_redux/generated/protos/protos.dart';
import 'package:beatscratch_flutter_redux/util/music_theory.dart';
import 'package:path_provider/path_provider.dart';

import '../widget/my_platform.dart';
import 'export_models.dart';

class ExportManager {
  late Directory exportsDirectory;

  File createExportFile(BSExport export) {
    String path =
        "${exportsDirectory.path.toString()}/${Uri.encodeComponent(export.score.name).replaceAll("%20", " ")}";
    Section? exportedSection = export.exportedSection;
    if (exportedSection != null) {
      path += "-${Uri.encodeComponent(exportedSection.canonicalName)}";
    }

    path +=
        "-${DateTime.now().toString().replaceAll(" ", '-').replaceAll(":", '-').split(".").first}";
    path += ".${export.exportType.toString().split(".").last}";
    File result = File(path);
    result.createSync();
    return result;
  }

  List<FileSystemEntity> get exportFiles {
    List<FileSystemEntity> result = exportsDirectory.listSync();
    result
        .sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return result;
  }

  ExportManager() {
    _initialize();
  }

  _initialize() async {
    if (!MyPlatform.isWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      exportsDirectory = Directory("${documentsDirectory.path}/Exports");
      exportsDirectory.createSync();
    }
  }
}
