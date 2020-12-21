import 'dart:math';

import 'package:beatscratch_flutter_redux/music_view/part_melody_browser.dart';
import 'package:beatscratch_flutter_redux/widget/my_platform.dart';
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
import 'part_instrument_picker.dart';
import 'music_scroll_container.dart';
import 'music_system_painter.dart';
import 'music_toolbars.dart';
import 'melody_editing_toolbar.dart';
import 'section_editing_toolbar.dart';

class MusicView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MusicViewMode musicViewMode;
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
  final Function(Part) selectOrDeselectPart;
  final Function(Melody) selectOrDeselectMelody;
  final Function(Part, Melody) createMelody;
  final Function cloneCurrentSection;
  final double initialScale;
  final bool isPreview;
  final Color backgroundColor;
  final bool isCurrentScore;
  final bool showViewOptions;
  final bool renderPartNames;
  final bool showBeatCounts;

  MusicView(
      {this.selectBeat,
      this.selectOrDeselectPart,
      this.selectOrDeselectMelody,
      this.melodyViewSizeFactor,
      this.cloneCurrentSection,
      this.superSetState,
      this.musicViewMode,
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
      this.backgroundColor = Colors.white,
      this.showBeatCounts,
      this.createMelody})
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
  bool isBrowsingPartMelodies;
  bool isEditingSection;
  bool _isTwoFingerScaling = false;

  // Offset _previousOffset = Offset.zero;
  bool _ignoreNextScale = false;
  Offset _offset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  bool _hasSwipedClosed = false;

  ValueNotifier<double> xScaleNotifier, yScaleNotifier, verticalScrollingPosition;

  /// Always immediately updated; the return values of [xScale] and [yScale].
  double _targetedXScale, _targetedYScale;

  /// Used to maintain a locking mechanism as we animate from [_xScale] to [_targetedXScale] in the setter for [xScale].
  DateTime _xScaleLock, _yScaleLock;
  List<AnimationController> _xScaleAnimationControllers, _yScaleAnimationControllers;

  /// Used to notify the [MusicScrollContainer] as we animate [_xScale] to [_targetedXScale] in the setter for [xScale].
  BSValueNotifier<ScaleUpdate> _xScaleUpdate, _yScaleUpdate;

  Map<MusicViewMode, List<SwipeTutorial>> _swipeTutorialsSeen;
  SwipeTutorial _currentSwipeTutorial;

  BSNotifier scrollToCurrentBeat, centerCurrentSection, scrollToPart;

  static const double maxScaleDiscrepancy = 1.5;
  static const double minScaleDiscrepancy = 1 / maxScaleDiscrepancy;

  ValueNotifier<int> highlightedBeat;
  DateTime focusedBeatUpdated = DateTime(0);
  ValueNotifier<int> focusedBeat, tappedBeat;
  ValueNotifier<Part> tappedPart;

  // ValueNotifier<double> _tappedYCoord;

  ValueNotifier<Offset> requestedScrollOffsetForScale;

  String _lastIgnoreId;
  bool _ignoreNextTap = false;

  MusicViewMode _previousMusicViewMode;
  SplitMode _previousSplitMode;
  bool _aligned;
  bool _partAligned;

  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 200));

  SwipeTutorial get currentSwipeTutorial => _currentSwipeTutorial;

  set currentSwipeTutorial(SwipeTutorial value) {
    if (value == null || _swipeTutorialsSeen[widget.musicViewMode].contains(value)) {
      _currentSwipeTutorial = null;
      return;
    }
    _currentSwipeTutorial = value;
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _swipeTutorialsSeen[widget.musicViewMode]?.add(value);
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
            // print("_startValueAnimation onComplete");
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
              melodyRendererVisibleRect.width / (context.isLandscape && widget.splitMode == SplitMode.half ? 4 : 2), 0),
          targeted: false);

      focusedBeatUpdated = DateTime.now();
      delayClear() {
        Future.delayed(Duration(milliseconds: focusTimeout), () {
          if (DateTime.now().difference(focusedBeatUpdated).inMilliseconds > focusTimeout) {
            // print("Cleared focusedBeat");
            focusedBeat.value = null;
          } else {
            delayClear();
          }
        });
      }

      delayClear();
      // print("Set focusedBeat to ${focusedBeat.value}");
    } else {
      focusedBeatUpdated = DateTime.now();
      // print("Keeping focusedBeat at ${focusedBeat.value}");
    }
  }

  _animateScaleAtomically({
    @required DateTime Function() getLockTime,
    @required Function(DateTime) setLockTime,
    @required double Function() value,
    @required double Function() currentValue,
    @required Function(double) applyAnimatedValue,
    @required List<AnimationController> controllers,
    @required BSValueNotifier<ScaleUpdate> notifyUpdate,
  }) {
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
              controllers: controllers,
            );
          });
      notifyUpdate(ScaleUpdate(currentValue(), value()));
    }

    if (getLockTime() == null || DateTime.now().difference(getLockTime()).inMilliseconds > 500) {
      if (lock()) {
        // print("unlocked");
        startAnimation();
      } else {
        // print("locked");
        retry() {
          Future.delayed(animationDuration, () {
            if (lock()) {
              // print("unlocked: retry");
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
    tappedBeat = new ValueNotifier(null);
    tappedPart = new ValueNotifier(null);
    verticalScrollingPosition = new ValueNotifier(0);
    requestedScrollOffsetForScale = ValueNotifier(null);
    _swipeTutorialsSeen = {
      MusicViewMode.melody: List(),
      MusicViewMode.part: List(),
      MusicViewMode.section: List(),
    };
    _xScaleAnimationControllers = [];
    _yScaleAnimationControllers = [];
    scrollToCurrentBeat = BSNotifier();
    centerCurrentSection = BSNotifier();
    _xScaleUpdate = BSValueNotifier(null);
    _yScaleUpdate = BSValueNotifier(null);
    centerCurrentSection = BSNotifier();
    scrollToPart = BSNotifier();

    isConfiguringPart = false;
    isBrowsingPartMelodies = false;
    isEditingSection = false;
    autoScroll = true;
    autoFocus = true;
    _aligned = true;
    _partAligned = false;
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

  bool get editingMelody => widget.editingMelody && widget.currentSection.referenceTo(widget.melody).isEnabled;

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
    if (_partAligned && (widget.musicViewMode == MusicViewMode.part || widget.musicViewMode == MusicViewMode.melody || widget.musicViewMode == MusicViewMode.score)) {
      if (xScale.notRoughlyEquals(partAlignedScale)) {
        partAlignVertically();
      }
    } else if (_aligned && xScale.notRoughlyEquals(alignedScale)) {
      alignVertically();
    }
    _previousSplitMode = widget.splitMode;
    _previousMusicViewMode = widget.musicViewMode;
    if (widget.part == null) {
      // isConfiguringPart = false;
    }
    if (widget.musicViewMode != MusicViewMode.section) {
      // isEditingSection = false;
    }
    if (!editingMelody || !BeatScratchPlugin.playing) {
      highlightedBeat.value = null;
    }
    currentSwipeTutorial = _swipeTutorialsSeen.keys.contains(widget.musicViewMode) && widget.melodyViewSizeFactor > 0
        ? widget.splitMode == SplitMode.half
            ? SwipeTutorial.closeExpand
            : SwipeTutorial.collapse
        : null;
    final sensitivity = 10;
    return Column(
      key: ValueKey("music-view-$widget.score.id"),
      children: [
        Column(children: [
          AnimatedContainer(
            duration: animationDuration,
            color: (widget.musicViewMode == MusicViewMode.section)
                ? widget.sectionColor
                : (widget.musicViewMode == MusicViewMode.melody)
                    ? Colors.white
                    : (widget.musicViewMode == MusicViewMode.part)
                        ? ((widget.part != null && widget.part.instrument.type == InstrumentType.drum)
                            ? Colors.brown
                            : Colors.grey)
                        : Colors.black,
            child: Row(
              children: <Widget>[
                if (MyPlatform.isMacOS || MyPlatform.isWeb)
                  Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity:
                            (widget.musicViewMode != MusicViewMode.score && widget.musicViewMode != MusicViewMode.none)
                                ? 1
                                : 0,
                        child: AnimatedContainer(
                            duration: animationDuration,
                            width: (widget.musicViewMode != MusicViewMode.score &&
                                    widget.musicViewMode != MusicViewMode.none)
                                ? 36
                                : 0,
                            height: (widget.musicViewMode != MusicViewMode.score &&
                                    widget.musicViewMode != MusicViewMode.none)
                                ? 36
                                : 0,
                            child: MyRaisedButton(
                                onPressed: widget.toggleSplitMode,
                                padding: EdgeInsets.all(7),
                                child: Transform.scale(
                                    scale: 0.8,
                                    child: Stack(
                                      children: [
                                        AnimatedOpacity(
                                            duration: animationDuration,
                                            opacity: widget.splitMode == SplitMode.half ? 1 : 0,
                                            child: Image.asset("assets/split_full.png")),
                                        AnimatedOpacity(
                                            duration: animationDuration,
                                            opacity: widget.splitMode != SplitMode.half && context.isPortrait ? 1 : 0,
                                            child: Image.asset("assets/split_horizontal.png")),
                                        AnimatedOpacity(
                                            duration: animationDuration,
                                            opacity: widget.splitMode != SplitMode.half && context.isLandscape ? 1 : 0,
                                            child: Image.asset("assets/split_vertical.png")),
                                      ],
                                    )))),
                      )),
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
                                  height: (widget.musicViewMode == MusicViewMode.section) ? toolbarHeight(context) : 0,
                                  child: SectionToolbar(
                                    currentSection: widget.currentSection,
                                    sectionColor: widget.sectionColor,
                                    musicViewMode: widget.musicViewMode,
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
                                  height: (widget.musicViewMode == MusicViewMode.part) ? toolbarHeight(context) : 0,
                                  child: PartToolbar(
                                      enableColorboard: widget.enableColorboard,
                                      part: widget.part,
                                      setKeyboardPart: widget.setKeyboardPart,
                                      configuringPart: isConfiguringPart,
                                      browsingPartMelodies: isBrowsingPartMelodies,
                                      toggleConfiguringPart: () {
                                        setState(() {
                                          isConfiguringPart = !isConfiguringPart;
                                          if (isConfiguringPart && !context.isTablet) {
                                            makeFullSize();
                                          }
                                        });
                                      },
                                      toggleBrowsingPartMelodies: () {
                                        setState(() {
                                          isBrowsingPartMelodies = !isBrowsingPartMelodies;
                                          // if (isConfiguringPart && !context.isTablet) {
                                          //   makeFullSize();
                                          // }
                                        });
                                      },
                                      setColorboardPart: widget.setColorboardPart,
                                      colorboardPart: widget.colorboardPart,
                                      keyboardPart: widget.keyboardPart,
                                      deletePart: widget.deletePart,
                                      sectionColor: widget.sectionColor)),
                              AnimatedContainer(
                                  duration: animationDuration,
                                  height: (widget.musicViewMode == MusicViewMode.melody) ? toolbarHeight(context) : 0,
                                  child: MelodyToolbar(
                                    melody: widget.melody,
                                    musicViewMode: widget.musicViewMode,
                                    currentSection: widget.currentSection,
                                    toggleMelodyReference: widget.toggleMelodyReference,
                                    setReferenceVolume: widget.setReferenceVolume,
                                    editingMelody: editingMelody,
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
                                    opacity: currentSwipeTutorial == null || MyPlatform.isMacOS || MyPlatform.isWeb
                                        ? 0
                                        : 0.8,
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
                                                widget.splitMode, widget.musicViewMode, context),
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
                //       opacity: (widget.musicViewMode != MusicViewMode.score && widget.musicViewMode != MusicViewMode.none) ? 1 : 0,
                //       child: AnimatedContainer(
                //           duration: animationDuration,
                //           width: (widget.musicViewMode != MusicViewMode.score && widget.musicViewMode != MusicViewMode.none) ? 36 : 0,
                //           height: (widget.musicViewMode != MusicViewMode.score && widget.musicViewMode != MusicViewMode.none) ? 36 : 0,
                //           child: MyRaisedButton(
                //               onPressed: widget.closeMelodyView, padding: EdgeInsets.all(0), child: widget.previewMode ? SizedBox() : Icon(Icons.close))),
                //     ))
              ],
            ),
          ),
          AnimatedOpacity(
            duration: animationDuration,
            opacity: widget.musicViewMode == MusicViewMode.part && isBrowsingPartMelodies ? 1 : 0,
            child: AnimatedContainer(
                color: widget.part != null && widget.part.instrument.type == InstrumentType.drum
                    ? Colors.brown
                    : Colors.grey,
                duration: animationDuration,
                height:
                    (widget.musicViewMode == MusicViewMode.part && isBrowsingPartMelodies) ? toolbarHeight(context) : 0,
                child: PartMelodyBrowser(
                  sectionColor: widget.sectionColor,
                  score: widget.score,
                  currentSection: widget.currentSection,
                  part: widget.part,
                  browsingMelodies: isBrowsingPartMelodies,
                  selectOrDeselectMelody: widget.selectOrDeselectMelody,
                  createMelody: widget.createMelody,
                  toggleMelodyReference: widget.toggleMelodyReference,
                )),
          ),
          AnimatedContainer(
              duration: animationDuration,
              color: widget.part != null && widget.part.instrument.type == InstrumentType.drum
                  ? Colors.brown
                  : Colors.grey,
              height: (widget.musicViewMode == MusicViewMode.part && isConfiguringPart)
                  ? min(280, max(110, widget.height))
                  : 0,
              child: PartConfiguration(
                  part: widget.part,
                  superSetState: widget.superSetState,
                  availableHeight: widget.height,
                  visible: (widget.musicViewMode == MusicViewMode.part && isConfiguringPart))),
          AnimatedContainer(
              color: Colors.white,
              duration: animationDuration,
              height: (widget.musicViewMode == MusicViewMode.melody && editingMelody) ? toolbarHeight(context) : 0,
              child: MelodyEditingToolbar(
                editingMelody: editingMelody,
                sectionColor: widget.sectionColor,
                score: widget.score,
                melodyId: widget.melody?.id,
                currentSection: widget.currentSection,
                highlightedBeat: highlightedBeat,
              )),
          AnimatedContainer(
              color: widget.sectionColor,
              duration: animationDuration,
              height: (widget.musicViewMode == MusicViewMode.section && isEditingSection) ? toolbarHeight(context) : 0,
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
    // if (widget.musicViewMode == MusicViewMode.score) {
    maxBeat = widget.score.beatCount - 1;
    // } else {
    //   maxBeat = widget.currentSection.beatCount - 1;
    // }
    beat = max(0, min(beat, maxBeat));
    return beat;
  }

  Part mainPart() {
    Part mainPart = widget.part; // default for Part view mode is pass it through
    if (widget.musicViewMode == MusicViewMode.score) {
      mainPart = widget.keyboardPart;
    } else if (widget.musicViewMode == MusicViewMode.melody) {
      widget.score.parts
        .firstWhere((part) => part.melodies.any((melody) => melody.id == widget.melody.id), orElse: () => null);
    }
    return mainPart;
  }

  Widget _mainMelody(BuildContext context) {
    List<MusicStaff> staves;
    Part mainPart = this.mainPart();
    bool focusPartsAndMelodies = autoFocus &&
        (widget.musicViewMode == MusicViewMode.score ||
            widget.musicViewMode == MusicViewMode.part ||
            widget.musicViewMode == MusicViewMode.melody);
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
        mainPart != null && widget.score.parts.indexWhere((it) => it.id == mainPart.id) != 0;
    bool focusedMelodyIsNotFirst = widget.melody != null &&
        widget.score.parts.indexWhere((p) => p.melodies.any((m) => m.id == widget.melody.id)) != 0;
    bool showAutoFocusButton =
        (widget.musicViewMode == MusicViewMode.part || widget.musicViewMode == MusicViewMode.melody || widget.musicViewMode == MusicViewMode.score) &&
            (focusedPartIsNotFirst || focusedMelodyIsNotFirst);
    bool isPartOrMelodyView =
        widget.musicViewMode == MusicViewMode.part || widget.musicViewMode == MusicViewMode.melody;
    return Container(
        color: widget.backgroundColor.withOpacity(widget.backgroundColor.opacity * (widget.isPreview ? 0.5 : 1)),
        child: GestureDetector(
            onTapDown: (details) {
              int beat = getBeat(details.localPosition);
              print("onTapDown: ${details.localPosition} -> beat: $beat; x/t: $_xScale/$_targetedXScale");
              tappedBeat.value = beat;
              double absoluteY = verticalScrollingPosition.value + details.localPosition.dy;
              absoluteY -= MusicSystemPainter.calculateHarmonyHeight(yScale);
              if(widget.musicViewMode == MusicViewMode.score) {
                absoluteY -= MusicSystemPainter.calculateSectionHeight(yScale);
              }
              int partIndex = (absoluteY / (yScale * MusicSystemPainter.staffHeight)).floor();
              if (!autoFocus ||
                      widget.musicViewMode ==
                          MusicViewMode.section  /*||
                  (widget.musicViewMode == MusicViewMode.score && widget.)*/
                  ) {
                final parts = widget.score.parts;
                tappedPart.value = parts[min(parts.length - 1, partIndex)];
              } else {
                if (partIndex == 0 || widget.score.parts.length == 1) {
                  tappedPart.value = widget.part ?? widget.score.parts.first;
                } else {
                  final parts = widget.score.parts.where((p) => p.id != mainPart?.id).toList(growable: false);
                  if (parts.isEmpty) return;
                  tappedPart.value = parts[min(parts.length - 1, --partIndex)];
                }
              }
              Future.delayed(Duration(milliseconds: 800), () {
                tappedBeat.value = null;
                tappedPart.value = null;
              });
            },
            onTapUp: (details) {
              if (ignoreNextTap) {
                return;
              }
              int beat = getBeat(details.localPosition);
              print("onTapUp: ${details.localPosition} -> beat: $beat; x/t: $_xScale/$_targetedXScale");
              if (BeatScratchPlugin.playing && editingMelody && highlightedBeat.value != beat) {
                setState(() {
                  highlightedBeat.value = beat;
                });
              } else if (BeatScratchPlugin.playing && editingMelody && highlightedBeat.value == beat) {
                setState(() {
                  highlightedBeat.value = null;
                });
              } else {
                widget.selectBeat(beat);
              }
            },
            onLongPress: () {
              if (widget.score.parts.isEmpty) return;
              if (widget.musicViewMode == MusicViewMode.score) {
                widget.selectBeat(tappedBeat.value);
                widget.setKeyboardPart(tappedPart.value);
                if (autoFocus) {
                  print("scrollToPart");
                  scrollToPart();
                }
                return;
              }
              final part = tappedPart.value;
              if (part == null) return;
              if (isPartOrMelodyView) {
                widget.selectOrDeselectPart(part);
              } else if (widget.musicViewMode == MusicViewMode.section) {
                widget.selectOrDeselectPart(part);
              }
              if (autoFocus) {
                print("scrollToPart");
                scrollToPart();
              }
              widget.selectBeat(tappedBeat.value);
            },
            onScaleStart: (details) => setState(() {
                  if (_ignoreNextScale) {
                    return;
                  }
                  _aligned = false;
                  _partAligned = false;
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
                if (details.scale > 0) {
                  final target = _startHorizontalScale * details.horizontalScale;
                  rawXScale = target;
                  rawYScale = target;
                }
                // if (details.horizontalScale > 0) {
                //   final target = _startHorizontalScale * details.horizontalScale;
                //   rawXScale = target;
                // }
                // if (details.verticalScale > 0) {
                //   final target = _startVerticalScale * details.verticalScale;
                //   rawYScale = target;
                // }
              });
            },
            onScaleEnd: (ScaleEndDetails details) {
              _ignoreNextScale = false;
              _isTwoFingerScaling = false;
              focusedBeat.value = null;
            },
            child: Stack(children: [
              MusicScrollContainer(
                musicViewMode: widget.musicViewMode,
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
                tappedBeat: tappedBeat,
                tappedPart: tappedPart,
                verticalScrollNotifier: verticalScrollingPosition,
                requestedScrollOffsetForScale: requestedScrollOffsetForScale,
                targetXScale: xScale,
                targetYScale: yScale,
                isTwoFingerScaling: _isTwoFingerScaling,
                scrollToCurrentBeat: scrollToCurrentBeat,
                scrollToPart: scrollToPart,
                centerCurrentSection: centerCurrentSection,
                autoScroll: autoScroll,
                autoFocus: autoFocus,
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
                    focusZoomButton(
                        visible: xScale == alignedScale &&
                            xScale != partAlignedScale &&
                            (widget.musicViewMode == MusicViewMode.part ||
                                widget.musicViewMode == MusicViewMode.score ||
                                widget.musicViewMode == MusicViewMode.melody)),
                    SizedBox(height: 2),
                    expandButton(visible: xScale != alignedScale),
                    SizedBox(height: 2),
                  ]),
                  if (xScale != alignedScale || xScale != partAlignedScale) SizedBox(width: 2),
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
                    _aligned = false;
                    _partAligned = false;
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
                    _aligned = false;
                    _partAligned = false;
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
                height: visible ? 48 : 0,
                width: visible ? 48 : 0,
                child: MyFlatButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _aligned = true;
                        _partAligned = false;
                        alignVertically();
                      });
                    },
                    child: Stack(children: [
                      AnimatedOpacity(
                        duration: animationDuration,
                        opacity: true ? 1 : 0,
                        child: Icon(Icons.expand),
                      ),
                    ])))));
  }

  AnimatedOpacity focusZoomButton({@required bool visible}) {
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
                        _partAligned = true;
                        partAlignVertically();
                      });
                    },
                    child: Stack(children: [
                      Transform.translate(
                        offset: Offset(-6, -6),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: true ? 1 : 0,
                          child: Icon(Icons.zoom_in, size: 18),
                        ),
                      ),
                      Transform.translate(
                          offset: Offset(6, 6),
                          child: AnimatedOpacity(
                            duration: animationDuration,
                            opacity: true ? 1 : 0,
                            child: Icon(Icons.expand, size: 18),
                          )),
                    ])))));
  }

  alignVertically() {
    final scale = alignedScale;
    xScale = scale;
    yScale = scale;
  }

  partAlignVertically() {
    final scale = partAlignedScale;
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

  double get partAlignedScale => min(maxScale, max(minScale, partAlignedStaffHeight / MusicSystemPainter.staffHeight));

  // double get toolbarHeight => widget.musicViewMode == MusicViewMode.score ||widget.musicViewMode == MusicViewMode.none
  double get removedHeight => context.isLandscapePhone
      ? _removedHeightLandscapePhone
      : (widget.musicViewMode == MusicViewMode.score || widget.musicViewMode == MusicViewMode.none)
          ? 32
          : editingMelody || isEditingSection || isBrowsingPartMelodies
              ? 100
              : isConfiguringPart
                  ? 300
                  : 50;

  double get _removedHeightLandscapePhone =>
      widget.musicViewMode == MusicViewMode.score || widget.musicViewMode == MusicViewMode.none
          ? -23
          : editingMelody || isEditingSection || isBrowsingPartMelodies
              ? 40
              : isConfiguringPart
                  ? 300
                  : 0;

  double get alignedStaffHeight => (widget.height - removedHeight) / widget.score.parts.length;

  double get partAlignedStaffHeight => (widget.height - removedHeight) / 1.62;
}

enum SwipeTutorial { collapse, closeExpand }

extension TutorialText on SwipeTutorial {
  String tutorialText(SplitMode splitMode, MusicViewMode musicViewMode, BuildContext context) {
    return splitMode == SplitMode.full
        ? "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to collapse/close ${musicViewMode.toString().substring(14).capitalize()}"
        : "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to close,\n" +
            "${context.isPortrait ? "⬆️️" : "⬅️"}️ to expand " +
            "${musicViewMode.toString().substring(14).capitalize()}";
  }
}
