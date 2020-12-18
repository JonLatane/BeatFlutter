import 'dart:math';

import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/bs_notifiers.dart';
import '../util/util.dart';
import '../widget/incrementable_value.dart';
import '../widget/my_buttons.dart';
import 'instrument_picker.dart';
import 'music_scroll_container.dart';
import 'music_system_painter.dart';
import 'music_toolbars.dart';

class MusicView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MelodyViewMode melodyViewMode;
  final SplitMode splitMode;
  final RenderingMode renderingMode;
  final Function(RenderingMode) requestRenderingMode;
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
  final bool isPreview;
  final Color backgroundColor;
  final bool isCurrentScore;
  final bool showViewOptions;
  final bool renderPartNames;

  MusicView(
      {this.selectBeat,
      this.melodyViewSizeFactor,
      this.cloneCurrentSection,
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
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.height,
      this.enableColorboard,
      this.initialScale,
      this.isPreview = false,
      this.isCurrentScore = true,
      this.renderPartNames = true,
      Key key,
      this.requestRenderingMode,
      this.showViewOptions = false,
      this.backgroundColor = Colors.white})
      : super(key: key);

  @override
  _MusicViewState createState() => _MusicViewState();
}

class _MusicViewState extends State<MusicView> with TickerProviderStateMixin {
  static const double minScale = MusicScrollContainer.minScale;
  static const double maxScale = MusicScrollContainer.maxScale;
  bool autoScroll;
  bool autoFocus;
  bool isConfiguringPart;
  bool isEditingSection;
  bool _isTwoFingerScaling = false;
  // Offset _previousOffset = Offset.zero;
  bool _ignoreNextScale = false;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  bool _hasSwipedClosed = false;

  ValueNotifier<double> xScaleNotifier, yScaleNotifier;

  /// Always immediately updated; the return values of [xScale] and [yScale].
  double _targetedXScale, _targetedYScale;

  /// Used to maintain a locking mechanism as we animate from [_xScale] to [_targetedXScale] in the setter for [xScale].
  DateTime _xScaleLock, _yScaleLock;
  List<AnimationController> _xScaleAnimationControllers, _yScaleAnimationControllers;

  /// Used to notify the [MusicScrollContainer] as we animate [_xScale] to [_targetedXScale] in the setter for [xScale].
  BSValueNotifier<ScaleUpdate> _xScaleUpdate, _yScaleUpdate;

  Map<MelodyViewMode, List<SwipeTutorial>> _swipeTutorialsSeen;
  SwipeTutorial _currentSwipeTutorial;

  BSNotifier scrollToCurrentBeat, centerCurrentSection;

  static const double maxScaleDiscrepancy = 1.5;
  static const double minScaleDiscrepancy = 1 / maxScaleDiscrepancy;

  ValueNotifier<int> highlightedBeat;
  DateTime focusedBeatUpdated = DateTime(0);
  ValueNotifier<int> focusedBeat;

  ValueNotifier<Offset> requestedScrollOffsetForScale;

  String _lastIgnoreId;
  bool _ignoreNextTap = false;

