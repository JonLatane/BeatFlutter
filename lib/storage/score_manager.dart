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
import 'url_conversions.dart';


/// ScoreManager gonna be funky if [BeatScratchPlugin.supportsStorage]
/// isn't true (i.e. for the web). You still have JSON serialization
/// stuff available... you could write this, enterprising code school dev!
class ScoreManager {
  static const String PASTED_SCORE = "Pasted Score";
  static const String FROM_CLIPBOARD = " (from Clipboard)";
  static const String WEB_SCORE = "Linked Score";
  static const String FROM_WEB = " (from Link)";
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
    if (!MyPlatform.isWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      _scoresDirectory = Directory("${documentsDirectory.path}/scores}");
      _scoresDirectory.createSync();
      loadCurrentScoreIntoUI();
    }
  }

  createScore(String name, {Score score}) {
    score = score ?? defaultScore();
    currentScoreName = name;
    saveCurrentScore(score);
    doOpenScore(score);
  }

  saveCurrentScore(Score score) {
    _saveCurrentScore(_currentScoreFile, score);
  }

  _saveCurrentScore(File scoreFile, Score score) async {
    _currentScoreFile.writeAsBytes(score.bsCopy().writeToBuffer());
  }

  openScore(File file) async {
    currentScoreName = file.scoreName;
    loadCurrentScoreIntoUI();
  }

  loadCurrentScoreIntoUI() async {
    Score score;
    try {
      score = await loadCurrentScore();
    } catch (e) {
      score = defaultScore();
    }
    doOpenScore?.call(score);
  }

  loadFromScoreUrl(String scoreUrl,
      {String newScoreDefaultFilename = PASTED_SCORE,
      String newScoreNameSuffix = FROM_CLIPBOARD,
      Score currentScoreToSave,
      VoidCallback onFail,
      Function(String) onSuccess}) {
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#score='), '');
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/score/'), '');
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/s/'), '');
    try {
      if (scoreUrl.length < 10) {
        throw Exception("nope");
      }
      Score score = scoreFromUrlHashValue(scoreUrl);
      if (score == null || score.sections.isEmpty) {
        throw Exception("nope");
      }
      String scoreName = score.name ?? "";
      String suggestedScoreName = scoreName;
      if (suggestedScoreName.trim().isEmpty) {
        suggestedScoreName = newScoreDefaultFilename;
      } else {
        suggestedScoreName += newScoreNameSuffix;
      }
      if(currentScoreToSave != null) {
        saveCurrentScore(currentScoreToSave);
      }
      openScoreWithFilename(score, newScoreDefaultFilename); // side-effect: updates this.score
      _lastSuggestedScoreName = suggestedScoreName;
      onSuccess?.call(suggestedScoreName);
    } catch (any) {
      loadPastebinScoreIntoUI(scoreUrl,
          newScoreDefaultFilename: newScoreDefaultFilename,
          newScoreNameSuffix: newScoreNameSuffix,
          currentScoreToSave: currentScoreToSave,
          onFail: onFail,
          onSuccess: onSuccess);
    }
  }

  static String _lastSuggestedScoreName;
  static String get lastSuggestedScoreName {
    final value = _lastSuggestedScoreName;
    _lastSuggestedScoreName = null;
    return value;
  }

  static suggestScoreName(String name) {
    _lastSuggestedScoreName = name;
  }

  loadPastebinScoreIntoUI(String pastebinCode,
    {String newScoreDefaultFilename = PASTED_SCORE,
      String newScoreNameSuffix = FROM_CLIPBOARD,
      Score currentScoreToSave,
      VoidCallback onFail,
      Function(String) onSuccess}) async {
    if (pastebinCode == null) {
      return;
    }
    try {
      http.Response response = await http.get(
        'https://api.paste.ee/v1/pastes/$pastebinCode',
        headers: <String, String>{
          "X-Auth-Token": "aoOBUGRTRNe1caTvisGYOjCpGT1VmwthQcqC8zrjX",
        },
      );
      dynamic data = jsonDecode(response.body);
      String longUrl = data['paste']['sections'].first['contents'];
      longUrl = longUrl.replaceFirst(new RegExp(r'http.*#score='), '');
      longUrl = longUrl.replaceFirst(new RegExp(r'http.*#/score/'), '');

      Score score = scoreFromUrlHashValue(longUrl);
      String scoreName = score.name ?? "";
      String suggestedScoreName = scoreName;
      if (suggestedScoreName.trim().isEmpty) {
        suggestedScoreName = newScoreDefaultFilename;
      } else {
        suggestedScoreName += newScoreNameSuffix;
      }
      if (BeatScratchPlugin.supportsStorage) {
        if(currentScoreToSave != null) {
          saveCurrentScore(currentScoreToSave);
        }
        openScoreWithFilename(score, newScoreDefaultFilename);
      } else {
        doOpenScore(score);
      }
      onSuccess?.call(suggestedScoreName);
      _lastSuggestedScoreName = suggestedScoreName;
    } catch (any) {
      onFail?.call();
    }
  }

  openWebScore(Score score) async {
    openScoreWithFilename(score, WEB_SCORE);
  }

  openClipboardScore(Score score) async {
    openScoreWithFilename(score, PASTED_SCORE);
  }

  openScoreWithFilename(Score score, String filename) async {
    currentScoreName = filename;
    doOpenScore(score);
    saveCurrentScore(score);
  }

  Future<Score> loadCurrentScore() async => loadScore(_currentScoreFile);

  static Future<Score> loadScore(File file) async => Score.fromBuffer(file.readAsBytesSync());
}

extension ScoreName on FileSystemEntity {
  String get scoreName {
    String fileName = path.split("/")?.last ?? ".beatscratch";
    fileName = fileName.substring(0, fileName.length - 12);
    String scoreName = Uri.decodeComponent(fileName);
    return scoreName;
  }
}
