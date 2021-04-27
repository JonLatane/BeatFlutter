import 'package:beatscratch_flutter_redux/storage/score_manager.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../util/dummydata.dart';
import '../util/proto_utils.dart';
import '../widget/my_platform.dart';
import 'url_conversions.dart';

class UniverseManager {
  Function(Score) doOpenScore;
  Directory scoresDirectory;
  SharedPreferences _prefs;

  UniverseManager() {
    _initialize();
  }
  String get currentUniverseScore =>
      _prefs?.getString('currentUniverseScore') ?? "";

  set currentUniverseScore(String value) =>
      _prefs?.setString("currentUniverseScore", value);

  String get redditRefreshToken =>
      _prefs?.getString('redditRefreshToken') ?? "";

  set redditRefreshToken(String value) =>
      _prefs?.setString("redditRefreshToken", value);

  String get redditAccessToken => _prefs?.getString('redditAccessToken') ?? "";

  set redditAccessToken(String value) =>
      _prefs?.setString("redditAccessToken", value);

  String get redditUsername => _prefs?.getString('redditUsername') ?? "";

  set redditUsername(String value) =>
      _prefs?.setString("redditUsername", value);

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // if (!MyPlatform.isWeb) {
    //   Directory documentsDirectory = await getApplicationDocumentsDirectory();
    //   final scoresPath = "${documentsDirectory.path}/$scoresDirectoryName";
    //   scoresDirectory = Directory(scoresPath);
    //   scoresDirectory.createSync();
    // }
  }

  // String get scoresDirectoryName => "Universe";

  // FileSystemEntity fileForUrl(String url) => File(
  //     "${scoresDirectory.path}/${Uri.encodeComponent(currentScoreName)}.beatscratch");
}
