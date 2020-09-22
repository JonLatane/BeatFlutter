import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:beatscratch_flutter_redux/ui_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:path_provider/path_provider.dart';
import 'melody_view.dart';
import 'my_buttons.dart';
import 'score_manager.dart';

import 'animations/size_fade_transition.dart';
import 'generated/protos/music.pb.dart';
import 'generated/protos/protobeats_plugin.pb.dart';
import 'music_utils.dart';

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
      this.requestKeyboardFocused})
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
    nameController.value = nameController.value.copyWith(text: scoreManager.currentScoreName);
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
      Future.delayed(Duration(milliseconds: 1), () { widget.requestKeyboardFocused(false); });
    }
    if (showScoreNameEntry && !wasShowingScoreNameEntry) {
      nameFocus.requestFocus();
    }
    if (previousMode != widget.mode) {
      String suggestedName = scoreManager.currentScoreName;
      if (suggestedName == "Pasted Score") {
        suggestedName = widget.openedScore.name;
      }
      nameController.value = nameController.value.copyWith(text: suggestedName);
    }
    previousMode = widget.mode;
    return Column(
      children: [
        AnimatedContainer(
          height: showScoreNameEntry ? 36 : 0,
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
                    child: TextField(
                        focusNode: nameFocus,
                        controller: nameController,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 18),
                        enabled: showScoreNameEntry,
                        decoration: InputDecoration(border: InputBorder.none, hintText: "Score Name"),
                        onChanged: (value) {
                          // widget.melody.name = value;
                          //                          BeatScratchPlugin.updateMelody(widget.melody);
                          BeatScratchPlugin.onSynthesizerStatusChange();
                        },
                      ),
                  )),
                  AnimatedContainer(
                    duration: animationDuration,
                    width: widget.mode == ScorePickerMode.create ? 80 : 0,
                    padding: EdgeInsets.only(right: 5),
                    child: MyFlatButton(
                        color: chromaticSteps[0],
                        onPressed: () {
                          setState(() {
                            if (scoreManager.scoreFiles.any((f) => f.scoreName == nameController.value.text)) {
                              overwritingScoreName = nameController.value.text;
                              int index =
                                  scoreManager.scoreFiles.indexWhere((f) => f.scoreName == nameController.value.text);
                              double position = _Score.width * (index);
                              position = min(_scrollController.position.maxScrollExtent, position);
                              _scrollController.animateTo(position,
                                  duration: animationDuration, curve: Curves.easeInOut);
                            } else {
                              widget.openedScore.reKeyMelodies();
                              scoreManager.createScore(nameController.value.text);
                              overwritingScoreName = null;
                              Future.delayed(Duration(seconds: 1), widget.close);
                            }
                          });
                        },
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
                        onPressed: widget.mode == ScorePickerMode.duplicate && nameController.value.text != "Pasted Score" ? () {
                          setState(() {
                            if (scoreManager.scoreFiles.any((f) => f.scoreName == nameController.value.text)) {
                              overwritingScoreName = nameController.value.text;
                              int index =
                                  scoreManager.scoreFiles.indexWhere((f) => f.scoreName == nameController.value.text);
                              double position = _Score.width * (index);
                              position = min(_scrollController.position.maxScrollExtent, position);
                              _scrollController.animateTo(position,
                                  duration: animationDuration, curve: Curves.easeInOut);
                            } else {
                              widget.openedScore.reKeyMelodies();
                              scoreManager.createScore(nameController.value.text, score: widget.openedScore);
                              overwritingScoreName = null;
                              Future.delayed(Duration(seconds: 1), widget.close);
                            }
                          });
                        } : null,
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
                          nameController.value = nameController.value.copyWith(text: scoreManager.currentScoreName);
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
                  AnimatedContainer(
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
                      ]))
                ])
              : Column(children: [
                  Expanded(child: getList(context)),
                ]),
        ),
      ],
    );
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
          scoreManager: scoreManager,
          deleteScore: () {
            setState(() {
              scoreFile.delete();
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
  static const double height = 200.0;
  final Axis scrollDirection;
  final Color sectionColor;
  final File file;
  final VoidCallback deleteScore;
  final ScoreManager scoreManager;
  final bool openable;
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
      this.currentScoreName})
      : super(key: key);

  @override
  __ScoreState createState() => __ScoreState();
}

class __ScoreState extends State<_Score> {
  bool _confirmingDelete = false;
  DateTime lastFileLastModified;

  Score _previewScore;

  @override
  Widget build(BuildContext context) {
    String scoreName = widget.file?.scoreName ?? "";
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
      lastFileLastModified = lastModified;
    }
    if (scoreName == widget.overwritingScoreName) {
      _confirmingDelete = true;
    }
    Color foregroundColor, backgroundColor;
    if (widget.currentScoreName != scoreName) {
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
                    : null,
                padding: EdgeInsets.all(5),
                child: Column(children: [
                  Row(children: [
//          Icon(Icons.input, color: Colors.white), SizedBox(width:5),
                    Expanded(
                        child: Text(scoreName,
                            style: TextStyle(color: foregroundColor, fontSize: 12, fontWeight: FontWeight.w100))),
//          if(midiController.id == "keyboard")
//            Image.asset("assets/piano.png", width: 16, height: 16),
//          if(midiController.id == "colorboard")
//            Image.asset("assets/colorboard.png", width: 16, height: 16)

                    Container(
                        width: 36,
                        height: 36,
                        child: MyFlatButton(
                            onPressed: () {
                              setState(() {
                                _confirmingDelete = true;
                              });
                            },
                            padding: EdgeInsets.zero,
                            child: Icon(Icons.delete, color: foregroundColor))),
//          SizedBox(width:5),
                  ]),
                  Expanded(
                      child: Column(children: [
                    Expanded(
                        child: previewScore != null
                            ? IgnorePointer(
                                child: MelodyView(
                                initialScale: 0.1,
                                previewMode: true,
                                enableColorboard: false,
                                superSetState: setState,
                                focusPartsAndMelodies: false,
                                melodyViewSizeFactor: 1.0,
                                melodyViewMode: MelodyViewMode.score,
                                score: previewScore,
                                currentSection: previewScore?.sections?.first,
                                colorboardNotesNotifier: ValueNotifier([]),
                                keyboardNotesNotifier: ValueNotifier([]),
                                melody: null,
                                part: null,
                                sectionColor: chromaticSteps[0],
                                splitMode: SplitMode.full,
                                renderingMode: RenderingMode.notation,
                                toggleSplitMode: () {},
                                closeMelodyView: () {},
                                toggleMelodyReference: (r) {},
                                setReferenceVolume: (r, d) {},
                                editingMelody: false,
                                toggleEditingMelody: () {},
                                setPartVolume: (p, v) {},
                                setMelodyName: (m, n) {},
                                setSectionName: (s, n) {},
                                setKeyboardPart: (p) {},
                                setColorboardPart: (p) {},
                                colorboardPart: null,
                                keyboardPart: null,
                                height: _Score.height,
                                deletePart: (part) {},
                                deleteMelody: (melody) {},
                                deleteSection: (section) {},
                                selectBeat: (beat) {},
                                cloneCurrentSection: () {},
                              ))
                            : SizedBox()),
//            Text(scoreName, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
//            if(midiController.id == "keyboard" && !kIsWeb)
//              Text("MIDI controllers connected to your device route to the Keyboard Part.", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
//            if(midiController.id == "colorboard")
//              Switch(
//                activeColor: sectionColor,
//                value: enableColorboard,
//                onChanged: setColorboardEnabled,
////                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
//              ),

//                Expanded(child:SizedBox()),
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
