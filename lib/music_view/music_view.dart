import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/generated/i18n.dart';
import 'package:beatscratch_flutter_redux/widget/color_filtered_image_asset.dart';

import '../colors.dart';
import '../music_view/part_melody_browser.dart';
import '../settings/app_settings.dart';
import '../widget/my_platform.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_icons/flutter_icons.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/bs_methods.dart';
import '../util/util.dart';
import '../widget/incrementable_value.dart';
import '../widget/my_buttons.dart';
import 'part_instrument_picker.dart';
import 'music_scroll_container.dart';
import 'music_system_painter.dart';
import 'music_toolbars.dart';
import 'music_action_button.dart';
import 'melody_editing_toolbar.dart';
import 'section_editing_toolbar.dart';

class MusicView extends StatefulWidget {
  final AppSettings appSettings;
  final double melodyViewSizeFactor;
  final MusicViewMode musicViewMode;
  final SplitMode splitMode;
  final RenderingMode renderingMode;
  final Function(RenderingMode) requestRenderingMode;
  final Score score;
  final Section currentSection;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier,
      keyboardNotesNotifier;
  final ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;
  final Melody melody;
  final Part part;
  final Color sectionColor;
  final VoidCallback toggleSplitMode, closeMelodyView, toggleRecording;
  final Function(VoidCallback) superSetState;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Function(Part, double) setPartVolume;
  final Function(Melody, String) setMelodyName;
  final Function(Section, String) setSectionName;
  final bool recordingMelody;
  final Function(Part) setKeyboardPart, setColorboardPart;
  final Part keyboardPart, colorboardPart;
  final Function(Part) deletePart;
  final Function(Melody) deleteMelody;
  final Function(Section) deleteSection;
  final double width, height;
  final bool enableColorboard;
  final Function(int) selectBeat;
  final Function(Part) selectOrDeselectPart;
  final Function(Melody) selectOrDeselectMelody;
  final Function(Part, Melody, bool) createMelody;
  final Function addPart;
  final Function cloneCurrentSection;
  final Color backgroundColor;
  final bool isCurrentScore;
  final bool showViewOptions;
  final bool showBeatCounts;
  final bool showingSectionList;
  final BSMethod scrollToCurrentBeat;

  MusicView(
      {this.appSettings,
      this.selectBeat,
      this.selectOrDeselectPart,
      this.selectOrDeselectMelody,
      this.melodyViewSizeFactor,
      this.addPart,
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
      this.recordingMelody,
      this.toggleRecording,
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
      this.bluetoothControllerPressedNotes,
      this.height,
      this.width,
      this.enableColorboard,
      this.isCurrentScore = true,
      Key key,
      this.requestRenderingMode,
      this.showViewOptions = false,
      this.backgroundColor = Colors.white,
      this.showBeatCounts,
      this.createMelody,
      this.scrollToCurrentBeat,
      this.showingSectionList})
      : super(key: key);

  @override
  _MusicViewState createState() => _MusicViewState();
}

class _MusicViewState extends State<MusicView> with TickerProviderStateMixin {
  static const double minScale = MusicScrollContainer.minScale;
  static const double maxScale = MusicScrollContainer.maxScale;
  bool _disposed;
  bool get autoScroll => widget.appSettings.autoScrollMusic;
  set autoScroll(bool v) => widget.appSettings.autoScrollMusic = v;
  bool get autoSort => widget.appSettings.autoSortMusic;
  set autoSort(bool v) => widget.appSettings.autoSortMusic = v;
  bool get autoZoomAlign => widget.appSettings.autoZoomAlignMusic;
  set autoZoomAlign(bool v) => widget.appSettings.autoZoomAlignMusic = v;
  bool isConfiguringPart;
  bool isBrowsingPartMelodies;
  bool isEditingSection;
  TransformationController transformationController;
  ValueNotifier<ScaleUpdateDetails> scaleUpdateNotifier =
      ValueNotifier(ScaleUpdateDetails());

  // Offset _previousOffset = Offset.zero;
  bool _ignoreNextScale = false;
  // Offset _offset = Offset.zero;
  // Offset _startFocalPoint = Offset.zero;
  double _startScale = 1.0;
  // double _startHorizontalScale = 1.0;
  // double _startVerticalScale = 1.0;
  bool _hasSwipedClosed = false;
  bool _forceShowViewOptions = false;
  DateTime _forceShowViewOptionsTime = DateTime.now();
  bool get forceShowViewOptions => _forceShowViewOptions;
  set forceShowViewOptions(bool v) {
    _forceShowViewOptions = v;
    final now = DateTime.now();
    if (v) {
      _forceShowViewOptionsTime = now;
      Future.delayed(Duration(milliseconds: 1500), () {
        if (_forceShowViewOptionsTime == now) {
          setState(() {
            _forceShowViewOptions = false;
          });
        }
      });
    }
  }

  bool get showViewOptions => widget.showViewOptions || forceShowViewOptions;

  /// Always immediately updated; the return values of [targetedScale] and [scale].
  ValueNotifier<double> _targetedScale;
  double get targetedScale => _targetedScale.value;
  set targetedScale(double v) {
    print("set targetedScale=$v");
    _targetedScale.value = v;
    widget.appSettings.musicScale = v;
  }

  /// Used to maintain a locking mechanism as we animate from [_xScale] to [targetedScale] in the setter for [targetedScale].
  DateTime _xScaleLock;
  List<AnimationController> _xScaleAnimationControllers,
      _yScaleAnimationControllers;

  /// Used to notify the [MusicScrollContainer] as we animate [_xScale] to [targetedScale] in the setter for [targetedScale].
  // BSValueMethod<ScaleUpdate> _xScaleUpdate, _yScaleUpdate;

