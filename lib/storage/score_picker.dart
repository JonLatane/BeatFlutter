import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:beatscratch_flutter_redux/settings/app_settings.dart';
import 'package:beatscratch_flutter_redux/storage/url_conversions.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:beatscratch_flutter_redux/music_view/music_system_painter.dart';
import 'package:beatscratch_flutter_redux/storage/score_picker_preview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/bs_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../generated/protos/music.pb.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../music_preview/score_preview.dart';
import '../util/music_utils.dart';
import '../widget/my_buttons.dart';
import 'score_manager.dart';
import 'universe_manager.dart';

enum ScorePickerMode {
  create,
  open,
  duplicate,
  show,
  none,
  universe,
}

extension ShowScoreNameEntry on ScorePickerMode {
  bool get showScoreNameEntry =>
      this == ScorePickerMode.duplicate || this == ScorePickerMode.create;
  bool get isLocalOperationMode =>
      this == ScorePickerMode.duplicate ||
      this == ScorePickerMode.create ||
      this == ScorePickerMode.open;
}

class ScorePicker extends StatefulWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final Function(VoidCallback) setState;
  final VoidCallback close;
  final ScorePickerMode mode;
  final Function(ScorePickerMode) requestMode;
  final Score openedScore;
  final ScoreManager scoreManager;
  final UniverseManager universeManager;
  final AppSettings appSettings;
  final Function(bool) requestKeyboardFocused;
  final double width, height;
  final BSMethod refreshUniverseData;

  const ScorePicker(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState,
      this.close,
      this.mode,
      this.openedScore,
      this.scoreManager,
      this.universeManager,
      this.appSettings,
      this.requestKeyboardFocused,
      this.requestMode,
      this.width,
      this.height,
      this.refreshUniverseData})
      : super(key: key);

  @override
  ScorePickerState createState() => ScorePickerState();
}

