import 'dart:io';

import 'package:beatscratch_flutter_redux/my_platform.dart';

import 'fake_js.dart'
if(dart.library.js) 'dart:js';

import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'generated/protos/music.pb.dart';
import 'dummydata.dart';
import 'url_conversions.dart';

class ScoreManager {
  Function(Score) doOpenScore;
  Directory _scoresDirectory;
  SharedPreferences _prefs;

  String get currentScoreName => _prefs?.getString('currentScoreName') ?? "Untitled Score";

  set currentScoreName(String value) => _prefs?.setString("currentScoreName", value);

  File get _currentScoreFile => File("${_scoresDirectory.path}/${Uri.encodeComponent(currentScoreName)}.beatscratch");

  List<FileSystemEntity> get scoreFiles {
    if (_scoresDirectory != null) {
      List<FileSystemEntity> result = _scoresDirectory?.listSync();
      result.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return result;
    }
    return [];
  }

  ScoreManager() {
    _initialize();
  }

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();

    if(MyPlatform.isWeb) {
      loadUrlScoreIntoUI();
    } else {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      _scoresDirectory = Directory("${documentsDirectory.path}/scores}");
      _scoresDirectory.createSync();
      loadCurrentScoreIntoUI();
    }
  }

  createScore(String name, { Score score }) {
    score = score ?? defaultScore();
    currentScoreName = name;
    saveCurrentScore(score);
    doOpenScore(score);
  }

  saveCurrentScore(Score score) async {
    _currentScoreFile.writeAsBytes(score.clone().writeToBuffer());
  }

  openScore(File file) async {
    currentScoreName = file.scoreName;
    loadCurrentScoreIntoUI();
  }

  loadCurrentScoreIntoUI() async {
    Score score;
    try {
      score = await loadCurrentScore();
    } catch(e) {
      score = defaultScore();
    }
    doOpenScore(score);
  }
  
  loadUrlScoreIntoUI() async {
    String data = context.callMethod('getPageHashValueOnLoad', []);
    data = data.replaceFirst("score=", "");
    Score score;
    try {
      score = scoreFromUrlHashValue(data);
    } catch(any) {
      score = defaultScore();
    }
    doOpenScore(score);
  }

  Future<Score> loadCurrentScore() async => loadScore(_currentScoreFile);
  Future<Score> loadScore(File file) async => Score.fromBuffer(file.readAsBytesSync());
}

extension ScoreName on FileSystemEntity {
  String get scoreName {
    String fileName = path.split("/")?.last ?? ".beatscratch";
    fileName = fileName.substring(0, fileName.length - 12);
    String scoreName = Uri.decodeComponent(fileName);
    return scoreName;
  }
}
