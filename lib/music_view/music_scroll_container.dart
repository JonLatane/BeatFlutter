import 'dart:math';

import 'package:beatscratch_flutter_redux/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/bs_methods.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import 'music_system_painter.dart';

class ScaleUpdate {
  final double oldScale;
  final double newScale;

  ScaleUpdate(this.oldScale, this.newScale);
}

class MusicScrollContainer extends StatefulWidget {
  static const double minScale = 0.09;
  static const double maxScale = 1.0;

  final MusicViewMode musicViewMode;
  final Score score;
  final Section currentSection;
  final Color sectionColor;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final double xScale, yScale;
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
  final ValueNotifier<ScaleUpdate> notifyXScaleUpdate, notifyYScaleUpdate;
  final ValueNotifier<double> xScaleNotifier,
      yScaleNotifier,
      targetXScaleNotifier,
      targetYScaleNotifier;
  final ValueNotifier<double> verticalScrollNotifier;
  final BSMethod scrollToFocusedBeat;

  const MusicScrollContainer(
      {Key key,
      this.score,
      this.scrollToFocusedBeat,
      this.currentSection,
      this.sectionColor,
      this.xScale,
      this.yScale,
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
      this.targetXScaleNotifier,
      this.targetYScaleNotifier,
      this.isTwoFingerScaling,
      this.scrollToCurrentBeat,
      this.centerCurrentSection,
      this.appSettings,
      this.notifyXScaleUpdate,
      this.notifyYScaleUpdate,
      this.xScaleNotifier,
      this.yScaleNotifier,
      this.verticalScrollNotifier,
      this.scrollToPart})
      : super(key: key);

  @override
  _MusicScrollContainerState createState() => _MusicScrollContainerState();
}

Rect horizontallyVisibleRect = Rect.zero;
Rect verticallyVisibleRect = Rect.zero;

