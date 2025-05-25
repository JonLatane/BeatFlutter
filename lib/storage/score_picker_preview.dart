import 'dart:io';
import 'dart:math';

import 'package:beatscratch_flutter_redux/settings/app_settings.dart';
import 'package:beatscratch_flutter_redux/util/music_notation_theory.dart';
import 'package:beatscratch_flutter_redux/util/util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../music_preview/score_preview.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../widget/my_buttons.dart';
import 'score_manager.dart';
import 'universe_manager.dart';
import 'url_conversions.dart';

class ScoreFuture {
  final String? filePath, scoreUrl, title, author, commentUrl, fullName;
  int? voteCount;
  bool? likes;

  ScoreFuture({
    this.filePath,
    this.title,
    this.author,
    this.commentUrl,
    this.voteCount,
    this.likes,
    this.fullName,
    this.scoreUrl,
  });

  ScoreFuture.fromJson(Map<String, dynamic> json)
      : filePath = json['filePath'],
        title = json['title'],
        author = json['author'],
        commentUrl = json['commentUrl'],
        voteCount = json['voteCount'],
        likes = json['likes'],
        fullName = json['fullName'],
        scoreUrl = json['scoreUrl'];

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'title': title,
        'author': author,
        'commentUrl': commentUrl,
        'voteCount': voteCount,
        'likes': likes,
        'fullName': fullName,
        'scoreUrl': scoreUrl,
      };

  String get identity => filePath ?? "//universe-score://$scoreUrl";
  File? get file {
    try {
      if (filePath == null) return null;

      return File(filePath!);
    } catch (e) {
      print("Error loading score from file: $e");
    }
    return null;
  }

  Future<Score> loadScore(ScoreManager scoreManager) async {
    return loadScoreFromFile();
  }

  Future<Score> loadScoreFromFile() async {
    try {
      final file = this.file;
      if (file == null) {
        return Future.value(defaultScore());
      }
      final data = await File(file.path).readAsBytes();

      return Score.fromBuffer(data);
    } catch (e) {
      return Future.value(defaultScore());
    }
  }

  Future<Score> loadScoreFromUniverse(ScoreManager scoreManager) async {
    String scoreUrl = this.scoreUrl!;
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#score='), '');
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/score/'), '');
    scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/s/'), '');
    try {
      final score = scoreFromUrlHashValue(scoreUrl);
      if (score == null) {
        return Future.value(defaultScore());
      }
      return score..name = title!;
    } catch (e) {
      try {
        return scoreManager.loadPastebinScore(scoreUrl, titleOverride: title!);
      } catch (e) {
        return Future.value(defaultScore());
      }
    }
  }
}

class ScorePickerPreview extends StatefulWidget {
  final Color sectionColor;
  final ScoreFuture scoreFuture;
  final VoidCallback? deleteScore;
  final VoidCallback? overwriteScore;
  final ScoreManager scoreManager;
  final UniverseManager universeManager;
  final AppSettings appSettings;
  final VoidCallback? onClickScore;
  final int scoreKey;
  final String? deletingScoreName;
  final String? overwritingScoreName;
  final VoidCallback? cancelDelete;
  final VoidCallback? cancelOverwrite;
  final double width, height;

  const ScorePickerPreview(
      {Key? key,
      required this.sectionColor,
      required this.scoreFuture,
      required this.deleteScore,
      required this.overwriteScore,
      required this.scoreManager,
      required this.appSettings,
      this.deletingScoreName,
      this.overwritingScoreName,
      required this.scoreKey,
      required this.cancelDelete,
      required this.cancelOverwrite,
      required this.universeManager,
      this.onClickScore,
      required this.width,
      required this.height})
      : super(key: key);

  @override
  _ScorePickerPreviewState createState() => _ScorePickerPreviewState();
}

class _ScorePickerPreviewState extends State<ScorePickerPreview> {
  late bool _confirmingDelete;
  late bool _confirmingOverwrite;
  late int _lastScoreKey;
  late bool disposed;

