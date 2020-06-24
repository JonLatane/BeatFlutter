import 'package:beatscratch_flutter_redux/clearCaches.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'beatscratch_plugin.dart';
import 'music_theory.dart';
import 'no_stupid_hands.dart';
import 'part_melodies_view.dart';
import 'ui_models.dart';
import 'util.dart';

class MelodyToolbar extends StatefulWidget {
  final MelodyViewMode melodyViewMode;
  final bool editingMelody;
  final Melody melody;
  final Section currentSection;
  final Color sectionColor;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final VoidCallback toggleEditingMelody;
  final Function(Melody, String) setMelodyName;
  final Function(Melody) deleteMelody;

  const MelodyToolbar(
      {Key key,
      this.melody,
      this.currentSection,
      this.toggleMelodyReference,
      this.setReferenceVolume,
      this.editingMelody,
      this.sectionColor,
      this.toggleEditingMelody,
      this.setMelodyName,
      this.melodyViewMode,
      this.deleteMelody})
      : super(key: key);

  @override
  MelodyToolbarState createState() => MelodyToolbarState();
}

class MelodyToolbarState extends State<MelodyToolbar> {
  MelodyReference get melodyReference => widget.currentSection.referenceTo(widget.melody);

  bool get melodySelected => widget.melody != null;

  bool get melodyEnabled => melodySelected && melodyReference.playbackType != MelodyReference_PlaybackType.disabled;

  Melody confirmingDeleteFor;

  bool get isConfirmingDelete => confirmingDeleteFor != null && confirmingDeleteFor == widget.melody;

  TextEditingController nameController = TextEditingController();
  @override
  dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }

    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.melody) {
      confirmingDeleteFor = null;
    }
    nameController.value = nameController.value.copyWith(text: widget.melody?.name ?? "");
    return Container(
//        color: Colors.white,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.melodyViewMode == MelodyViewMode.melody)
                  ? TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (melodySelected)
                          ? (value) {
                        widget.melody.name = value;
                        widget.setMelodyName(widget.melody, widget.melody.name);
//                        BeatScratchPlugin.updateMelody(widget.melody);
                            }
                          : null,
//                      onEditingComplete: () {
//                        widget.setMelodyName(widget.melody, widget.melody.name);
//                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: (melodySelected) ? "Melody ${widget.melody.id.substring(0, 5)}" : ""),
                    )
                  : Text(""))),
      AnimatedContainer(
          duration: animationDuration,
          width: (melodyEnabled && !isConfirmingDelete) ? 40 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
            color: (widget.editingMelody)
              ? widget.sectionColor == chromaticSteps[7]
              ? Colors.white : widget.sectionColor : null,
            onPressed: (melodyEnabled)
                ? () {
                    widget.toggleEditingMelody();
                  }
                : null,
            padding: EdgeInsets.all(0),
            child: AnimatedOpacity(duration: animationDuration, opacity: (melodyEnabled && !isConfirmingDelete) ? 1 : 0,
              child: Stack(children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.fiber_manual_record, color: chromaticSteps[7])),
                Align(
                  alignment: Alignment.topLeft,
                  child: Icon(Icons.edit,))
              ])
            ),
          )),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 40,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: melodySelected
                  ? () {
                      widget.toggleMelodyReference(melodyReference);
                    }
                  : null,
              padding: EdgeInsets.all(0),
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: (melodySelected && !isConfirmingDelete) ? 1 : 0,
                  child: Icon(melodySelected
                      ? (melodyEnabled ? Icons.volume_up : Icons.not_interested)
                      : Icons.not_interested)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 128 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: Align(
              alignment: Alignment.center,
              child: Text("Really delete?",
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.black)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  widget.deleteMelody(confirmingDeleteFor);
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text(
                "Yes",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  confirmingDeleteFor = widget.melody;
                });
              },
              padding: EdgeInsets.zero,
              child: Padding(padding: EdgeInsets.all(5), child: Image.asset("assets/trash.png")))),
    ]));
  }
}

