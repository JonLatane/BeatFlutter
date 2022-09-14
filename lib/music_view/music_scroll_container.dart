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
  static const double maxScale = 1.0;

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
  final bool showingSectionList;

  const MusicScrollContainer(
      {Key key,
      this.score,
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
  static final double scrollTopMarginPercent = 0.17;
  static final double scrollLeftMarginPercent = 0.25;
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

  MusicViewMode _prevViewMode;
  bool _hasBuilt = false;
  DateTime _lastAutoScrollTime = DateTime(0);
  double prevWidth;
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

  int get maxSupportedSystems => widget.appSettings.systemsToRender < 1
      ? 9999999
      : widget.appSettings.systemsToRender;

  double systemRenderAreaWidth({double customScale = null}) =>
      max(0, (widget.width / (customScale ?? scale)) - clefWidth);
  double beatsOnScreenPerSystem({double customScale = null}) =>
      systemRenderAreaWidth(customScale: customScale) / beatWidth;
  int maxSystemsNeeded({double customScale = null}) => (widget.score.beatCount /
          max(0.1, beatsOnScreenPerSystem(customScale: customScale)))
      .ceil();

  int systemsToRender({double customScale = null}) =>
      min(maxSystemsNeeded(customScale: customScale), maxSupportedSystems);

  double calculatedSystemThingy({double customScale = null}) {
    final systemsToRender = this.systemsToRender(customScale: customScale);
    return ((systemsToRender) *
        ((currentBeat - 2) /
            (beatsOnScreenPerSystem(customScale: customScale) *
                systemsToRender)));
  }

  // In multi-system mode, we select a "target system" for the
  // currentBeat based on how far into the score currentBeat is.
  int currentBeatTargetSystemIndex({double customScale = null}) {
    final systemsToRender = this.systemsToRender(customScale: customScale);
    return max(
        0,
        min(
            systemsToRender - 1,
            systemsToRender == 1
                ? 0
                : calculatedSystemThingy(customScale: customScale).floor()));
  }

  double currentBeatTargetSystemXOffset({double customScale = null}) =>
      currentBeatTargetSystemIndex(customScale: customScale) *
      (systemRenderAreaWidth(customScale: customScale));
  double get _systemHeightForScrolling =>
      MusicSystemPainter.calculateSystemHeight(
          scale, widget.score.parts.length) +
      systemPadding;
  double get _extraHeightForScrolling =>
      _systemHeightForScrolling < widget.height
          ? max(0, (widget.height - _systemHeightForScrolling) / 3)
          : 0;

  double get smallerScale => scale * 0.6;
  double get overallCanvasWidth =>
      max(widget.width / smallerScale,
          (numberOfBeats + extraBeatsSpaceForClefs) * targetBeatWidth) *
      3;
  double overallCanvasHeight({double customScale = null}) =>
      max(widget.height / smallerScale,
          systemsToRender(customScale: customScale) * systemHeight) *
      3;

  double get targetClefWidth => extraBeatsSpaceForClefs * targetBeatWidth;
  double get sectionWidth => widget.currentSection.beatCount * targetBeatWidth;
  double get visibleHeight => transformedRect.height;
  double get visibleWidth => transformedRect.width;
  double get visibleAreaForSection => visibleWidth - targetClefWidth;
  bool get autoScroll => widget.appSettings.autoScrollMusic;
  bool get autoSort => widget.appSettings.autoSortMusic;
  bool get autoZoomAlign => widget.appSettings.autoZoomAlignMusic;

  get minScale => MusicScrollContainer.minScale;
  get maxScale => MusicScrollContainer.maxScale;
  double get scaledSystemHeight => MusicSystemPainter.calculateSystemHeight(
      scale, widget.score.parts.length);

  Animation<Matrix4> interactiveAnimation;
  AnimationController interactiveController;
  void _interactiveAnimationStop() {
    interactiveController.stop();
    interactiveAnimation?.removeListener(_onInteractiveAnimation);
    interactiveAnimation = null;
    interactiveController.reset();
  }

  void _onInteractiveAnimation() {
    if (interactiveAnimation != null) {
      transformationController.value = interactiveAnimation.value;
      if (!interactiveController.isAnimating) {
        interactiveAnimation.removeListener(_onInteractiveAnimation);
        interactiveAnimation = null;
        interactiveController.reset();
      }
    }
  }

  bool _animateToTargetedScale = true;
  int get focusedSystem =>
      max(
          0,
          ((transformedRect.top + 0.5 * transformedRect.top) /
                  scaledSystemHeight)
              .round()) +
      1;
  void animateToTargetScaleAndPosition() {
    if (!_animateToTargetedScale) return;

    if (widget.appSettings.autoScrollMusic) {
      scrollToCurrentBeat(customScale: targetScale);
    } else {
      // interactiveController.reset();
      final targetedMatrix = transformationController.value.clone();
      targetedMatrix.scale(
          targetScale / scale, targetScale / scale, targetScale / scale);

      double scaleChange = targetScale / scale;
      int focusedSystem = this.focusedSystem;
      adjustDxForScale(focusedSystem, scaleChange, targetedMatrix,
          adjustingAfterChange: false);

      double extraDx = 0.5 *
          (1 - scaleChange) *
          (transformedRect.left + 0.5 * transformedRect.width);
      if (transformedRect.left > extraDx) {
        targetedMatrix.translate(extraDx, 0.0, 0.0);
      } else {
        targetedMatrix.translate(transformedRect.left, 0.0, 0.0);
      }

      double dy = 0.5 *
          (-focusedSystem * systemHeight +
              focusedSystem * systemHeight / scaleChange);
      if (transformedRect.top > dy) {
        targetedMatrix.translate(0.0, dy, 0.0);
      } else {
        targetedMatrix.translate(0.0, transformedRect.top, 0.0);
      }
      _animateTo(targetedMatrix);
    }
  }

  _animateTo(Matrix4 targetedMatrix) {
    if (targetedMatrix != transformationController.value) {
      _interactiveAnimationStop();
      interactiveAnimation = Matrix4Tween(
        begin: transformationController.value,
        end: targetedMatrix,
      ).animate(interactiveController);
      interactiveAnimation.addListener(_onInteractiveAnimation);
      interactiveController.forward();
    }
  }

  void animateToWithinBounds() {
    _interactiveAnimationStop();
    final targetedMatrix = transformationController.value.clone();
    // Animate to within vertical bounds
    final scaledWidth = widget.width / (scale);
    final scaledAvailableWidth = scaledWidth - clefWidth;
    final endOfLastSystem =
        overallCanvasWidth - systemsToRender() * scaledAvailableWidth;
    final systemsAwayFromBottom = //max(
        //0,
        ((transformedRect.left - endOfLastSystem) / scaledAvailableWidth)
            .floor(); //);
    final systemsRendered = max(0, systemsToRender() - systemsAwayFromBottom);
    final transformedRectMaxTop = max(
        0,
        systemsRendered * systemHeight -
            min(staffHeight * scale, (widget.height / scale)) +
            staffHeight / 2);
    print(
        "animateToWithinBounds: systemsAwayFromBottom=$systemsAwayFromBottom, systemsRendered=$systemsRendered, transformedRectMaxTop=$transformedRectMaxTop");
    return;
    if (transformedRect.top >= transformedRectMaxTop) {
      final untranslate = transformedRect.top - transformedRectMaxTop;
      print(
          "animateToWithinBounds: systemsAwayFromBottom=$systemsAwayFromBottom, systemsRendered=$systemsRendered, transformedRectMaxTop=$transformedRectMaxTop");
      targetedMatrix.translate(0.0, untranslate, 0.0);
    } else if (transformedRect.top < 0) {
      targetedMatrix.translate(0.0, transformedRect.top, 0.0);
    }
    _animateTo(targetedMatrix);
  }

  @override
  void initState() {
    super.initState();
    interactiveController =
        AnimationController(vsync: this, duration: animationDuration);
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
    widget.centerCurrentSection.addListener(constrainToSectionBounds);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentBeat();
    });
    interactionStartFocal.addListener(_deriveStartSystemFromFocal);
  }

  VoidCallback xScaleUpdateListener, yScaleUpdateListener;

  _transformationListener() {}

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
    widget.centerCurrentSection.removeListener(constrainToSectionBounds);
    super.dispose();
  }

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
      max(0, min(systemsToRender() - 1, interactionStartSystem.value));

  adjustDxForScale(int systemNumber, double scaleChange, Matrix4 target,
      {bool adjustingAfterChange = true}) {
    final scaledWidth1 = adjustingAfterChange
        ? widget.width / (scale / scaleChange)
        : widget.width / (scale);
    final scaledWidth2 = adjustingAfterChange
        ? widget.width / (scale)
        : widget.width / (scale * scaleChange);
    final scaledAvailableWidth1 = scaledWidth1 - clefWidth;
    final scaledAvailableWidth2 = scaledWidth2 - clefWidth;
    double systemXOffset1 = systemNumber * scaledAvailableWidth1;
    double systemXOffset2 = systemNumber * scaledAvailableWidth2;
    double diff = systemXOffset2 - systemXOffset1;
    if (transformedRect.left > -scaledAvailableWidth2) {
      target.translate(diff, 0.0, 0.0);
    } else {
      interactionStartSystem.value -= 1;
      target.translate(diff - scaledAvailableWidth2, systemHeight, 0.0);
    }
    // } else if (adjustingAfterChange) {
    //   if (interactionStartSystem.value > 0) {
    //     interactionStartSystem.value -= 1;
    //     final dx = diff - scaledAvailableWidth2;
    //     final dy = systemHeight;
    //     // if (transformedRect.top > dy &&
    //     //     transformedRect.right + dx < overallCanvasWidth) {
    //     target.translate(dx, dy, 0);
    //     // }
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    _animateOpacitiesAndScale();
    _animateStaffAndPartPositions();
    focusedPart.value = widget.focusedPart;
    sectionColor.value = widget.sectionColor;
    animationController.forward(from: 0);

    double currentBeat = this.currentBeat;
    String sectionOrder = widget.score.sections.map((e) => e.id).join();
    if (autoScroll) {
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
        scrollToCurrentBeat();
        _lastAutoScrollTime = DateTime.now();
      }
    }

    if (_hasBuilt && widget.score != _prevScore) {
      scrollToBeat(0);
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
      key: ValueKey("music-interactive-viewer"),
      minScale: minScale,
      maxScale: maxScale,
      constrained: false,
      transformationController: transformationController,
      boundaryMargin: EdgeInsets.only(
        left: overallCanvasWidth,
        // left: widget.width / 2.0
        top: overallCanvasHeight(),
        // bottom: widget.width / minScale,
        // right: 0
      ),
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
        // return;
        // If the user tries to cause a transformation while the reset animation is
        // running, cancel the reset animation.
        if (interactiveController.status == AnimationStatus.forward) {
          _interactiveAnimationStop();
        }
        print(
            "onInteractionUpdate: ${details.scale} ${scale} ${Size(overallCanvasWidth, overallCanvasHeight())}");
        scaleUpdateNotifier.value = details;
        widget.tappedBeat.value = null;
        if (details.scale != 1) {
          if ((details.scale > 1 && scale >= maxScale - 0.0001) ||
              (details.scale < 1 && scale <= minScale + 0.0001)) {
            return;
          }
          _animateToTargetedScale = false;
          widget.targetScaleNotifier.value = scale;
          _animateToTargetedScale = true;
          adjustDxForScale(
              interactingSystem, details.scale, transformationController.value);
        } else {
          final scaledWidth = widget.width / (scale);
          final scaledAvailableWidth = scaledWidth - clefWidth;
          if (transformedRect.top < -systemHeight) {
            transformationController.value
                .translate(scaledAvailableWidth, -systemHeight, 0.0);
          } else if (transformedRect.left < -scaledAvailableWidth ||
              transformedRect.top > 2 * systemHeight) {
            transformationController.value
                .translate(-scaledAvailableWidth, systemHeight, 0.0);
          }
        }
        // print("matrix=${transformationController.value}");
        // print("transformedRect=$transformedRect");
        // print("dims=$overallCanvasWidth x $overallCanvasHeight");
      },
      child: CustomPaint(
          //                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
          size: Size(overallCanvasWidth, overallCanvasHeight()),
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
              systemsToRender: systemsToRender(),
              otherListenables: [])),
    );
  }

  Rect get transformedRect => MatrixUtils.inverseTransformRect(
      transformationController.value,
      Rect.fromLTRB(0, 0, widget.width, widget.height));

  // double get secondSystemOffset =>
  //     widget.width - clefWidth;
  // bool showOnSecondSystem(double animationPos) =>
  //     systemsToRender > 1 && animationPos > secondSystemOffset;

  double _animationPos(double currentBeat, {double customScale = null}) {
    // print(
    //     "_animationPos: $currentBeat $targetBeatWidth $overallCanvasWidth ${horizontallyVisibleRect.width}!");

    double animationPos = _singleSystemAnimationPos(currentBeat);
    animationPos -= currentBeatTargetSystemXOffset(customScale: customScale);
    if (currentBeat == 0.0) {
      return max(0.0, animationPos);
    }
    return animationPos;
  }

  double _singleSystemAnimationPos(double currentBeat) {
    // print(
    //     "_singleSystemAnimationPos: $currentBeat $targetBeatWidth $overallCanvasWidth ${horizontallyVisibleRect.width}!");

    final beatWidth = targetBeatWidth;
    if (autoZoomAlign && false) {
      currentBeat = currentBeat.floorToDouble();
    }
    double animationPos = (currentBeat) * beatWidth;
    animationPos = min(animationPos, overallCanvasWidth - visibleWidth);
    animationPos = animationPos;
    return animationPos;
  }

  bool isBeatOnScreen(double beat) {
    return true;
    // double animationPos = _animationPos(currentBeat);
    // double currentPos = timeScrollController.position.pixels;
    // return animationPos >= currentPos &&
    //     animationPos < currentPos + visibleRect.width - targetClefWidth;
  }

  bool get sectionCanBeCentered =>
      sectionWidth + targetClefWidth <= transformedRect.width;
  int get staffCount => stavesNotifier.value.length;

  void scrollToCurrentBeat({double customScale = null}) {
    print("scrollToCurrentBeat, sectionCanBeCentered=$sectionCanBeCentered");
    if (sectionCanBeCentered) {
      constrainToSectionBounds(customScale: customScale);
    } else {
      scrollToBeat(currentBeat, customScale: customScale);
    }
  }

  double get marginBeatsForBeat =>
      max(0, visibleWidth - 2 * targetClefWidth - targetBeatWidth) /
      targetBeatWidth;

  constrainToSectionBounds({double customScale = null}) {
    double ratioScale = (customScale ?? scale) / scale;
    double marginBeatsForSection =
        max(0.0, visibleWidth / ratioScale - targetClefWidth - sectionWidth) /
            targetBeatWidth;
    double targetBeat =
        max(0.0, firstBeatOfSection - (marginBeatsForSection / 2.0));
    print(
        "constrainToSectionBounds customScale=$customScale, scale=$scale ratioScale=$ratioScale firstBeatOfSection=$firstBeatOfSection marginBeatsForSection=$marginBeatsForSection targetBeat=$targetBeat");
    try {
      scrollToBeat(targetBeat, customScale: customScale, includeMarginX: false);
    } catch (e) {
      print(e);
    }
  }

  void scrollToBeat(double targetBeat,
      {double customScale = null,
      bool includeMarginX = true,
      bool scrollHorizontally = true}) {
    final scale = this.scale;
    double ratioScale = (customScale ?? scale) / scale;
    double scoreWidth = widget.score.beatCount * beatWidth + clefWidth;
    bool entireScoreFitsHorizontally = visibleWidth / ratioScale >= scoreWidth;
    if (entireScoreFitsHorizontally) {
      final marginWidth = max(0.0, visibleWidth / ratioScale - scoreWidth);
      final topMarginHeight =
          max(0.0, visibleHeight / ratioScale - systemHeight);
      final targetedMatrix = Matrix4.identity().clone()
        ..scale(customScale ?? scale)
        ..translate(marginWidth / 2.0, topMarginHeight / 2.0, 0.0);
      _animateTo(targetedMatrix);
    } else {
      // _lastBeatScrolledTo = currentBeat;
      double targetedDx = _animationPos(targetBeat, customScale: customScale);
      if (includeMarginX) {
        final marginWidth = max(
            0.0,
            min(targetBeat * beatWidth,
                visibleWidth / ratioScale - beatWidth - clefWidth));
        print(
            "includeMarginX: marginWidth=$marginWidth, targetBeat=$targetBeat");
        targetedDx -= scrollLeftMarginPercent * marginWidth;
      } else {
        print("includeMarginX FALSE, targetBeat=$targetBeat");
      }
      final topMarginHeight =
          max(0.0, visibleHeight / ratioScale - systemHeight);
      double systemCount = systemsToRender(customScale: customScale).toDouble();
      double maxDy =
          max(0.0, (systemCount) * systemHeight - visibleHeight / ratioScale);
      double topMargin = scrollTopMarginPercent * topMarginHeight;
      double scoreHeight = systemHeight * systemCount;
      bool entireScoreFitsVertically = scoreHeight < transformedRect.height;
      double targetedDy = entireScoreFitsVertically
          ? -0.5 * (visibleHeight / ratioScale - scoreHeight)
          : min(
              maxDy,
              max(
                  targetedDx == 0.0 ? 0.0 : -topMargin,
                  systemHeight *
                      currentBeatTargetSystemIndex(customScale: customScale)));
      print(
          "scrollToBeat, targetedDx=$targetedDx entireScoreFitsVertically=$entireScoreFitsVertically customScale=$customScale, scale=$scale ratioScale=$ratioScale systemsToRender=$systemsToRender currentBeatTargetSystemIndex=$currentBeatTargetSystemIndex, systemHeight=$systemHeight visibleHeight=$visibleHeight topMarginHeight=$topMarginHeight maxDy=$maxDy targetedDy=$targetedDy");
      // "Scrolling ideally" means horizontally when going forward/down
      bool goDownLeft =
          (targetedDy > transformedRect.top + 0.5 * transformedRect.height);
      print(
          "stb: goDownLeft=$goDownLeft, targetedDy=$targetedDy, transformedRect.top=${transformedRect.top}, transformedRect.bottom=${transformedRect.bottom}, transformedRect.height=${transformedRect.height} ");
      if (scrollHorizontally && goDownLeft) {
        translateDownLeft();
      }
      // Compensate for scale chanegs
      if (customScale != scale) {
        int currentSystem = currentBeatTargetSystemIndex(customScale: scale);
        int newSystem = currentBeatTargetSystemIndex(customScale: customScale);
        while (currentSystem < newSystem) {
          translateDownLeft();
          currentSystem++;
        }
        while (currentSystem > newSystem) {
          translateUpRight();
          currentSystem--;
        }
      }
      final targetedMatrix = Matrix4.identity().clone()
        ..scale(customScale ?? scale)
        ..translate(-targetedDx, -targetedDy, 0.0);
      _animateTo(targetedMatrix);
    }
  }

  translateDownLeft() => transformationController.value
      .translate((visibleWidth - clefWidth), -systemHeight, 0);

  translateUpRight() => transformationController.value
      .translate(-(visibleWidth - clefWidth), systemHeight, 0);

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
          staffOffsets.value.putIfAbsent(staff.id, () => overallCanvasHeight());
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
            .putIfAbsent(part.id, () => overallCanvasHeight());
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