class _MusicScrollContainerState extends State<MusicScrollContainer>
    with TickerProviderStateMixin {
  ScrollController verticalController;

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

  ScrollController timeScrollController;
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

  double get xScale => widget.xScale;

  double get yScale => widget.yScale;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get targetXScale => widget.targetXScaleNotifier.value;
  double get targetYScale => widget.targetYScaleNotifier.value;

  double get targetBeatWidth => unscaledStandardBeatWidth * targetXScale;

  double get canvasHeightMagic => 1.3 - 0.3 * (widget.staves.length) / 5;

  double get sectionsHeight => widget.musicViewMode == MusicViewMode.score ||
          xScale < 2 * MusicScrollContainer.minScale
      ? 30
      : 0;

  // TODO: Eliminate magic "1.2" constant
  double get systemHeight => (((widget.staves.length + 0.5) *
          (MusicSystemPainter.staffHeight) *
          yScale) +
      sectionsHeight * 2);

  double get systemRenderAreaWidth =>
      widget.width - MusicSystemPainter.calculateClefWidth(xScale);
  double get beatsOnScreenPerSystem =>
      systemRenderAreaWidth / standardBeatWidth;
  int get maxSystemsNeeded =>
      (widget.score.beatCount / beatsOnScreenPerSystem).ceil();

  int get maxSupportedSystems => widget.appSettings.systemsToRender;
  int get systemsToRender => /*systemHeight < widget.height*/ true
      ? min(maxSystemsNeeded, maxSupportedSystems)
      : 1;

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
      (MusicSystemPainter.calculateHarmonyHeight(yScale) +
          MusicSystemPainter.calculateSectionHeight(yScale) +
          MusicSystemPainter.calculateSystemHeight(
              yScale, widget.score.parts.length) +
          0.75 * MusicSystemPainter.calculateSystemPadding(yScale));
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
      (numberOfBeats + MusicSystemPainter.extraBeatsSpaceForClefs) *
      targetBeatWidth;
  double get overallCanvasHeight => systemsToRender * systemHeight;
  double get targetClefWidth =>
      MusicSystemPainter.extraBeatsSpaceForClefs * targetBeatWidth;

  double get sectionWidth => widget.currentSection.beatCount * targetBeatWidth;

  double get visibleWidth => horizontallyVisibleRect.width;

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

  @override
  void initState() {
    super.initState();
    timeScrollController = ScrollController();
    verticalController = ScrollController();
    widget.scrollToFocusedBeat.addListener(() {
      scrollToFocusedBeat();
    });
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
    // scrollToCurrentBeat
    timeScrollController.addListener(_timeScrollListener);
    verticalController.addListener(_verticalScrollListener);

    VoidCallback _scaleUpdateListener(
        ValueNotifier<ScaleUpdate> notifier, Function(ScaleUpdate) handler) {
      return () {
        final value = notifier.value;
        if (value != null &&
            value.oldScale
                .notRoughlyEquals(value.newScale, precision: 0.0005)) {
          // print("ScaleUpdate: ${value.oldScale.toStringAsFixed(12)} -> "
          // "${value.newScale.toStringAsFixed(12)}");
          handler(value);
          notifier.value = null;
        }
      };
    }

    xScaleUpdateListener =
        _scaleUpdateListener(widget.notifyXScaleUpdate, (update) {
      widget.xScaleNotifier.value = update.newScale;

      if (widget.isTwoFingerScaling) {
        scrollToFocusedBeat(instant: true);
      } else {
        // s1, s2: before/after scale. p1: before offset
        final double p1 = timeScrollController.offset,
            s1 = update.oldScale,
            s2 = update.newScale,
            w1 = widget.width, // * s1 / s2,
            w2 = widget.width * s2 / s1,
            bw2 = unscaledStandardBeatWidth * s2,
            bw1 = unscaledStandardBeatWidth * s1;
        // p2: the target offset
        double p2;
        if (autoScroll) {
          p2 = p1 * s2 / s1;
          double cb1 = currentBeat * bw1;
          // if cb1 (the current beat) was on screen
          if (cb1 + bw1 >= p1 && cb1 <= p1 + w1) {
            // if cb1 was on the right/left third of the view,
            // shift focus that way
            if (cb1 >= p1 + w1 * 0.66667) {
              p2 += (w2 - w1) / 2;
            } else if (cb1 <= p1 + w1 * 0.33333) {
              p2 -= (w2 - w1) / 2;
            }
          } else {
            print('cb1 out of bounds');
          }
        } else {
          p2 = p1 * s2 / s1;
        }
        p2 += (w2 - w1) / 2;
        // print("For scale, jumping from $p1 to $p2");
        timeScrollController.jumpTo(p2);
        // scrollToFocusedBeat();
      }
    });
    yScaleUpdateListener =
        _scaleUpdateListener(widget.notifyYScaleUpdate, (update) {
      widget.yScaleNotifier.value = update.newScale;
    });
    widget.notifyXScaleUpdate.addListener(xScaleUpdateListener);
    widget.notifyYScaleUpdate.addListener(yScaleUpdateListener);

    widget.scrollToPart.addListener(scrollToPart);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentBeat();
    });
  }

  DateTime _lastScrollEventSeen = DateTime(0);
  DateTime _lastScrollStopEventTime = DateTime(0);
  double _lastTimeScrollValue = 0;
  VoidCallback xScaleUpdateListener, yScaleUpdateListener;

  static const int _autoScrollDelayDuration = 2500;

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
    widget.verticalScrollNotifier.value = verticalController.offset;
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
    timeScrollController.removeListener(_timeScrollListener);
    verticalController.removeListener(_verticalScrollListener);
    widget.scrollToCurrentBeat.removeListener(scrollToCurrentBeat);
    widget.scrollToPart.removeListener(scrollToPart);
    widget.centerCurrentSection.removeListener(_constrainToSectionBounds);
    widget.notifyXScaleUpdate.removeListener(xScaleUpdateListener);
    widget.notifyYScaleUpdate.removeListener(_constrainToSectionBounds);
    super.dispose();
  }

  MusicViewMode _prevViewMode;
  bool _hasBuilt = false;
  DateTime _lastAutoScrollTime = DateTime(0);
  double prevWidth;

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

    return CustomScrollView(
        controller: verticalController,
        scrollDirection: Axis.vertical,
        slivers: [
          CustomSliverToBoxAdapter(
              setVisibleRect: (rect) {
                verticallyVisibleRect = rect;
              },
              child: AnimatedContainer(
                  duration: animationDuration,
                  height: overallCanvasHeight,
                  child: CustomScrollView(
                    controller: timeScrollController,
                    scrollDirection: Axis.horizontal,
                    slivers: [
                      CustomSliverToBoxAdapter(
                        setVisibleRect: (rect) {
                          horizontallyVisibleRect = rect;
                        },
                        child: CustomPaint(
//                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
                            size: Size(overallCanvasWidth, overallCanvasHeight),
                            painter: MusicSystemPainter(
                                sectionScaleNotifier: sectionScaleNotifier,
                                score: widget.score,
                                section: widget.currentSection,
                                musicViewMode: widget.musicViewMode,
                                xScaleNotifier: widget.xScaleNotifier,
                                yScaleNotifier: widget.yScaleNotifier,
                                focusedMelodyId: widget.focusedMelody?.id,
                                staves: stavesNotifier,
                                partTopOffsets: partTopOffsets,
                                staffOffsets: staffOffsets,
                                colorGuideOpacityNotifier:
                                    colorGuideOpacityNotifier,
                                colorblockOpacityNotifier:
                                    colorblockOpacityNotifier,
                                notationOpacityNotifier:
                                    notationOpacityNotifier,
                                colorboardNotesNotifier:
                                    widget.colorboardNotesNotifier,
                                keyboardNotesNotifier:
                                    widget.keyboardNotesNotifier,
                                bluetoothControllerPressedNotes:
                                    widget.bluetoothControllerPressedNotes,
                                visibleRect: () => horizontallyVisibleRect,
                                verticallyVisibleRect: () => Rect.fromLTRB(
                                    horizontallyVisibleRect.left,
                                    horizontallyVisibleRect.top +
                                        verticalController.offset,
                                    horizontallyVisibleRect.right,
                                    horizontallyVisibleRect.top +
                                        verticalController.offset +
                                        widget.height),
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
                                otherListenables: [verticalController])),
                      )
                    ],
                  )))
        ]);
  }

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
  //     widget.width - MusicSystemPainter.calculateClefWidth(xScale);
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
    animationPos = min(
        animationPos,
        overallCanvasWidth -
            horizontallyVisibleRect.width +
            0.62 * targetBeatWidth);
    animationPos = max(0, animationPos);
    return animationPos;
  }

  bool isBeatOnScreen(double beat) {
    double animationPos = _animationPos(currentBeat);
    double currentPos = timeScrollController.position.pixels;
    return animationPos >= currentPos &&
        animationPos < currentPos + visibleRect.width - targetClefWidth;
  }

  void scrollToBeat(double currentBeat,
      {Duration duration = animationDuration, Curve curve = Curves.linear}) {
    // _lastBeatScrolledTo = currentBeat;
    double animationPos = _animationPos(currentBeat);
    // print(
    //     "scrollToBeat $currentBeat : $animationPos; s/t: ${widget.xScale}/$targetXScale");
    // final pixels = timeScrollController.position.pixels;
    // final offset = timeScrollController.offset;
    if (_hasBuilt &&
        animationPos.notRoughlyEquals(timeScrollController.offset)) {
      try {
        animate() {
          if (duration.inMilliseconds > 0) {
            timeScrollController.animateTo(animationPos,
                duration: duration, curve: curve);
          } else {
            timeScrollController.jumpTo(animationPos);
          }
        }

        animate();
      } catch (e) {}
    }
  }

  void scrollToPart() {
    // systemsToRender - 1,
    //           ((systemsToRender - 1) *
    //                   ((currentBeat - 2) /
    //                       (beatsOnScreenPerSystem * systemsToRender
    print(
        "scrollToPart: target system: $currentBeatTargetSystemIndex; currentBeat=$currentBeat, beatsOnScreenPerSystem=$beatsOnScreenPerSystem, calculatedSystemThingy=$calculatedSystemThingy");

    if (systemsToRender == 1) {
      if (autoSort) {
        verticalController.animateTo(0,
            duration: animationDuration, curve: Curves.ease);
      } else if (verticalController.offset > maxSystemVerticalPosition) {
        scrollToBottomMostPart();
      }
    } else {
      verticalController.animateTo(0 + currentBeatTargetSystemYOffset,
          duration: animationDuration, curve: Curves.ease);
    }
  }

  void scrollToBottomMostPart({double positionOffset = 0}) {
    verticalController.animateTo(maxSystemVerticalPosition + positionOffset,
        duration: animationDuration, curve: Curves.ease);
  }

  bool get sectionCanBeCentered =>
      sectionWidth + targetClefWidth <= widget.width;
  int get staffCount => stavesNotifier.value.length;
  double get maxSystemVerticalPosition => max(
      0,
      (staffCount) * MusicSystemPainter.staffHeight * yScale -
          widget.height +
          100);
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
      (horizontallyVisibleRect.width / targetBeatWidth);
  _constrainToSectionBounds() {
    if (widget.isTwoFingerScaling) return;
    // print("_constrainToSectionBounds");
    try {
      double position = timeScrollController.position.pixels;
      double sectionWidth = widget.currentSection.beatCount * targetBeatWidth;
      double visibleWidth = horizontallyVisibleRect.width;
      if (sectionCanBeCentered) {
        scrollToBeat(firstBeatOfSection - (marginBeatsForSection / 2));
      } else {
        double sectionStart =
            (firstBeatOfSection + MusicSystemPainter.extraBeatsSpaceForClefs) *
                targetBeatWidth;
        final allowedMargin = visibleWidth * 0.2;
        if (position < sectionStart - allowedMargin) {
          scrollToBeat(firstBeatOfSection);
        } else if (position + visibleWidth >
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
      double staffPosition =
          staffIndex * MusicSystemPainter.staffHeight * yScale;
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