class MelodyEditingToolbar extends StatefulWidget {
  final String melodyId;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final bool editingMelody;
  Melody get melody => score.parts.expand((p) => p.melodies).firstWhere((m) => m.id == melodyId, orElse: () => null);

  const MelodyEditingToolbar({Key key, this.melodyId, this.sectionColor, this.score, this.currentSection, this.editingMelody}) : super(key: key);

  @override
  _MelodyEditingToolbarState createState() => _MelodyEditingToolbarState();
}

class _MelodyEditingToolbarState extends State<MelodyEditingToolbar> with TickerProviderStateMixin {
  AnimationController animationController;
  Color recordingAnimationColor;
  Animation<Color> recordingAnimation;
  bool showHoldToClear = false;
  bool showDataCleared = false;
  bool animationStarted = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    recordingAnimation = ColorTween(
      begin: Colors.grey,
      end: chromaticSteps[7],
    ).animate(animationController)
      ..addListener(() {
        setState(() {
          recordingAnimationColor = recordingAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!animationStarted && widget.editingMelody && BeatScratchPlugin.playing) {
      animationController.repeat(reverse: true);
      animationStarted = true;
    } else if (widget.editingMelody || !BeatScratchPlugin.playing) {
      animationController.stop(canceled: false);
      animationStarted = false;
    }
    Color recordingColor;
    if(widget.editingMelody && BeatScratchPlugin.playing) {
      recordingColor = recordingAnimationColor;
    } else {
      recordingColor = Colors.grey;
    }
    int beats;
    if(widget.melody != null) {
      beats = widget.melody.length ~/ widget.melody.subdivisionsPerBeat;
    }
    return Row(children: [
      SizedBox(width: 5),
      Column(children: [
        Transform.translate(offset: Offset(0, 5), child:
        Icon(Icons.fiber_manual_record, color: recordingColor)),
        Text('Recording',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w100, fontSize: 12, color: recordingColor)),
      ]),
      AnimatedContainer(
        duration: animationDuration,
        width: 44,
        height: 36,
        padding: EdgeInsets.only(left: 8),
        child:  MyRaisedButton(
          padding: EdgeInsets.zero,
          onLongPress: widget.melody != null ? () {
            print("clearing");
            widget.melody.midiData.data.clear();
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateMelody(widget.melody);
            setState(() {
              showDataCleared = true;
            });
            Future.delayed(Duration(seconds: 3), () {
              setState(() {
                showDataCleared = false;
              });
            });
          } : null,
          onPressed: () {
            setState(() {
              showHoldToClear = true;
            });
            Future.delayed(Duration(seconds: 3), () {
              setState(() {
                showHoldToClear = false;
              });
            });
          },
          child: AnimatedOpacity(duration: animationDuration, opacity: widget.editingMelody ? 1 : 0,
            child: Icon(Icons.delete_sweep)))),
      AnimatedContainer(
        duration: animationDuration,
        width: showHoldToClear ? 35 : 0,
        height: 36,
        padding: EdgeInsets.only(left: 5),
        child:  AnimatedOpacity(duration: animationDuration, opacity: widget.melody != null && showHoldToClear ? 1 : 0,
          child: Stack(children:[
            Transform.translate(offset: Offset(0, -7), child: Align(alignment: Alignment.center, child:
            Text("Hold", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            Transform.translate(offset: Offset(0,  0), child:Align(alignment: Alignment.center, child:
            Text("to", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            Transform.translate(offset: Offset(0, 7), child: Align(alignment: Alignment.center, child:
            Text("clear", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
          ]))),
      AnimatedContainer(
        duration: animationDuration,
        width: showDataCleared ? 40 : 0,
        height: 36,
        padding: EdgeInsets.only(left: 5),
        child:  AnimatedOpacity(duration: animationDuration, opacity: widget.melody != null && showDataCleared ? 1 : 0,
          child: Stack(children:[
            Transform.translate(offset: Offset(0, -7), child: Align(alignment: Alignment.center, child:
            Text("Data", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            Transform.translate(offset: Offset(0, 7), child: Align(alignment: Alignment.center, child:
            Text("cleared", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
          ]))),
      Expanded(child: SizedBox(width: 5),),
      IncrementableValue(
        onDecrement: (widget.melody != null && widget.melody.beatCount > 1)
          ? () {
          if(widget.melody != null && widget.melody.beatCount > 1) {
            widget.melody.length -= widget.melody.subdivisionsPerBeat;
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
        onIncrement: (widget.melody != null && widget.melody.beatCount <= 999)
          ? () {
          if (widget.melody != null && widget.melody.beatCount <= 999) {
            widget.melody.length += widget.melody.subdivisionsPerBeat;
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        }
          : null,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5), child:BeatsBadge(beats: beats)),
//        valueWidth: 100,
//        value: "$beats beat${beats == 1 ? "" : "s"}",
      ),
      SizedBox(width: 5),
      IncrementableValue(
        onDecrement: (widget.melody?.subdivisionsPerBeat ?? -1) > 1 ? () {
          if((widget.melody?.subdivisionsPerBeat ?? -1) > 1) {
            widget.melody?.subdivisionsPerBeat -= 1;
            widget.melody.length = beats * widget.melody.subdivisionsPerBeat;
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
        onIncrement: (widget.melody?.subdivisionsPerBeat ?? -1) < 24 ? () {
          if ((widget.melody?.subdivisionsPerBeat ?? -1) < 24) {
            widget.melody?.subdivisionsPerBeat += 1;
            widget.melody.length = beats * widget.melody.subdivisionsPerBeat;
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          child:BeatsBadge(beats: widget.melody?.subdivisionsPerBeat, isPerBeat: true,)),
      ),
      SizedBox(width: 5),
    ]);
  }
}

class PartToolbar extends StatefulWidget {
  final Color sectionColor;
  final Part part;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Part colorboardPart;
  final Part keyboardPart;
  final Function(Part) deletePart;
  final bool configuringPart;
  final VoidCallback toggleConfiguringPart;
  final bool enableColorboard;

  const PartToolbar(
      {Key key,
      this.part,
      this.setKeyboardPart,
      this.setColorboardPart,
      this.colorboardPart,
      this.keyboardPart,
      this.deletePart,
      this.configuringPart,
      this.toggleConfiguringPart,
      this.sectionColor, this.enableColorboard})
      : super(key: key);

  @override
  PartToolbarState createState() => PartToolbarState();
}

class PartToolbarState extends State<PartToolbar> {
  Part confirmingDeleteFor;

  bool get isConfirmingDelete => confirmingDeleteFor != null && confirmingDeleteFor == widget.part;

  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.part) {
      confirmingDeleteFor = null;
    }
    return Container(
      key: Key("part-toolbar-${widget.part?.id}"),
      child: Row(children: [
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(left: 5),
            child: MyRaisedButton(
                onPressed: widget.toggleConfiguringPart,
                padding: EdgeInsets.zero,
                color: widget.configuringPart ? Colors.black : null,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.part == null || isConfirmingDelete ? 0 : 1,
                    child: Icon(Icons.settings, color: widget.configuringPart ? Colors.white : Colors.black)))),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text((widget.part != null) ? widget.part.midiName : "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)))),
//        AnimatedContainer(
//            duration: animationDuration,
//            width: isConfirmingDelete ? 0 : 41,
//            height: 36,
//            padding: EdgeInsets.only(right: 5),
//            child: MyRaisedButton(
//                onPressed: widget.part != null
//                    ? () {
//                        widget.setKeyboardPart(widget.part);
//                      }
//                    : null,
//                padding: EdgeInsets.zero,
//                child: AnimatedOpacity(
//                    duration: animationDuration,
//                    opacity: widget.part == null || isConfirmingDelete ? 0 : 1,
//                    child: Stack(children: [
//                      Align(
//                          alignment: Alignment.bottomRight,
//                          child: Padding(
//                              padding: EdgeInsets.all(2),
//                              child: Image.asset("assets/piano.png", width: 22, height: 22))),
//                      Align(
//                          alignment: Alignment.topLeft,
//                          child: Container(
//                              width: 26,
//                              height: 26,
//                              child: Checkbox(value: widget.keyboardPart == widget.part, onChanged: null)))
//                    ])))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete || !widget.enableColorboard ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: (widget.part != null && widget.part.instrument.type != InstrumentType.drum)
                    ? () {
                        widget.setColorboardPart(widget.part);
                      }
                    : null,
                padding: EdgeInsets.zero,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.part == null || isConfirmingDelete || !widget.enableColorboard ? 0 : 1,
                    child: Stack(children: [
                      Align(
                          alignment: Alignment.bottomRight,
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: (widget.part != null && widget.part.instrument.type != InstrumentType.drum)
                                  ? 1
                                  : 0.25,
                              child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Image.asset("assets/colorboard.png", width: 24, height: 24)))),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                              width: 26,
                              height: 26,
                              child: Checkbox(value: widget.colorboardPart == widget.part, onChanged: null)))
                    ])))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 128 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: Align(
                alignment: Alignment.center,
                child: Text("Really delete?",
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white)))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 48 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    widget.deletePart(widget.part);
                    confirmingDeleteFor = null;
                  });
                },
                padding: EdgeInsets.zero,
                child: Text(
                  "Yes",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 48 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    confirmingDeleteFor = null;
                  });
                },
                padding: EdgeInsets.zero,
                child: Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    confirmingDeleteFor = widget.part;
                  });
                },
                padding: EdgeInsets.zero,
                child: Padding(padding: EdgeInsets.all(5), child: Image.asset("assets/trash.png")))),
      ]),
    );
  }
}

