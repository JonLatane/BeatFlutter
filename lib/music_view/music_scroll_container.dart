import 'dart:math';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
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
  static const double minScale = 0.1;
  static const double maxScale = 1.0;

  final MelodyViewMode melodyViewMode;
  final Score score;
  final Section currentSection;
  final Color sectionColor;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final double xScale;
  final double yScale;
  final double targetXScale;
  final double targetYScale;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier;
  final ValueNotifier<Iterable<int>> keyboardNotesNotifier;
  final List<MusicStaff> staves;
  final Part focusedPart;
  final Part keyboardPart;
  final Part colorboardPart;
  final double height;
  final double width;
  final bool previewMode;
  final bool isCurrentScore;
  final ValueNotifier<int> highlightedBeat;
  final ValueNotifier<int> focusedBeat;
  final ValueNotifier<Offset> requestedScrollOffsetForScale;
  final bool isTwoFingerScaling;
  final ChangeNotifier scrollToCurrentBeat;
  final ChangeNotifier centerCurrentSection;
  final bool autoScroll;
  final bool renderPartNames;
  final bool isPreview;
  final ValueNotifier<ScaleUpdate> notifyXScaleUpdate, notifyYScaleUpdate;

  const MusicScrollContainer(
      {Key key,
      this.score,
      this.currentSection,
      this.sectionColor,
      this.xScale,
      this.yScale,
      this.focusedMelody,
      this.renderingMode,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.melodyViewMode,
      this.staves,
      this.keyboardPart,
      this.colorboardPart,
      this.focusedPart,
      this.width,
      this.height,
      this.previewMode,
      this.isCurrentScore,
      this.highlightedBeat,
      this.requestedScrollOffsetForScale,
      this.focusedBeat,
      this.targetXScale,
      this.targetYScale, this.isTwoFingerScaling, this.scrollToCurrentBeat, this.centerCurrentSection, this.autoScroll, this.renderPartNames, this.isPreview, this.notifyXScaleUpdate, this.notifyYScaleUpdate})
      : super(key: key);

  @override
  _MusicScrollContainerState createState() => _MusicScrollContainerState();
}

Rect melodyRendererVisibleRect = Rect.zero;

class _MusicScrollContainerState extends State<MusicScrollContainer> with TickerProviderStateMixin {
  ScrollController verticalController;

  AnimationController animationController;
  ValueNotifier<double> colorGuideOpacityNotifier;
  ValueNotifier<double> colorblockOpacityNotifier;
  ValueNotifier<double> notationOpacityNotifier;
  ValueNotifier<double> sectionScaleNotifier;

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
  double _prevXScale;
  String _prevSectionId;
  DateTime _lastScaleTime = DateTime(0);
  Rect visibleRect = Rect.zero;

  bool get isViewingSection => widget.melodyViewMode != MelodyViewMode.score;

  int get numberOfBeats => /*isViewingSection ? widget.currentSection.harmony.beatCount :*/
      widget.score.beatCount;

  double get xScale => widget.xScale;

  double get yScale => widget.yScale;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;
  double get targetXScale => widget.notifyXScaleUpdate.value?.newScale ?? widget.targetXScale;
  double get targetBeatWidth => unscaledStandardBeatWidth * targetXScale;

  double get canvasHeightMagic => 1.3 - 0.3 * (widget.staves.length) / 5;

  double get toolbarHeight => widget.melodyViewMode == MelodyViewMode.score ? 0 : 48;

  double get renderAreaHeight => widget.height - toolbarHeight;

  double get sectionsHeight => widget.melodyViewMode == MelodyViewMode.score ? 30 : 0;

  double get overallCanvasHeight => max(renderAreaHeight, widget.staves.length * MusicSystemPainter.staffHeight * yScale)
    + sectionsHeight;
  double get maxCanvasHeight => max(renderAreaHeight, widget.staves.length * MusicSystemPainter.staffHeight * MusicScrollContainer.maxScale)
    + sectionsHeight;

  double get overallCanvasWidth =>
      (numberOfBeats + MusicSystemPainter.extraBeatsSpaceForClefs) * targetBeatWidth; // + 20 * xScale; // + 1 for clefs
  double get maxCanvasWidth =>
    (numberOfBeats + MusicSystemPainter.extraBeatsSpaceForClefs) * unscaledStandardBeatWidth * MusicScrollContainer.maxScale; // + 20 * xScale; // + 1 for clefs
  double get targetClefWidth => MusicSystemPainter.extraBeatsSpaceForClefs * targetBeatWidth;
  double get sectionWidth => widget.currentSection.beatCount * targetBeatWidth;
  double get visibleWidth => myVisibleRect.width;
  double get visibleAreaForSection => visibleWidth - targetClefWidth;
  double get marginBeatsForBeat => max(0,visibleWidth - 2 * targetClefWidth - targetBeatWidth) / targetBeatWidth;
  double get marginBeatsForSection => max(0,visibleWidth - targetClefWidth - sectionWidth) / targetBeatWidth;

