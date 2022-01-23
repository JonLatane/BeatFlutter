import 'dart:math';

import 'package:beatscratch_flutter_redux/settings/settings.dart';
import 'package:beatscratch_flutter_redux/widget/my_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:matrix4_transform/matrix4_transform.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/bs_methods.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import 'music_system_painter.dart';

class MusicScrollContainer extends StatefulWidget {
  static const double minScale = 0.04;
  static const double maxScale = 1;

  final MusicViewMode musicViewMode;
  final Score score;
  final Section currentSection;
  final Color sectionColor;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final List<MusicStaff> staves;
  final Part focusedPart, keyboardPart, colorboardPart;
  final double height, width;
  final bool isCurrentScore;
  final bool isTwoFingerScaling;
  final BSMethod scrollToCurrentBeat, centerCurrentSection, scrollToPart;
  final AppSettings appSettings;
  final ValueNotifier<Iterable<int>> keyboardNotesNotifier,
      colorboardNotesNotifier;
  final ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;
  final ValueNotifier<int> highlightedBeat, focusedBeat, tappedBeat;
  final ValueNotifier<Part> tappedPart;
  final ValueNotifier<Offset> requestedScrollOffsetForScale;
  final TransformationController transformationController;
  final ValueNotifier<ScaleUpdateDetails> scaleUpdateNotifier;
  final ValueNotifier<double> targetScaleNotifier;
  final BSMethod scrollToFocusedBeat;
  final bool showingSectionList;

  const MusicScrollContainer(
      {Key key,
      this.score,
      this.scrollToFocusedBeat,
      this.currentSection,
      this.sectionColor,
      this.focusedMelody,
      this.renderingMode,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.bluetoothControllerPressedNotes,
      this.musicViewMode,
      this.staves,
      this.keyboardPart,
      this.colorboardPart,
      this.focusedPart,
      this.width,
      this.height,
      this.isCurrentScore,
      this.highlightedBeat,
      this.focusedBeat,
      this.tappedBeat,
      this.tappedPart,
      this.requestedScrollOffsetForScale,
      this.targetScaleNotifier,
      this.isTwoFingerScaling,
      this.scrollToCurrentBeat,
      this.centerCurrentSection,
      this.appSettings,
      this.transformationController,
      this.scaleUpdateNotifier,
      this.scrollToPart,
      this.showingSectionList})
      : super(key: key);

  @override
  _MusicScrollContainerState createState() => _MusicScrollContainerState();
}

// Rect horizontallyVisibleRect = Rect.zero;
// Rect verticallyVisibleRect = Rect.zero;