class SectionToolbar extends StatefulWidget {
  // This widget is the root of your application.
  final bool canDeleteSection;
  final Section currentSection;
  final Color sectionColor;
  final MelodyViewMode melodyViewMode;
  final Function(Section, String) setSectionName;
  final Function(Section) deleteSection;
  final Function cloneCurrentSection;
  final bool editingSection;
  final Function(bool) setEditingSection;

  const SectionToolbar(
      {Key key,
      this.currentSection,
      this.sectionColor,
      this.melodyViewMode,
      this.setSectionName,
      this.deleteSection,
      this.canDeleteSection,
      this.editingSection, this.cloneCurrentSection, this.setEditingSection})
      : super(key: key);

  @override
  SectionToolbarState createState() => SectionToolbarState();
}

class SectionToolbarState extends State<SectionToolbar> {
  Section confirmingDeleteFor;

  bool get isConfirmingDelete => confirmingDeleteFor != null && confirmingDeleteFor == widget.currentSection;

  TextEditingController nameController = TextEditingController();
  @override
  dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.currentSection) {
      confirmingDeleteFor = null;
    }
    nameController.value = nameController.value.copyWith(text: widget.currentSection.name ?? "");
    return Container(
//        color: sectionColor,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.melodyViewMode == MelodyViewMode.section)
                  ? TextField(
                      style: TextStyle(fontWeight: FontWeight.w100),
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (widget.melodyViewMode == MelodyViewMode.section)
                          ? (value) {
                              widget.currentSection.name = value;
                              widget.setSectionName(widget.currentSection, widget.currentSection.name);
                            }
                          : null,
//                      onEditingComplete: () {
//                        widget.setSectionName(widget.currentSection, widget.currentSection.name);
//                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: (widget.melodyViewMode == MelodyViewMode.section)
                              ? "Section ${widget.currentSection.id.substring(0, 5)}"
                              : ""),
                    )
                  : Text(""))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
            padding: EdgeInsets.zero,
            color: widget.editingSection ? Colors.white : null,
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: widget.melodyViewMode != MelodyViewMode.section || isConfirmingDelete ? 0 : 1,
              child: Icon(Icons.edit)),
            onPressed: () {
              widget.setEditingSection(!widget.editingSection);
            },
          )),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: widget.cloneCurrentSection,
              padding: EdgeInsets.zero,
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: widget.melodyViewMode != MelodyViewMode.section || isConfirmingDelete ? 0 : 1,
                  child: Icon(Icons.control_point_duplicate)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 128 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: Align(
              alignment: Alignment.center,
              child: Text("Really delete?",
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  widget.deleteSection(confirmingDeleteFor);
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text(
                "Yes",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: widget.canDeleteSection
                  ? () {
                      setState(() {
                        confirmingDeleteFor = widget.currentSection;
                      });
                    }
                  : null,
              padding: EdgeInsets.zero,
              child: Padding(padding: EdgeInsets.all(5), child: Image.asset("assets/trash.png")))),
    ]));
  }
}


