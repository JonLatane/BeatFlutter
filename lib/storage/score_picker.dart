import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/music_view/music_system_painter.dart';
import 'package:beatscratch_flutter_redux/storage/score_picker_preview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/bs_notifiers.dart';
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
  final double width, height;

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
      this.requestMode,
      this.width,
      this.height})
      : super(key: key);

  @override
  _ScorePickerState createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers =
      BeatScratchPlugin.midiSynthesizers;
  TextEditingController nameController = TextEditingController();
  FocusNode nameFocus = FocusNode();

  ScoreManager get scoreManager => widget.scoreManager;
  ScorePickerMode previousMode;
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
    bool showHeader = widget.mode != ScorePickerMode.none &&
        widget.mode != ScorePickerMode.show &&
        widget.mode != ScorePickerMode.universe;
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
        extraDetailText =
            "Create a Score with one Section at 123bpm in 4/4 time, a Piano Part and a Drum Part. You can customize them in the Layers View.";
        break;
      case ScorePickerMode.duplicate:
        headerText = "Duplicate Score";
        icon = FontAwesomeIcons.codeBranch;
        String openedScoreName = widget.openedScore.name;
        String scoreManagerName = widget.scoreManager.currentScoreName;
        if (openedScoreName != scoreManagerName) {
          extraDetailText =
              "The Score \"$openedScoreName\" has been opened with the name \"$scoreManagerName.\" To avoid data being overwritten, you should choose a new name and Duplicate it.";
        } else {
          extraDetailText = "Create a copy of the Score \"$openedScoreName\".";
        }
        break;
      default:
        headerText = "";
        break;
    }
    bool detailsTextInColumn = MediaQuery.of(context).size.width < 500;
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
                        SizedBox(width: 5),
                        if (icon != null)
                          Icon(icon, color: Colors.white, size: 32),
                        if (icon != null) SizedBox(width: 5),
                        Text(
                          headerText,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        if (!detailsTextInColumn) SizedBox(width: 15),
                        if (!detailsTextInColumn)
                          Expanded(
                            child: Text(
                              extraDetailText,
                              maxLines: 3,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w200),
                            ),
                          ),
                        if (!detailsTextInColumn) SizedBox(width: 100),
                      ],
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ))),
        AnimatedContainer(
            height: detailsTextInColumn && extraDetailText.isNotEmpty
                ? extraDetailText.length < 64
                    ? 32
                    : 48
                : 0,
            duration: animationDuration,
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity:
                    detailsTextInColumn && extraDetailText.isNotEmpty ? 1 : 0,
                child: Column(
                  children: [
                    Expanded(child: SizedBox()),
                    Row(
                      children: [
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            extraDetailText,
                            maxLines: 3,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w200),
                          ),
                        ),
                        SizedBox(width: 5),
                      ],
                    ),
                    Expanded(child: SizedBox()),
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
                  AnimatedContainer(
                    duration: animationDuration,
                    width: widget.mode == ScorePickerMode.create ? 80 : 0,
                    padding: EdgeInsets.only(right: 5),
                    child: MyFlatButton(
                        color: chromaticSteps[0],
                        onPressed:
                            widget.mode == ScorePickerMode.create && nameIsValid
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
                        color: ChordColor.tonic.color,
                        onPressed: widget.mode == ScorePickerMode.duplicate &&
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
                  Container(
                    width: 80,
                    child: MyFlatButton(
                        color: ChordColor.dominant.color,
                        onPressed: () {
                          nameController.value =
                              nameController.value.copyWith(text: "");
                          overwritingScoreName = null;
                          widget.close();
                        },
                        padding: EdgeInsets.zero,
                        child: Text("Cancel",
                            style: TextStyle(
                                color: ChordColor.dominant.color.textColor()))),
                  ),
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
                              Icon(Icons.check,
                                  color: ChordColor.tonic.color.textColor()),
                              Text("DONE",
                                  style: TextStyle(
                                      color: ChordColor.tonic.color.textColor(),
                                      fontSize: 10)),
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

  double get _scoreWidth => widget.width < 400
      ? widget.height < 400
          ? 150
          : 250
      : widget.width < 800
          ? 340
          : 480;

  _doCreate() {
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
        _scrollController.animateTo(0,
            duration: animationDuration, curve: Curves.easeInOut);
        widget.requestMode(ScorePickerMode.show);
        widget.openedScore.reKeyMelodies();
        scoreManager.createScore(nameController.value.text,
            score: widget.openedScore);
        overwritingScoreName = null;
        Future.delayed(Duration(seconds: 2), widget.close);
      }
    });
  }

  Widget getList(BuildContext context) {
    List<FileSystemEntity> scoreFiles;
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
      areItemsTheSame: (a, b) => a?.path == b?.path,
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        File scoreFile;
        if (index < scoreFiles.length) {
          scoreFile = scoreFiles[index];
        }
        // Future
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

        Widget tile = ScorePickerPreview(
          currentScoreName: scoreManager.currentScoreName,
          sectionColor: widget.sectionColor,
          width: _scoreWidth,
          height: widget.height,
          unloadedScoreName: scoreFile?.scoreName ?? "",
          onClickScore: () {
            switch (widget.mode) {
              case ScorePickerMode.open:
                if (scoreFile != null) {
                  widget.scoreManager.openScore(scoreFile);
                }
                break;
              case ScorePickerMode.universe:
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
          scoreKey: (scoreFile?.lastModifiedSync() ?? DateTime(0)).hashCode,
          loadScore: scoreFile != null ? loadScore() : null,
          deleteScore: widget.mode == ScorePickerMode.universe
              ? null
              : () {
                  setState(() {
                    scoreFile.delete();
                    if (widget.mode == ScorePickerMode.duplicate &&
                        overwritingScoreName == (scoreFile?.scoreName ?? "")) {
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