  Rect get myVisibleRect => (widget.previewMode) ? visibleRect : melodyRendererVisibleRect;

  set myVisibleRect(value) {
    if (widget.previewMode) {
      visibleRect = value;
    } else {
      melodyRendererVisibleRect = value;
    }
  }

  @override
  void initState() {
    super.initState();
    timeScrollController = ScrollController();
    verticalController = ScrollController();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: kIsWeb ? 1000 : 500));
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
    timeScrollController.addListener(_isScrollingListener);
    xScaleUpdateListener = _scaleUpdateListener(widget.notifyXScaleUpdate, (update) {
      scrollToFocusedBeat(/*specificXScale: update.newScale*/);
    });
    yScaleUpdateListener = _scaleUpdateListener(widget.notifyYScaleUpdate, (update) {});
    widget.notifyXScaleUpdate.addListener(xScaleUpdateListener);
    widget.notifyYScaleUpdate.addListener(yScaleUpdateListener);
  }

  DateTime _lastScrollEventSeen = DateTime(0);
  DateTime _lastScrollStopEventTime = DateTime(0);
  VoidCallback xScaleUpdateListener, yScaleUpdateListener;

  static const int _autoScrollDelayDuration = 2500;
  _isScrollingListener() {
    _lastScrollEventSeen = DateTime.now();
    Future.delayed(Duration(milliseconds: _autoScrollDelayDuration + 50), () {
      if (_autoScrollDelayDuration < DateTime.now().millisecondsSinceEpoch - _lastScrollEventSeen.millisecondsSinceEpoch &&
        _autoScrollDelayDuration < DateTime.now().millisecondsSinceEpoch - _lastScrollStopEventTime.millisecondsSinceEpoch) {
        print('scroll is stopped');
        _lastScrollStopEventTime = DateTime.now();
        _onScrollStopped();
      }
    });
  }

  _onScrollStopped() {
    if (widget.autoScroll && !widget.isTwoFingerScaling &&
      (widget.melodyViewMode != MelodyViewMode.score ||
        !BeatScratchPlugin.playing)
    ) {
      _constrainToSectionBounds();
    }
  }
  
  VoidCallback _scaleUpdateListener(ValueNotifier<ScaleUpdate> notifier, Function(ScaleUpdate) handler) {
    return () {
      final value = notifier.value;
      if (value != null) {
        print("ScaleUpdate: ${value.oldScale.toStringAsFixed(4)} -> ${value.newScale.toStringAsFixed(4)}");
        handler(value);
        notifier.value = null;
      }
    };
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
    timeScrollController.removeListener(_isScrollingListener);
    widget.scrollToCurrentBeat.removeListener(scrollToCurrentBeat);
    widget.centerCurrentSection.removeListener(_constrainToSectionBounds);
    widget.notifyXScaleUpdate.removeListener(xScaleUpdateListener);
    widget.notifyYScaleUpdate.removeListener(_constrainToSectionBounds);
    super.dispose();
  }

  MelodyViewMode _prevViewMode;
  bool _hasBuilt = false;
  DateTime _lastAutoScrollTime = DateTime(0);

  @override
  Widget build(BuildContext context) {
    String key = widget.score.id;
    // if (widget.requestedScrollOffsetForScale.value != null) {
    //   timeScrollController.animateTo(xScale * (timeScrollController.offset + widget.requestedScrollOffsetForScale.value.dx),
    //     duration: Duration(milliseconds: 200), curve: Curves.linear);
    //   widget.requestedScrollOffsetForScale.value = null;
    // }
    if (widget.currentSection != null) {
      key = widget.currentSection.toString();
    }
    _animateOpacitiesAndScale();
    _animateStaffAndPartPositions();
    focusedPart.value = widget.focusedPart;
    sectionColor.value = widget.sectionColor;
    animationController.forward(from: 0);

    int currentBeatOfSection = BeatScratchPlugin.currentBeat.value;
    double currentBeat = this.currentBeat;
    Duration beatAnimationDuration = animationDuration;
    // if(_prevViewMode == MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.score
    //     && _prevBeat > widget.currentSection.beatCount - 2) {
    //   beatAnimationDuration = Duration(microseconds: 1);
    // }
    String sectionOrder = widget.score.sections.map((e) => e.id).join();
    if (!widget.isPreview) {
      if (widget.isTwoFingerScaling) {
        scrollToFocusedBeat(instant: false);
      } else if (widget.focusedBeat.value != null) {
        // scrollToFocusedBeat();
      } else if (widget.autoScroll) {
        if (DateTime.now().difference(_lastAutoScrollTime).inMilliseconds > 1000) {
          if (_prevViewMode == MelodyViewMode.score &&
            widget.melodyViewMode != MelodyViewMode.score &&
            _prevBeat > widget.currentSection.beatCount - 2) {
            Future.delayed(slowAnimationDuration, () {
              _constrainToSectionBounds();
              _lastAutoScrollTime = DateTime.now();
            });
          } else if (_prevSectionId != null && _prevSectionId != widget.currentSection.id) {
            _constrainToSectionBounds();
            _lastAutoScrollTime = DateTime.now();
          } /*else if (_prevXScale != null && (_prevXScale - widget.xScale).abs() > 0.001) {
            if (sectionWidth + targetClefWidth < visibleWidth) {
              _constrainToSectionBounds();
            } else {
              final beat = (max(0, currentBeat - marginBeatsForBeat) / 2.0);
              scrollToBeat(beat);
            }
            _lastScaleTime = DateTime.now();
            _prevXScale = widget.xScale;
            _lastAutoScrollTime = DateTime.now();
          }*/ else if (_prevSectionOrder != null && _prevSectionOrder != sectionOrder) {
            Future.delayed(animationDuration, () {
              _constrainToSectionBounds();
              _lastAutoScrollTime = DateTime.now();
            });
          } else if (BeatScratchPlugin.playing && _hasBuilt
            && sectionWidth > visibleWidth - targetClefWidth
            && _prevBeat != currentBeat &&
            (currentBeat - firstBeatOfSection) % widget.currentSection.meter.defaultBeatsPerMeasure == 0 &&
            !isBeatOnScreen(currentBeat + widget.currentSection.meter.defaultBeatsPerMeasure)) {
            scrollToBeat(currentBeat,);
            _lastAutoScrollTime = DateTime.now();
          }
        }
      }
    }
    //TODO reimplement scrolling with playback, better though
    // final isFirstBeatOfMeasure = _prevBeat != currentBeat &&
    //   currentBeatOfSection % widget.currentSection.meter.defaultBeatsPerMeasure == 0;
    // final switchedToScoreView = _prevViewMode != widget.melodyViewMode && widget.melodyViewMode == MelodyViewMode.score;
    // if(widget.isCurrentScore && (isFirstBeatOfMeasure/* || switchedToScoreView*/)) {
    //   scrollToBeat(currentBeat, beatAnimationDuration: beatAnimationDuration,
    //     delay: switchedToScoreView ? Duration(milliseconds:
    //       animationDuration.inMilliseconds + slowAnimationDuration.inMilliseconds
    //     ) : null);
    // }
    _prevViewMode = widget.melodyViewMode;
    _prevBeat = currentBeat;
    _prevXScale = widget.xScale;
    _prevSectionOrder = sectionOrder;
    _prevSectionId = widget.currentSection.id;
    _hasBuilt = true;

    final useMaxCanvasHeight = true; // DateTime.now().difference(_lastScaleTime).inMilliseconds  < 1000;
    return SingleChildScrollView(
        controller: verticalController,
//        key: Key(key),
        child: AnimatedContainer(
            duration: animationDuration,
            height: maxCanvasHeight,
            child: CustomScrollView(
              controller: timeScrollController,
              scrollDirection: Axis.horizontal,
              slivers: [
                CustomSliverToBoxAdapter(
                  setVisibleRect: (rect) {
                    myVisibleRect = rect;
                  },
                  child: CustomPaint(
//                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
                    size: Size(maxCanvasWidth, maxCanvasHeight),
                    painter: MusicSystemPainter(
                      sectionScaleNotifier: sectionScaleNotifier,
                      score: widget.score,
                      section: widget.currentSection,
                      melodyViewMode: widget.melodyViewMode,
                      xScale: widget.xScale,
                      yScale: widget.yScale,
                      focusedMelodyId: widget.focusedMelody?.id,
                      staves: stavesNotifier,
                      partTopOffsets: partTopOffsets,
                      staffOffsets: staffOffsets,
                      colorGuideOpacityNotifier: colorGuideOpacityNotifier,
                      colorblockOpacityNotifier: colorblockOpacityNotifier,
                      notationOpacityNotifier: notationOpacityNotifier,
                      colorboardNotesNotifier: widget.colorboardNotesNotifier,
                      keyboardNotesNotifier: widget.keyboardNotesNotifier,
                      visibleRect: () => myVisibleRect,
                      keyboardPart: keyboardPart,
                      colorboardPart: colorboardPart,
                      focusedPart: focusedPart,
                      sectionColor: sectionColor,
                      isCurrentScore: widget.isCurrentScore,
                      highlightedBeat: widget.highlightedBeat,
                      focusedBeat: widget.focusedBeat,
                      firstBeatOfSection: firstBeatOfSection,
                      renderPartNames: widget.renderPartNames,
                      isPreview: widget.isPreview,
                    ),
                  ),
//          child: _MelodyPaint(
//            score: widget.score,
//            section: widget.section,
//            xScale: widget.xScale,
//            yScale: widget.yScale,
//            visibleRect: () => _visibleRect,
//            width: width,
//          ),
                )
              ],
            )));
  }

  scrollToFocusedBeat({bool instant = false,}) {
    if (instant) {
      scrollToBeat(widget.focusedBeat.value - marginBeatsForBeat / 2, beatAnimationDuration: Duration(milliseconds: 0),
        curve: Curves.linear);
    } else {
      scrollToBeat(widget.focusedBeat.value - marginBeatsForBeat / 2, beatAnimationDuration: Duration(milliseconds: 200),
        curve: Curves.linear);
    }
    // if (_prevXScale != null && _prevXScale.notRoughlyEquals(widget.xScale)) {
    //   _lastScaleTime = DateTime.now();
    // }
  }

  bool get sectionCanBeCentered => sectionWidth + targetClefWidth <= visibleWidth;
  void scrollToCurrentBeat() {
    verticalController.animateTo(0, duration: animationDuration, curve: Curves.ease);
    scrollToBeat(currentBeat);
    // if (widget.autoScroll && !widget.isTwoFingerScaling && sectionCanBeCentered) {
    //   Future.delayed(animationDuration, _constrainToSectionBounds);
    // }
  }
  
  double _animationPos(double currentBeat) {
    print("_animationPos: $currentBeat $targetBeatWidth $overallCanvasWidth ${myVisibleRect.width}!");
    final beatWidth = targetBeatWidth;
    double animationPos = (currentBeat) * beatWidth;
    animationPos = min(animationPos, overallCanvasWidth - myVisibleRect.width + 0.62 * targetBeatWidth);
    // if (widget.melodyViewMode != MelodyViewMode.score) {
    //   if (sectionCanBeCentered) {
    //     double start = (firstBeatOfSection + MusicSystemPainter.extraBeatsSpaceForClefs) * beatWidth;
    //     animationPos = min(animationPos, start - (marginBeatsForSection / 2) * beatWidth);
    //   } else {
    //     double start = (firstBeatOfSection + MusicSystemPainter.extraBeatsSpaceForClefs) * beatWidth;
    //     animationPos = min(animationPos, start + sectionWidth - myVisibleRect.width + beatWidth);
    //   }
    // }
    animationPos = max(0, animationPos);
    return animationPos;
  }
  
  bool isBeatOnScreen(double beat) {
    double animationPos = _animationPos(currentBeat);
    double currentPos = timeScrollController.position.pixels;
    return animationPos >= currentPos && animationPos < currentPos + visibleRect.width - targetClefWidth;
  }

  void scrollToBeat(double currentBeat, {
    Duration beatAnimationDuration = animationDuration, Curve curve = Curves.linear}) {
    double animationPos = _animationPos(currentBeat);
    print("scrollToBeat $currentBeat : $animationPos; s/t: ${widget.xScale}/$targetXScale");
    // final pixels = timeScrollController.position.pixels;
    // final offset = timeScrollController.offset;
    if (_hasBuilt && animationPos.notRoughlyEquals(timeScrollController.offset)) {
      try {
        animate() => timeScrollController.animateTo(
          animationPos, duration: beatAnimationDuration, curve: curve);
        animate();
      } catch (e) {}
    }
  }

  _constrainToSectionBounds() {
    if (widget.isTwoFingerScaling) return;
    print("_constrainToSectionBounds");
    // if (widget.melodyViewMode != MelodyViewMode.score) {
    //TODO restrict the user to their current section more properly
    double position = timeScrollController.position.pixels;
    double sectionWidth = widget.currentSection.beatCount * targetBeatWidth;
    double visibleWidth = myVisibleRect.width;
    double targetClefWidth = MusicSystemPainter.extraBeatsSpaceForClefs * targetBeatWidth;
    if (sectionWidth + targetClefWidth <= visibleWidth) {
      scrollToBeat(firstBeatOfSection - (marginBeatsForSection / 2));
    } else {
      double sectionStart = (firstBeatOfSection + MusicSystemPainter.extraBeatsSpaceForClefs) * targetBeatWidth;
      final allowedMargin = visibleWidth * 0.2;
      if (position < sectionStart - allowedMargin) {
        scrollToBeat(firstBeatOfSection);
      } else if (position + visibleWidth > sectionStart + sectionWidth + allowedMargin) {
        scrollToBeat(firstBeatOfSection +
            2.62 +
            (sectionWidth / targetBeatWidth) -
            (myVisibleRect.width /
                targetBeatWidth));
      }
    }
    // }
  }

  double get firstBeatOfSection => widget.score.firstBeatOfSection(widget.currentSection).toDouble();

  double get currentBeat {
    return BeatScratchPlugin.currentBeat.value + firstBeatOfSection;
  }

  void _animateStaffAndPartPositions() {
    var removedOffsets = staffOffsets.value.keys.where((id) => !widget.staves.any((staff) => staff.id == id));
    removedOffsets.forEach((removedStaffId) {
      Animation staffAnimation;
      staffAnimation = Tween<double>(begin: staffOffsets.value[removedStaffId], end: 0)
          .animate(CurvedAnimation(parent: animationController, curve: Curves.ease))
            ..addListener(() {
              staffOffsets.value[removedStaffId] = staffAnimation.value;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              staffOffsets.notifyListeners();
            });
    });
    widget.staves.asMap().forEach((staffIndex, staff) {
      double staffPosition = staffIndex * MusicSystemPainter.staffHeight * yScale;
      double initialStaffPosition = staffOffsets.value.putIfAbsent(staff.id, () => overallCanvasHeight);
      Animation staffAnimation;
      staffAnimation = Tween<double>(begin: initialStaffPosition, end: staffPosition)
          .animate(CurvedAnimation(parent: animationController, curve: Curves.ease))
            ..addListener(() {
              staffOffsets.value[staff.id] = staffAnimation.value;
              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
              staffOffsets.notifyListeners();
            });
      staff.getParts(widget.score, widget.staves).forEach((part) {
        double partPosition = staffPosition;
        double initialPartPosition = partTopOffsets.value.putIfAbsent(part.id, () => overallCanvasHeight);
        Animation partAnimation;
        partAnimation = Tween<double>(begin: initialPartPosition, end: partPosition)
            .animate(CurvedAnimation(parent: animationController, curve: Curves.ease))
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
    double colorGuideOpacityValue = (widget.renderingMode == RenderingMode.colorblock) ? 0.5 : 0;
    double colorblockOpacityValue = (widget.renderingMode == RenderingMode.colorblock) ? 1 : 0;
    double notationOpacityValue = (widget.renderingMode == RenderingMode.notation) ? 1 : 0;
    double sectionScaleValue = widget.melodyViewMode == MelodyViewMode.score ? 1 : 0;
    Animation animation1;
    animation1 =
        Tween<double>(begin: colorblockOpacityNotifier.value, end: colorblockOpacityValue).animate(animationController)
          ..addListener(() {
            colorblockOpacityNotifier.value = animation1.value;
          });
    Animation animation2;
    animation2 =
        Tween<double>(begin: notationOpacityNotifier.value, end: notationOpacityValue).animate(animationController)
          ..addListener(() {
            notationOpacityNotifier.value = animation2.value;
          });
    Animation animation3;
    animation3 = Tween<double>(begin: sectionScaleNotifier.value, end: sectionScaleValue).animate(animationController)
      ..addListener(() {
        sectionScaleNotifier.value = animation3.value;
      });
    Animation animation4;
    animation4 =
        Tween<double>(begin: colorGuideOpacityNotifier.value, end: colorGuideOpacityValue).animate(animationController)
          ..addListener(() {
            colorGuideOpacityNotifier.value = animation4.value;
          });
  }
}

extension CloseComparison on double {
  bool roughlyEquals(double x, {double precision = 0.005}) => (this - x).abs() < precision;
  bool notRoughlyEquals(double x, {double precision = 0.005}) => !roughlyEquals(x, precision: precision);
}