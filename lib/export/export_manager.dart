import 'dart:convert';
import 'dart:io';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/widget/my_platform.dart';

import '../util/fake_js.dart' if (dart.library.js) 'dart:js';

import 'package:beatscratch_flutter_redux/util/dummydata.dart';
import 'package:flutter/foundation.dart';
import 'package:protobuf/protobuf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../generated/protos/music.pb.dart';
import '../util/dummydata.dart';
import '../util/proto_utils.dart';
import '../util/music_theory.dart';
import 'export_models.dart';
import '../storage/url_conversions.dart';

class ExportManager {
  Directory exportsDirectory;

  File createExportFile(BSExport export) {
    String path = "${exportsDirectory.path.toString()}/${Uri.encodeComponent(export.score.name)}";
    if (export.exportedSection != null) {
      path += "-${Uri.encodeComponent(export.exportedSection.canonicalName)}";
    }
    path +="-${DateTime.now().toString().replaceAll(" ", '-').replaceAll(":", '-').split(".").first}";
    path += ".${export.exportType.toString().split(".").last}";
    File result =  File(path);
    result.createSync();
    return result;
  }

  List<FileSystemEntity> get exportFiles {
    if (exportsDirectory != null) {
      List<FileSystemEntity> result = exportsDirectory?.listSync();
      result.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return result;
    }
    return [];
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