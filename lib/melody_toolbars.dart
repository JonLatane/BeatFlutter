import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/main.dart';
import 'package:beatscratch_flutter_redux/platform_svg/platform_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'melodybeat.dart';
import 'expanded_section.dart';
import 'part_melodies_view.dart';
import 'dart:math';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:uuid/uuid.dart';
import 'ui_models.dart';
import 'util.dart';
import 'music_theory.dart';

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

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }

    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.melody) {
      confirmingDeleteFor = null;
    }
    return Container(
//        color: Colors.white,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.melodyViewMode == MelodyViewMode.melody)
                  ? TextField(
                      controller: (melodySelected)
                          ? (TextEditingController()..text = widget.melody.name)
                          : TextEditingController(),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (melodySelected)
                          ? (value) {
                              widget.melody.name = value;
                            }
                          : null,
                      onEditingComplete: () {
                        widget.setMelodyName(widget.melody, widget.melody.name);
                      },
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
          child: RaisedButton(
            color: (widget.editingMelody) ? widget.sectionColor : null,
            onPressed: (melodyEnabled)
                ? () {
                    widget.toggleEditingMelody();
                  }
                : null,
            padding: EdgeInsets.all(0),
            child: Image.asset(
              'assets/edit.png',
              fit: BoxFit.fill,
            ),
          )),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 40,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: RaisedButton(
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
          child: RaisedButton(
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
          child: RaisedButton(
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
          child: RaisedButton(
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

class MelodyEditingToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 5),
      Text('This is pre-release software.', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
      Container(width: 5),
      Expanded(child:
      Text('Melody editing features are coming. Ode to Joy is nice.',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w100, fontSize: 12, color: Colors.grey))),
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
            child: RaisedButton(
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
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: RaisedButton(
                onPressed: widget.part != null
                    ? () {
                        widget.setKeyboardPart(widget.part);
                      }
                    : null,
                padding: EdgeInsets.zero,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.part == null || isConfirmingDelete ? 0 : 1,
                    child: Stack(children: [
                      Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                              padding: EdgeInsets.all(2),
                              child: Image.asset("assets/piano.png", width: 22, height: 22))),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                              width: 26,
                              height: 26,
                              child: Checkbox(value: widget.keyboardPart == widget.part, onChanged: null)))
                    ])))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete || !widget.enableColorboard ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: RaisedButton(
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
            child: RaisedButton(
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
            child: RaisedButton(
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
            child: RaisedButton(
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
  final bool editingSection;

  const SectionToolbar(
      {Key key,
      this.currentSection,
      this.sectionColor,
      this.melodyViewMode,
      this.setSectionName,
      this.deleteSection,
      this.canDeleteSection,
      this.editingSection})
      : super(key: key);

  @override
  SectionToolbarState createState() => SectionToolbarState();
}

class SectionToolbarState extends State<SectionToolbar> {
  Section confirmingDeleteFor;

  bool get isConfirmingDelete => confirmingDeleteFor != null && confirmingDeleteFor == widget.currentSection;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.currentSection) {
      confirmingDeleteFor = null;
    }
    return Container(
//        color: sectionColor,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.melodyViewMode == MelodyViewMode.section)
                  ? TextField(
                      style: TextStyle(fontWeight: FontWeight.w100),
                      controller: (widget.melodyViewMode == MelodyViewMode.section)
                          ? (TextEditingController()..text = widget.currentSection.name)
                          : TextEditingController(),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (widget.melodyViewMode == MelodyViewMode.section)
                          ? (value) {
                              widget.currentSection.name = value;
                            }
                          : null,
                      onEditingComplete: () {
                        widget.setSectionName(widget.currentSection, widget.currentSection.name);
                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: (widget.melodyViewMode == MelodyViewMode.section)
                              ? "Section ${widget.currentSection.id.substring(0, 5)}"
                              : ""),
                    )
                  : Text(""))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 95,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: RaisedButton(
            padding: EdgeInsets.zero,
            child: Row(children: [
              Container(
                  width: 36,
                  padding: EdgeInsets.only(top: 7, bottom: 5),
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.center,
                      child: Opacity(opacity: 0.2, child: Image.asset('assets/metronome.png')),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child:
                      Transform.translate(offset: Offset(0, -7), child: Text('123', )),
                    )
                  ])),
              Container(
                width: 24,
                height: 32,
                padding: EdgeInsets.only(left:5),
                child: Stack(children: [
                  Transform.translate(offset: Offset(0, -4), child:
                  Text("4", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
                  Transform.translate(offset: Offset(0, 11), child:
                  Text(
                    "4",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ))
                ])),
              Container(
                width: 24,
                height: 32,
                child: Stack(children: [
                  Transform.translate(offset: Offset(0, -2), child:
                  Text("C", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w200))),
                ])),
              Expanded(child:SizedBox())
            ]),
            onPressed: null,//() => {},
          )),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: RaisedButton(
              onPressed: null,
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
          child: RaisedButton(
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
          child: RaisedButton(
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
          child: RaisedButton(
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
