import 'dart:math';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'instrument_picker.dart';
import 'melody_renderer.dart';
import 'melody_toolbars.dart';
import 'music_theory.dart';
import 'music_notation_theory.dart';
import 'ui_models.dart';
import 'util.dart';

class MelodyView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MelodyViewMode melodyViewMode;
  final SplitMode splitMode;
  final RenderingMode renderingMode;
  final bool focusPartsAndMelodies;
  final Score score;
  final Section currentSection;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier, keyboardNotesNotifier;
  final Melody melody;
  final Part part;
  final Color sectionColor;
  final VoidCallback toggleSplitMode, closeMelodyView, toggleEditingMelody;
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
  final double height;
  final bool enableColorboard;
  final Function(int) selectBeat;

  MelodyView(
      {this.selectBeat,this.focusPartsAndMelodies, this.melodyViewSizeFactor,
        this.superSetState,
      this.melodyViewMode,
      this.score,
      this.currentSection,
      this.melody,
      this.part,
      this.sectionColor,
      this.splitMode,
      this.toggleSplitMode,
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
  this.colorboardNotesNotifier, this.keyboardNotesNotifier, this.height, this.enableColorboard});

  @override
  _MelodyViewState createState() => _MelodyViewState();
}

class _MelodyViewState extends State<MelodyView> with TickerProviderStateMixin {
  static const double minScale = 0.1;
  static const double maxScale = 1.0;
  bool isConfiguringPart = false;
  Offset _previousOffset = Offset.zero;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _xScale;
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
  double _yScale;
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
    if(widget.splitMode == SplitMode.half) {
      widget.toggleSplitMode();
    }
  }

  MelodyViewMode _previousMelodyViewMode;
  SplitMode _previousSplitMode;
  @override
  Widget build(context) {
    if(_xScale == null) {
      if(context.isTablet) {
        _xScale = 0.33;
        _yScale = 0.33;
      } else {
        _xScale = 0.22;
        _yScale = 0.22;
      }
    }
    if(context.isPortrait) {
      var verticalSizeHalved = (_previousSplitMode == SplitMode.full && widget.splitMode == SplitMode.half)
        || (_previousMelodyViewMode == MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.score
          && widget.splitMode == SplitMode.half);
      var verticalSizeDoubled = (_previousSplitMode == SplitMode.half && widget.splitMode == SplitMode.full)
        || (_previousMelodyViewMode != MelodyViewMode.score && widget.melodyViewMode == MelodyViewMode.score
          && widget.splitMode == SplitMode.half);
      if (verticalSizeDoubled) {
        xScale *= 1.6666;
        yScale *= 1.6666;
      }
      if (verticalSizeHalved) {
        xScale /= 1.6666;
        yScale /= 1.6666;
      }
    }
    _previousSplitMode = widget.splitMode;
    _previousMelodyViewMode = widget.melodyViewMode;
    if(widget.part == null) {
      isConfiguringPart = false;
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
                        onPressed: widget.toggleSplitMode,
                        padding: EdgeInsets.all(7),
                        child: widget.splitMode == SplitMode.half
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
                        enableColorboard: widget.enableColorboard,
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
    List<MusicStaff> staves;
    Part mainPart = widget.part;
    if (widget.melody != null) {
      mainPart = widget.score.parts.firstWhere((part) => part.melodies.any((melody) => melody.id == widget.melody.id),
        orElse: () => null);
    }
    bool focusPartsAndMelodies = widget.focusPartsAndMelodies &&
      (widget.melodyViewMode == MelodyViewMode.part || widget.melodyViewMode == MelodyViewMode.melody);
    if (focusPartsAndMelodies) {
      staves = [];

      if (mainPart != null && mainPart.isHarmonic) {
        staves.add(PartStaff(mainPart));
      } else if (mainPart != null && mainPart.isDrum) {
        staves.add(DrumStaff());
      }
      staves.addAll(widget.score.parts.where((part) => part.id != mainPart.id)
        .map((part) => (part.isDrum) ? DrumStaff() : PartStaff(part)).toList(growable: false));
//      if (widget.score.parts.any((part) => part.isHarmonic && part != mainPart)) {
//        staves.add(AccompanimentStaff());
//      }
//      if (widget.score.parts.any((part) => part.isDrum && part != mainPart)) {
//        staves.add(DrumStaff());
//      }
    } else {
      staves = widget.score.parts.map((part) => (part.isDrum) ? DrumStaff() : PartStaff(part)).toList(growable: false);
    }
    return Container(
        color: Colors.white,
        child: GestureDetector(
            onTapUp: (details) {
              print("onTapUp: ${details.localPosition}");
              int beat = ((details.localPosition.dx + melodyRendererVisibleRect.left
                - 2 * unscaledStandardBeatWidth * xScale) / (unscaledStandardBeatWidth * xScale)).floor();
              print("beat=$beat");
              if(beat >= 0) {
                widget.selectBeat(beat);
              }
            },
            onScaleStart: (details) => setState(() {
                  _previousOffset = _offset;
                  _startFocalPoint = details.focalPoint;
                  _startHorizontalScale = xScale;
                  _startVerticalScale = yScale;
                }),
            onScaleUpdate: (ScaleUpdateDetails details) {
              setState(() {
                if (details.horizontalScale > 0) {
                  _xScale = max(minScale, min(maxScale, _startHorizontalScale * details.horizontalScale));
//                  if(_xScale > maxScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
//                  if(_xScale < minScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
                }
                if (details.verticalScale > 0) {
                  _yScale = max(minScale, min(maxScale, _startVerticalScale * details.verticalScale));
                }
                // TODO: Use _startFocalPoint to scroll the MelodyRenderer ScrollViews
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
                section: widget.currentSection,
                sectionColor: widget.sectionColor,
                colorboardNotesNotifier: widget.colorboardNotesNotifier,
                keyboardNotesNotifier: widget.keyboardNotesNotifier,
                focusedMelody: widget.melody,
                renderingMode: widget.renderingMode,
                xScale: _xScale,
                yScale: _xScale,
                staves: staves,
                focusedPart: mainPart,
                keyboardPart: widget.keyboardPart,
                colorboardPart: widget.colorboardPart,
                height: widget.height
              ),
              Align(alignment: Alignment.topRight,child:Padding(padding:EdgeInsets.only(right:5), child:Opacity(opacity: 0.8, child:Column(children: [
                Container(
                  width: 36,
                  child: RaisedButton(
                    padding: EdgeInsets.all(0),
                    onPressed: (xScale < maxScale || yScale < maxScale)
                      ? () {
                      setState(() {
                        xScale = min(maxScale, xScale * 1.3333);
                        yScale = min(maxScale, yScale * 1.3333);
//                        print("zoomIn done; xScale=$xScale, yScale=$yScale");
                      });
                    } : null,
                    child: Icon(Icons.zoom_in))),
                Container(
                  width: 36,
                  child: RaisedButton(
                    padding: EdgeInsets.all(0),
                    onPressed: (xScale > minScale || yScale > minScale)
                      ? () {
                      setState(() {
//                        print("zoomOut start; xScale=$xScale, yScale=$yScale");
                        xScale = max(minScale, xScale / 1.3333);
                        yScale = max(minScale, yScale / 1.3333);
//                        print("zoomOut done; xScale=$xScale, yScale=$yScale");
                      });
                    } : null,
                    child: Icon(Icons.zoom_out))),
              ]))))
            ])
            ));
  }
}