class SectionEditingToolbar extends StatefulWidget {
  final Score score;
  final Color sectionColor;
  final Section currentSection;

  const SectionEditingToolbar({Key key, this.sectionColor, this.score, this.currentSection}) : super(key: key);

  @override
  _SectionEditingToolbarState createState() => _SectionEditingToolbarState();
}

class _SectionEditingToolbarState extends State<SectionEditingToolbar> with TickerProviderStateMixin {
  AnimationController animationController;
  Color recordingAnimationColor;
  Animation<Color> recordingAnimation;

  static final List<NoteName> keys = [
    NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.natural,
    NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.sharp,
    NoteName()..noteLetter = NoteLetter.D..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.D..noteSign = NoteSign.natural,
    NoteName()..noteLetter = NoteLetter.D..noteSign = NoteSign.sharp,
    NoteName()..noteLetter = NoteLetter.E..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.E..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.E..noteSign = NoteSign.sharp,
//    NoteName()..noteLetter = NoteLetter.F..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.F..noteSign = NoteSign.natural,
    NoteName()..noteLetter = NoteLetter.F..noteSign = NoteSign.sharp,
    NoteName()..noteLetter = NoteLetter.G..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.G..noteSign = NoteSign.natural,
    NoteName()..noteLetter = NoteLetter.G..noteSign = NoteSign.sharp,
    NoteName()..noteLetter = NoteLetter.A..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.A..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.A..noteSign = NoteSign.sharp,
    NoteName()..noteLetter = NoteLetter.B..noteSign = NoteSign.flat,
    NoteName()..noteLetter = NoteLetter.B..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.B..noteSign = NoteSign.sharp,
  ];

