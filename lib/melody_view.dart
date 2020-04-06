import 'dart:collection';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/main.dart';
import 'package:beatscratch_flutter_redux/platform_svg/platform_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'instrument_picker.dart';
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
  final ValueNotifier<Set<int>> colorboardNotesNotifier, keyboardNotesNotifier;
  final Melody melody;
  final Part part;
  final Color sectionColor;
  final VoidCallback toggleMelodyViewDisplayMode, closeMelodyView, toggleEditingMelody;
  final Function(VoidCallback) superSetState;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Function(Part, double) setPartVolume;
  final Function(Melody, String) setMelodyName;
  final Function(Section, String) setSectionName;
  final bool editingMelody;
  final Function(Part) setKeyboardPart, setColorboardPart;
  final Part keyboardPart, colorboardPart;
  final Function(Part) deletePart;
  final Function(Melody) deleteMelody;
  final Function(Section) deleteSection;

  MelodyView(
      {this.melodyViewSizeFactor,
        this.superSetState,
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

class _MelodyViewState extends State<MelodyView> with TickerProviderStateMixin {
  bool isConfiguringPart = false;
  Offset _previousOffset = Offset.zero;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _xScale = null;
  double get xScale => _xScale;
  List<AnimationController> _xScaleAnimationControllers = [];
  set xScale(double value) {
    _xScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _xScaleAnimationControllers.clear();
    AnimationController scaleAnimationController = animationController();
    _xScaleAnimationControllers.add(scaleAnimationController);
    Animation animation;
    print("animating xScale to $value");
    animation = Tween<double>(begin: _xScale, end: value)
      .animate(scaleAnimationController)
      ..addListener(() {
        setState(() { _xScale = animation.value; });
      });
    scaleAnimationController.forward();
  }
  double _yScale = null;
  double get yScale => _yScale;
  List<AnimationController> _yScaleAnimationControllers = [];
  set yScale(double value) {
    _yScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _yScaleAnimationControllers.clear();
    AnimationController scaleAnimationController = animationController();
    _yScaleAnimationControllers.add(scaleAnimationController);
    Animation animation;
    animation = Tween<double>(begin: _yScale, end: value)
      .animate(scaleAnimationController)
      ..addListener(() {
        setState(() { _yScale = animation.value; });
      });
    scaleAnimationController.forward();
  }

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    _xScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _yScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _xScaleAnimationControllers.clear();
    _yScaleAnimationControllers.clear();
    super.dispose();
  }
  makeFullSize() {
    if(widget.melodyViewDisplayMode == MelodyViewDisplayMode.half) {
      widget.toggleMelodyViewDisplayMode();
    }
  }
  @override
  Widget build(context) {
    if(_xScale == null) {
      if(context.isTablet) {
        _xScale = 1;
        _yScale = 1;
      } else {
        _xScale = 0.66;
        _yScale = 0.66;
      }
    }
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
                        configuringPart: isConfiguringPart,
                        toggleConfiguringPart: () {setState(() {
                          isConfiguringPart = !isConfiguringPart;
                          if(isConfiguringPart && !context.isTablet) {
                            makeFullSize();
                          }
                        });},
                        setColorboardPart: widget.setColorboardPart,
                        colorboardPart: widget.colorboardPart,
                        keyboardPart: widget.keyboardPart,
                        deletePart: widget.deletePart,
                      sectionColor: widget.sectionColor)),
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
          duration: animationDuration,
          color: widget.part != null && widget.part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
          height: (widget.melodyViewMode == MelodyViewMode.part && isConfiguringPart) ? 280 : 0,
          child: PartConfiguration(part: widget.part, superSetState: widget.superSetState)),
        AnimatedContainer(
          color: Colors.white,
          duration: animationDuration,
          height: (widget.melodyViewMode == MelodyViewMode.melody && widget.editingMelody) ? 24 : 0,
          child: MelodyEditingToolbar()),
        Expanded(child: _mainMelody(context))
      ],
    );
  }

  static const double maxScaleDiscrepancy = 1.5;
  static const double minScaleDiscrepancy = 1/maxScaleDiscrepancy;
  Widget _mainMelody(BuildContext context) {
    return Container(
        color: Colors.white,
        child: GestureDetector(
            onScaleStart: (details) => setState(() {
                  _previousOffset = _offset;
                  _startFocalPoint = details.focalPoint;
                  _startHorizontalScale = xScale;
                  _startVerticalScale = yScale;
                }),
            onScaleUpdate: (ScaleUpdateDetails details) {
              setState(() {
                if (details.horizontalScale > 0) {
                  _xScale = max(0.1, min(16, _startHorizontalScale * details.horizontalScale));
//                  if(_xScale > maxScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
//                  if(_xScale < minScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
                }
                if (details.verticalScale > 0) {
                  _yScale = max(0.1, min(16, _startVerticalScale * details.verticalScale));
                }
                final Offset normalizedOffset = (_startFocalPoint - _previousOffset) / _startHorizontalScale;
                final Offset newOffset = details.focalPoint - normalizedOffset * xScale;
                _offset = newOffset;
              });
            },
            onScaleEnd: (ScaleEndDetails details) {
              //_horizontalScale = max(0.1, min(16, _horizontalScale.ceil().toDouble()));
            },
            child: Stack(children:[
              MelodyRenderer(
                melodyViewMode: widget.melodyViewMode,
                score: widget.score,
                section: widget.melodyViewMode != MelodyViewMode.score ? widget.currentSection : null,
                currentBeat: widget.currentBeat,
                colorboardNotesNotifier: widget.colorboardNotesNotifier,
                keyboardNotesNotifier: widget.keyboardNotesNotifier,
                focusedMelody: widget.melody,
                renderingMode: widget.renderingMode,
                xScale: _xScale,
                yScale: _xScale,
              ),
              Align(alignment: Alignment.topRight,child:Padding(padding:EdgeInsets.only(right:5), child:Opacity(opacity: 0.8, child:Column(children: [
                Container(
                  width: 36,
                  child: RaisedButton(
                    padding: EdgeInsets.all(0),
                    onPressed: (xScale < 16 || yScale < 16)
                      ? () {
                      setState(() {
                        if(xScale < 16) xScale *= 1.62;
                        if(yScale < 16) yScale *= 1.62;
                        print("zoomIn done; xScale=$xScale, yScale=$yScale");
                      });
                    } : null,
                    child: Icon(Icons.zoom_in))),
                Container(
                  width: 36,
                  child: RaisedButton(
                    padding: EdgeInsets.all(0),
                    onPressed: (xScale > 0.1 || yScale > 0.1)
                      ? () {
                      setState(() {
                        if(xScale > 0.1) xScale /= 1.62;
                        if(yScale > 0.1) yScale /= 1.62;
                        print("zoomOut done; xScale=$xScale, yScale=$yScale");
                      });
                    } : null,
                    child: Icon(Icons.zoom_out))),
              ]))))
            ])
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