class ScorePickerState extends State<ScorePicker> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers =
      BeatScratchPlugin.midiSynthesizers;
  TextEditingController nameController = TextEditingController();
  FocusNode nameFocus = FocusNode();

  ScoreManager get scoreManager => widget.scoreManager;
  ScorePickerMode previousMode;
  String deletingScoreName;
  String overwritingScoreName;

  bool get wasShowingScoreNameEntry =>
      previousMode?.showScoreNameEntry ?? false;

  @override
  initState() {
    super.initState();
    // nameController.value = nameController.value.rebuild(text: scoreManager.currentScoreName);
    nameFocus.addListener(() {
      widget.requestKeyboardFocused(nameFocus.hasFocus);
    });
    widget.refreshUniverseData.addListener(_refreshUniverseData);
    previousMode = widget.mode;
  }

  _refreshUniverseData() {
    _scrollController.animateTo(0,
        duration: animationDuration, curve: Curves.easeInOut);
    loadUniverseData();
  }

  loadUniverseData() async {
    final data = await widget.universeManager.loadUniverseData();
    if (!disposed) {
      setState(() {
        widget.universeManager.cachedUniverseData = data;
      });
    } else {
      widget.universeManager.cachedUniverseData = data;
    }
  }

  bool disposed = false;
  @override
  dispose() {
    _scrollController.dispose();
    nameController.dispose();
    nameFocus.dispose();
    widget.refreshUniverseData.removeListener(_refreshUniverseData);
    disposed = true;
    super.dispose();
  }

  bool hideDetailsText = false;
  @override
  Widget build(BuildContext context) {
    if (widget.mode != ScorePickerMode.universe) {
      // cachedUniverseData = null;
    }
    bool showScoreNameEntry = widget.mode.showScoreNameEntry;
    if (!showScoreNameEntry && wasShowingScoreNameEntry) {
      Future.delayed(Duration(milliseconds: 1), () {
        widget.requestKeyboardFocused(false);
      });
    }
    if (showScoreNameEntry && !wasShowingScoreNameEntry) {
      nameFocus.requestFocus();
    }
    if (previousMode != widget.mode) {
      hideDetailsText = false;
      if (widget.mode == ScorePickerMode.duplicate) {
        String suggestedName = widget.openedScore.name;
        nameController.value =
            nameController.value.copyWith(text: suggestedName);
      }
    }
    previousMode = widget.mode;
    final nameIsValid = nameController.value.text.trim().isNotEmpty &&
        nameController.value.text.trim() != ScoreManager.PASTED_SCORE &&
        nameController.value.text.trim() != ScoreManager.WEB_SCORE &&
        nameController.value.text.trim() != ScoreManager.UNIVERSE_SCORE;
    bool showHeader = widget.mode != ScorePickerMode.none &&
        widget.mode != ScorePickerMode.show &&
        widget.mode != ScorePickerMode.universe;
    String operationText;
    TextStyle detailTextStyle = TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w200,
        fontFamily: DefaultTextStyle.of(context).style.fontFamily);
    TextSpan extraDetailText = TextSpan(
      text: '',
      style: detailTextStyle,
    ); //ing extraDetailText = "";
    IconData icon;
    switch (widget.mode) {
      case ScorePickerMode.open:
        operationText = "Open";
        icon = Icons.folder_open;
        break;
      case ScorePickerMode.create:
        operationText = "Create";
        icon = Icons.add;
        extraDetailText = TextSpan(
          text:
              "Create a Score with one Section at 123bpm in 4/4 time, a Piano Part and a Drum Part. You can customize them in the Layers View.",
          style: detailTextStyle,
        );
        break;
      case ScorePickerMode.duplicate:
        operationText = "Duplicate";
        icon = FontAwesomeIcons.codeBranch;
        String openedScoreName = widget.openedScore.name;
        String scoreManagerName = widget.scoreManager.currentScoreName;
        if (openedScoreName != scoreManagerName) {
          extraDetailText = duplicateWarningText(
              detailTextStyle, widget.openedScore, widget.scoreManager);
        } else {
          extraDetailText = TextSpan(
            text: "Create a copy of the Score \"$openedScoreName\".",
            style: detailTextStyle,
          );
          ;
        }
        break;
      default:
        operationText = "";
        break;
    }
    bool detailsTextInColumn = true; //MediaQuery.of(context).size.width < 500;
    bool showDetailsText = detailsTextInColumn &&
        extraDetailText.text.isNotEmpty &&
        !hideDetailsText;

    return Column(
      children: [
        AnimatedContainer(
            height: showHeader ? 45 : 0,
            duration: animationDuration,
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity: showHeader ? 1 : 0,
                child: Column(
                  children: [
                    Expanded(child: SizedBox()),
                    Row(
                      children: [
                        if (icon != null && operationText.isNotEmpty)
                          MyFlatButton(
                              padding: EdgeInsets.zero,
                              lightHighlight: true,
                              // padding: EdgeInsets.al;l 5),
                              onPressed: () {
                                if (widget.mode == ScorePickerMode.create) {
                                  widget.requestMode(ScorePickerMode.duplicate);
                                } else if (widget.mode ==
                                    ScorePickerMode.duplicate) {
                                  widget.requestMode(ScorePickerMode.open);
                                } else if (widget.mode ==
                                    ScorePickerMode.open) {
                                  widget.requestMode(ScorePickerMode.create);
                                }
                              },
                              child: Row(children: [
                                SizedBox(width: 5),
                                Icon(icon, color: Colors.white, size: 32),
                                SizedBox(width: 5),
                                Text(
                                  operationText,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 2.5),
                              ])),
                        SizedBox(width: 2.5),
                        AnimatedOpacity(
                          opacity: widget.mode.isLocalOperationMode ? 1 : 0,
                          duration: animationDuration,
                          child: Text(
                            "Score",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w100),
                          ),
                        ),
                        Expanded(child: SizedBox()),
                        AnimatedContainer(
                          duration: animationDuration,
                          width: widget.mode == ScorePickerMode.create ? 80 : 0,
                          padding: EdgeInsets.only(right: 5),
                          child: MyFlatButton(
                              color: chromaticSteps[0],
                              onPressed:
                                  widget.mode == ScorePickerMode.create &&
                                          nameIsValid
                                      ? () {
                                          _doCreate();
                                        }
                                      : null,
                              padding: EdgeInsets.zero,
                              child: Text(
                                "Create",
                                maxLines: 1,
                              )),
                        ),
                        AnimatedContainer(
                          duration: animationDuration,
                          width:
                              widget.mode == ScorePickerMode.duplicate ? 80 : 0,
                          padding: EdgeInsets.only(right: 5),
                          child: MyFlatButton(
                              color: ChordColor.tonic.color,
                              onPressed:
                                  widget.mode == ScorePickerMode.duplicate &&
                                          nameIsValid
                                      ? () {
                                          _doDuplicate();
                                        }
                                      : null,
                              padding: EdgeInsets.zero,
                              child: Text(
                                "Duplicate",
                                maxLines: 1,
                              )),
                        ),
                        AnimatedContainer(
                          duration: animationDuration,
                          width: widget.mode == ScorePickerMode.create ||
                                  widget.mode == ScorePickerMode.duplicate
                              ? 80
                              : 0,
                          padding: EdgeInsets.only(right: 5),
                          child: MyFlatButton(
                              color: ChordColor.dominant.color,
                              onPressed: () {
                                nameController.value =
                                    nameController.value.copyWith(text: "");
                                deletingScoreName = null;
                                overwritingScoreName = null;
                                widget.close();
                              },
                              padding: EdgeInsets.zero,
                              child: Text("Cancel",
                                  maxLines: 1,
                                  style: TextStyle(
                                      color: ChordColor.dominant.color
                                          .textColor()))),
                        ),
                        AnimatedContainer(
                          duration: animationDuration,
                          width: widget.mode == ScorePickerMode.open ? 80 : 0,
                          padding: EdgeInsets.only(right: 5),
                          child: MyFlatButton(
                              color: ChordColor.tonic.color,
                              onPressed: () {
                                nameController.value =
                                    nameController.value.copyWith(text: "");
                                deletingScoreName = null;
                                overwritingScoreName = null;
                                widget.close();
                              },
                              padding: EdgeInsets.zero,
                              child: Text("Done",
                                  maxLines: 1,
                                  style: TextStyle(
                                      color:
                                          ChordColor.tonic.color.textColor()))),
                        ),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ))),
        AnimatedContainer(
            height: showDetailsText
                ? 0 == extraDetailText.children?.length ?? 0
                    ? 32
                    : 48
                : 0,
            duration: animationDuration,
            child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  final sensitivity = 7;
                  if (details.delta.dy > sensitivity) {
                    // Down swipe
                  } else if (details.delta.dy < -sensitivity) {
                    // Up swipe
                    if (showDetailsText) {
                      HapticFeedback.lightImpact();
                      setState(() {
                        hideDetailsText = true;
                      });
                    }
                  }
                },
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: showDetailsText ? 1 : 0,
                    child: Column(
                      children: [
                        Expanded(child: SizedBox()),
                        Row(
                          children: [
                            SizedBox(width: 5),
                            Expanded(
                              child: RichText(
                                text: extraDetailText,
                                maxLines: 3,
                              ),
                            ),
                            SizedBox(width: 5),
                          ],
                        ),
                        Expanded(child: SizedBox()),
                      ],
                    )))),
        AnimatedContainer(
          height: showScoreNameEntry ? 40 : 0,
          duration: animationDuration,
          child: AnimatedOpacity(
            duration: animationDuration,
            opacity: showScoreNameEntry ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: [
                  SizedBox(width: 5),
                  Expanded(
                      child: Transform.translate(
                    offset: Offset(0, 4.5),
                    child: Container(
                        height: 48,
                        child: TextField(
                          focusNode: nameFocus,
                          controller: nameController,
                          maxLines: 1,
                          cursorColor: Colors.white,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14),
                          enabled: showScoreNameEntry,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Score Name",
                              isDense: true),
                          onChanged: (value) {
                            // widget.melody.name = value;
                            //                          BeatScratchPlugin.updateMelody(widget.melody);
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          },
                        )),
                  )),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: (widget.scrollDirection == Axis.horizontal)
              ? Row(children: [
                  Expanded(
                      child: Padding(
                          padding: EdgeInsets.all(2), child: getList(context))),
//                   AnimatedOpacity(
//                     duration: animationDuration,
//                     opacity: widget.mode == ScorePickerMode.open ? 1 : 0,
//                     child: AnimatedContainer(
//                         duration: animationDuration,
//                         width: widget.mode == ScorePickerMode.open ? 44 : 0,
// //    height: 32,
//                         padding: EdgeInsets.zero,
//                         child: Column(children: [
//                           Expanded(
//                               child: MyRaisedButton(
//                             color: ChordColor.tonic.color,
//                             child: Column(children: [
//                               Expanded(child: SizedBox()),
//                               Icon(Icons.check,
//                                   color: ChordColor.tonic.color.textColor()),
//                               Text("DONE",
//                                   style: TextStyle(
//                                       color: ChordColor.tonic.color.textColor(),
//                                       fontSize: 10)),
//                               Expanded(child: SizedBox()),
//                             ]),
//                             padding: EdgeInsets.all(2),
//                             onPressed: widget.close,
//                           ))
//                         ])),
//                   )
                ])
              : Column(children: [
                  Expanded(
                      child: AnimatedContainer(
                          duration: animationDuration,
                          width: widget.width,
                          child: getList(context))),
                ]),
        ),
      ],
    );
  }

  static TextSpan duplicateWarningText(
    TextStyle textStyle,
    Score score,
    ScoreManager scoreManager,
  ) {
    String openedScoreName = score.name;
    String scoreManagerName = scoreManager.currentScoreName;
    return TextSpan(
      text: 'The Score "',
      style: textStyle,
      children: <TextSpan>[
        TextSpan(
            text: openedScoreName,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: chromaticSteps[0])),
        TextSpan(text: '" is opened with the name "'),
        TextSpan(
            text: scoreManagerName,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: chromaticSteps[5])),
        TextSpan(text: '." To avoid losing changes, choose a new name and '),
        TextSpan(
            text: 'Duplicate', style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: ' it.'),
      ],
    );
  }

  double get _scoreWidth => widget.scrollDirection == Axis.horizontal
      ? widget.width < 400
          ? widget.height < 400
              ? 200
              : 250
          : widget.width < 800
              ? 340
              : 480
      : max(0,
          widget.width - (widget.mode == ScorePickerMode.universe ? 62 : 10));
  double get _scoreHeight => widget.scrollDirection == Axis.horizontal
      ? widget.height
      : widget.height > 500
          ? 340
          : 250;

  _doCreate() {
    setState(() {
      if (scoreManager.scoreFiles
          .any((f) => f.scoreName == nameController.value.text)) {
        overwritingScoreName = nameController.value.text;
        int index = scoreManager.scoreFiles
            .indexWhere((f) => f.scoreName == nameController.value.text);
        double position = (widget.scrollDirection == Axis.horizontal
                ? _scoreWidth
                : _scoreHeight + 10) *
            (index);
        position = min(_scrollController.position.maxScrollExtent, position);
        _scrollController.animateTo(position,
            duration: animationDuration, curve: Curves.easeInOut);
      } else {
        _scrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
        widget.requestMode(ScorePickerMode.show);
        widget.openedScore.reKeyMelodies();
        scoreManager.createScore(nameController.value.text);
        overwritingScoreName = null;
        Future.delayed(Duration(seconds: 2), widget.close);
      }
    });
  }

  _doDuplicate() {
    setState(() {
      if (scoreManager.scoreFiles
          .any((f) => f.scoreName == nameController.value.text)) {
        overwritingScoreName = nameController.value.text;
        int index = scoreManager.scoreFiles
            .indexWhere((f) => f.scoreName == nameController.value.text);
        double position = _scoreWidth * (index);
        position = min(_scrollController.position.maxScrollExtent, position);
        _scrollController.animateTo(position,
            duration: animationDuration, curve: Curves.easeInOut);
      } else {
        widget.universeManager.currentUniverseScore = "";
        _scrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
        widget.requestMode(ScorePickerMode.show);
        widget.openedScore.reKeyMelodies();
        widget.openedScore.name = nameController.value.text;
        scoreManager.createScore(nameController.value.text,
            score: widget.openedScore);
        overwritingScoreName = null;
        Future.delayed(Duration(seconds: 2), widget.close);
      }
    });
  }

  List<ScoreFuture> get _listedScores {
    if (widget.mode == ScorePickerMode.none) {
      return [];
    } else if (widget.mode == ScorePickerMode.universe) {
      return widget.universeManager.cachedUniverseData;
    } else {
      List<FileSystemEntity> scoreFiles;
      scoreFiles = scoreManager.scoreFiles;
      return scoreFiles.map((scoreFile) {
        Future<Score> loadScore() async {
          if (scoreFile == null) {
            return Future.value(defaultScore());
          }
          try {
            final data = await File(scoreFile?.path).readAsBytes();

            return Score.fromBuffer(data);
          } catch (e) {
            return Future.value(defaultScore());
          }
        }

        return ScoreFuture(filePath: scoreFile.path);
      }).toList();
    }
  }

  Widget getList(BuildContext context) {
    List<ScoreFuture> scores = _listedScores;
    return ImplicitlyAnimatedList<ScoreFuture>(
      key: ValueKey("ScorePickerList"),
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: scores,
      areItemsTheSame: (a, b) => a?.identity == b?.identity,
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        ScoreFuture scoreFuture;
        if (index < scores.length) {
          scoreFuture = scores[index];
        }
        File scoreFile = scoreFuture?.file;

        Widget tile = ScorePickerPreview(
          sectionColor: widget.sectionColor,
          width: _scoreWidth,
          height: _scoreHeight,
          appSettings: widget.appSettings,
          onClickScore: widget.mode == ScorePickerMode.show ||
                  widget.mode == ScorePickerMode.none
              ? null
              : () {
                  switch (widget.mode) {
                    case ScorePickerMode.open:
                      if (scoreFile != null) {
                        widget.scoreManager.openScore(scoreFile);
                        widget.universeManager.currentUniverseScore = "";
                      }
                      break;
                    case ScorePickerMode.universe:
                      scoreFuture.loadScore(scoreManager).then((value) {
                        widget.scoreManager.doOpenScore(value);
                        widget.universeManager.currentUniverseScore =
                            scoreFuture.identity;
                        widget.scoreManager.saveCurrentScore(value);
                      });
                      break;
                    default:
                      String scoreName = scoreFile?.scoreName;
                      if (scoreName != null) {
                        nameController.clear();
                        setState(() {
                          nameController.value =
                              nameController.value.copyWith(text: scoreName);
                        });
                      }
                  }
                },
          scoreManager: scoreManager,
          universeManager: widget.universeManager,
          scoreKey: (scoreFile?.lastModifiedSync() ?? DateTime(0)).hashCode,
          scoreFuture: scoreFuture,
          deleteScore: widget.mode == ScorePickerMode.universe
              ? null
              : () {
                  setState(() {
                    scoreFile.delete();
                  });
                },
          overwriteScore: widget.mode == ScorePickerMode.universe
              ? null
              : () {
                  setState(() {
                    if (widget.mode == ScorePickerMode.duplicate) {
                      scoreFile.delete().then((value) => _doDuplicate());
                    }
                    if (widget.mode == ScorePickerMode.create) {
                      scoreFile.delete().then((value) => _doCreate());
                    }
                  });
                },
          deletingScoreName: deletingScoreName,
          overwritingScoreName: overwritingScoreName,
          cancelDelete: () {
            setState(() {
              deletingScoreName = null;
            });
          },
          cancelOverwrite: () {
            setState(() {
              overwritingScoreName = null;
            });
          },
        );
        tile = Padding(
            padding: EdgeInsets.only(
                left: 5,
                right: 5,
                bottom: widget.scrollDirection == Axis.vertical ? 10 : 0),
            child: tile);
        return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            axis: widget.scrollDirection,
            animation: animation,
            child: tile);
      },
    );
  }
}
