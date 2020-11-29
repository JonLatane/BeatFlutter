import 'dart:math';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'beatscratch_plugin.dart';
import 'instrument_picker.dart';
import 'melody_renderer.dart';
import 'melody_toolbars.dart';
import 'music_theory.dart';
import 'music_notation_theory.dart';
import 'my_buttons.dart';
import 'ui_models.dart';
import 'util.dart';
import 'incrementable_value.dart';

class MelodyView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MelodyViewMode melodyViewMode;
  final SplitMode splitMode;
  final RenderingMode renderingMode;
  final Function(RenderingMode) requestRenderingMode;
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
  final Function cloneCurrentSection;
  final double initialScale;
  final bool previewMode;
  final bool isCurrentScore;

  MelodyView(
      {this.selectBeat,this.focusPartsAndMelodies, this.melodyViewSizeFactor, this.cloneCurrentSection,
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
  this.colorboardNotesNotifier, this.keyboardNotesNotifier, this.height, this.enableColorboard, this.initialScale, this.previewMode = false,
        this.isCurrentScore = true, Key key, this.requestRenderingMode}): super(key:key);

  @override
  _MelodyViewState createState() => _MelodyViewState();
}

class _MelodyViewState extends State<MelodyView> with TickerProviderStateMixin {
  static const double minScale = 0.1;
  static const double maxScale = 1.0;
  bool isConfiguringPart = false;
  bool isEditingSection = false;
  Offset _previousOffset = Offset.zero;
  bool _ignoreNextScale = false;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _xScale;
  double get xScale => _xScale;
  bool _hasSwipedClosed = false;

