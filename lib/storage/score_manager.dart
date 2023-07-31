import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

/// ScoreManager is in charge of loading Scores from local storage
/// or the web.
/// ScoreManager gonna be funky if [BeatScratchPlugin.supportsStorage]
/// isn't true (i.e. for the web). You still have JSON serialization
/// stuff available... you could write this, enterprising code school dev!
class ScoreManager {
  static const String PASTED_SCORE = "Pasted Score";
  static const String FROM_CLIPBOARD = " (from Clipboard)";
  static const String WEB_SCORE = "Linked Score";
  static const String FROM_WEB = " (from Link)";
  static const String UNIVERSE_SCORE = "Universe Score";
  static const String FROM_UNIVERSE = " (from Universe)";
  Function(Score) doOpenScore;
  Directory scoresDirectory;
  SharedPreferences _prefs;

  String get currentScoreName =>
      _prefs?.getString('currentScoreName') ?? UNIVERSE_SCORE;

  set currentScoreName(String value) =>
      _prefs?.setString("currentScoreName", value);

  File get currentScoreFile => File(
      "${scoresDirectory.path}/${Uri.encodeComponent(currentScoreName).replaceAll("%20", " ")}.beatscratch");

  List<FileSystemEntity> get scoreFiles {
    if (scoresDirectory != null) {
      List<FileSystemEntity> result = scoresDirectory
          ?.listSync()
          .where((f) => f.path.endsWith(".beatscratch"))
          .toList();
      result.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return result;
    }
    return [];
  }

  ScoreManager() {
    _initialize();
  }

  String get scoresDirectoryName => "Scores";

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (!MyPlatform.isWeb) {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      final scoresPath = "${documentsDirectory.path}/$scoresDirectoryName";
      scoresDirectory = Directory(scoresPath);
      scoresDirectory.createSync();

      //Migrate files
      scoreFiles.forEach((file) {
        file.rename(file.path.replaceAll("%20", " "));
      });

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
    saveScoreFile(currentScoreFile, score);
  }

  Future saveScoreFile(File scoreFile, Score score) async {
    return //compute(
        _saveScoreFile(_SaveRequest(scoreFile.path, score.writeToBuffer()));
  }

  openScore(File file) async {
    currentScoreName = file.scoreName;
    loadCurrentScoreIntoUI();
  }

  openScoreWithName(String name) {
    currentScoreName = name;
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
    print("ScoreURL=$scoreUrl");
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
      if (currentScoreToSave != null) {
        saveCurrentScore(currentScoreToSave);
      }
      openScoreWithFilename(
          score, newScoreDefaultFilename); // side-effect: updates this.score
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

  Future<Score> loadPastebinScore(String codeOrUrl,
      {String titleOverride}) async {
    final code = codeOrUrl.replaceFirst(new RegExp(r'http.*#/s/'), '');

    http.Response response = await http.get(
      Uri.parse('https://api.paste.ee/v1/pastes/$code'),
      headers: <String, String>{
        "X-Auth-Token": "aoOBUGRTRNe1caTvisGYOjCpGT1VmwthQcqC8zrjX",
      },
    );
    dynamic data = jsonDecode(response.body);
    String longUrl = data['paste']['sections'].first['contents'];
    longUrl = longUrl.replaceFirst(new RegExp(r'http.*#score='), '');
    longUrl = longUrl.replaceFirst(new RegExp(r'http.*#/score/'), '');

    Score score = scoreFromUrlHashValue(longUrl);
    if (titleOverride != null) {
      score.name = titleOverride;
    }
    return score;
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
      Score score = await loadPastebinScore(pastebinCode);
      String scoreName = score.name ?? "";
      String suggestedScoreName = scoreName;
      if (suggestedScoreName.trim().isEmpty) {
        suggestedScoreName = newScoreDefaultFilename;
      } else {
        suggestedScoreName += newScoreNameSuffix;
      }
      if (BeatScratchPlugin.supportsStorage) {
        if (currentScoreToSave != null) {
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

  openScoreWithFilename(Score score, String filename) async {
    currentScoreName = filename;
    doOpenScore(score);
    saveCurrentScore(score);
  }

  Future<Score> loadCurrentScore() async => loadScore(currentScoreFile);

  static Future<Score> loadScore(File file) async =>
      Score.fromBuffer(file.readAsBytesSync());
}

extension ScoreName on FileSystemEntity {
  String get scoreName {
    String fileName = path.split("/")?.last ?? ".beatscratch";
    fileName = fileName.substring(0, max(0, fileName.length - 12));
    String scoreName = Uri.decodeComponent(fileName.replaceAll(" ", "%20"));
    return scoreName;
  }
}

class _SaveRequest {
  final String scoreFilePath;
  final Uint8List scoreBytes;

  const _SaveRequest(this.scoreFilePath, this.scoreBytes);
}

_saveScoreFile(_SaveRequest request) {
  File scoreFile = File(request.scoreFilePath);
  Score score = Score.fromBuffer(request.scoreBytes);
  if (scoreFile.scoreName != ScoreManager.WEB_SCORE &&
      scoreFile.scoreName != ScoreManager.PASTED_SCORE &&
      scoreFile.scoreName != ScoreManager.UNIVERSE_SCORE) {
    print("Updating score name");
    score.name = scoreFile.scoreName;
  }
  scoreFile.writeAsBytes(score.bsCopy().writeToBuffer());
}