class _MusicScrollContainerState extends State<MusicScrollContainer>
    with TickerProviderStateMixin {
  AnimationController animationController;
  ValueNotifier<double> colorGuideOpacityNotifier,
      colorblockOpacityNotifier,
      notationOpacityNotifier,
      sectionScaleNotifier;

  // partTopOffsets are animated based off the Renderer's StaffConfigurations
  ValueNotifier<List<MusicStaff>> stavesNotifier;
  ValueNotifier<Map<String, double>> partTopOffsets;
  ValueNotifier<Map<String, double>> staffOffsets;

  ValueNotifier<Part> keyboardPart;
  ValueNotifier<Part> colorboardPart;
  ValueNotifier<Part> focusedPart;
  ValueNotifier<Color> sectionColor;

  double _prevBeat;
  String _prevSectionOrder;
  String _prevSectionId;
  Score _prevScore;
  // ignore: unused_field
  String _prevPartId;
  Rect visibleRect = Rect.zero;

  bool get isViewingSection => widget.musicViewMode != MusicViewMode.score;

  int get numberOfBeats => /*isViewingSection ? widget.currentSection.harmony.beatCount :*/
      widget.score.beatCount;

  TransformationController get transformationController =>
      widget.transformationController;
  ValueNotifier<ScaleUpdateDetails> get scaleUpdateNotifier =>
      widget.scaleUpdateNotifier;
  double get dx =>
      MatrixUtils.getAsTranslation(transformationController.value).dx;
  double get dy =>
      MatrixUtils.getAsTranslation(transformationController.value).dy;
  double get scale => transformationController.value.getMaxScaleOnAxis();

  double get scaledStandardBeatWidth => beatWidth * scale;

  double get targetScale => widget.targetScaleNotifier.value;

  double get targetBeatWidth => beatWidth;

  double get canvasHeightMagic => 1.3 - 0.3 * (widget.staves.length) / 5;

  bool get showSectionNames =>
      widget.musicViewMode == MusicViewMode.score ||
      scale < 2 * MusicScrollContainer.minScale ||
      !widget.showingSectionList;
  double get sectionsHeight => showSectionNames ? 30 : 0;

  double get systemHeight =>
      (((widget.staves.length + 0.5) * (staffHeight)) + sectionsHeight * 2);

  double get systemRenderAreaWidth => max(0, widget.width - clefWidth);
  double get beatsOnScreenPerSystem => systemRenderAreaWidth / beatWidth;
  int get maxSystemsNeeded =>
      (widget.score.beatCount / max(0.1, beatsOnScreenPerSystem)).ceil();

  int get maxSupportedSystems => widget.appSettings.systemsToRender < 1
      ? 9999999
      : widget.appSettings.systemsToRender;
  int get systemsToRender => min(maxSystemsNeeded, maxSupportedSystems);

  double get calculatedSystemThingy => ((systemsToRender) *
      ((currentBeat - 2) / (beatsOnScreenPerSystem * systemsToRender)));
  // In multi-system mode, we select a "target system" for the
  // currentBeat based on how far into the score currentBeat is.
  int get currentBeatTargetSystemIndex => max(
      0,
      min(systemsToRender - 1,
          systemsToRender == 1 ? 0 : calculatedSystemThingy.floor()));

  double get currentBeatTargetSystemXOffset =>
      currentBeatTargetSystemIndex * (systemRenderAreaWidth);
  double get _systemHeightForScrolling =>
      MusicSystemPainter.calculateSystemHeight(
          scale, widget.score.parts.length) +
      systemPadding;
  double get _extraHeightForScrolling =>
      _systemHeightForScrolling < widget.height
          ? max(0, (widget.height - _systemHeightForScrolling) / 3)
          : 0;
  double get currentBeatTargetSystemYOffset => min(
      max(0, overallCanvasHeight - widget.height),
      max(
          0,
          currentBeatTargetSystemIndex * _systemHeightForScrolling -
              _extraHeightForScrolling));

  double get overallCanvasWidth =>
      (numberOfBeats + extraBeatsSpaceForClefs) * targetBeatWidth;
  double get overallCanvasHeight => systemsToRender * systemHeight;
  double get targetClefWidth => extraBeatsSpaceForClefs * targetBeatWidth;

  double get sectionWidth => widget.currentSection.beatCount * targetBeatWidth;

  double get visibleWidth => widget.width;

  double get visibleAreaForSection => visibleWidth - targetClefWidth;

  double get marginBeatsForBeat =>
      max(0, visibleWidth - 2 * targetClefWidth - targetBeatWidth) /
      targetBeatWidth;

  double get marginBeatsForSection =>
      max(0, visibleWidth - targetClefWidth - sectionWidth) / targetBeatWidth;

  // Rect get horizontallyVisibleRect => horizontallyVisibleRect;
  // set horizontallyVisibleRect(value) {
  //   horizontallyVisibleRect = value;
  // }

  // Rect get verticallyVisibleRect => verticallyVisibleRect;
  // set verticallyVisibleRect(value) {
  //   verticallyVisibleRect = value;
  // }

  bool get autoScroll => widget.appSettings.autoScrollMusic;
  bool get autoSort => widget.appSettings.autoSortMusic;
  bool get autoZoomAlign => widget.appSettings.autoZoomAlignMusic;

  Animation<Matrix4> interactiveAnimation;
  AnimationController interactiveController;
  void _interactiveAnimationStop() {
    interactiveController.stop();
    interactiveAnimation?.removeListener(_onInteractiveAnimation);
    interactiveAnimation = null;
    interactiveController.reset();
  }

  void _onInteractiveAnimation() {
    transformationController.value = interactiveAnimation.value;
    if (!interactiveController.isAnimating) {
      interactiveAnimation.removeListener(_onInteractiveAnimation);
      interactiveAnimation = null;
      interactiveController.reset();
    }
  }

  bool _animateToTargetedScale = true;
  void animateToTargetScaleAndPosition() {
    if (!_animateToTargetedScale) return;
    _interactiveAnimationStop();
    // interactiveController.reset();
    final targetedScale = widget.targetScaleNotifier.value;
    final targetedMatrix = transformationController.value.clone()
      ..scale(
          targetedScale / scale, targetedScale / scale, targetedScale / scale);
    interactiveAnimation = Matrix4Tween(
      begin: transformationController.value,
      end: targetedMatrix,
    ).animate(interactiveController);
    interactiveAnimation.addListener(_onInteractiveAnimation);
    interactiveController.forward();
  }

  void animateToWithinBounds() {
    _interactiveAnimationStop();
    final targetedMatrix = transformationController.value.clone();
    // Animate to within vertical bounds
    final scaledWidth = widget.width / (scale);
    final scaledAvailableWidth = scaledWidth - clefWidth;
    final endOfLastSystem =
        overallCanvasWidth - systemsToRender * scaledAvailableWidth;
    final systemsAwayFromBottom = max(
        0,
        ((transformedRect.left - endOfLastSystem) / scaledAvailableWidth)
            .floor());
    final systemsRendered = max(0, systemsToRender - systemsAwayFromBottom);
    final transformedRectMaxTop = max(
        0,
        systemsRendered * systemHeight -
            (widget.height / scale) +
            staffHeight / 2);
    if (transformedRect.top >= transformedRectMaxTop) {
      final untranslate = transformedRect.top - transformedRectMaxTop;
      print(
          "animateToWithinBounds: systemsAwayFromBottom=$systemsAwayFromBottom, systemsRendered=$systemsRendered, transformedRectMaxTop=$transformedRectMaxTop");
      targetedMatrix.translate(0.0, untranslate, 0.0);
    }
    // TODO: Animate to within horizontal bounds
    interactiveAnimation = Matrix4Tween(
      begin: transformationController.value,
      end: targetedMatrix,
    ).animate(interactiveController);
    interactiveAnimation.addListener(_onInteractiveAnimation);
    interactiveController.forward();
  }

  @override
  void initState() {
    super.initState();
    interactiveController =
        AnimationController(vsync: this, duration: animationDuration);
    widget.scrollToFocusedBeat.addListener(() {
      scrollToFocusedBeat();
    });
    widget.targetScaleNotifier.addListener(animateToTargetScaleAndPosition);
    animationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: kIsWeb ? 1000 : 500));
    colorblockOpacityNotifier = ValueNotifier(0);
    colorGuideOpacityNotifier = ValueNotifier(0);
    notationOpacityNotifier = ValueNotifier(0);
    sectionScaleNotifier = ValueNotifier(0);
    partTopOffsets = ValueNotifier(Map());
    staffOffsets = ValueNotifier(Map());
    stavesNotifier = ValueNotifier(widget.staves);
    keyboardPart = ValueNotifier(widget.keyboardPart);
    colorboardPart = ValueNotifier(widget.colorboardPart);
    focusedPart = ValueNotifier(widget.focusedPart);
    sectionColor = ValueNotifier(widget.sectionColor);
    widget.scrollToCurrentBeat.addListener(scrollToCurrentBeat);
    widget.centerCurrentSection.addListener(_constrainToSectionBounds);

    widget.scrollToPart.addListener(scrollToPart);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentBeat();
    });
    interactionStartFocal.addListener(_deriveStartSystemFromFocal);
  }

  DateTime _lastScrollEventSeen = DateTime(0);
  DateTime _lastScrollStopEventTime = DateTime(0);
  double _lastTimeScrollValue = 0;
  VoidCallback xScaleUpdateListener, yScaleUpdateListener;

  static const int _autoScrollDelayDuration = 2500;

  _transformationListener() {}

  _timeScrollListener() {
    // _lastScrollEventSeen = DateTime.now();
    // if ((_lastTimeScrollValue - timeScrollController.offset).abs() > 25) {
    //   print(
    //       "non-continuous scroll change: $_lastTimeScrollValue to ${timeScrollController.offset}");
    //   // timeScrollController.jumpTo(_lastTimeScrollValue);
    // }
    // _lastTimeScrollValue = timeScrollController.offset;
    // double maxScrollExtent = widget.focusedBeat.value != null
    //     ? maxCanvasWidth
    //     : max(10, overallCanvasWidth - widget.width + 150);
    // if (timeScrollController.offset > maxScrollExtent) {
    //   if (timeScrollController.offset > maxScrollExtent + 10) {
    //     timeScrollController.animateTo(maxScrollExtent,
    //         duration: animationDuration, curve: Curves.ease);
    //   } else {
    //     timeScrollController.jumpTo(maxScrollExtent);
    //   }
    // }
    Future.delayed(Duration(milliseconds: _autoScrollDelayDuration + 50), () {
      if (_autoScrollDelayDuration <
              DateTime.now().millisecondsSinceEpoch -
                  _lastScrollEventSeen.millisecondsSinceEpoch &&
          _autoScrollDelayDuration <
              DateTime.now().millisecondsSinceEpoch -
                  _lastScrollStopEventTime.millisecondsSinceEpoch) {
        print('scroll is stopped');
        _lastScrollStopEventTime = DateTime.now();
        _onScrollStopped();
      }
    });
  }

  _verticalScrollListener() {
    // widget.verticalScrollNotifier.value = verticalController.offset;
    // double maxScrollExtent = widget.focusedBeat.value != null
    //     ? maxCanvasHeight
    //     : max(10, overallCanvasHeight - widget.height);
    // if (verticalController.offset > maxScrollExtent) {
    //   if (timeScrollController.offset > maxScrollExtent + 50) {
    //     verticalController.animateTo(maxScrollExtent,
    //         duration: animationDuration, curve: Curves.ease);
    //   } else {
    //     verticalController.jumpTo(maxScrollExtent);
    //   }
    // }
  }

  _onScrollStopped() {
    if (autoScroll &&
        !widget.isTwoFingerScaling &&
        (widget.musicViewMode != MusicViewMode.score ||
            !BeatScratchPlugin.playing)) {
      _constrainToSectionBounds();
    }
  }

  @override
  void dispose() {
    widget.targetScaleNotifier.removeListener(animateToTargetScaleAndPosition);
    animationController.dispose();
    colorblockOpacityNotifier.dispose();
    notationOpacityNotifier.dispose();
    sectionScaleNotifier.dispose();
    partTopOffsets.dispose();
    staffOffsets.dispose();
    stavesNotifier.dispose();
    keyboardPart.dispose();
    colorboardPart.dispose();
    focusedPart.dispose();
    sectionColor.dispose();
    interactionStartSystem.dispose();
    interactionStartFocal
      ..removeListener(_deriveStartSystemFromFocal)
      ..dispose();
    transformationController.removeListener(_transformationListener);
    widget.scrollToCurrentBeat.removeListener(scrollToCurrentBeat);
    widget.scrollToPart.removeListener(scrollToPart);
    widget.centerCurrentSection.removeListener(_constrainToSectionBounds);
    super.dispose();
  }

  MusicViewMode _prevViewMode;
  bool _hasBuilt = false;
  DateTime _lastAutoScrollTime = DateTime(0);
  double prevWidth;

  get minScale => MusicScrollContainer.minScale;
  get maxScale => MusicScrollContainer.maxScale;
  double get scaledSystemHeight => MusicSystemPainter.calculateSystemHeight(
      scale, widget.score.parts.length);

  ValueNotifier<Offset> interactionStartFocal = ValueNotifier(null);
  ValueNotifier<int> interactionStartSystem = ValueNotifier(null);
  _deriveStartSystemFromFocal() {
    if (interactionStartFocal.value == null) {
      interactionStartSystem.value = null;
    } else {
      interactionStartSystem.value =
          max(0, (interactingFocal.dy / scaledSystemHeight).floor());
    }
  }

  Offset get interactingFocal => interactionStartFocal.value;
  int get interactingSystem =>
      max(0, min(systemsToRender - 1, interactionStartSystem.value));

  @override
  Widget build(BuildContext context) {
    _animateOpacitiesAndScale();
    _animateStaffAndPartPositions();
    focusedPart.value = widget.focusedPart;
    sectionColor.value = widget.sectionColor;
    animationController.forward(from: 0);

    double currentBeat = this.currentBeat;
    String sectionOrder = widget.score.sections.map((e) => e.id).join();
    if (widget.isTwoFingerScaling) {
      scrollToFocusedBeat(instant: true);
    } else if (autoScroll) {
      // if (DateTime.now().difference(_lastAutoScrollTime).inMilliseconds >
      //     500) {
      if (_prevViewMode == MusicViewMode.score &&
          widget.musicViewMode != MusicViewMode.score &&
          _prevBeat > widget.currentSection.beatCount - 2) {
        Future.delayed(slowAnimationDuration, () {
          scrollToCurrentBeat();
          _lastAutoScrollTime = DateTime.now();
        });
      } else if (_prevSectionId != null &&
          _prevSectionId != widget.currentSection.id) {
        scrollToCurrentBeat();
        _lastAutoScrollTime = DateTime.now();
      } else if (prevWidth != null && prevWidth != widget.width) {
        // print("width changed");
        scrollToCurrentBeat();
        _lastAutoScrollTime = DateTime.now();
      } else if (_prevSectionOrder != null &&
          _prevSectionOrder != sectionOrder) {
        Future.delayed(animationDuration, () {
          scrollToCurrentBeat();
          _lastAutoScrollTime = DateTime.now();
        });
      } else if ((BeatScratchPlugin.playing ||
              (currentBeat == 0 &&
                  widget.currentSection.id ==
                      widget.score.sections.first.id)) &&
          _hasBuilt &&
          sectionWidth > visibleAreaForSection &&
          _prevBeat != currentBeat &&
          (currentBeat - firstBeatOfSection) %
                  widget.currentSection.meter.defaultBeatsPerMeasure ==
              0 &&
          !isBeatOnScreen(currentBeat +
              widget.currentSection.meter.defaultBeatsPerMeasure)) {
        scrollToBeat(
          currentBeat,
        );
        _lastAutoScrollTime = DateTime.now();
      }
      // }
    }

    if (_hasBuilt && widget.score != _prevScore) {
      scrollToBeat(0, duration: Duration.zero);
      _prevScore = widget.score;
    }
    prevWidth = widget.width;
    _prevViewMode = widget.musicViewMode;
    _prevBeat = currentBeat;
    _prevSectionOrder = sectionOrder;
    _prevSectionId = widget.currentSection.id;
    _prevPartId = widget.focusedPart?.id;
    _hasBuilt = true;
    // print(
    //     "InteractiveViewer overallCanvasHeight=$overallCanvasHeight, systemsToRender=$systemsToRender, systemHeight=$systemHeight");
    return InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      boundaryMargin: EdgeInsets.only(
          bottom: widget.width / minScale, right: widget.height / scale),
      // boundaryMargin: EdgeInsets.symmetric(
      //     horizontal: widget.width / scale, vertical: widget.height / scale),
      onInteractionStart: (ScaleStartDetails details) {
        // If the user tries to cause a transformation while the reset animation is
        // running, cancel the reset animation.
        if (interactiveController.status == AnimationStatus.forward) {
          _interactiveAnimationStop();
        }
        interactionStartFocal.value =
            transformationController.toScene(details.focalPoint);
      },
      onInteractionEnd: (ScaleEndDetails details) {
        interactionStartFocal.value = null;
        animateToWithinBounds();
      },
      onInteractionUpdate: (ScaleUpdateDetails details) {
        // If the user tries to cause a transformation while the reset animation is
        // running, cancel the reset animation.
        if (interactiveController.status == AnimationStatus.forward) {
          _interactiveAnimationStop();
        }
        scaleUpdateNotifier.value = details;
        widget.tappedBeat.value = null;
        if (details.scale != 1) {
          _animateToTargetedScale = false;
          widget.targetScaleNotifier.value = scale;
          _animateToTargetedScale = true;
          int systemNumber = interactingSystem;
          final scaledWidth1 = widget.width / (scale / details.scale);
          final scaledWidth2 = widget.width / (scale);
          final scaledAvailableWidth1 = scaledWidth1 - clefWidth;
          final scaledAvailableWidth2 = scaledWidth2 - clefWidth;
          double systemXOffset1 = systemNumber * scaledAvailableWidth1;
          double systemXOffset2 = systemNumber * scaledAvailableWidth2;
          double diff = systemXOffset2 - systemXOffset1;
          // if (!MyPlatform.isDebug) return;
          // print(
          //     "onInteractionUpdate: scale = ${details.scale}, focal=$interactingFocal, scaledSystemHeight=$scaledSystemHeight, systemNumber=$systemNumber, translationX=${translationX}, diff=$diff, transformedRect=$transformedRect");

          if (details.scale < 1 &&
              transformedRect.left < diff &&
              interactionStartSystem.value > 0) {
            interactionStartSystem.value -= 1;
            transformationController.value
                .translate(-scaledAvailableWidth2, systemHeight, 0);
          }
          if (transformedRect.left > diff) {
            transformationController.value.translate(diff, 0, 0);
          }
        }
        // print("matrix=${transformationController.value}");
        // print("transformedRect=$transformedRect");
        // print("dims=$overallCanvasWidth x $overallCanvasHeight");
      },
      constrained: false,
      transformationController: transformationController,
      child: CustomPaint(
          //                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
          size: Size(overallCanvasWidth, overallCanvasHeight),
          painter: MusicSystemPainter(
              sectionScaleNotifier: sectionScaleNotifier,
              score: widget.score,
              section: widget.currentSection,
              musicViewMode: widget.musicViewMode,
              transformationController: transformationController,
              focusedMelodyId: widget.focusedMelody?.id,
              staves: stavesNotifier,
              partTopOffsets: partTopOffsets,
              staffOffsets: staffOffsets,
              colorGuideOpacityNotifier: colorGuideOpacityNotifier,
              colorblockOpacityNotifier: colorblockOpacityNotifier,
              notationOpacityNotifier: notationOpacityNotifier,
              colorboardNotesNotifier: widget.colorboardNotesNotifier,
              keyboardNotesNotifier: widget.keyboardNotesNotifier,
              bluetoothControllerPressedNotes:
                  widget.bluetoothControllerPressedNotes,
              visibleRect: () => transformedRect,
              verticallyVisibleRect: () => transformedRect,
              keyboardPart: keyboardPart,
              colorboardPart: colorboardPart,
              focusedPart: focusedPart,
              tappedPart: widget.tappedPart,
              sectionColor: sectionColor,
              isCurrentScore: widget.isCurrentScore,
              highlightedBeat: widget.highlightedBeat,
              focusedBeat: widget.focusedBeat,
              tappedBeat: widget.tappedBeat,
              firstBeatOfSection: firstBeatOfSection,
              renderPartNames: true,
              isPreview: false,
              systemsToRender: systemsToRender,
              otherListenables: [])),
    );
  }

  Rect get transformedRect => MatrixUtils.inverseTransformRect(
      transformationController.value,
      Rect.fromLTRB(0, 0, widget.width, widget.height));

  scrollToFocusedBeat({
    bool instant = false,
  }) {
    if (instant) {
      scrollToBeat(widget.focusedBeat.value - marginBeatsForBeat / 2,
          duration: Duration(milliseconds: 0), curve: Curves.ease);
    } else {
      scrollToBeat(widget.focusedBeat.value - marginBeatsForBeat / 2,
          duration: animationDuration, curve: Curves.linear);
    }
  }

  // double get secondSystemOffset =>
  //     widget.width - clefWidth;
  // bool showOnSecondSystem(double animationPos) =>
  //     systemsToRender > 1 && animationPos > secondSystemOffset;

  double _animationPos(double currentBeat) {
    // print(
    //     "_animationPos: $currentBeat $targetBeatWidth $overallCanvasWidth ${horizontallyVisibleRect.width}!");

    double animationPos = _singleSystemAnimationPos(currentBeat);
    animationPos -= currentBeatTargetSystemXOffset;
    return max(0, animationPos);
  }

  double _singleSystemAnimationPos(double currentBeat) {
    // print(
    //     "_singleSystemAnimationPos: $currentBeat $targetBeatWidth $overallCanvasWidth ${horizontallyVisibleRect.width}!");

    final beatWidth = targetBeatWidth;
    if (autoZoomAlign) {
      currentBeat = currentBeat.floorToDouble();
    }
    double animationPos = (currentBeat) * beatWidth;
    animationPos = min(animationPos,
        overallCanvasWidth - widget.width + 0.62 * targetBeatWidth);
    animationPos = max(0, animationPos);
    return animationPos;
  }

  bool isBeatOnScreen(double beat) {
    return true;
    // double animationPos = _animationPos(currentBeat);
    // double currentPos = timeScrollController.position.pixels;
    // return animationPos >= currentPos &&
    //     animationPos < currentPos + visibleRect.width - targetClefWidth;
  }

  void scrollToBeat(double currentBeat,
      {Duration duration = animationDuration, Curve curve = Curves.linear}) {
    //TODO reimplement this!
    return;
    // _lastBeatScrolledTo = currentBeat;
    double animationPos = _animationPos(currentBeat);
    // print(
    //     "scrollToBeat $currentBeat : $animationPos; s/t: ${widget.scale}/$targetScale");
    // final pixels = timeScrollController.position.pixels;
    // final offset = timeScrollController.offset;
    // if (_hasBuilt &&
    //     animationPos.notRoughlyEquals(timeScrollController.offset)) {
    //   try {
    //     animate() {
    //       if (duration.inMilliseconds > 0) {
    //         timeScrollController.animateTo(animationPos,
    //             duration: duration, curve: curve);
    //       } else {
    //         timeScrollController.jumpTo(animationPos);
    //       }
    //     }

    //     animate();
    //   } catch (e) {}
    // }
  }

  void scrollToPart() {
    // systemsToRender - 1,
    //           ((systemsToRender - 1) *
    //                   ((currentBeat - 2) /
    //                       (beatsOnScreenPerSystem * systemsToRender
    print(
        "scrollToPart: target system: $currentBeatTargetSystemIndex; currentBeat=$currentBeat, beatsOnScreenPerSystem=$beatsOnScreenPerSystem, calculatedSystemThingy=$calculatedSystemThingy, currentBeatTargetSystemIndex=$currentBeatTargetSystemIndex,_systemHeightForScrolling=$_systemHeightForScrolling, _extraHeightForScrolling=$_extraHeightForScrolling");

    // if (systemsToRender == 1) {
    //   if (autoSort) {
    //     verticalController.animateTo(0,
    //         duration: animationDuration, curve: Curves.ease);
    //   } else if (verticalController.offset > maxSystemVerticalPosition) {
    //     scrollToBottomMostPart();
    //   }
    // } else {
    // verticalController.animateTo(0 + currentBeatTargetSystemYOffset,
    //     duration: animationDuration, curve: Curves.ease);
    // }
  }

  // void scrollToBottomMostPart({double positionOffset = 0}) {
  //   verticalController.animateTo(maxSystemVerticalPosition + positionOffset,
  //       duration: animationDuration, curve: Curves.ease);
  // }

  bool get sectionCanBeCentered =>
      sectionWidth + targetClefWidth <= widget.width;
  int get staffCount => stavesNotifier.value.length;
  double get maxSystemVerticalPosition =>
      max(0, (staffCount) * staffHeight * scale - widget.height + 100);
  void scrollToCurrentBeat() {
    if (sectionCanBeCentered) {
      _constrainToSectionBounds();
    } else {
      scrollToBeat(autoScroll
          ? min(currentBeat, rightMostBeatConstrainedToSection)
          : currentBeat);
    }
    scrollToPart();

    // if (widget.autoFocus) {
    //   scrollToPart();
    // } else if (verticalController.offset > maxSystemVerticalPosition) {
    //   scrollToBottomMostPart();
    // }
  }

  double get rightMostBeatConstrainedToSection =>
      firstBeatOfSection +
      2.62 +
      (sectionWidth / targetBeatWidth) -
      (widget.width / targetBeatWidth);
  _constrainToSectionBounds() {
    if (widget.isTwoFingerScaling) return;
    // print("_constrainToSectionBounds");
    try {
      MatrixUtils.getAsTranslation(transformationController.value).dx;
      double sectionWidth = widget.currentSection.beatCount * targetBeatWidth;
      double visibleWidth = widget.width;
      if (sectionCanBeCentered) {
        scrollToBeat(firstBeatOfSection - (marginBeatsForSection / 2));
      } else {
        double sectionStart =
            (firstBeatOfSection + extraBeatsSpaceForClefs) * targetBeatWidth;
        final allowedMargin = visibleWidth * 0.2;
        if (dx < sectionStart - allowedMargin) {
          scrollToBeat(firstBeatOfSection);
        } else if (dx + visibleWidth >
            sectionStart + sectionWidth + allowedMargin) {
          scrollToBeat(rightMostBeatConstrainedToSection);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  double get firstBeatOfSection =>
      widget.score.firstBeatOfSection(widget.currentSection).toDouble();

  double get currentBeat {
    return BeatScratchPlugin.currentBeat.value + firstBeatOfSection;
  }

  void _animateStaffAndPartPositions() {
    var removedOffsets = staffOffsets.value.keys
        .where((id) => !widget.staves.any((staff) => staff.id == id));
    removedOffsets.forEach((removedStaffId) {
      Animation staffAnimation;
      staffAnimation = Tween<double>(
              begin: staffOffsets.value[removedStaffId], end: 0)
          .animate(
              CurvedAnimation(parent: animationController, curve: Curves.ease))
        ..addListener(() {
          staffOffsets.value[removedStaffId] = staffAnimation.value;
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          staffOffsets.notifyListeners();
        });
    });
    widget.staves.asMap().forEach((staffIndex, staff) {
      double staffPosition = staffIndex * staffHeight;
      double initialStaffPosition =
          staffOffsets.value.putIfAbsent(staff.id, () => overallCanvasHeight);
      Animation staffAnimation;
      staffAnimation = Tween<double>(
              begin: initialStaffPosition, end: staffPosition)
          .animate(
              CurvedAnimation(parent: animationController, curve: Curves.ease))
        ..addListener(() {
          staffOffsets.value[staff.id] = staffAnimation.value;
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          staffOffsets.notifyListeners();
        });
      staff.getParts(widget.score, widget.staves).forEach((part) {
        double partPosition = staffPosition;
        double initialPartPosition = partTopOffsets.value
            .putIfAbsent(part.id, () => overallCanvasHeight);
        Animation partAnimation;
        partAnimation =
            Tween<double>(begin: initialPartPosition, end: partPosition)
                .animate(CurvedAnimation(
                    parent: animationController, curve: Curves.ease))
              ..addListener(() {
                partTopOffsets.value[part.id] = partAnimation.value;
                // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                partTopOffsets.notifyListeners();
              });
      });
      stavesNotifier.value = widget.staves;
      colorboardPart.value = widget.colorboardPart;
      keyboardPart.value = widget.keyboardPart;
    });
  }

  void _animateOpacitiesAndScale() {
    double colorGuideOpacityValue =
        (widget.renderingMode == RenderingMode.colorblock) ? 0.5 : 0;
    double colorblockOpacityValue =
        (widget.renderingMode == RenderingMode.colorblock) ? 1 : 0;
    double notationOpacityValue =
        (widget.renderingMode == RenderingMode.notation) ? 1 : 0;
    double sectionScaleValue = sectionsHeight != 0 ? 1 : 0;
    Animation animation1;
    animation1 = Tween<double>(
            begin: colorblockOpacityNotifier.value, end: colorblockOpacityValue)
        .animate(animationController)
      ..addListener(() {
        colorblockOpacityNotifier.value = animation1.value;
      });
    Animation animation2;
    animation2 = Tween<double>(
            begin: notationOpacityNotifier.value, end: notationOpacityValue)
        .animate(animationController)
      ..addListener(() {
        notationOpacityNotifier.value = animation2.value;
      });
    Animation animation3;
    animation3 =
        Tween<double>(begin: sectionScaleNotifier.value, end: sectionScaleValue)
            .animate(animationController)
          ..addListener(() {
            sectionScaleNotifier.value = animation3.value;
          });
    Animation animation4;
    animation4 = Tween<double>(
            begin: colorGuideOpacityNotifier.value, end: colorGuideOpacityValue)
        .animate(animationController)
      ..addListener(() {
        colorGuideOpacityNotifier.value = animation4.value;
      });
  }
}

extension CloseComparison on double {
  bool roughlyEquals(double x, {double precision = 0.005}) =>
      x != null && (this - x).abs() < precision;

  bool notRoughlyEquals(double x, {double precision = 0.005}) =>
      !roughlyEquals(x, precision: precision);
}