  Map<MelodyViewMode, List<SwipeTutorial>> _swipeTutorialsSeen = {
    MelodyViewMode.melody: List(),
    MelodyViewMode.part: List(),
    MelodyViewMode.section: List(),
    // MelodyViewMode.score: List(),
    // MelodyViewMode.none: List(),
  };
  SwipeTutorial _currentSwipeTutorial;
  SwipeTutorial get currentSwipeTutorial => _currentSwipeTutorial;
  set currentSwipeTutorial(SwipeTutorial value) {
    if (value == null || _swipeTutorialsSeen[widget.melodyViewMode].contains(value)) {
      _currentSwipeTutorial = null;
      return;
    }
    _currentSwipeTutorial = value;
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _swipeTutorialsSeen[widget.melodyViewMode].add(value);
        _currentSwipeTutorial = null;
      });
    });
  }

  List<AnimationController> _xScaleAnimationControllers = [];
  set xScale(double value) {
    _xScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _xScaleAnimationControllers.clear();
    AnimationController scaleAnimationController = animationController();
    _xScaleAnimationControllers.add(scaleAnimationController);
    Animation animation;
    // print("animating xScale to $value");
    animation = Tween<double>(begin: _xScale, end: value)
      .animate(scaleAnimationController)
      ..addListener(() {
        setState(() {
          print("Tween _xScale access");
          _xScale = animation.value;
        });
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
    highlightedBeat = new ValueNotifier(null);
    requestedScrollOffsetForScale = ValueNotifier(null);
  }

  double toolbarHeight(BuildContext context) => context.isLandscapePhone ? 42 : 48;

  @override
  void dispose() {
    _xScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _yScaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _xScaleAnimationControllers.clear();
    _yScaleAnimationControllers.clear();
    highlightedBeat.dispose();
    super.dispose();
  }
  makeFullSize() {
    if(widget.splitMode == SplitMode.half) {
      widget.toggleSplitMode();
    }
  }

  bool _ignoreDragEvents = false;
  bool get ignoreDragEvents => _ignoreDragEvents;
  set ignoreDragEvents(value) {
    _ignoreDragEvents = value;
    if (value) {
      Future.delayed(Duration(milliseconds: 400), () {
        ignoreDragEvents = false;
      });
    }
  }
  MelodyViewMode _previousMelodyViewMode;
  SplitMode _previousSplitMode;
  @override
  Widget build(context) {
    if(_xScale == null) {
      if(widget.initialScale != null) {
        _xScale = widget.initialScale;
        _yScale = widget.initialScale;
      } else if(context.isTablet) {
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
    if (widget.part == null) {
      isConfiguringPart = false;
    }
    if (widget.melodyViewMode != MelodyViewMode.section) {
      isEditingSection = false;
    }
    if (!widget.editingMelody || !BeatScratchPlugin.playing) {
      highlightedBeat.value = null;
    }
    currentSwipeTutorial = _swipeTutorialsSeen.keys.contains(widget.melodyViewMode) && widget.melodyViewSizeFactor > 0 ?
      widget.splitMode == SplitMode.half ? SwipeTutorial.closeExpand : SwipeTutorial.collapse : null;
    final sensitivity = 10;
    return Column(
      children: [
        Column(
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
                // Padding(
                //   padding: EdgeInsets.only(left: 5),
                //   child: AnimatedOpacity(
                //     duration: animationDuration,
                //     opacity: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 1 : 0,
                //     child: AnimatedContainer(
                //       duration: animationDuration,
                //       width: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 0 : 0,
                //       height: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 0 : 0,
                //       child: MyRaisedButton(
                //           onPressed: widget.toggleSplitMode,
                //           padding: EdgeInsets.all(7),
                //           child: Transform.scale(scale: 0.8, child: widget.splitMode == SplitMode.half
                //               ? Image.asset("assets/split_full.png")
                //               : context.isPortrait
                //                   ? Image.asset("assets/split_horizontal.png")
                //                   : Image.asset("assets/split_vertical.png")))),
                // )),
                Expanded(
                    child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          if (ignoreDragEvents) return;
                          if (details.delta.dy > sensitivity) { // Down swipe
                            if (widget.splitMode == SplitMode.half) {
                              _hasSwipedClosed = true;
                              widget.closeMelodyView();
                            } else {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          } else if (details.delta.dy < -sensitivity) { // Up swipe
                            if (widget.splitMode == SplitMode.half) {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          if (ignoreDragEvents) return;
                          if (details.delta.dx > sensitivity) { // Right swipe
                            if (widget.splitMode == SplitMode.half) {
                              _hasSwipedClosed = true;
                              widget.closeMelodyView();
                            } else {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          } else if (details.delta.dx < -sensitivity) { // Left swipe
                            if (widget.splitMode == SplitMode.half) {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          }
                        },
                        child: Stack(
                          children: [
                            Column(children: [
                              AnimatedContainer(
                                  duration: animationDuration,
                                  height: (widget.melodyViewMode == MelodyViewMode.section) ? toolbarHeight(context) : 0,
                                  child: SectionToolbar(
                                    currentSection: widget.currentSection,
                                    sectionColor: widget.sectionColor,
                                    melodyViewMode: widget.melodyViewMode,
                                    setSectionName: widget.setSectionName,
                                    deleteSection: widget.deleteSection,
                                    canDeleteSection: widget.score.sections.length > 1,
                                    cloneCurrentSection: widget.cloneCurrentSection,
                                    editingSection: isEditingSection,
                                    setEditingSection: (value) {
                                      setState(() {
                                        isEditingSection = value;
                                      });
                                    },
                                  )),
                              AnimatedContainer(
                                  duration: animationDuration,
                                  height: (widget.melodyViewMode == MelodyViewMode.part) ? toolbarHeight(context) : 0,
                                  child: PartToolbar(
                                      enableColorboard: widget.enableColorboard,
                                      part: widget.part,
                                      setKeyboardPart: widget.setKeyboardPart,
                                      configuringPart: isConfiguringPart,
                                      toggleConfiguringPart: () {
                                        setState(() {
                                          isConfiguringPart = !isConfiguringPart;
                                          if (isConfiguringPart && !context.isTablet) {
                                            makeFullSize();
                                          }
                                        });
                                      },
                                      setColorboardPart: widget.setColorboardPart,
                                      colorboardPart: widget.colorboardPart,
                                      keyboardPart: widget.keyboardPart,
                                      deletePart: widget.deletePart,
                                      sectionColor: widget.sectionColor)),
                              AnimatedContainer(
                                  duration: animationDuration,
                                  height: (widget.melodyViewMode == MelodyViewMode.melody) ? toolbarHeight(context) : 0,
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
                            ]),
                            Transform.translate(
                              offset: Offset(0, 2),
                              child: Align(alignment: Alignment.center, child:
                              AnimatedOpacity(
                                opacity: currentSwipeTutorial == null ? 0 : 0.8,
                                duration: animationDuration,
                                child: AnimatedContainer(
                                  height: currentSwipeTutorial == null || _hasSwipedClosed
                                    ? 0 : 36,
                                  duration: animationDuration,
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          color: Colors.white,
                                        ),
                                        width: 150,
                                        child: Column(children: [
                                          Expanded(child:SizedBox()),
                                          Text(currentSwipeTutorial.tutorialText(widget.splitMode, widget.melodyViewMode, context),
                                            style: TextStyle(fontSize: 11),
                                            textAlign: TextAlign.center,
                                          ),
                                          Expanded(child:SizedBox()),
                                ])),
                              )),
                            )
                          ],
                        ))),
                // Padding(
                //     padding: EdgeInsets.only(right: 5),
                //     child: AnimatedOpacity(
                //       duration: animationDuration,
                //       opacity: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 1 : 0,
                //       child: AnimatedContainer(
                //           duration: animationDuration,
                //           width: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 36 : 0,
                //           height: (widget.melodyViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.none) ? 36 : 0,
                //           child: MyRaisedButton(
                //               onPressed: widget.closeMelodyView, padding: EdgeInsets.all(0), child: widget.previewMode ? SizedBox() : Icon(Icons.close))),
                //     ))
              ],
            ),
          ),
          AnimatedContainer(
            duration: animationDuration,
            color: widget.part != null && widget.part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
            height: (widget.melodyViewMode == MelodyViewMode.part && isConfiguringPart) ? min(280, max(110,widget.height)) : 0,
            child: PartConfiguration(part: widget.part, superSetState: widget.superSetState, availableHeight: widget.height,)),
          AnimatedContainer(
            color: Colors.white,
            duration: animationDuration,
            height: (widget.melodyViewMode == MelodyViewMode.melody && widget.editingMelody) ? toolbarHeight(context) : 0,
            child:
            MelodyEditingToolbar(
              editingMelody: widget.editingMelody,
              sectionColor: widget.sectionColor,
              score: widget.score,
              melodyId: widget.melody?.id,
              currentSection: widget.currentSection,
              highlightedBeat: highlightedBeat,
            )),
          AnimatedContainer(
            color: widget.sectionColor,
            duration: animationDuration,
            height: (widget.melodyViewMode == MelodyViewMode.section && isEditingSection) ? toolbarHeight(context) : 0,
            child: SectionEditingToolbar(
              sectionColor: widget.sectionColor,
              score: widget.score,
              currentSection: widget.currentSection,
            )),
          ]),
        Expanded(child: _mainMelody(context))
      ],
    );
  }

  static const double maxScaleDiscrepancy = 1.5;
  static const double minScaleDiscrepancy = 1/maxScaleDiscrepancy;
  
  ValueNotifier<int> highlightedBeat;

  ValueNotifier<Offset> requestedScrollOffsetForScale;

  String _lastIgnoreId;
  bool _ignoreNextTap = false;
  set ignoreNextTap(bool value) {
    if (value) {
      final ignoreId = uuid.v1();
      _lastIgnoreId = ignoreId;
      _ignoreNextTap = true;
      Future.delayed(Duration(milliseconds: 100), () {
        if (_lastIgnoreId == ignoreId) {
          _ignoreNextTap = false;
        }
      });
    } else {
      _ignoreNextTap = value;
    }

  }
  bool get ignoreNextTap {
    if (_ignoreNextTap) {
      _ignoreNextTap = false;
      return true;
    }
    return false;
  }
  
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
      staves.addAll(widget.score.parts.where((part) => part.id != mainPart?.id)
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
    var width = MediaQuery.of(context).size.width / 2;
    if (context.isPortrait && widget.splitMode == SplitMode.half) {
      width = width / 2;
    }
    return Container(
        color: widget.previewMode ? Colors.white.withOpacity(0.5) : Colors.white,
        child: GestureDetector(
            onTapUp: (details) {
              print("onTapUp: ${details.localPosition}");
              if (ignoreNextTap) {
                return;
              }
              int beat = ((details.localPosition.dx + melodyRendererVisibleRect.left
                - 2 * unscaledStandardBeatWidth * xScale) / (unscaledStandardBeatWidth * xScale)).floor();
              print("beat=$beat");
              int maxBeat;
              if (widget.melodyViewMode == MelodyViewMode.score) {
                maxBeat = widget.score.beatCount - 1;
              } else {
                maxBeat = widget.currentSection.beatCount - 1;
              }
              beat = max(0, min(beat, maxBeat));
              if (BeatScratchPlugin.playing && widget.editingMelody && highlightedBeat.value != beat) {
                setState(() {
                  highlightedBeat.value = beat;
                });
              } else if (BeatScratchPlugin.playing && widget.editingMelody && highlightedBeat.value == beat) {
                setState(() {
                  highlightedBeat.value = null;
                });
              } else {
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
              if (_ignoreNextScale) {
                return;
              }
              setState(() {
                double oldXScale, oldYScale;
                if (details.horizontalScale > 0) {
                  oldXScale = _xScale;
                  _xScale = max(minScale, min(maxScale, _startHorizontalScale * details.horizontalScale));
//                  if(_xScale > maxScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
//                  if(_xScale < minScaleDiscrepancy * _yScale) {
//                    _yScale = _xScale * minScaleDiscrepancy;
//                  }
                }
                if (details.verticalScale > 0) {
                  oldYScale = _yScale;
                  _yScale = max(minScale, min(maxScale, _startVerticalScale * details.verticalScale));
                }
                // TODO: Use _startFocalPoint to scroll the MelodyRenderer ScrollViews
                final Offset normalizedOffset = (_startFocalPoint - _previousOffset) / _startHorizontalScale;
                final Offset newOffset = details.focalPoint - normalizedOffset * xScale;

                requestedScrollOffsetForScale.value = newOffset * 1.1;
                _offset = newOffset;

              });
            },
            onScaleEnd: (ScaleEndDetails details) {
              _ignoreNextScale = false;
              //_horizontalScale = max(0.1, min(16, _horizontalScale.ceil().toDouble()));
            },
            child: Stack(children:[
              MelodyRenderer(
                melodyViewMode: widget.melodyViewMode,
                score: widget.score,
                currentSection: widget.currentSection,
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
                height: widget.height,
                width: width,
                previewMode: widget.previewMode,
                isCurrentScore: widget.isCurrentScore,
                highlightedBeat: highlightedBeat,
                requestedScrollOffsetForScale: requestedScrollOffsetForScale,
              ),
              if(!widget.previewMode) Row(children:[
                Expanded(child: SizedBox()),
              Column(children: [
                Expanded(child:SizedBox()),
              Container(color: Colors.black12,
                height: 48, width:48, child:
                FlatButton(onPressed:() {
                  widget.requestRenderingMode(widget.renderingMode == RenderingMode.colorblock
                  ? RenderingMode.notation : RenderingMode.colorblock);
                            },
                            child: Stack(children: [
                              AnimatedOpacity(
                                duration: animationDuration,
                                opacity: widget.renderingMode == RenderingMode.colorblock ? 1 : 0,
                                child: Image.asset(
                                  'assets/notehead_filled.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              AnimatedOpacity(
                                  duration: animationDuration,
                                  opacity: widget.renderingMode == RenderingMode.colorblock ? 0 : 1,
                                  child: Image.asset(
                                    'assets/colorboard_vertical.png',
                                    width: 20,
                                    height: 20,
                                  ))
                            ]))),
                    SizedBox(height: 2),
              Container(color: Colors.black12,
                padding:EdgeInsets.zero,
                child:
                  IncrementableValue(child:
                    Container(
                      // color: Colors.black12,
                      width: 48,
                      height: 48,
                              child: Align(
                                  alignment: Alignment.center,
                                  child: Stack(children: [
                                    AnimatedOpacity(
                                        opacity: 0.5,
                                        duration: animationDuration,
                                        child: Transform.translate(
                                            offset: Offset(-5, 5),
                                            child: Transform.scale(scale: 1, child: Icon(Icons.zoom_out)))),
                                    AnimatedOpacity(
                                        opacity: 0.5,
                                        duration: animationDuration,
                                        child: Transform.translate(
                                            offset: Offset(5, -5),
                                            child: Transform.scale(scale: 1, child: Icon(Icons.zoom_in)))),
                                    AnimatedOpacity(
                                        opacity: 0.8,
                                        duration: animationDuration,
                                        child: Transform.translate(
                                          offset: Offset(2, 20),
                                          child: Text("${(xScale * 100).toStringAsFixed(0)}%",
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                        )),
                                  ])),
                            ),
                            collapsing: true,
                            onPointerUpCallback: () {
                              ignoreNextTap = true;
                            },
                            incrementIcon: Icons.zoom_in,
                            decrementIcon: Icons.zoom_out,
                            onIncrement: (xScale < maxScale || yScale < maxScale)
                                ? () {
                                    _ignoreNextScale = true;
                                    setState(() {
                                      _xScale = min(maxScale, _xScale * 1.05);
                                      _yScale = min(maxScale, _yScale * 1.05);
                                      print("zoomIn done; xScale=$xScale, yScale=$yScale");
                                    });
                                  }
                                : null,
                            onDecrement: (xScale > minScale || yScale > minScale)
                                ? () {
                                    _ignoreNextScale = true;
                                    setState(() {
                                      _xScale = max(minScale, _xScale / 1.05);
                                      _yScale = max(minScale, _yScale / 1.05);
                                      print("zoomOut done; xScale=$xScale, yScale=$yScale");
                                    });
                                  }
                                : null)),
                SizedBox(height: 2),
                  ]),
                SizedBox(width: 2),
                ])
            ])));
  }
}

enum SwipeTutorial {
  collapse, closeExpand
}

extension TutorialText on SwipeTutorial {
  String tutorialText(SplitMode splitMode, MelodyViewMode melodyViewMode, BuildContext context) {
    return splitMode == SplitMode.full
      ? "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to collapse/close ${melodyViewMode.toString().substring(15).capitalize()}"
      : "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to close,\n" +
      "${context.isPortrait ? "⬆️️" : "⬅️"}️ to expand " +
      "${melodyViewMode.toString().substring(15).capitalize()}";
  }
}