  MelodyViewMode _previousMelodyViewMode;
  SplitMode _previousSplitMode;
  bool _previouslyAligned;

  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 200));

  SwipeTutorial get currentSwipeTutorial => _currentSwipeTutorial;

  set currentSwipeTutorial(SwipeTutorial value) {
    if (value == null || _swipeTutorialsSeen[widget.melodyViewMode].contains(value)) {
      _currentSwipeTutorial = null;
      return;
    }
    _currentSwipeTutorial = value;
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _swipeTutorialsSeen[widget.melodyViewMode]?.add(value);
        _currentSwipeTutorial = null;
      });
    });
  }

  _startValueAnimation(
      {@required double Function() value,
      @required double Function() currentValue,
      @required Function(double) applyAnimatedValue,
      @required List<AnimationController> controllers,
      VoidCallback onComplete}) {
    if (value() == currentValue()) {
      // print("skipping scale animation: no change (${currentValue()} to ${value()}");
    } else if (_isTwoFingerScaling) {
      // print("skipping scale animation: isTwoFingerScaling");
    } else {
      // print("starting scale animation");
      controllers.forEach((controller) {
        controller.stop(canceled: false);
        controller.dispose();
      });
      controllers.clear();
      AnimationController scaleAnimationController = animationController();
      controllers.add(scaleAnimationController);
      Animation animation;
      // print("animating xScale to $value");
      // print("Tween params: begin: $currentValue, end: $value");
      animation = Tween<double>(begin: currentValue(), end: value()).animate(scaleAnimationController)
        ..addListener(() {
          // print("Tween scale: ${animation.value}");
          setState(() {
            applyAnimatedValue(animation.value);
          });
        });
      scaleAnimationController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(animationDuration, () {
            print("_startValueAnimation onComplete");
            onComplete?.call();
          });
        }
      });
      scaleAnimationController.forward();
    }
  }

  static const focusTimeout = 2500;
  _updateFocusedBeatValue() {
    if (focusedBeat.value == null || DateTime.now().difference(focusedBeatUpdated).inMilliseconds > focusTimeout) {
      focusedBeat.value = getBeat(
        Offset(
          melodyRendererVisibleRect.width / (context.isLandscape && widget.splitMode == SplitMode.half ? 4 : 2),
          0),
        targeted: false);

      focusedBeatUpdated = DateTime.now();
      delayClear() {
        Future.delayed(Duration(milliseconds: focusTimeout), () {
          if (DateTime.now().difference(focusedBeatUpdated).inMilliseconds > focusTimeout) {
            print("Cleared focusedBeat");
            focusedBeat.value = null;
          } else {
            delayClear();
          }
        });
      }

      delayClear();
      print("Set focusedBeat to ${focusedBeat.value}");
    } else {
      focusedBeatUpdated = DateTime.now();
      print("Keeping focusedBeat at ${focusedBeat.value}");
    }
  }
  _animateScaleAtomically(
      {@required DateTime Function() getLockTime,
      @required Function(DateTime) setLockTime,
      @required double Function() value,
      @required double Function() currentValue,
      @required Function(double) applyAnimatedValue,
      @required List<AnimationController> controllers,
      @required BSValueNotifier<ScaleUpdate> notifyUpdate,}) {
    if (value() == currentValue()) {
      return;
    }

    bool lock() {
      final lockTime = DateTime.now();
      setLockTime(lockTime);
      return getLockTime() == lockTime;
    }

    startAnimation() {
      _updateFocusedBeatValue();
      _startValueAnimation(
          value: value,
          currentValue: currentValue,
          applyAnimatedValue: applyAnimatedValue,
          controllers: controllers,
          onComplete: () {
            _animateScaleAtomically(
                getLockTime: getLockTime,
                setLockTime: setLockTime,
                notifyUpdate: notifyUpdate,
                value: value,
                currentValue: currentValue,
                applyAnimatedValue: applyAnimatedValue,
                controllers: controllers,);
          });
      notifyUpdate(ScaleUpdate(currentValue(), value()));
    }

    if (getLockTime() == null || DateTime.now().difference(getLockTime()).inMilliseconds > 500) {
      if (lock()) {
        print("unlocked");
        startAnimation();
      } else {
        print("locked");
        retry() {
          Future.delayed(animationDuration, () {
            if (lock()) {
              print("unlocked: retry");
              startAnimation();
            } else {
              retry();
            }
          });
        }
        retry();
      }
    }
  }

  double get _xScale => xScaleNotifier.value;
  set _xScale(value) => xScaleNotifier.value = value;
  double get _yScale => yScaleNotifier.value;
  set _yScale(value) => yScaleNotifier.value = value;

  double get xScale => _targetedXScale;

  double get yScale => _targetedYScale;

  set xScale(double value) {
    value = max(0, min(maxScale, value));
    _targetedXScale = value;
    _animateScaleAtomically(
      value: () => xScale,
      currentValue: () => _xScale,
      applyAnimatedValue: (value) => _xScale = value,
      controllers: _xScaleAnimationControllers,
      setLockTime: (it) {
        _xScaleLock = it;
      },
      getLockTime: () => _xScaleLock,
      notifyUpdate: _xScaleUpdate,
    );
  }
  set rawXScale(double value) {
    value = max(minScale, min(maxScale, value));
    _updateFocusedBeatValue();
    final oldValue = _xScale;
    _targetedXScale = value;
    _xScale = value;
    _xScaleUpdate(ScaleUpdate(oldValue, value));
  }

  set yScale(double value) {
    value = max(minScale, min(maxScale, value));
    _targetedYScale = value;
    _animateScaleAtomically(
      value: () => yScale,
      currentValue: () => _yScale,
      applyAnimatedValue: (value) => _yScale = value,
      controllers: _yScaleAnimationControllers,
      setLockTime: (it) {
        _yScaleLock = it;
      },
      getLockTime: () => _yScaleLock,
      notifyUpdate: _yScaleUpdate,
    );
  }
  set rawYScale(double value) {
    value = max(minScale, min(maxScale, value));
    final oldValue = _yScale;
    _targetedYScale = value;
    _yScale = value;
    _yScaleUpdate(ScaleUpdate(oldValue, value));
  }

  @override
  void initState() {
    super.initState();
    highlightedBeat = new ValueNotifier(null);
    focusedBeat = new ValueNotifier(null);
    requestedScrollOffsetForScale = ValueNotifier(null);
    _swipeTutorialsSeen = {
      MelodyViewMode.melody: List(),
      MelodyViewMode.part: List(),
      MelodyViewMode.section: List(),
    };
    _xScaleAnimationControllers = [];
    _yScaleAnimationControllers = [];
    scrollToCurrentBeat = BSNotifier();
    centerCurrentSection = BSNotifier();
    _xScaleUpdate = BSValueNotifier(null);
    _yScaleUpdate = BSValueNotifier(null);
    centerCurrentSection = BSNotifier();

    isConfiguringPart = false;
    isEditingSection = false;
    autoScroll = true;
    autoFocus = true;
    _previouslyAligned = true;
    xScaleNotifier = ValueNotifier(null);
    yScaleNotifier = ValueNotifier(null);
  }

  double toolbarHeight(BuildContext context) => context.isLandscapePhone ? 42 : 48;

  @override
  void dispose() {
    _xScaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _yScaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _xScaleAnimationControllers.clear();
    _yScaleAnimationControllers.clear();
    highlightedBeat.dispose();
    scrollToCurrentBeat.dispose();
    centerCurrentSection.dispose();
    super.dispose();
  }

  makeFullSize() {
    if (widget.splitMode == SplitMode.half) {
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

  @override
  Widget build(context) {
    if (_xScale == null) {
      if (widget.initialScale != null) {
        _xScale = widget.initialScale;
        _yScale = widget.initialScale;
      } else if (context.isTablet) {
        _xScale = 0.33;
        _yScale = 0.33;
      } else {
        _xScale = 0.22;
        _yScale = 0.22;
      }
      _targetedXScale = _xScale;
      _targetedYScale = _yScale;
    }
    if (_xScale.notRoughlyEquals(_targetedXScale) || _yScale.notRoughlyEquals(_targetedYScale)) {
      xScale = xScale;
      yScale = yScale;
    }
    // if (context.isPortrait) {
    //   var verticalSizeHalved = (_previousSplitMode == SplitMode.full && widget.splitMode == SplitMode.half) ||
    //       (_previousMelodyViewMode == MelodyViewMode.score &&
    //           widget.melodyViewMode != MelodyViewMode.score &&
    //           widget.splitMode == SplitMode.half);
    //   var verticalSizeDoubled = (_previousSplitMode == SplitMode.half && widget.splitMode == SplitMode.full) ||
    //       (_previousMelodyViewMode != MelodyViewMode.score &&
    //           widget.melodyViewMode == MelodyViewMode.score &&
    //           widget.splitMode == SplitMode.half);
    //   if (verticalSizeDoubled) {
    //     xScale *= 1.6666;
    //     yScale *= 1.6666;
    //   }
    //   if (verticalSizeHalved) {
    //     xScale /= 1.6666;
    //     yScale /= 1.6666;
    //   }
    // }
    if (_previouslyAligned && xScale.notRoughlyEquals(alignedScale)) {
      alignVertically();
      _previouslyAligned = true;
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
    currentSwipeTutorial = _swipeTutorialsSeen.keys.contains(widget.melodyViewMode) && widget.melodyViewSizeFactor > 0
        ? widget.splitMode == SplitMode.half
            ? SwipeTutorial.closeExpand
            : SwipeTutorial.collapse
        : null;
    final sensitivity = 10;
    return Column(
      children: [
        Column(children: [
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
                          if (details.delta.dy > sensitivity) {
                            // Down swipe
                            if (widget.splitMode == SplitMode.half) {
                              _hasSwipedClosed = true;
                              widget.closeMelodyView();
                            } else {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          } else if (details.delta.dy < -sensitivity) {
                            // Up swipe
                            if (widget.splitMode == SplitMode.half) {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          if (ignoreDragEvents) return;
                          if (details.delta.dx > sensitivity) {
                            // Right swipe
                            if (widget.splitMode == SplitMode.half) {
                              _hasSwipedClosed = true;
                              widget.closeMelodyView();
                            } else {
                              widget.toggleSplitMode();
                            }
                            ignoreDragEvents = true;
                          } else if (details.delta.dx < -sensitivity) {
                            // Left swipe
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
                                  height:
                                      (widget.melodyViewMode == MelodyViewMode.section) ? toolbarHeight(context) : 0,
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
                                  child: MusicToolbar(
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
                              child: Align(
                                  alignment: Alignment.center,
                                  child: AnimatedOpacity(
                                    opacity: currentSwipeTutorial == null ? 0 : 0.8,
                                    duration: animationDuration,
                                    child: AnimatedContainer(
                                        height: currentSwipeTutorial == null || _hasSwipedClosed ? 0 : 36,
                                        duration: animationDuration,
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          color: Colors.white,
                                        ),
                                        width: 150,
                                        child: Column(children: [
                                          Expanded(child: SizedBox()),
                                          Text(
                                            currentSwipeTutorial.tutorialText(
                                                widget.splitMode, widget.melodyViewMode, context),
                                            style: TextStyle(fontSize: 11),
                                            overflow: TextOverflow.fade,
                                            maxLines: 2,
                                            textAlign: TextAlign.center,
                                          ),
                                          Expanded(child: SizedBox()),
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
              color: widget.part != null && widget.part.instrument.type == InstrumentType.drum
                  ? Colors.brown
                  : Colors.grey,
              height: (widget.melodyViewMode == MelodyViewMode.part && isConfiguringPart)
                  ? min(280, max(110, widget.height))
                  : 0,
              child: PartConfiguration(
                  part: widget.part,
                  superSetState: widget.superSetState,
                  availableHeight: widget.height,
                  visible: (widget.melodyViewMode == MelodyViewMode.part && isConfiguringPart))),
          AnimatedContainer(
              color: Colors.white,
              duration: animationDuration,
              height:
                  (widget.melodyViewMode == MelodyViewMode.melody && widget.editingMelody) ? toolbarHeight(context) : 0,
              child: MelodyEditingToolbar(
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
              height:
                  (widget.melodyViewMode == MelodyViewMode.section && isEditingSection) ? toolbarHeight(context) : 0,
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

  getBeat(Offset position, {bool targeted = true}) {
    int beat = ((position.dx + melodyRendererVisibleRect.left - 2 * unscaledStandardBeatWidth * xScale) /
            (unscaledStandardBeatWidth * (targeted ? xScale : _xScale)))
        .floor();
    // print("beat=$beat");
    int maxBeat;
    // if (widget.melodyViewMode == MelodyViewMode.score) {
    maxBeat = widget.score.beatCount - 1;
    // } else {
    //   maxBeat = widget.currentSection.beatCount - 1;
    // }
    beat = max(0, min(beat, maxBeat));
    return beat;
  }

  Widget _mainMelody(BuildContext context) {
    List<MusicStaff> staves;
    Part mainPart = widget.part;
    if (widget.melody != null) {
      mainPart = widget.score.parts
          .firstWhere((part) => part.melodies.any((melody) => melody.id == widget.melody.id), orElse: () => null);
    }
    bool focusPartsAndMelodies =
        autoFocus && (widget.melodyViewMode == MelodyViewMode.part || widget.melodyViewMode == MelodyViewMode.melody);
    if (focusPartsAndMelodies) {
      staves = [];

      if (mainPart != null && mainPart.isHarmonic) {
        staves.add(PartStaff(mainPart));
      } else if (mainPart != null && mainPart.isDrum) {
        staves.add(DrumStaff());
      }
      staves.addAll(widget.score.parts
          .where((part) => part.id != mainPart?.id)
          .map((part) => (part.isDrum) ? DrumStaff() : PartStaff(part))
          .toList(growable: false));
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

    bool focusedPartIsNotFirst =
        widget.part != null && widget.score.parts.indexWhere((it) => it.id == widget.part.id) != 0;
    bool focusedMelodyIsNotFirst = widget.melody != null &&
        widget.score.parts.indexWhere((p) => p.melodies.any((m) => m.id == widget.melody.id)) != 0;
    bool showAutoFocusButton =
        (widget.melodyViewMode == MelodyViewMode.part || widget.melodyViewMode == MelodyViewMode.melody) &&
            (focusedPartIsNotFirst || focusedMelodyIsNotFirst);

    return Container(
        color: widget.backgroundColor.withOpacity(widget.backgroundColor.opacity * (widget.isPreview ? 0.5 : 1)),
        child: GestureDetector(
            onTapUp: (details) {
              if (ignoreNextTap) {
                return;
              }
              int beat = getBeat(details.localPosition);
              print("onTapUp: ${details.localPosition} -> beat: $beat; x/t: $_xScale/$_targetedXScale");
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
                  if (_ignoreNextScale) {
                    return;
                  }
                  _previouslyAligned = false;
                  _isTwoFingerScaling = true;
                  int beat = getBeat(details.focalPoint);
                  focusedBeat.value = beat;
                  _startHorizontalScale = xScale;
                  _startVerticalScale = yScale;
                }),
            onScaleUpdate: (ScaleUpdateDetails details) {
              if (_ignoreNextScale) {
                return;
              }
              setState(() {
                if (focusedBeat.value == null) {
                  int beat = getBeat(details.focalPoint);
                  focusedBeat.value = beat;
                }
                if (details.horizontalScale > 0) {
                  final target = _startHorizontalScale * details.horizontalScale;
                  rawXScale = target;
                }
                if (details.verticalScale > 0) {
                  final target = _startVerticalScale * details.verticalScale;
                  rawYScale = target;
                }
              });
            },
            onScaleEnd: (ScaleEndDetails details) {
              _ignoreNextScale = false;
              _isTwoFingerScaling = false;
              focusedBeat.value = null;
            },
            child: Stack(children: [
              MusicScrollContainer(
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
                previewMode: widget.isPreview,
                isCurrentScore: widget.isCurrentScore,
                highlightedBeat: highlightedBeat,
                focusedBeat: focusedBeat,
                requestedScrollOffsetForScale: requestedScrollOffsetForScale,
                targetXScale: xScale,
                targetYScale: yScale,
                isTwoFingerScaling: _isTwoFingerScaling,
                scrollToCurrentBeat: scrollToCurrentBeat,
                centerCurrentSection: centerCurrentSection,
                autoScroll: autoScroll,
                renderPartNames: widget.renderPartNames,
                isPreview: widget.isPreview,
                notifyXScaleUpdate: _xScaleUpdate,
                notifyYScaleUpdate: _yScaleUpdate,
                xScaleNotifier: xScaleNotifier,
                yScaleNotifier: yScaleNotifier,
              ),
              if (!widget.isPreview)
                Row(children: [
                  Expanded(child: SizedBox()),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    AnimatedOpacity(
                      duration: animationDuration,
                      opacity: widget.showViewOptions && showAutoFocusButton ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !widget.showViewOptions && showAutoFocusButton,
                        child: Container(
                            color: Colors.black12,
                            height: 48,
                            width: 48,
                            child: MyFlatButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    autoFocus = !autoFocus;
                                  });
                                },
                                child: Stack(children: [
                                  Transform.translate(
                                      offset: Offset(0, -8),
                                      child: Text("Auto",
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: autoFocus ? Colors.white : Colors.grey))),
                                  Transform.translate(
                                    offset: Offset(-6, 3),
                                    child: AnimatedOpacity(
                                      duration: animationDuration,
                                      opacity: !autoFocus ? 1 : 0,
                                      child: Icon(Icons.arrow_upward_sharp, color: Colors.grey),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(6, 9),
                                    child: AnimatedOpacity(
                                      duration: animationDuration,
                                      opacity: !autoFocus ? 1 : 0,
                                      child: Icon(
                                        Icons.arrow_downward_sharp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(-6, 3),
                                    child: AnimatedOpacity(
                                      duration: animationDuration,
                                      opacity: autoFocus ? 1 : 0,
                                      child: Icon(Icons.arrow_upward_sharp, color: widget.sectionColor),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(6, 9),
                                    child: AnimatedOpacity(
                                      duration: animationDuration,
                                      opacity: autoFocus ? 1 : 0,
                                      child: Icon(
                                        Icons.arrow_downward_sharp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ]))),
                      ),
                    ),
                    SizedBox(height: 2),
                  ]),
                  SizedBox(width: 2),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    colorblockButton(visible: widget.showViewOptions),
                    SizedBox(height: 2),
                  ]),
                  SizedBox(width: 2),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    expandButton(visible: xScale != alignedScale),
                    SizedBox(height: 2),
                  ]),
                  if (xScale != alignedScale) SizedBox(width: 2),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    autoScrollButton(visible: widget.showViewOptions),
                    SizedBox(height: 2),
                    scrollToCurrentBeatButton(),
                    SizedBox(height: 2),
                    zoomButton(),
                    SizedBox(height: 2),
                  ]),
                  SizedBox(width: 2),
                ])
            ])));
  }

  Container zoomButton() {
    return Container(
        color: Colors.black12,
        padding: EdgeInsets.zero,
        child: IncrementableValue(
            child: Container(
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
                            offset: Offset(-5, 5), child: Transform.scale(scale: 1, child: Icon(Icons.zoom_out)))),
                    AnimatedOpacity(
                        opacity: 0.5,
                        duration: animationDuration,
                        child: Transform.translate(
                            offset: Offset(5, -5), child: Transform.scale(scale: 1, child: Icon(Icons.zoom_in)))),
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
              focusedBeat.value = null;
            },
            onPointerDownCallback: () {
              // focusedBeat.value = BeatScratchPlugin.currentBeat.value;
            },
            incrementIcon: Icons.zoom_in,
            decrementIcon: Icons.zoom_out,
            onIncrement: (xScale < maxScale || yScale < maxScale)
                ? () {
                    _ignoreNextScale = true;
                    _previouslyAligned = false;
                    setState(() {
                      xScale = min(maxScale, (xScale) * 1.05);
                      yScale = min(maxScale, (yScale) * 1.05);
                      // print("zoomIn done; xScale=$targetXScale, yScale=$targetYScale");
                    });
                  }
                : null,
            onDecrement: (xScale > minScale || yScale > minScale)
                ? () {
                    _ignoreNextScale = true;
                    _previouslyAligned = false;
                    setState(() {
                      xScale = max(minScale, xScale / 1.05);
                      yScale = max(minScale, yScale / 1.05);
                      // print("zoomOut done; xScale=$xScale, yScale=$yScale");
                    });
                  }
                : null));
  }

  Container scrollToCurrentBeatButton() {
    return Container(
        color: Colors.black12,
        height: 48,
        width: 48,
        child: MyFlatButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              scrollToCurrentBeat();
            },
            child: Stack(children: [
              AnimatedOpacity(
                duration: animationDuration,
                opacity: 1,
                child: Icon(Icons.my_location, color: widget.sectionColor),
              ),
            ])));
  }

  AnimatedOpacity expandButton({@required bool visible}) {
    return AnimatedOpacity(
        duration: animationDuration,
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedContainer(
                duration: animationDuration,
                color: Colors.black12,
                height: 48,
                width: visible ? 48 : 0,
                child: MyFlatButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _previouslyAligned = true;
                        alignVertically();
                      });
                      // Future.delayed(slowAnimationDuration * 2, () {
                      //   if (autoScroll) {
                      //     scrollToCurrentBeat();
                      //   }
                      // });
                    },
                    child: Stack(children: [
                      AnimatedOpacity(
                        duration: animationDuration,
                        opacity: true ? 1 : 0,
                        child: Icon(Icons.expand),
                      ),
                    ])))));
  }

  alignVertically() {
    final scale = alignedScale;
    xScale = scale;
    yScale = scale;
  }

  AnimatedOpacity autoScrollButton({@required bool visible}) {
    return AnimatedOpacity(
      duration: animationDuration,
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedContainer(
            duration: animationDuration,
            color: Colors.black12,
            height: 48,
            width: 48,
            child: MyFlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    autoScroll = !autoScroll;
                  });
                },
                child: Stack(children: [
                  Transform.translate(
                      offset: Offset(0, -8),
                      child: Text("Auto",
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: autoScroll ? Colors.white : Colors.grey))),
                  Transform.translate(
                    offset: Offset(0, 6),
                    child: AnimatedOpacity(
                      duration: animationDuration,
                      opacity: !autoScroll ? 1 : 0,
                      child: Icon(Icons.location_disabled, color: Colors.grey),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, 6),
                    child: AnimatedOpacity(
                      duration: animationDuration,
                      opacity: autoScroll ? 1 : 0,
                      child: Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ]))),
      ),
    );
  }

  AnimatedOpacity colorblockButton({@required bool visible}) {
    return AnimatedOpacity(
        duration: animationDuration,
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedContainer(
                duration: animationDuration,
                color: Colors.black12,
                height: true ? 48 : 0,
                width: true ? 48 : 0,
                child: MyFlatButton(
                    onPressed: () {
                      widget.requestRenderingMode(widget.renderingMode == RenderingMode.colorblock
                          ? RenderingMode.notation
                          : RenderingMode.colorblock);
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
                    ])))));
  }

  double get alignedScale => min(maxScale, max(minScale, alignedStaffHeight / MusicSystemPainter.staffHeight));

  // double get toolbarHeight => widget.melodyViewMode == MelodyViewMode.score ||widget.melodyViewMode == MelodyViewMode.none
  double get removedHeight => context.isLandscapePhone
      ? _removedHeightLandscapePhone
      : (widget.melodyViewMode == MelodyViewMode.score || widget.melodyViewMode == MelodyViewMode.none)
          ? 32
          : widget.editingMelody || isEditingSection
              ? 100
              : isConfiguringPart
                  ? 300
                  : 50;

  double get _removedHeightLandscapePhone =>
      widget.melodyViewMode == MelodyViewMode.score || widget.melodyViewMode == MelodyViewMode.none
          ? -23
          : widget.editingMelody || isEditingSection
              ? 40
              : isConfiguringPart
                  ? 300
                  : 0;

  double get alignedStaffHeight => (widget.height - removedHeight) / widget.score.parts.length;
}

enum SwipeTutorial { collapse, closeExpand }

extension TutorialText on SwipeTutorial {
  String tutorialText(SplitMode splitMode, MelodyViewMode melodyViewMode, BuildContext context) {
    return splitMode == SplitMode.full
        ? "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to collapse/close ${melodyViewMode.toString().substring(15).capitalize()}"
        : "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to close,\n" +
            "${context.isPortrait ? "⬆️️" : "⬅️"}️ to expand " +
            "${melodyViewMode.toString().substring(15).capitalize()}";
  }
}