  Map<MusicViewMode, List<SwipeTutorial>> _swipeTutorialsSeen;
  SwipeTutorial _currentSwipeTutorial;

  BSMethod centerCurrentSection, scrollToPart;

  // static const double maxScaleDiscrepancy = 1.5;
  // static const double minScaleDiscrepancy = 1 / maxScaleDiscrepancy;

  ValueNotifier<int> highlightedBeat;
  DateTime focusedBeatUpdated = DateTime(0);
  ValueNotifier<int> focusedBeat, tappedBeat;
  ValueNotifier<Part> tappedPart;

  // ValueNotifier<double> _tappedYCoord;

  ValueNotifier<Offset> requestedScrollOffsetForScale;

  String _lastIgnoreId;
  bool _ignoreNextTap = false;

  // ignore: unused_field
  MusicViewMode _previousMusicViewMode;
  // ignore: unused_field
  SplitMode _previousSplitMode;

  bool get _aligned => widget.appSettings.alignMusic;
  set _aligned(bool v) => widget.appSettings.alignMusic = v;
  bool get _partAligned => widget.appSettings.partAlignMusic;
  set _partAligned(bool v) => widget.appSettings.partAlignMusic = v;

  AnimationController animationController() =>
      AnimationController(vsync: this, duration: animationDuration);

  SwipeTutorial get currentSwipeTutorial => _currentSwipeTutorial;

