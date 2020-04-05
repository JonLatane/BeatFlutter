import 'dart:collection';

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
import 'melody_renderer.dart';
import 'melody_toolbars.dart';

class MelodyView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MelodyViewMode melodyViewMode;
  final MelodyViewDisplayMode melodyViewDisplayMode;
  final RenderingMode renderingMode;
  final Score score;
  final Section currentSection;
  final int currentBeat;
  final ValueNotifier<Set<int>> colorboardNotesNotifier;
  final ValueNotifier<Set<int>> keyboardNotesNotifier;
  final Melody melody;
  final Part part;
  final Color sectionColor;
  final VoidCallback toggleMelodyViewDisplayMode;
  final VoidCallback closeMelodyView;
  final VoidCallback toggleEditingMelody;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Function(Part, double) setPartVolume;
  final Function(Melody, String) setMelodyName;
  final Function(Section, String) setSectionName;
  final bool editingMelody;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Part colorboardPart;
  final Part keyboardPart;
  final Function(Part) deletePart;
  final Function(Melody) deleteMelody;
  final Function(Section) deleteSection;

  MelodyView(
      {this.melodyViewSizeFactor,
      this.melodyViewMode,
      this.score,
      this.currentSection,
      this.melody,
      this.part,
      this.sectionColor,
      this.melodyViewDisplayMode,
      this.toggleMelodyViewDisplayMode,
      this.closeMelodyView,
      this.toggleMelodyReference,
      this.setReferenceVolume,
      this.setPartVolume,
      this.editingMelody,
      this.toggleEditingMelody,
      this.setMelodyName,
      this.setSectionName,
      this.setKeyboardPart,
      this.setColorboardPart,
      this.colorboardPart,
      this.keyboardPart,
      this.deletePart,
      this.deleteMelody,
      this.deleteSection,
      this.renderingMode,
      this.currentBeat, this.colorboardNotesNotifier, this.keyboardNotesNotifier});

  @override
  _MelodyViewState createState() => _MelodyViewState();
}