  @override
  void initState() {
    super.initState();
//    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    super.dispose();
//    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
//    recordingAnimation = ColorTween(
//      begin: Colors.grey,
//      end: chromaticSteps[7],
//    ).animate(animationController)
//      ..addListener(() {
//        setState(() {
//          recordingAnimationColor = recordingAnimation.value;
//        });
//      });
//    animationController.repeat(reverse: true);
//    Color recordingColor;
//    if(widget.melody != null && BeatScratchPlugin.playing) {
//      recordingColor = recordingAnimationColor;
//    } else {
//      recordingColor = Colors.grey;
//    }
    NoteName key = widget.currentSection.harmony.data[0].rootNote;
    int keyIndex = keys.indexOf(key);
    return Row(children: [
      SizedBox(width:5),
      IncrementableValue(
        onDecrement: (widget.currentSection.meter.defaultBeatsPerMeasure > 1)
          ? () {
          if(widget.currentSection.meter.defaultBeatsPerMeasure > 1) {
            widget.currentSection.meter.defaultBeatsPerMeasure -= 1;
            MelodyTheory.tonesInMeasureCache.clear();
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateSections(widget.score);
          }
        } : null,
        onIncrement: (widget.currentSection.meter.defaultBeatsPerMeasure < 99)
          ? () {
          if(widget.currentSection.meter.defaultBeatsPerMeasure < 99) {
            widget.currentSection.meter.defaultBeatsPerMeasure += 1;
            MelodyTheory.tonesInMeasureCache.clear();
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateSections(widget.score);
          }
        } : null,
        child: Container(
          width: 30,
          height: 32,
          padding: EdgeInsets.only(left:5),
          child: Stack(children: [
            Align(alignment: Alignment.center, child:
            Transform.translate(offset: Offset(-1.5, -9), child:
            Text(widget.currentSection.meter.defaultBeatsPerMeasure.toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)))),
            Align(alignment: Alignment.center, child:
            Transform.translate(offset: Offset(-1.5, 6), child:
            Text("4",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            )))
          ])),
      ),
      SizedBox(width:5),
      IncrementableValue(
        onDecrement: () {
          int newKeyIndex = keyIndex - 1;
          if (newKeyIndex < 0) {
            newKeyIndex += keys.length;
          }
          widget.currentSection.harmony.data[0].rootNote = keys[newKeyIndex];
          MelodyTheory.tonesInMeasureCache.clear();
          BeatScratchPlugin.onSynthesizerStatusChange();
          BeatScratchPlugin.updateSections(widget.score);
          clearMutableCaches();

//          BeatScratchPlugin.updateMelody(widget.currentSection.harmony);
        },
        onIncrement: () {
          int newKeyIndex = keyIndex + 1;
          if (newKeyIndex >= keys.length) {
            newKeyIndex -= keys.length;
          }
          widget.currentSection.harmony.data[0].rootNote = keys[newKeyIndex];
          MelodyTheory.tonesInMeasureCache.clear();
          BeatScratchPlugin.onSynthesizerStatusChange();
          BeatScratchPlugin.updateSections(widget.score);
          clearMutableCaches();
        },
        child: Container(
          width: 30,
          height: 32,
          padding: EdgeInsets.only(left:5),
          child: Align(alignment: Alignment.center,
            child: Transform.translate(offset: Offset(-1.5, -2),
              child:Text(key.simpleString, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w200))))),
      ),
      SizedBox(width:5),
      IncrementableValue(
        onDecrement: null,
        onIncrement: null,
        child: Container(
          width: 36,
          padding: EdgeInsets.only(top: 7, bottom: 5),
          child: Stack(children: [
            Align(
              alignment: Alignment.center,
              child: Opacity(opacity: 0.4, child: Image.asset('assets/metronome.png')),
            ),
            Align(
              alignment: Alignment.centerRight,
              child:
              Transform.translate(offset: Offset(0, -7), child:
              Text('123', style: TextStyle(fontWeight: FontWeight.w700) )),
            )
          ])),
      ),
      Expanded(child: SizedBox(width: 5),),
      IncrementableValue(
        onDecrement: (widget.currentSection.beatCount > 1)
          ? () {
          if(widget.currentSection.beatCount > 1) {
            widget.currentSection.harmony.length -= widget.currentSection.harmony.subdivisionsPerBeat;
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateSections(widget.score);
          }

//          BeatScratchPlugin.updateMelody(widget.currentSection.harmony);
        } : null,
        onIncrement: (widget.currentSection.beatCount <= 999)
          ? () {
          if(widget.currentSection.beatCount <= 999) {
            widget.currentSection.harmony.length += widget.currentSection.harmony.subdivisionsPerBeat;
            BeatScratchPlugin.onSynthesizerStatusChange();
            BeatScratchPlugin.updateSections(widget.score);
          }
//          BeatScratchPlugin.updateMelody(widget.melody);
        }
          : null,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5), child:BeatsBadge(beats: widget.currentSection.beatCount)),
      ),
      SizedBox(width: 5),
//      IncrementableValue(
//        onDecrement: null,
//        onIncrement: null,
//        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
//          child:BeatsBadge(beats: widget.currentSection.harmony.subdivisionsPerBeat, isPerBeat: true,)),
//      ),
      SizedBox(width: 5),
    ]);
  }
}