  late Score? _previewScore;
  late ScrollController scrollController;
  late BSMethod notifyUpdate;

  @override
  initState() {
    super.initState();
    disposed = false;
    _confirmingDelete = false;
    _confirmingOverwrite = false;
    notifyUpdate = BSMethod();
    scrollController = ScrollController();
  }

  @override
  dispose() {
    disposed = true;
    scrollController.dispose();
    super.dispose();
  }

  String get unloadedScoreName =>
      widget.scoreFuture.title ?? widget.scoreFuture.file?.scoreName ?? "";

  bool get isUniverse => widget.scoreFuture.voteCount != null;
  @override
  Widget build(BuildContext context) {
    final scoreName = unloadedScoreName;
    bool isCurrentScore = isUniverse
        ? widget.scoreFuture.identity ==
            widget.universeManager.currentUniverseScore
        : unloadedScoreName == widget.scoreManager.currentScoreName;
    if (widget.scoreKey != _lastScoreKey) {
      _confirmingDelete = false;
      _confirmingOverwrite = false;
      _previewScore = null;
      Future.microtask(() async {
        Score previewScore =
            await widget.scoreFuture.loadScore(widget.scoreManager);
        if (!disposed) {
          setState(() {
            _previewScore = previewScore;
          });
        }
      });
      notifyUpdate();
      _lastScoreKey = widget.scoreKey;
    }
    if (unloadedScoreName == widget.deletingScoreName) {
      _confirmingDelete = true;
      _confirmingOverwrite = false;
    }
    if (unloadedScoreName == widget.overwritingScoreName) {
      _confirmingOverwrite = true;
      _confirmingDelete = false;
    }
    Color foregroundColor, backgroundColor;
    if (!isCurrentScore) {
      foregroundColor = Colors.white;
      backgroundColor = Colors.grey;
    } else {
      foregroundColor = musicForegroundColor;
      backgroundColor = musicBackgroundColor;
    }

    Score previewScore = _previewScore ?? defaultScore();
    // if (previewScore == null) {
    //   previewScore = defaultScore();
    // }
    if (previewScore.sections.isEmpty == true) {
      previewScore.sections.add(defaultSection());
    }
    final actualScoreName = isUniverse
        ? unloadedScoreName
        : _previewScore != null
            ? _previewScore!.name
            : unloadedScoreName;

    double previewScale =
        widget.width > 200 && widget.height > 200 ? 0.23 : 0.13;
    bool isLocked = scoreName == ScoreManager.PASTED_SCORE ||
        scoreName == ScoreManager.WEB_SCORE ||
        scoreName == ScoreManager.UNIVERSE_SCORE;
    return Row(children: [
      AnimatedContainer(
          duration: animationDuration,
          width: /*widget.scoreFuture?.loadScore != null ? */
              widget.width /*: 0*/,
          height: widget.height,
          color: backgroundColor,
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              MyFlatButton(
                  onPressed: widget.onClickScore,
                  padding: EdgeInsets.all(5),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(width: 5),
                      Expanded(
                          child: isLocked
                              ? Stack(children: [
                                  Transform.translate(
                                      offset: Offset(0, 5),
                                      child: Text(actualScoreName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: foregroundColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w100))),
                                  Transform.translate(
                                      offset: Offset(0, -5),
                                      child: Text(scoreName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: foregroundColor
                                                  .withOpacity(0.5),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w100)))
                                ])
                              : Text(
                                  actualScoreName.isNotEmpty
                                      ? actualScoreName
                                      : scoreName,
                                  style: TextStyle(
                                      color: foregroundColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w100))),

                      (widget.deleteScore != null)
                          ? Container(
                              width: 36,
                              height: 36,
                              child: MyFlatButton(
                                  onPressed: isLocked
                                      ? null
                                      : () {
                                          if (!disposed) {
                                            setState(() {
                                              _confirmingDelete = true;
                                            });
                                          }
                                        },
                                  padding: EdgeInsets.zero,
                                  child: Icon(
                                      isLocked ? Icons.lock : Icons.delete,
                                      color: foregroundColor
                                          .withOpacity(isLocked ? 0.5 : 1))))
                          : SizedBox(height: 36),
//          SizedBox(width:5),
                    ]),
                    Expanded(
                        child: Column(children: [
                      Expanded(
                          child: AnimatedOpacity(
                              duration: slowAnimationDuration,
                              opacity: previewScore != null ? 1 : 0,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                        color: musicBackgroundColor
                                            .withOpacity(0.7),
                                        child: SingleChildScrollView(
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            controller: scrollController,
                                            child: previewScore != null
                                                ? ScorePreview(previewScore,
                                                    scale: previewScale,
                                                    width: widget.width,
                                                    height: max(
                                                        widget.height,
                                                        36 +
                                                            previewScale *
                                                                staffHeight *
                                                                previewScore
                                                                    .parts
                                                                    .length),
                                                    notifyUpdate: notifyUpdate)
                                                : SizedBox(
                                                    width: 200,
                                                    height: 300,
                                                  ))),
                                  ),
                                ],
                              ))),
                    ]))
                  ])),
              AnimatedOpacity(
                duration: animationDuration,
                opacity: _confirmingDelete ? 1 : 0,
                child: _confirmingDelete
                    ? Container(
                        color: Colors.black87,
                        child: Column(
                          children: [
                            Expanded(child: SizedBox()),
                            Text(
                              "Really delete?",
                              style: TextStyle(color: Colors.white),
                            ),
                            Row(children: [
                              Expanded(
                                child: MyFlatButton(
                                    onPressed: () {
                                      if (!disposed) {
                                        setState(() {
                                          widget.deleteScore?.call();
                                        });
                                      }
                                    },
                                    child: Text("Yes",
                                        style: TextStyle(color: Colors.white))),
                              ),
                              Expanded(
                                child: MyFlatButton(
                                    onPressed: () {
                                      if (!disposed) {
                                        setState(() {
                                          _confirmingDelete = false;
                                          widget.cancelDelete?.call();
                                        });
                                      }
                                    },
                                    child: Text("No",
                                        style: TextStyle(color: Colors.white))),
                              ),
                            ]),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      )
                    : SizedBox(),
              ),
              AnimatedOpacity(
                duration: animationDuration,
                opacity: _confirmingOverwrite ? 1 : 0,
                child: _confirmingOverwrite
                    ? Container(
                        color: Colors.black87,
                        child: Column(
                          children: [
                            Expanded(child: SizedBox()),
                            Text(
                              "Really overwrite?",
                              style: TextStyle(color: Colors.white),
                            ),
                            Row(children: [
                              Expanded(
                                child: MyFlatButton(
                                    onPressed: () {
                                      if (!disposed) {
                                        setState(() {
                                          widget.overwriteScore?.call();
                                        });
                                      }
                                    },
                                    child: Text("Yes",
                                        style: TextStyle(color: Colors.white))),
                              ),
                              Expanded(
                                child: MyFlatButton(
                                    onPressed: () {
                                      if (!disposed) {
                                        setState(() {
                                          _confirmingOverwrite = false;
                                          widget.cancelOverwrite?.call();
                                        });
                                      }
                                    },
                                    child: Text("No",
                                        style: TextStyle(color: Colors.white))),
                              ),
                            ]),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      )
                    : SizedBox(),
              ),
              Align(
                  alignment: Alignment.bottomLeft,
                  child: AnimatedOpacity(
                      duration: animationDuration,
                      opacity: widget.scoreFuture.author != null ? 1 : 0,
                      child: Container(
                          height: 36,
                          padding: EdgeInsets.all(5),
                          color: musicBackgroundColor.withOpacity(0.5),
                          child: Row(children: [
                            Column(children: [
                              Text("submitted",
                                  style: TextStyle(
                                      color: musicForegroundColor,
                                      fontWeight: FontWeight.w100,
                                      fontSize: 8)),
                              Text("by",
                                  style: TextStyle(
                                      color: musicForegroundColor,
                                      fontWeight: FontWeight.w100,
                                      fontSize: 8))
                            ]),
                            SizedBox(width: 5),
                            Text(widget.scoreFuture.author ?? "",
                                style: TextStyle(
                                    color: musicForegroundColor,
                                    fontWeight: FontWeight.w700))
                          ]))))
            ],
          )),
      AnimatedOpacity(
          duration: animationDuration,
          opacity: isUniverse ? 1 : 0,
          child: AnimatedContainer(
              duration: animationDuration,
              color: musicBackgroundColor,
              width: isUniverse ? 48 : 0,
              height: widget.height,
              child: Column(
                children: [
                  MyFlatButton(
                      color: widget.scoreFuture.likes == true
                          ? chromaticSteps[11]
                          : Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 5),
                      onPressed:
                          widget.universeManager.redditUsername.isNotEmpty
                              ? () {
                                  bool? oldValue = widget.scoreFuture.likes;
                                  setState(() {
                                    if (oldValue == true) {
                                      widget.scoreFuture.likes = null;
                                      widget.scoreFuture.voteCount =
                                          widget.scoreFuture.voteCount! - 1;
                                    } else {
                                      widget.scoreFuture.likes = true;
                                      widget.scoreFuture.voteCount =
                                          widget.scoreFuture.voteCount! +
                                              (oldValue == null ? 1 : 2);
                                    }
                                    widget.universeManager.vote(
                                        widget.scoreFuture.fullName!,
                                        widget.scoreFuture.likes);
                                  });
                                }
                              : null,
                      child: Icon(Icons.arrow_upward,
                          color: widget.universeManager.isAuthenticated
                              ? widget.scoreFuture.likes == true
                                  ? chromaticSteps[11].textColor()
                                  : chromaticSteps[11]
                              : musicForegroundColor.withOpacity(0.5))),
                  Row(children: [
                    Expanded(child: SizedBox()),
                    Text(widget.scoreFuture.voteCount.toString() ?? '',
                        style: TextStyle(
                            color: musicForegroundColor,
                            fontWeight: FontWeight.w800)),
                    Expanded(child: SizedBox()),
                  ]),
                  MyFlatButton(
                      color: widget.scoreFuture.likes == false
                          ? chromaticSteps[10]
                          : Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 5),
                      onPressed:
                          widget.universeManager.redditUsername.isNotEmpty
                              ? () {
                                  bool? oldValue = widget.scoreFuture.likes;
                                  setState(() {
                                    if (oldValue == false) {
                                      widget.scoreFuture.likes = null;
                                      widget.scoreFuture.voteCount =
                                          widget.scoreFuture.voteCount! + 1;
                                    } else {
                                      widget.scoreFuture.likes = false;
                                      widget.scoreFuture.voteCount =
                                          widget.scoreFuture.voteCount! -
                                              (oldValue == null ? 1 : 2);
                                    }
                                    widget.universeManager.vote(
                                        widget.scoreFuture.fullName!,
                                        widget.scoreFuture.likes);
                                  });
                                }
                              : null,
                      child: Icon(Icons.arrow_downward,
                          color: widget.universeManager.isAuthenticated
                              ? widget.scoreFuture.likes == false
                                  ? chromaticSteps[10].textColor()
                                  : chromaticSteps[10]
                              : musicForegroundColor.withOpacity(0.5))),
                  Expanded(child: SizedBox()),
                  MyFlatButton(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      onPressed: () {
                        if (widget.appSettings.enableApollo) {
                          launchURL(
                              widget.scoreFuture.commentUrl!
                                  .replaceAll("https://", "apollo://"),
                              forceSafariVC: false);
                        } else {
                          launchURL(widget.scoreFuture.commentUrl!,
                              forceSafariVC: false);
                        }
                      },
                      child: Icon(FontAwesomeIcons.commentDots,
                          color: chromaticSteps[0])),
                ],
              )))
    ]);
  }
}