  set currentSwipeTutorial(SwipeTutorial value) {
    if (value == null ||
        _swipeTutorialsSeen[widget.musicViewMode].contains(value)) {
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
      // print("animating targetedScale to $value");
      // print("Tween params: begin: $currentValue, end: $value");
      animation = Tween<double>(begin: currentValue(), end: value())
          .animate(scaleAnimationController)
        ..addListener(() {
          // print("Tween scale: ${animation.value}");
          if (!_disposed) {
            setState(() {
              applyAnimatedValue(animation.value);
            });
          }
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

  _updateFocusedBeatValue(
      {int value, bool withDelayClear = true, bool force = false}) {
    if (value == null) {
      value = getBeat(
          Offset(
              widget.width /
                  (context.isLandscape && widget.splitMode == SplitMode.half
                      ? 4
                      : 2),
              0),
          targeted: false);
    }
    if (force ||
        focusedBeat.value == null ||
        DateTime.now().difference(focusedBeatUpdated).inMilliseconds >
            focusTimeout) {
      focusedBeat.value = value;

      focusedBeatUpdated = DateTime.now();

      if (withDelayClear) {
        delayClear() {
          Future.delayed(Duration(milliseconds: focusTimeout), () {
            if (DateTime.now().difference(focusedBeatUpdated).inMilliseconds >
                focusTimeout) {
              // print("Cleared focusedBeat");
              focusedBeat.value = null;
            } else {
              delayClear();
            }
          });
        }

        delayClear();
      }
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
      // _updateFocusedBeatValue();
      double prevValue = currentValue();
      _startValueAnimation(
          value: value,
          currentValue: currentValue,
          applyAnimatedValue: (v) {
            applyAnimatedValue(v);
            // notifyUpdate(ScaleUpdate(prevValue, v));
            prevValue = v;
          },
          controllers: controllers,
          onComplete: () {
            // _updateFocusedBeatValue(value: null);
            _animateScaleAtomically(
              getLockTime: getLockTime,
              setLockTime: setLockTime,
              // notifyUpdate: notifyUpdate,
              value: value,
              currentValue: currentValue,
              applyAnimatedValue: applyAnimatedValue,
              controllers: controllers,
            );
          });
      // notifyUpdate(ScaleUpdate(currentValue(), value()));
    }

    if (getLockTime() == null ||
        DateTime.now().difference(getLockTime()).inMilliseconds > 500) {
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

  double get dx =>
      MatrixUtils.getAsTranslation(transformationController.value).dx;
  double get dy =>
      MatrixUtils.getAsTranslation(transformationController.value).dy;
  double get scale => transformationController.value.getMaxScaleOnAxis();
  set scale(value) {
    print(
        "Setting scale to $value, currently=$scale, scaling by ${value / scale}");
    transformationController.value
        .scale(value / scale, value / scale, value / scale);
  }

  _onScaleUpdated() {
    if (scaleUpdateNotifier.value.scale != 1) {
      _partAligned = false;
      _aligned = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _disposed = false;
    transformationController = TransformationController()
      ..addListener(_onTransformationChange);
    highlightedBeat = new ValueNotifier(null);
    focusedBeat = new ValueNotifier(null);
    tappedBeat = new ValueNotifier(null);
    tappedPart = new ValueNotifier(null);
    _targetedScale = ValueNotifier(null);
    requestedScrollOffsetForScale = ValueNotifier(null);
    _swipeTutorialsSeen = {
      MusicViewMode.melody: [],
      MusicViewMode.part: [],
      MusicViewMode.section: [],
    };
    _xScaleAnimationControllers = [];
    _yScaleAnimationControllers = [];
    centerCurrentSection = BSMethod();
    centerCurrentSection = BSMethod();
    scrollToPart = BSMethod();
    scaleUpdateNotifier.addListener(_onScaleUpdated);
    isConfiguringPart = false;
    isBrowsingPartMelodies = true;
    isEditingSection = true;
    _aligned = true;
    _partAligned = false;
    widget.scrollToCurrentBeat.addListener(handleZoomAlign);
  }

  double toolbarHeight(BuildContext context) =>
      context.isLandscapePhone ? 42 : 48;

  double get partConfigHeight => min(280, max(110, widget.height));

  @override
  void dispose() {
    _disposed = true;
    _xScaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _yScaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _xScaleAnimationControllers.clear();
    _yScaleAnimationControllers.clear();
    highlightedBeat.dispose();
    centerCurrentSection.dispose();
    scaleUpdateNotifier.removeListener(_onScaleUpdated);
    widget.scrollToCurrentBeat.removeListener(handleZoomAlign);
    transformationController
      ..removeListener(_onTransformationChange)
      ..dispose();
    super.dispose();
  }

  scaleText(double scale) => "${(scale * 100).toStringAsFixed(0)}%";

  double _preTransformationScale = 1;
  _onTransformationChange() {
    if (scaleText(scale) != scaleText(_preTransformationScale)) {
      setState(() {});
    }
    _preTransformationScale = scale;
  }

  makeFullSize() {
    if (widget.splitMode == SplitMode.half) {
      widget.toggleSplitMode();
    }
  }

  bool _ignoreDragEvents = false;

  bool get ignoreDragEvents => _ignoreDragEvents;

  bool get recordingMelody =>
      widget.recordingMelody &&
      widget.currentSection.referenceTo(widget.melody).isEnabled;

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
    if (scale == null || targetedScale == null) {
      final musicScale = widget.appSettings.musicScale;
      if (musicScale == null) {
        if (context.isTablet) {
          scale = 0.33;
        } else {
          scale = 0.22;
        }
      } else {
        scale = musicScale;
      }
      targetedScale = scale;
    }
    // if (targetedScale != null &&
    //     (_xScale.notRoughlyEquals(targetedScale) ||
    //         _yScale.notRoughlyEquals(targetedScale))) {
    //   targetedScale = targetedScale;
    //   scale = scale;
    // }
    if (_partAligned &&
        (widget.musicViewMode == MusicViewMode.part ||
            widget.musicViewMode == MusicViewMode.melody ||
            widget.musicViewMode == MusicViewMode.score)) {
      if (targetedScale.notRoughlyEquals(partAlignedScale)) {
        partAlignVertically();
      }
    } else if (_aligned && targetedScale.notRoughlyEquals(alignedScale)) {
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
    if (!recordingMelody || !BeatScratchPlugin.playing) {
      highlightedBeat.value = null;
    }
    currentSwipeTutorial =
        _swipeTutorialsSeen.keys.contains(widget.musicViewMode) &&
                widget.melodyViewSizeFactor > 0
            ? widget.splitMode == SplitMode.half
                ? SwipeTutorial.closeExpand
                : SwipeTutorial.collapse
            : null;
    final sensitivity = 10;
    return Stack(children: [
      Column(
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
                          ? ((widget.part != null &&
                                  widget.part.instrument.type ==
                                      InstrumentType.drum)
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
                          opacity: (widget.musicViewMode !=
                                      MusicViewMode.score &&
                                  widget.musicViewMode != MusicViewMode.none)
                              ? 1
                              : 0,
                          child: AnimatedContainer(
                              duration: animationDuration,
                              width: (widget.musicViewMode !=
                                          MusicViewMode.score &&
                                      widget.musicViewMode !=
                                          MusicViewMode.none)
                                  ? 36
                                  : 0,
                              height: (widget.musicViewMode !=
                                          MusicViewMode.score &&
                                      widget.musicViewMode !=
                                          MusicViewMode.none)
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
                                              opacity: widget.splitMode ==
                                                      SplitMode.half
                                                  ? 1
                                                  : 0,
                                              child: ColorFilteredImageAsset(
                                                imageSource:
                                                    "assets/split_full.png",
                                                imageColor: Colors.white,
                                              )),
                                          AnimatedOpacity(
                                              duration: animationDuration,
                                              opacity: widget.splitMode !=
                                                          SplitMode.half &&
                                                      context.isPortrait
                                                  ? 1
                                                  : 0,
                                              child: ColorFilteredImageAsset(
                                                imageSource:
                                                    "assets/split_horizontal.png",
                                                imageColor: Colors.white,
                                              )),
                                          AnimatedOpacity(
                                              duration: animationDuration,
                                              opacity: widget.splitMode !=
                                                          SplitMode.half &&
                                                      context.isLandscape
                                                  ? 1
                                                  : 0,
                                              child: ColorFilteredImageAsset(
                                                imageSource:
                                                    "assets/split_vertical.png",
                                                imageColor: Colors.white,
                                              )),
                                        ],
                                      )))),
                        )),
                  Expanded(
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: context.isPortrait
                              ? (details) {
                                  if (ignoreDragEvents) return;
                                  if (details.delta.dy > sensitivity) {
                                    // Down swipe
                                    HapticFeedback.lightImpact();
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
                                      HapticFeedback.lightImpact();
                                      widget.toggleSplitMode();
                                    }
                                    ignoreDragEvents = true;
                                  }
                                }
                              : null,
                          onHorizontalDragUpdate: context.isLandscape
                              ? (details) {
                                  if (ignoreDragEvents) return;
                                  if (details.delta.dx > sensitivity) {
                                    // Right swipe
                                    HapticFeedback.lightImpact();
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
                                      HapticFeedback.lightImpact();
                                      widget.toggleSplitMode();
                                    }
                                    ignoreDragEvents = true;
                                  }
                                }
                              : null,
                          child: Stack(
                            children: [
                              Column(children: [
                                AnimatedContainer(
                                    duration: animationDuration,
                                    height: (widget.musicViewMode ==
                                            MusicViewMode.section)
                                        ? toolbarHeight(context)
                                        : 0,
                                    child: SectionToolbar(
                                      currentSection: widget.currentSection,
                                      sectionColor: widget.sectionColor,
                                      musicViewMode: widget.musicViewMode,
                                      setSectionName: widget.setSectionName,
                                      deleteSection: widget.deleteSection,
                                      canDeleteSection:
                                          widget.score.sections.length > 1,
                                      addPart: widget.addPart,
                                      cloneCurrentSection:
                                          widget.cloneCurrentSection,
                                      editingSection: isEditingSection,
                                      setEditingSection: (value) {
                                        setState(() {
                                          isEditingSection = value;
                                        });
                                      },
                                    )),
                                AnimatedContainer(
                                    duration: animationDuration,
                                    height: (widget.musicViewMode ==
                                            MusicViewMode.part)
                                        ? toolbarHeight(context)
                                        : 0,
                                    child: PartToolbar(
                                        enableColorboard:
                                            widget.enableColorboard,
                                        part: widget.part,
                                        setKeyboardPart: widget.setKeyboardPart,
                                        configuringPart: isConfiguringPart,
                                        browsingPartMelodies:
                                            isBrowsingPartMelodies,
                                        toggleConfiguringPart: () {
                                          setState(() {
                                            isConfiguringPart =
                                                !isConfiguringPart;
                                            if (isConfiguringPart &&
                                                !context.isTablet) {
                                              makeFullSize();
                                            }
                                          });
                                        },
                                        toggleBrowsingPartMelodies: () {
                                          setState(() {
                                            isBrowsingPartMelodies =
                                                !isBrowsingPartMelodies;
                                            // if (isConfiguringPart && !context.isTablet) {
                                            //   makeFullSize();
                                            // }
                                          });
                                        },
                                        setColorboardPart:
                                            widget.setColorboardPart,
                                        colorboardPart: widget.colorboardPart,
                                        keyboardPart: widget.keyboardPart,
                                        deletePart: widget.deletePart,
                                        sectionColor: widget.sectionColor)),
                                AnimatedContainer(
                                    duration: animationDuration,
                                    height: (widget.musicViewMode ==
                                            MusicViewMode.melody)
                                        ? toolbarHeight(context)
                                        : 0,
                                    child: MelodyToolbar(
                                      melody: widget.melody,
                                      musicViewMode: widget.musicViewMode,
                                      currentSection: widget.currentSection,
                                      toggleMelodyReference:
                                          widget.toggleMelodyReference,
                                      setReferenceVolume:
                                          widget.setReferenceVolume,
                                      editingMelody: recordingMelody,
                                      sectionColor: widget.sectionColor,
                                      toggleRecording: widget.toggleRecording,
                                      setMelodyName: widget.setMelodyName,
                                      deleteMelody: widget.deleteMelody,
                                      backToPart: () =>
                                          widget.selectOrDeselectPart(
                                              widget.keyboardPart),
                                    )),
                              ]),
                              Transform.translate(
                                offset: Offset(0, 2),
                                child: Align(
                                    alignment: Alignment.center,
                                    child: AnimatedOpacity(
                                      opacity: currentSwipeTutorial == null ||
                                              MyPlatform.isMacOS ||
                                              MyPlatform.isWeb
                                          ? 0
                                          : 0.8,
                                      duration: animationDuration,
                                      child: AnimatedContainer(
                                          height:
                                              currentSwipeTutorial == null ||
                                                      _hasSwipedClosed
                                                  ? 0
                                                  : 36,
                                          duration: animationDuration,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: Colors.white,
                                          ),
                                          width: 150,
                                          child: Column(children: [
                                            Expanded(child: SizedBox()),
                                            Text(
                                              currentSwipeTutorial.tutorialText(
                                                  widget.splitMode,
                                                  widget.musicViewMode,
                                                  context),
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
                opacity: (widget.musicViewMode == MusicViewMode.melody) ? 1 : 0,
                child: AnimatedContainer(
                    color: Colors.white,
                    duration: animationDuration,
                    height: (widget.musicViewMode == MusicViewMode.melody)
                        ? toolbarHeight(context)
                        : 0,
                    child: MelodyEditingToolbar(
                      visible: widget.musicViewMode == MusicViewMode.melody,
                      recordingMelody: recordingMelody,
                      sectionColor: widget.sectionColor,
                      score: widget.score,
                      melodyId: widget.melody?.id,
                      currentSection: widget.currentSection,
                      highlightedBeat: highlightedBeat,
                      setReferenceVolume: widget.setReferenceVolume,
                    ))),
            AnimatedOpacity(
              duration: animationDuration,
              opacity: widget.musicViewMode == MusicViewMode.part ? 1 : 0,
              child: AnimatedContainer(
                  color: widget.part != null &&
                          widget.part.instrument.type == InstrumentType.drum
                      ? Colors.brown
                      : Colors.grey,
                  duration: animationDuration,
                  height: (widget.musicViewMode == MusicViewMode.part)
                      ? toolbarHeight(context)
                      : 0,
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
            AnimatedOpacity(
                duration: animationDuration,
                opacity: (widget.musicViewMode == MusicViewMode.part &&
                        isConfiguringPart)
                    ? 1
                    : 0,
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: widget.part != null &&
                            widget.part.instrument.type == InstrumentType.drum
                        ? Colors.brown
                        : Colors.grey,
                    height: (widget.musicViewMode == MusicViewMode.part &&
                            isConfiguringPart)
                        ? partConfigHeight
                        : 0,
                    child: PartConfiguration(
                        part: widget.part,
                        superSetState: widget.superSetState,
                        availableHeight: widget.height,
                        visible: (widget.musicViewMode == MusicViewMode.part &&
                            isConfiguringPart)))),
            AnimatedOpacity(
                duration: animationDuration,
                opacity:
                    (widget.musicViewMode == MusicViewMode.section) ? 1 : 0,
                child: AnimatedContainer(
                    color: widget.sectionColor,
                    duration: animationDuration,
                    height: (widget.musicViewMode == MusicViewMode.section &&
                            isEditingSection)
                        ? toolbarHeight(context)
                        : 0,
                    child: SectionEditingToolbar(
                      sectionColor: widget.sectionColor,
                      score: widget.score,
                      currentSection: widget.currentSection,
                    ))),
          ]),
          Expanded(child: _mainMelody(context))
        ],
      ),
      if (MyPlatform.isDebug && true)
        IgnorePointer(
            child: Container(
          width: 2 * targetedScale * beatWidth,
          height: widget.height,
          decoration: BoxDecoration(
              color: Colors.black12,
              border: Border.all(
                color: Colors.red[500],
              ),
              borderRadius: BorderRadius.all(Radius.circular(5))),
        )),
      if (MyPlatform.isDebug && true)
        IgnorePointer(
            child: Container(
          width: widget.width,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.black12,
              border: Border.all(
                color: Colors.blue[500],
              ),
              borderRadius: BorderRadius.all(Radius.circular(5))),
        ))
    ]);
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

  double get scaledSystemHeight => MusicSystemPainter.calculateSystemHeight(
      scale, widget.score.parts.length);

  int systemNumber(transformedPosition) =>
      (transformedPosition.dy / scaledSystemHeight).floor();

  getBeat(Offset position, {bool targeted = true}) {
    position = transformationController.toScene(position);
    int systemNumber = this.systemNumber(position);
    final scaledWidth = widget.width / scale;
    final scaledAvailableWidth = scaledWidth - clefWidth;
    double systemXOffset = systemNumber * scaledAvailableWidth;
    double dx = position.dx + systemXOffset - clefWidth;

    int beat = (dx / beatWidth).floor();
    // print("beat=$beat");
    beat = max(0, min(beat, widget.score.maxBeat));
    // print(
    //     "getBeat: $position, width=$scaledWidth, systemNumber=$systemNumber, systemXOffset=$systemXOffset ==> $beat");
    return beat;
  }

  Part getPart(Offset position, {bool targeted = true}) {
    position = transformationController.toScene(position);
    int systemNumber = this.systemNumber(position);
    double dy = position.dy;
    dy -= systemNumber * scaledSystemHeight;
    dy -= MusicSystemPainter.calculateHarmonyHeight(scale);
    if (widget.musicViewMode == MusicViewMode.score ||
        scale < 2 * MusicScrollContainer.minScale ||
        !widget.showingSectionList) {
      dy -= MusicSystemPainter.calculateSectionHeight(scale);
    }
    int partIndex = (dy / staffHeight).floor();
    List<Part> parts;
    if (!autoSort || widget.musicViewMode == MusicViewMode.section) {
      parts = widget.score.parts;
    } else {
      final mainPart = this.mainPart();
      parts = [mainPart] +
          widget.score.parts
              .where((p) => p.id != mainPart?.id)
              .toList(growable: false);
    }
    final part = parts[max(0, min(parts.length - 1, partIndex))];
    // print("getPart: $position, partIndex=$partIndex ==> $part");
    return part;
  }

  /// In View Mode this is the Keyboard Part. In Edit Mode it's the Part that's focused, or the Part of the Melody
  /// that's focused, or the Keyboard Part if only a Section is focused.
  Part mainPart() {
    Part mainPart;
    switch (widget.musicViewMode) {
      case MusicViewMode.score:
      case MusicViewMode.section:
      case MusicViewMode.none:
        mainPart = widget.keyboardPart;
        break;
      case MusicViewMode.part:
        mainPart = widget.part;
        break;
      case MusicViewMode.melody:
        mainPart = widget.keyboardPart;
        // mainPart = widget.score.parts.firstWhere(
        //     (part) =>
        //         part.melodies.any((melody) => melody.id == widget.melody.id),
        //     orElse: () => null);
        break;
    }
    return mainPart;
  }

  selectBeat(int value) {
    print("selectBeat");
    widget.selectBeat(value);
    if (autoScroll) {
      // widget.scrollToCurrentBeat();
    }
    _updateFocusedBeatValue(value: value, force: true);
  }

  Widget _mainMelody(BuildContext context) {
    List<MusicStaff> staves;
    Part mainPart = this.mainPart();
    bool focusPartsAndMelodies = autoSort &&
        (widget.musicViewMode == MusicViewMode.score ||
            widget.musicViewMode == MusicViewMode.part ||
            widget.musicViewMode == MusicViewMode.melody);
    if (focusPartsAndMelodies) {
      staves = [];

      // print("mainPart=$mainPart");
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
      staves = widget.score.parts
          .map((part) => (part.isDrum) ? DrumStaff() : PartStaff(part))
          .toList(growable: false);
    }

    bool focusedPartIsNotFirst = mainPart != null &&
        widget.score.parts.indexWhere((it) => it.id == mainPart.id) != 0;
    bool focusedMelodyIsNotFirst = widget.melody != null &&
        widget.score.parts.indexWhere(
                (p) => p.melodies.any((m) => m.id == widget.melody.id)) !=
            0;
    bool showAutoFocusButton = (widget.musicViewMode == MusicViewMode.part ||
            widget.musicViewMode == MusicViewMode.melody ||
            widget.musicViewMode == MusicViewMode.score) &&
        (focusedPartIsNotFirst || focusedMelodyIsNotFirst) &&
        showViewOptions;
    bool showMinimizeButton = targetedScale != minScale;
    bool showExpandButton = targetedScale != alignedScale;
    bool showExpandPartButton = (!showExpandButton || !showMinimizeButton) &&
        targetedScale != partAlignedScale &&
        (widget.musicViewMode == MusicViewMode.part ||
            widget.musicViewMode == MusicViewMode.score ||
            widget.musicViewMode == MusicViewMode.melody);
    bool isPartOrMelodyView = widget.musicViewMode == MusicViewMode.part ||
        widget.musicViewMode == MusicViewMode.melody;
    onLongPress() {
      if (widget.score.parts.isEmpty ||
          tappedPart.value == null ||
          tappedBeat.value == null) return;
      final part = tappedPart.value;
      if (part == null) return;
      HapticFeedback.lightImpact();
      if (widget.musicViewMode == MusicViewMode.score) {
        widget.setKeyboardPart(part);
      } else {
        if (isPartOrMelodyView) {
          widget.selectOrDeselectPart(part);
        } else if (widget.musicViewMode == MusicViewMode.section) {
          widget.selectOrDeselectPart(part);
        }
      }
      if (autoSort) {
        scrollToPart();
      }
      final beat = tappedBeat.value;
      // if (!BeatScratchPlugin.playing && beat != null) {
      //   selectBeat(beat);
      // }
    }

    pointerDown(Offset localPosition) {
      double systemHeight = MusicSystemPainter.calculateSystemHeight(
          scale, widget.score.parts.length);
      if (systemHeight < localPosition.dy) {
        if (autoScroll) {
          setState(() {
            // forceShowViewOptions = true;
            // autoScroll = false;
          });
        }
      }

      if (showViewOptions) {
        if (localPosition.dx > widget.width - 104 &&
            localPosition.dy > widget.height - 156) {
          tappedBeat.value = null;
          return;
        }
        if (showAutoFocusButton) {
          if (localPosition.dx > widget.width - 156 &&
              localPosition.dy > widget.height - 52) {
            tappedBeat.value = null;
            return;
          }
        }
      } else {
        if (localPosition.dx > widget.width - 104 &&
            localPosition.dy > widget.height - 104) {
          tappedBeat.value = null;
          return;
        }
      }

      int beat = getBeat(localPosition);
      print(
          "pointerDown: ${localPosition} -> beat: $beat; x/t: $scale/$targetedScale");

      tappedBeat.value = beat;
      final part = getPart(localPosition);
      tappedPart.value = part;
    }

    return AnimatedContainer(
        duration: animationDuration,
        color: musicBackgroundColor,
        child: GestureDetector(
            onTapDown: (details) {
              pointerDown(details.localPosition);
            },
            onTapUp: (details) {
              if (ignoreNextTap || tappedBeat.value == null) {
                return;
              }
              int beat = tappedBeat.value;
              print(
                  "onTapUp: ${details.localPosition} -> beat: $beat; x/t: $scale/$targetedScale");
              if (BeatScratchPlugin.playing &&
                  recordingMelody &&
                  highlightedBeat.value != beat) {
                setState(() {
                  highlightedBeat.value = beat;
                });
              } else if (BeatScratchPlugin.playing &&
                  recordingMelody &&
                  highlightedBeat.value == beat) {
                setState(() {
                  highlightedBeat.value = null;
                });
              } else {
                selectBeat(beat);
              }
            },
            onLongPress: onLongPress,
            onForcePressStart: (details) {
              pointerDown(details.localPosition);
              onLongPress();
            },
            child: Stack(children: [
              MusicScrollContainer(
                  musicViewMode: widget.musicViewMode,
                  score: widget.score,
                  currentSection: widget.currentSection,
                  sectionColor: widget.sectionColor,
                  colorboardNotesNotifier: widget.colorboardNotesNotifier,
                  keyboardNotesNotifier: widget.keyboardNotesNotifier,
                  bluetoothControllerPressedNotes:
                      widget.bluetoothControllerPressedNotes,
                  focusedMelody: widget.melody,
                  renderingMode: widget.renderingMode,
                  staves: staves,
                  focusedPart: mainPart,
                  keyboardPart: widget.keyboardPart,
                  colorboardPart: widget.colorboardPart,
                  height: widget.height - removedHeight,
                  width: widget.width,
                  isCurrentScore: widget.isCurrentScore,
                  highlightedBeat: highlightedBeat,
                  focusedBeat: focusedBeat,
                  tappedBeat: tappedBeat,
                  tappedPart: tappedPart,
                  requestedScrollOffsetForScale: requestedScrollOffsetForScale,
                  targetScaleNotifier: _targetedScale,
                  scrollToCurrentBeat: widget.scrollToCurrentBeat,
                  scrollToPart: scrollToPart,
                  centerCurrentSection: centerCurrentSection,
                  appSettings: widget.appSettings,
                  transformationController: transformationController,
                  scaleUpdateNotifier: scaleUpdateNotifier,
                  showingSectionList: widget.showingSectionList),
              Row(children: [
                Expanded(child: SizedBox()),
                Row(children: [
                  AnimatedContainer(
                      duration: animationDuration,
                      width: showViewOptions ? 99 : 0,
                      child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: showViewOptions ? 1 : 0,
                          child: Row(children: [
                            Expanded(child: SizedBox()),
                            Column(children: [
                              Expanded(child: SizedBox()),
                              autoFocusButton(visible: showAutoFocusButton),
                              SizedBox(height: 2),
                            ]),
                            if (showAutoFocusButton) SizedBox(width: 2),
                            Column(children: [
                              Expanded(child: SizedBox()),
                              autoZoomAlignButton(
                                  visible:
                                      showViewOptions && MyPlatform.isDebug),
                              SizedBox(height: 2),
                              nightModeButton(visible: true),
                              SizedBox(height: 2),
                              colorblockButton(visible: true),
                              SizedBox(height: 2),
                            ]),
                          ]))),
                  if (showViewOptions) SizedBox(width: 2),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    autoScrollButton(visible: showViewOptions),
                    SizedBox(height: 2),
                    scrollToCurrentBeatButton(),
                    SizedBox(height: 2),
                    zoomButton(),
                    SizedBox(height: 2),
                  ]),
                  SizedBox(width: 2),
                ])
              ]),
            ])));
  }

  handleZoomAlign() {
    return;
    if (autoZoomAlign) {
      final double x = targetedScale,
          // y = targetedScale,
          w = widget.width,
          numberOfBeatsOnScreen = w / (x * beatWidth),
          targetNumberOfBeatsOnScreen = numberOfBeatsOnScreen.roundToDouble(),
          newXScale = w / (targetNumberOfBeatsOnScreen * beatWidth);
      targetedScale = newXScale;
      // scale = newXScale;
    }
  }

  Widget autoFocusButton({bool visible}) {
    return MusicActionButton(
        child: Stack(children: [
          Transform.translate(
              offset: Offset(0, -8),
              child: Text("Auto",
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: autoSort ? Colors.white : Colors.grey))),
          Transform.translate(
            offset: Offset(-6, 3),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: !autoSort ? 1 : 0,
              child: Icon(Icons.arrow_upward_sharp, color: Colors.grey),
            ),
          ),
          Transform.translate(
            offset: Offset(6, 9),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: !autoSort ? 1 : 0,
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
              opacity: autoSort ? 1 : 0,
              child: Icon(Icons.arrow_upward_sharp, color: widget.sectionColor),
            ),
          ),
          Transform.translate(
            offset: Offset(6, 9),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: autoSort ? 1 : 0,
              child: Icon(
                Icons.arrow_downward_sharp,
                color: Colors.white,
              ),
            ),
          ),
        ]),
        visible: visible,
        width: visible ? 48 : 0,
        onPressed: () {
          setState(() {
            autoSort = !autoSort;
          });
        });
  }

  Widget autoZoomAlignButton({bool visible}) {
    return MusicActionButton(
        child: Stack(children: [
          Transform.translate(
              offset: Offset(0, -8),
              child: Text("Auto",
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: autoZoomAlign ? Colors.white : Colors.grey))),
          Transform.translate(
            offset: Offset(6, 9),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: !autoZoomAlign ? 1 : 0,
              child: Icon(
                Feather.move,
                color: Colors.grey,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-6, 3),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: !autoZoomAlign ? 1 : 0,
              child: Icon(Icons.center_focus_strong, color: Colors.grey),
            ),
          ),
          Transform.translate(
            offset: Offset(6, 9),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: autoZoomAlign ? 1 : 0,
              child: Icon(
                Feather.move,
                color: Colors.white,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-6, 3),
            child: AnimatedOpacity(
              duration: animationDuration,
              opacity: autoZoomAlign ? 1 : 0,
              child:
                  Icon(Icons.center_focus_strong, color: widget.sectionColor),
            ),
          ),
        ]),
        visible: visible,
        width: visible ? 48 : 0,
        height: visible ? 48 : 0,
        onPressed: () {
          setState(() {
            autoZoomAlign = !autoZoomAlign;
          });
        });
  }

  Widget zoomButton() {
    final zoomIncrement = .01;
    final bigDecrementIcon =
        (targetedScale > alignedScale || scale > alignedScale)
            ? Icons.expand
            : FontAwesomeIcons.compressArrowsAlt;
    final bigDecrementAction =
        (targetedScale > alignedScale || scale > alignedScale)
            ? () {
                setState(() {
                  _aligned = true;
                  _partAligned = false;
                  _preButtonScale();
                  alignVertically();
                  Future.delayed(animationDuration, () {
                    widget.scrollToCurrentBeat();
                  });
                });
              }
            : (targetedScale > minScale || scale > minScale)
                ? () {
                    setState(() {
                      minimize();
                    });
                  }
                : null;
    final bigIncrementIcon =
        (targetedScale >= alignedScale || scale >= alignedScale)
            ? FontAwesomeIcons.expandArrowsAlt
            : Icons.expand;
    final bigIncrementAction =
        (targetedScale < alignedScale || scale < alignedScale)
            ? () {
                setState(() {
                  _aligned = true;
                  _partAligned = false;
                  _preButtonScale();
                  alignVertically();
                  _lineUpAfterSizeChange();
                  Future.delayed(animationDuration, () {
                    widget.scrollToCurrentBeat();
                  });
                });
              }
            : (targetedScale < partAlignedScale || scale < partAlignedScale) &&
                    !targetedScale.roughlyEquals(partAlignedScale) &&
                    widget.musicViewMode != MusicViewMode.section
                ? () {
                    setState(() {
                      _aligned = true;
                      _partAligned = true;
                      _preButtonScale();
                      partAlignVertically();
                      _lineUpAfterSizeChange();
                    });
                  }
                : null;
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
              child: Transform.translate(
                  offset: Offset(0, -3),
                  child: Stack(children: [
                    Transform.translate(
                        offset: Offset(-5, 5),
                        child: Transform.scale(
                            scale: 1,
                            child: Icon(Icons.zoom_out,
                                color:
                                    musicForegroundColor.withOpacity(0.54)))),
                    Transform.translate(
                        offset: Offset(5, -5),
                        child: Transform.scale(
                            scale: 1,
                            child: Icon(Icons.zoom_in,
                                color:
                                    musicForegroundColor.withOpacity(0.54)))),
                    Transform.translate(
                      offset: Offset(2, 20),
                      child: Text(scaleText(targetedScale),
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: musicForegroundColor.withOpacity(0.87))),
                    ),
                  ])),
            ),
          ),
          musicActionButtonStyle: true,
          musicActionButtonColor: zoomButtonColor,
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
          incrementDistance: 1,
          onIncrement: (targetedScale < maxScale || scale < maxScale)
              ? () {
                  _ignoreNextScale = true;
                  _aligned = false;
                  _partAligned = false;
                  setState(() {
                    print("zoomIn: scale=$scale, targetedScale=$targetedScale");
                    targetedScale =
                        min(maxScale, targetedScale + zoomIncrement);
                    // print("zoomIn done; targetedScale=$targetXScale, scale=$targetYScale");
                  });
                }
              : null,
          onDecrement: (targetedScale > minScale || scale > minScale)
              ? () {
                  _ignoreNextScale = true;
                  _aligned = false;
                  _partAligned = false;
                  setState(() {
                    print(
                        "zoomOut: scale=$scale, targetedScale=$targetedScale");
                    targetedScale =
                        max(minScale, targetedScale - zoomIncrement);
                    // print("zoomOut done; targetedScale=$targetedScale, scale=$scale");
                  });
                }
              : null,
          onBigDecrement: bigDecrementAction,
          bigDecrementIcon: bigDecrementIcon,
          onBigIncrement: bigIncrementAction,
          bigIncrementIcon: bigIncrementIcon,
        ));
  }

  Widget scrollToCurrentBeatButton() {
    return MusicActionButton(
        child: Stack(children: [
          Icon(Icons.my_location, color: widget.sectionColor),
        ]),
        onPressed: () {
          widget.scrollToCurrentBeat();
        });
  }

  Color get zoomButtonColor =>
      (widget.keyboardPart.isDrum ? Colors.brown : Colors.grey)
          .withOpacity(0.26);

  minimize() {
    _aligned = false;
    _partAligned = false;
    _preButtonScale();
    targetedScale = minScale;
    // scale = minScale;
    _lineUpAfterSizeChange();
  }

  _preButtonScale() {
    if (widget.musicViewMode != MusicViewMode.score) {
      _updateFocusedBeatValue(
          value: widget.score.firstBeatOfSection(widget.currentSection) +
              BeatScratchPlugin.currentBeat.value);
    }
  }

  _lineUpAfterSizeChange() {
    scrollToPart();
    if (widget.musicViewMode != MusicViewMode.score) {
      Future.delayed(
          Duration(milliseconds: animationDuration.inMilliseconds + 100), () {
        setState(() {
          widget.scrollToCurrentBeat();
        });
      });
    }
  }

  Widget autoScrollButton({@required bool visible}) {
    return MusicActionButton(
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
      ]),
      visible: visible,
      height: visible ? 48 : 0,
      onPressed: () {
        setState(() {
          autoScroll = !autoScroll;
        });
      },
    );
  }

  Widget nightModeButton({@required bool visible}) {
    return MusicActionButton(
      child: Icon(FontAwesomeIcons.solidMoon, color: musicForegroundColor),
      color: musicBackgroundColor.withOpacity(0.12),
      visible: visible,
      width: visible ? 48 : 0,
      onPressed: () {
        widget.appSettings.darkMode = !widget.appSettings.darkMode;
      },
    );
  }

  Widget colorblockButton({@required bool visible}) {
    return MusicActionButton(
      child: Stack(children: [
        AnimatedOpacity(
            duration: animationDuration,
            opacity: widget.renderingMode == RenderingMode.notation ? 1 : 0,
            child: ColorFiltered(
              key: ValueKey("music-view-music-note"),
              child: Image.asset(
                "assets/notehead_filled.png",
                width: 20,
                height: 20,
              ),
              colorFilter:
                  ColorFilter.mode(musicForegroundColor, BlendMode.srcIn),
            )
            // child: Image.asset(
            //   'assets/notehead_filled.png',
            //   width: 20,
            //   height: 20,
            // ),
            ),
        AnimatedOpacity(
            duration: animationDuration,
            opacity: widget.renderingMode == RenderingMode.colorblock ? 1 : 0,
            child: Image.asset(
              'assets/colorboard_vertical.png',
              width: 20,
              height: 20,
            ))
      ]),
      visible: visible,
      width: visible ? 48 : 0,
      onPressed: () {
        widget.requestRenderingMode(
            widget.renderingMode == RenderingMode.colorblock
                ? RenderingMode.notation
                : RenderingMode.colorblock);
      },
    );
  }

  alignVertically() {
    final newScale = alignedScale;
    targetedScale = newScale;
    // scale = scale;
  }

  partAlignVertically() {
    final newScale = partAlignedScale;
    targetedScale = newScale;
    // scale = scale;
  }

  double get sectionsHeight => widget.musicViewMode == MusicViewMode.score ||
          targetedScale < 2 * MusicScrollContainer.minScale
      ? 30
      : 0;

  double get alignedScale {
    double result = alignedStaffHeight / staffHeight;
    if (sectionsHeight != 0) {
      result *= (widget.height - 0) / (widget.height + sectionsHeight);
    }
    return min(maxScale, max(minScale, result));
  }

  double get partAlignedScale {
    double result = partAlignedStaffHeight / staffHeight;
    if (sectionsHeight != 0) {
      result *= (widget.height - 0) / (widget.height + sectionsHeight);
    }
    return min(maxScale, max(minScale, result));
  }

  // double get toolbarHeight => widget.musicViewMode == MusicViewMode.score ||widget.musicViewMode == MusicViewMode.none
  double get removedHeight => (widget.musicViewMode == MusicViewMode.score ||
          widget.musicViewMode == MusicViewMode.none)
      ? 0
      : widget.musicViewMode == MusicViewMode.part && isConfiguringPart
          ? 2 * toolbarHeight(context) + partConfigHeight
          : 2 * toolbarHeight(context);

  double get alignedStaffHeight =>
      (widget.height - removedHeight) / widget.score.parts.length;

  double get partAlignedStaffHeight =>
      (widget.height - removedHeight); // / 1.38;
}

enum SwipeTutorial { collapse, closeExpand }

extension TutorialText on SwipeTutorial {
  String tutorialText(
      SplitMode splitMode, MusicViewMode musicViewMode, BuildContext context) {
    return splitMode == SplitMode.full
        ? "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to view Layers/close ${musicViewMode.toString().substring(14).capitalize()}"
        : "Swipe ${context.isPortrait ? "⬇️" : "➡️"}️ to close,\n" +
            "${context.isPortrait ? "⬆️️" : "⬅️"}️ to expand " +
            "${musicViewMode.toString().substring(14).capitalize()}";
  }
}
