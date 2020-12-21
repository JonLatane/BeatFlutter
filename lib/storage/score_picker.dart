import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/ui_models.dart';
import 'package:beatscratch_flutter_redux/util/dummydata.dart';
import 'package:beatscratch_flutter_redux/util/bs_notifiers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../animations/size_fade_transition.dart';
import '../generated/protos/music.pb.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../music_preview/score_preview.dart';
import '../util/music_utils.dart';
import '../widget/my_buttons.dart';
import 'score_manager.dart';

enum ScorePickerMode {
  create,
  open,
  duplicate,
  none,
}

extension ShowScoreNameEntry on ScorePickerMode {
  bool get showScoreNameEntry => this == ScorePickerMode.duplicate || this == ScorePickerMode.create;
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
  final Function(bool) requestKeyboardFocused;

  const ScorePicker(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState,
      this.close,
      this.mode,
      this.openedScore,
      this.scoreManager,
      this.requestKeyboardFocused,
      this.requestMode})
      : super(key: key);

  @override
  _ScorePickerState createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers = BeatScratchPlugin.midiSynthesizers;
  TextEditingController nameController = TextEditingController();
  FocusNode nameFocus = FocusNode();

  ScoreManager get scoreManager => widget.scoreManager;
  ScorePickerMode previousMode;
  String overwritingScoreName;

  bool get wasShowingScoreNameEntry => previousMode?.showScoreNameEntry ?? false;

  @override
  initState() {
    super.initState();
    // nameController.value = nameController.value.rebuild(text: scoreManager.currentScoreName);
    nameFocus.addListener(() {
      widget.requestKeyboardFocused(nameFocus.hasFocus);
    });
    previousMode = widget.mode;
  }

  @override
  dispose() {
    nameController.dispose();
    nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showScoreNameEntry = widget.mode.showScoreNameEntry;
    if (!showScoreNameEntry && wasShowingScoreNameEntry) {
      Future.delayed(Duration(milliseconds: 1), () {
        widget.requestKeyboardFocused(false);
      });
    }
    if (showScoreNameEntry && !wasShowingScoreNameEntry) {
      nameFocus.requestFocus();
    }
    // if (previousMode != widget.mode) {
    //   String suggestedName = scoreManager.currentScoreName;
    //   if (suggestedName == "Pasted Score") {
    //     suggestedName = widget.openedScore.name;
    //   }
    //   nameController.value = nameController.value.rebuild(text: suggestedName);
    // }
    final suggestedName = ScoreManager.lastSuggestedScoreName;
    if (suggestedName != null) {
      nameController.value = nameController.value.copyWith(text: suggestedName);
    }
    previousMode = widget.mode;
    final nameIsValid = nameController.value.text.trim().isNotEmpty &&
        nameController.value.text.trim() != ScoreManager.PASTED_SCORE &&
        nameController.value.text.trim() != ScoreManager.WEB_SCORE;
    bool showHeader = true;
    String headerText;
    String extraDetailText = "";
    IconData icon;
    switch (widget.mode) {
      case ScorePickerMode.open:
        headerText = "Open Score";
        icon = Icons.folder_open;
        break;
      case ScorePickerMode.create:
        headerText = "Create Score";
        icon = Icons.add;
        extraDetailText = "Create a Score with one Section at 123bpm in 4/4 time, a Piano Part and a Drum Part.";
        break;
      case ScorePickerMode.duplicate:
        headerText = "Duplicate Score";
        icon = Icons.control_point_duplicate;
        String openedScoreName = widget.openedScore.name;
        String scoreManagerName = widget.scoreManager.currentScoreName;
        if (openedScoreName != scoreManagerName) {
          extraDetailText =
              "The Score \"$openedScoreName\" has been opened with the name \"$scoreManagerName.\" To avoid data being overwritten, you should choose a new name and Duplicate it.";
        }
        break;
      default:
        headerText = "";
        break;
    }
    bool detailsTextInColumn = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        AnimatedContainer(
          height: showHeader ? 40 : 0,
          duration: animationDuration,
          child: AnimatedOpacity(
            duration: animationDuration,
            opacity: showHeader ? 1 : 0,
            child: Column(
              children: [
                Expanded(child:SizedBox()),
                Row(
                  children: [
                    SizedBox(width:5),
                    if (icon != null) Icon(icon, color: Colors.white, size: 32),
                    if (icon != null) SizedBox(width:5),
                    Text(
                      headerText,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    if (!detailsTextInColumn) SizedBox(width:15),
                    if (!detailsTextInColumn) Expanded(
                      child: Text(
                          extraDetailText,
                          maxLines: 3,
                          overflow: TextOverflow.fade,
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200),
                        ),
                    ),
                    if (!detailsTextInColumn) SizedBox(width:100),
                  ],
                ),
                Expanded(child:SizedBox()),
              ],
            ))),
        AnimatedContainer(
          height: detailsTextInColumn && extraDetailText.isNotEmpty ? 48 : 0,
          duration: animationDuration,
          child: AnimatedOpacity(
            duration: animationDuration,
            opacity: detailsTextInColumn && extraDetailText.isNotEmpty ? 1 : 0,
            child: Column(
              children: [
                Expanded(child:SizedBox()),
                Row(
                  children: [
                    SizedBox(width:5),
                    Expanded(
                      child: Text(
                        extraDetailText,
                        maxLines: 3,
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200),
                      ),
                    ),
                  ],
                ),
                Expanded(child:SizedBox()),
              ],
            ))),
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 14),
                          enabled: showScoreNameEntry,
                          decoration: InputDecoration(border: InputBorder.none, hintText: "Score Name", isDense: true),
                          onChanged: (value) {
                            // widget.melody.name = value;
                            //                          BeatScratchPlugin.updateMelody(widget.melody);
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          },
                        )),
                  )),
                  AnimatedContainer(
                    duration: animationDuration,
                    width: widget.mode == ScorePickerMode.create ? 80 : 0,
                    padding: EdgeInsets.only(right: 5),
                    child: MyFlatButton(
                        color: chromaticSteps[0],
                        onPressed: widget.mode == ScorePickerMode.create && nameIsValid
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
                    width: widget.mode == ScorePickerMode.duplicate ? 80 : 0,
                    padding: EdgeInsets.only(right: 5),
                    child: MyFlatButton(
                        color: chromaticSteps[0],
                        onPressed: widget.mode == ScorePickerMode.duplicate && nameIsValid
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
                  Container(
                    width: 80,
                    child: MyFlatButton(
                        color: chromaticSteps[7],
                        onPressed: () {
                          nameController.value = nameController.value.copyWith(text: "");
                          overwritingScoreName = null;
                          widget.close();
                        },
                        padding: EdgeInsets.zero,
                        child: Text("Cancel")),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: (widget.scrollDirection == Axis.horizontal)
              ? Row(children: [
                  Expanded(child: Padding(padding: EdgeInsets.all(2), child: getList(context))),
                  AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.mode == ScorePickerMode.open ? 1 : 0,
                    child: AnimatedContainer(
                        duration: animationDuration,
                        width: widget.mode == ScorePickerMode.open ? 44 : 0,
//    height: 32,
                        padding: EdgeInsets.zero,
                        child: Column(children: [
                          Expanded(
                              child: MyRaisedButton(
                            color: ChordColor.tonic.color,
                            child: Column(children: [
                              Expanded(child: SizedBox()),
                              Icon(Icons.check, color: Colors.white),
                              Text("DONE", style: TextStyle(color: Colors.white, fontSize: 10)),
                              Expanded(child: SizedBox()),
                            ]),
                            padding: EdgeInsets.all(2),
                            onPressed: widget.close,
                          ))
                        ])),
                  )
                ])
              : Column(children: [
                  Expanded(child: getList(context)),
                ]),
        ),
      ],
    );
  }

  _doCreate() {
    setState(() {
      if (scoreManager.scoreFiles.any((f) => f.scoreName == nameController.value.text)) {
        overwritingScoreName = nameController.value.text;
        int index = scoreManager.scoreFiles.indexWhere((f) => f.scoreName == nameController.value.text);
        double position = _Score.width * (index);
        position = min(_scrollController.position.maxScrollExtent, position);
        _scrollController.animateTo(position, duration: animationDuration, curve: Curves.easeInOut);
      } else {
        widget.requestMode(ScorePickerMode.open);
        widget.openedScore.reKeyMelodies();
        scoreManager.createScore(nameController.value.text);
        overwritingScoreName = null;
        Future.delayed(Duration(seconds: 2), widget.close);
      }
    });
  }

  _doDuplicate() {
    setState(() {
      if (scoreManager.scoreFiles.any((f) => f.scoreName == nameController.value.text)) {
        overwritingScoreName = nameController.value.text;
        int index = scoreManager.scoreFiles.indexWhere((f) => f.scoreName == nameController.value.text);
        double position = _Score.width * (index);
        position = min(_scrollController.position.maxScrollExtent, position);
        _scrollController.animateTo(position, duration: animationDuration, curve: Curves.easeInOut);
      } else {
        widget.requestMode(ScorePickerMode.open);
        widget.openedScore.reKeyMelodies();
        scoreManager.createScore(nameController.value.text, score: widget.openedScore);
        overwritingScoreName = null;
        Future.delayed(Duration(seconds: 2), widget.close);
      }
    });
  }

  Widget getList(BuildContext context) {
    var scoreFiles;
    if (widget.mode != ScorePickerMode.none) {
      scoreFiles = scoreManager.scoreFiles;
    } else {
      scoreFiles = <FileSystemEntity>[];
    }
    return ImplicitlyAnimatedList<FileSystemEntity>(
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: scoreFiles,
      areItemsTheSame: (a, b) => a.path == b.path,
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        File scoreFile;
        if (index < scoreFiles.length) {
          scoreFile = scoreFiles[index];
        }
        Widget tile = _Score(
          currentScoreName: scoreManager.currentScoreName,
          scrollDirection: widget.scrollDirection,
          sectionColor: widget.sectionColor,
          file: scoreFile,
          openable: widget.mode == ScorePickerMode.open,
          ifNotOpenable: () {
            String scoreName = scoreFile?.scoreName;
            if (scoreName != null) {
              nameController.clear();
              setState(() {
                nameController.value = nameController.value.copyWith(text: scoreName);
              });
            }
          },
          scoreManager: scoreManager,
          deleteScore: () {
            setState(() {
              scoreFile.delete();
              if (widget.mode == ScorePickerMode.duplicate && overwritingScoreName == (scoreFile?.scoreName ?? "")) {
                _doDuplicate();
              }
            });
          },
          overwritingScoreName: overwritingScoreName,
          cancelOverwrite: () {
            setState(() {
              overwritingScoreName = null;
            });
          },
        );
        tile = Padding(padding: EdgeInsets.all(5), child: tile);
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

class _Score extends StatefulWidget {
  static const double width = 150.0;
  static const double height = 300.0;
  final Axis scrollDirection;
  final Color sectionColor;
  final File file;
  final VoidCallback deleteScore;
  final ScoreManager scoreManager;
  final bool openable;
  final VoidCallback ifNotOpenable;
  final String overwritingScoreName;
  final VoidCallback cancelOverwrite;
  final String currentScoreName;

  const _Score(
      {Key key,
      this.scrollDirection,
      this.sectionColor,
      this.file,
      this.deleteScore,
      this.scoreManager,
      this.openable,
      this.overwritingScoreName,
      this.cancelOverwrite,
      this.currentScoreName,
      this.ifNotOpenable})
      : super(key: key);

  @override
  __ScoreState createState() => __ScoreState();
}

class __ScoreState extends State<_Score> {
  bool _confirmingDelete;
  DateTime lastFileLastModified;

  Score _previewScore;
  BSNotifier notifyUpdate;

  @override
  initState() {
    super.initState();
    _confirmingDelete = false;
    notifyUpdate = BSNotifier();
  }

  @override
  Widget build(BuildContext context) {
    String scoreName = widget.file?.scoreName ?? "";
    bool isCurrentScore = scoreName == widget.currentScoreName;
    DateTime lastModified = widget.file?.lastModifiedSync() ?? DateTime(0);
    if (lastModified != lastFileLastModified) {
      _confirmingDelete = false;
      _previewScore = null;
      Future.microtask(() {
        Score previewScore = Score.fromBuffer(File(widget.file.path).readAsBytesSync());
        setState(() {
          _previewScore = previewScore;
        });
      });
      notifyUpdate();
      lastFileLastModified = lastModified;
    }
    if (scoreName == widget.overwritingScoreName) {
      _confirmingDelete = true;
    }
    Color foregroundColor, backgroundColor;
    if (!isCurrentScore) {
      foregroundColor = Colors.white;
      backgroundColor = Colors.grey;
    } else {
      foregroundColor = Colors.black87;
      backgroundColor = Colors.white;
    }

    Score previewScore = _previewScore;
    if (previewScore == null) {
      previewScore = defaultScore();
    }
    if (previewScore.sections.isEmpty) {
      previewScore.sections.add(defaultSection());
    }
    bool isLocked = scoreName == ScoreManager.PASTED_SCORE || scoreName == ScoreManager.WEB_SCORE;
    return AnimatedContainer(
        duration: animationDuration,
        width: widget.scrollDirection == Axis.horizontal ? 200 : null,
        height: widget.scrollDirection == Axis.vertical ? _Score.width : null,
        color: backgroundColor,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            MyFlatButton(
                onPressed: widget.openable
                    ? () {
                        FileSystemEntity file = widget.file;
                        if (file != null) {
                          widget.scoreManager.openScore(widget.file);
                        }
                      }
                    : widget.ifNotOpenable,
                padding: EdgeInsets.all(5),
                child: Column(children: [
                  Row(children: [
                    SizedBox(width: 5),
                    Expanded(
                        child: Text(scoreName,
                            style: TextStyle(color: foregroundColor, fontSize: 12, fontWeight: FontWeight.w100))),
                    Container(
                        width: 36,
                        height: 36,
                        child: MyFlatButton(
                            onPressed: isLocked
                                ? null
                                : () {
                                    setState(() {
                                      _confirmingDelete = true;
                                    });
                                  },
                            padding: EdgeInsets.zero,
                            child: Icon(isLocked ? Icons.lock : Icons.delete, color: foregroundColor))),
//          SizedBox(width:5),
                  ]),
                  Expanded(
                      child: Column(children: [
                    Expanded(
                        child: previewScore != null
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                        color: Colors.white.withOpacity(0.3),
                                        child: SingleChildScrollView(
                                            child: ScorePreview(previewScore,
                                                scale: 0.1, width: 200, height: 300, notifyUpdate: notifyUpdate))),
                                  ),
                                ],
                              )
                            : SizedBox()),
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
                                    setState(() {
                                      widget.deleteScore();
                                    });
                                  },
                                  child: Text("Yes", style: TextStyle(color: Colors.white))),
                            ),
                            Expanded(
                              child: MyFlatButton(
                                  onPressed: () {
                                    setState(() {
                                      _confirmingDelete = false;
                                      widget.cancelOverwrite();
                                    });
                                  },
                                  child: Text("No", style: TextStyle(color: Colors.white))),
                            ),
                          ]),
                          Expanded(child: SizedBox()),
                        ],
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ));
  }
}
