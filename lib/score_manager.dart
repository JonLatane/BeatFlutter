import 'dart:io';

import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/protos/music.pb.dart';


class ScoreManager {
  Directory _documentsDirectory;
  SharedPreferences _prefs;
  String get currentScoreName => _prefs.getString('currentScoreName') ?? "Untitled Score";

  List<FileSystemEntity> get files => _documentsDirectory?.listSync() ?? [];

  ScoreManager() {
    _getLocalPath();
  }

  _getLocalPath() async {
    _documentsDirectory = await getApplicationDocumentsDirectory();
    _prefs = await SharedPreferences.getInstance();
  }

  File get currentScoreFile => File("${_documentsDirectory.path}/${Uri.encodeComponent(currentScoreName)}.beatscratch");

  Future<Score> loadCurrentScore() async {
    FileSystemEntity file = files.firstWhere((f) => f.path.endsWith("${Uri.encodeComponent(currentScoreName)}.beatscratch"), orElse: null);
    if (file != null) {
      final data = File(file.path).readAsBytesSync();
      return Score.fromBuffer(data);
    } else {
      return defaultScore();
    }
  }

  saveCurrentScore(Score score) async {
    currentScoreFile.writeAsBytes(score.clone().writeToBuffer());
  }
}