class _MelodyViewState extends State<MelodyView> {
  @override
  Widget build(context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: animationDuration,
          color: (widget.melodyViewMode == MelodyViewMode.section)
              ? widget.sectionColor
              : (widget.melodyViewMode == MelodyViewMode.melody)
                  ? Colors.white
                  : (widget.melodyViewMode == MelodyViewMode.part)
                      ? ((widget.part != null && widget.part.instrument.type == InstrumentType.drum)
                          ? Colors.brown
                          : Colors.grey)
                      : Colors.black,
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: AnimatedContainer(
                    duration: animationDuration,
                    width: 36,
                    height: (widget.melodyViewMode != MelodyViewMode.score) ? 36 : 0,
                    child: RaisedButton(
                        onPressed: widget.toggleMelodyViewDisplayMode,
                        padding: EdgeInsets.all(7),
                        child: widget.melodyViewDisplayMode == MelodyViewDisplayMode.half
                            ? Image.asset("assets/split_full.png")
                            : context.isPortrait
                                ? Image.asset("assets/split_horizontal.png")
                                : Image.asset("assets/split_vertical.png"))),
              ),
              Expanded(
                  child: Column(children: [
                AnimatedContainer(
                    duration: animationDuration,
                    height: (widget.melodyViewMode == MelodyViewMode.section) ? 48 : 0,
                    child: SectionToolbar(
                      currentSection: widget.currentSection,
                      sectionColor: widget.sectionColor,
                      melodyViewMode: widget.melodyViewMode,
                      setSectionName: widget.setSectionName,
                      deleteSection: widget.deleteSection,
                      canDeleteSection: widget.score.sections.length > 1,
                    )),
                AnimatedContainer(
                    duration: animationDuration,
                    height: (widget.melodyViewMode == MelodyViewMode.part) ? 48 : 0,
                    child: PartToolbar(
                        part: widget.part,
                        setKeyboardPart: widget.setKeyboardPart,
                        setColorboardPart: widget.setColorboardPart,
                        colorboardPart: widget.colorboardPart,
                        keyboardPart: widget.keyboardPart,
                        deletePart: widget.deletePart)),
                    AnimatedContainer(
                      duration: animationDuration,
                      height: (widget.melodyViewMode == MelodyViewMode.melody) ? 48 : 0,
                      child: MelodyToolbar(
                        melody: widget.melody,
                        melodyViewMode: widget.melodyViewMode,
                        currentSection: widget.currentSection,
                        toggleMelodyReference: widget.toggleMelodyReference,
                        setReferenceVolume: widget.setReferenceVolume,
                        editingMelody: widget.editingMelody,
                        sectionColor: widget.sectionColor,
                        toggleEditingMelody: widget.toggleEditingMelody,
                        setMelodyName: widget.setMelodyName,
                        deleteMelody: widget.deleteMelody,
                      )),
              ])),Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: AnimatedContainer(
                      duration: animationDuration,
                      width: 36,
                      height: (widget.melodyViewMode != MelodyViewMode.score) ? 36 : 0,
                      child: RaisedButton(
                          onPressed: widget.closeMelodyView, padding: EdgeInsets.all(0), child: Icon(Icons.close))))
            ],
          ),
        ),
        AnimatedContainer(
          color: Colors.white,
          duration: animationDuration,
          height: (widget.melodyViewMode == MelodyViewMode.melody && widget.editingMelody) ? 24 : 0,
          child: MelodyEditingToolbar()),
        Expanded(child: _mainMelody(context))
      ],
    );
  }

  Offset _previousOffset = Offset.zero;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  double _horizontalScale = 1.0;
  double _verticalScale = 1.0;

  Widget _mainMelody(BuildContext context) {
    return Container(
        color: Colors.white,
        child: GestureDetector(
            onScaleStart: (details) => setState(() {
                  _previousOffset = _offset;
                  _startFocalPoint = details.focalPoint;
                  _startHorizontalScale = _horizontalScale;
                  _startVerticalScale = _verticalScale;
                }),
            onScaleUpdate: (ScaleUpdateDetails details) {
              setState(() {
                if (details.horizontalScale > 0) {
                  _horizontalScale = max(0.1, min(16, _startHorizontalScale * details.horizontalScale));
                }
                if (details.horizontalScale > 0) {
                  _verticalScale = max(0.1, min(16, _startVerticalScale * details.verticalScale));
                }
                final Offset normalizedOffset = (_startFocalPoint - _previousOffset) / _startHorizontalScale;
                final Offset newOffset = details.focalPoint - normalizedOffset * _horizontalScale;
                _offset = newOffset;
              });
            },
            onScaleEnd: (ScaleEndDetails details) {
              //_horizontalScale = max(0.1, min(16, _horizontalScale.ceil().toDouble()));
            },
            child: MelodyRenderer(
              score: widget.score,
              section: widget.melodyViewMode != MelodyViewMode.score ? widget.currentSection : null,
              currentBeat: widget.currentBeat,
              colorboardNotesNotifier: widget.colorboardNotesNotifier,
              keyboardNotesNotifier: widget.keyboardNotesNotifier,
              focusedMelody: widget.melody,
              renderingMode: widget.renderingMode,
              xScale: _horizontalScale,
              yScale: _verticalScale,
            )
//          GridView.builder(
//            gridDelegate:
//                new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: max(1, (16 / _horizontalScale).floor())),
//            itemCount: 12,
//            itemBuilder: (BuildContext context, int index) {
//              return GridTile(
//                  child: Transform.scale(
//                      scale: 1 - 0.2 * ((16 / _horizontalScale).floor() - (16 / _horizontalScale)).abs(),
//                      child: SvgPicture.asset('assets/notehead_half.svg')));
//            },
//          ),
            ));
  }
}

