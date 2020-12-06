import 'dart:math';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:unification/unification.dart';

import 'drawing/color_guide.dart';
import 'drawing/harmony_beat_renderer.dart';
import 'drawing/melody/melody.dart';
import 'drawing/melody/melody_clef_renderer.dart';
import 'drawing/melody/melody_color_guide.dart';
import 'drawing/melody/melody_staff_lines_renderer.dart';
import 'dummydata.dart';
import 'generated/protos/music.pb.dart';
import 'midi_theory.dart';
import 'music_notation_theory.dart';
import 'music_theory.dart';
import 'ui_models.dart';
import 'util.dart';

const double _extraBeatsSpaceForClefs = 2;

class MelodyRenderer extends StatefulWidget {
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

  const MelodyRenderer(
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
      this.targetYScale, this.isTwoFingerScaling, this.scrollToCurrentBeat, this.centerCurrentSection, this.autoScroll})
      : super(key: key);

  @override
  _MelodyRendererState createState() => _MelodyRendererState();
}

Rect melodyRendererVisibleRect = Rect.zero;

class _MelodyRendererState extends State<MelodyRenderer> with TickerProviderStateMixin {
  bool get isViewingSection => widget.melodyViewMode != MelodyViewMode.score;

  int get numberOfBeats => /*isViewingSection ? widget.currentSection.harmony.beatCount :*/
      widget.score.beatCount;

  double get xScale => widget.xScale;

  double get yScale => widget.yScale;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;
  double get targetBeatWidth => unscaledStandardBeatWidth * widget.targetXScale;

  double get canvasHeightMagic => 1.3 - 0.3 * (widget.staves.length) / 5;

  double get toolbarHeight => widget.melodyViewMode == MelodyViewMode.score ? 0 : 48;

  double get renderAreaHeight => widget.height - toolbarHeight;

  double get sectionsHeight => widget.melodyViewMode == MelodyViewMode.score ? 30 : 0;

  double get overallCanvasHeight => max(renderAreaHeight, widget.staves.length * staffHeight * yScale) + sectionsHeight;

  double get overallCanvasWidth =>
      (numberOfBeats + _extraBeatsSpaceForClefs) * standardBeatWidth; // + 20 * xScale; // + 1 for clefs

  ScrollController verticalController;
  static const double staffHeight = 500;

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

  ScrollController timeScrollController = ScrollController();
  int _prevBeat;
  String _prevSectionOrder;
  double _prevXScale;
  String _prevSectionId;
  Rect visibleRect = Rect.zero;
  double get targetClefWidth => _extraBeatsSpaceForClefs * targetBeatWidth;
  double get sectionWidth => widget.currentSection.beatCount * targetBeatWidth;
  double get visibleWidth => myVisibleRect.width;


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
  }

  DateTime _lastScrollEventSeen = DateTime(0);
  DateTime _lastScrollStopEventTime = DateTime(0);

  _isScrollingListener() {
    _lastScrollEventSeen = DateTime.now();
    Future.delayed(Duration(milliseconds: 500), () {
      if (450 < DateTime.now().millisecondsSinceEpoch - _lastScrollEventSeen.millisecondsSinceEpoch &&
          450 < DateTime.now().millisecondsSinceEpoch - _lastScrollStopEventTime.millisecondsSinceEpoch) {
        print('scroll is stopped');
        _lastScrollStopEventTime = DateTime.now();
        if (widget.autoScroll &&
          (widget.melodyViewMode != MelodyViewMode.score ||
          !BeatScratchPlugin.playing)
        ) {
          _constrainToSectionBounds();
        }
      }
    });
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
    super.dispose();
  }

  MelodyViewMode _prevViewMode;
  bool _hasBuilt = false;

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
    int currentBeat = this.currentBeat;
    Duration beatAnimationDuration = animationDuration;
    // if(_prevViewMode == MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.score
    //     && _prevBeat > widget.currentSection.beatCount - 2) {
    //   beatAnimationDuration = Duration(microseconds: 1);
    // }
    String sectionOrder = widget.score.sections.map((e) => e.id).join();
    if (widget.isTwoFingerScaling) {
      scrollToBeat(widget.focusedBeat.value, beatAnimationDuration: Duration(milliseconds: 50), curve: Curves.linear);
    } else if (widget.autoScroll) {
      if (_prevViewMode == MelodyViewMode.score &&
        widget.melodyViewMode != MelodyViewMode.score &&
        _prevBeat > widget.currentSection.beatCount - 2) {
        Future.delayed(slowAnimationDuration, _constrainToSectionBounds);
      } else if (/*_prevViewMode != MelodyViewMode.score && widget.melodyViewMode != MelodyViewMode.score
     && */
      _prevSectionId != null && _prevSectionId != widget.currentSection.id) {
        _constrainToSectionBounds();
      } else if (_prevXScale != null && _prevXScale != widget.xScale) {
        _constrainToSectionBounds();
        if (sectionWidth + targetClefWidth > visibleWidth) {
          scrollToBeat(widget.focusedBeat.value ?? currentBeat,
            curve: Curves.linear,
            beatAnimationDuration: Duration(milliseconds: 150)
          );
        }
        // scrollToBeat(widget.focusedBeat.value ?? currentBeat);
      } else if (_prevSectionOrder != null && _prevSectionOrder != sectionOrder) {
        Future.delayed(animationDuration, _constrainToSectionBounds);
      } else if (_hasBuilt
        && sectionWidth > visibleWidth - targetClefWidth
        && _prevBeat != currentBeat && (currentBeat - firstBeatOfSection) % widget.currentSection.meter.defaultBeatsPerMeasure == 0 &&
        !isBeatOnScreen(currentBeat + widget.currentSection.meter.defaultBeatsPerMeasure)) {
        scrollToBeat(currentBeat,
          curve: Curves.ease,
          beatAnimationDuration: Duration(milliseconds: 150)
        );
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
    return SingleChildScrollView(
        controller: verticalController,
//        key: Key(key),
        child: Container(
            height: overallCanvasHeight,
            child: CustomScrollView(
              controller: timeScrollController,
              scrollDirection: Axis.horizontal,
              slivers: [
                new CustomSliverToBoxAdapter(
                  setVisibleRect: (rect) {
                    myVisibleRect = rect;
                  },
                  child: CustomPaint(
//                    key: Key("$overallCanvasWidth-$overallCanvasHeight"),
                    size: Size(overallCanvasWidth, overallCanvasHeight),
                    painter: new MusicSystemPainter(
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
                      firstBeatOfSection: firstBeatOfSection,
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

  bool _onScrollNotification(ScrollNotification scrollNotification) {
    if (scrollNotification is ScrollStartNotification) {
      // _onStartScroll(scrollNotification.metrics);
    } else if (scrollNotification is ScrollUpdateNotification) {
      // _onUpdateScroll(scrollNotification.metrics);
    } else if (scrollNotification is ScrollEndNotification) {
      // _onEndScroll(scrollNotification.metrics);

      scrollToBeat(currentBeat);
    }
  }

  void scrollToCurrentBeat() {
    scrollToBeat(currentBeat);
    if (widget.autoScroll) {
      Future.delayed(animationDuration, _constrainToSectionBounds);
    }
  }
  
  double _animationPos(int currentBeat) {
    double animationPos = (currentBeat) * targetBeatWidth;
    animationPos = min(animationPos, overallCanvasWidth - myVisibleRect.width);
    if (widget.melodyViewMode != MelodyViewMode.score) {
      double position = timeScrollController.position.pixels;
      if (sectionWidth + targetClefWidth <= visibleWidth) {
        int marginBeats = ((visibleWidth - sectionWidth - targetClefWidth) / targetBeatWidth).floor();
        // scrollToBeat(firstBeatOfSection - (marginBeats~/2));
        double start = (firstBeatOfSection + _extraBeatsSpaceForClefs) * targetBeatWidth;
        animationPos = min(animationPos, start - (marginBeats ~/ 2) * targetBeatWidth);
      } else {
        double start = (firstBeatOfSection + _extraBeatsSpaceForClefs) * targetBeatWidth;
        animationPos = min(animationPos, start + sectionWidth - myVisibleRect.width + targetBeatWidth);
      }
    }
    animationPos = max(0, animationPos);
    return animationPos;
  }
  
  bool isBeatOnScreen(int beat) {
    double animationPos = _animationPos(currentBeat);
    double currentPos = timeScrollController.position.pixels;
    return animationPos >= currentPos && animationPos < currentPos + visibleRect.width - targetClefWidth;
  }

  void scrollToBeat(int currentBeat, {Duration beatAnimationDuration = animationDuration, Curve curve = Curves.linear, Duration delay}) {
    double animationPos = _animationPos(currentBeat);
    if (_hasBuilt) {
      try {
        animate() => timeScrollController.animateTo(
          animationPos, duration: beatAnimationDuration, curve: curve);
        if (delay != null) {
          Future.delayed(delay, animate);
        } else {
          animate();
        }
      } catch (e) {}
    }
  }

  _constrainToSectionBounds() {
    // if (widget.melodyViewMode != MelodyViewMode.score) {
    //TODO restrict the user to their current section more properly
    double position = timeScrollController.position.pixels;
    double sectionWidth = widget.currentSection.beatCount * targetBeatWidth;
    double visibleWidth = myVisibleRect.width;
    double targetClefWidth = _extraBeatsSpaceForClefs * targetBeatWidth;
    if (sectionWidth + targetClefWidth <= visibleWidth) {
      int marginBeats = ((visibleWidth - sectionWidth - targetClefWidth) / targetBeatWidth).floor();

      scrollToBeat(firstBeatOfSection - (marginBeats ~/ 2));
    } else {
      double sectionStart = (firstBeatOfSection + _extraBeatsSpaceForClefs) * targetBeatWidth;
      if (position < sectionStart) {
        scrollToBeat(firstBeatOfSection);
      } else if (position + visibleWidth > sectionStart + sectionWidth) {
        scrollToBeat(firstBeatOfSection +
            2 +
            (sectionWidth ~/ targetBeatWidth) -
            (myVisibleRect.width ~/
                targetBeatWidth) /* + ((sectionWidth - 2*visibleRect.width)~/ targetBeatWidth)*/);
      }
    }
    // }
  }

  int get firstBeatOfSection => widget.score.firstBeatOfSection(widget.currentSection);

  int get currentBeat {
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
      double staffPosition = staffIndex * staffHeight * yScale;
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

class MusicSystemPainter extends CustomPainter {
  final String focusedMelodyId;
  final Score score;

  Melody get focusedMelody =>
      score.parts.expand((p) => p.melodies).firstWhere((m) => m.id == focusedMelodyId, orElse: () => null);
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  final MelodyViewMode melodyViewMode;
  final ValueNotifier<double> colorblockOpacityNotifier,
      colorGuideOpacityNotifier,
      notationOpacityNotifier,
      sectionScaleNotifier;
  final ValueNotifier<Iterable<int>> colorboardNotesNotifier;
  final ValueNotifier<Iterable<int>> keyboardNotesNotifier;
  final ValueNotifier<Iterable<MusicStaff>> staves;
  final ValueNotifier<Map<String, double>> partTopOffsets;
  final ValueNotifier<Map<String, double>> staffOffsets;
  final ValueNotifier<Color> sectionColor;
  final ValueNotifier<Part> focusedPart;
  final ValueNotifier<Part> keyboardPart;
  final ValueNotifier<Part> colorboardPart;
  final ValueNotifier<int> highlightedBeat;
  final bool isCurrentScore;
  final int firstBeatOfSection;

  bool get isViewingSection => melodyViewMode != MelodyViewMode.score;

  int get numberOfBeats => /*isViewingSection ? section.harmony.beatCount :*/ score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  int get colorGuideAlpha => (255 * colorGuideOpacityNotifier.value).toInt();

  MusicSystemPainter(
      {this.firstBeatOfSection,
      this.highlightedBeat,
      this.melodyViewMode,
      this.colorGuideOpacityNotifier,
      this.sectionColor,
      this.focusedPart,
      this.keyboardPart,
      this.colorboardPart,
      this.staves,
      this.partTopOffsets,
      this.staffOffsets,
      this.sectionScaleNotifier,
      this.colorboardNotesNotifier,
      this.keyboardNotesNotifier,
      this.score,
      this.section,
      this.xScale,
      this.yScale,
      this.visibleRect,
      this.focusedMelodyId,
      this.colorblockOpacityNotifier,
      this.notationOpacityNotifier,
      this.isCurrentScore})
      : super(
            repaint: Listenable.merge([
          colorblockOpacityNotifier,
          notationOpacityNotifier,
          colorboardNotesNotifier,
          keyboardNotesNotifier,
          staves,
          partTopOffsets,
          staffOffsets,
          keyboardPart,
          colorboardPart,
          BeatScratchPlugin.pressedMidiControllerNotes,
          BeatScratchPlugin.currentBeat
        ])) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100, 30 * yScale);

  double get idealSectionHeight => max(22, harmonyHeight);

  double get sectionHeight => idealSectionHeight * sectionScaleNotifier.value;

  double get melodyHeight => _MelodyRendererState.staffHeight * yScale;

  @override
  void paint(Canvas canvas, Size size) {
    // return;
    final startTime = DateTime.now().millisecondsSinceEpoch;
    bool drawContinuousColorGuide = false; //xScale <= 1;
//    canvas.clipRect(Offset.zero & size);

    // Calculate from which beat we should start drawing
    int startBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    double top, left, right, bottom;
    left = startBeat * standardBeatWidth;
//    canvas.drawRect(visibleRect(), Paint()..style=PaintingStyle.stroke..strokeWidth=10);

    staves.value.forEach((staff) {
      double staffOffset = staffOffsets.value.putIfAbsent(staff.id, () => 0);
      double top = visibleRect().top + harmonyHeight + sectionHeight + staffOffset;
      Rect staffLineBounds = Rect.fromLTRB(visibleRect().left, top, visibleRect().right, top + melodyHeight);
//      canvas.drawRect(staffLineBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);
      _renderStaffLines(canvas, !(staff is DrumStaff) && drawContinuousColorGuide, staffLineBounds);
      Rect clefBounds =
          Rect.fromLTRB(visibleRect().left, top, visibleRect().left + 2 * standardBeatWidth, top + melodyHeight);
//      canvas.drawRect(clefBounds, Paint()..style=PaintingStyle.stroke..strokeWidth=10);

      _renderClefs(canvas, clefBounds, staff);
    });

//    left += 2 * standardBeatWidth;
    int renderingBeat = startBeat - _extraBeatsSpaceForClefs.toInt(); // To make room for clefs
//    print("Drawing frame from beat=$renderingBeat. Colorblock alpha is ${colorblockOpacityNotifier.value}. Notation alpha is ${notationOpacityNotifier.value}");
//     bool keepRenderingBeats = true;
    while (left < visibleRect().right + standardBeatWidth) {
      // keepRenderingBeats &= DateTime.now().millisecondsSinceEpoch - startTime < 17;
      // if (!keepRenderingBeats) {
      //   break;
      // }
      if (renderingBeat >= 0) {
        // Figure out what beat of what section we're drawing
        int renderingSectionBeat = renderingBeat;
        Section renderingSection = this.section;
        // if (melodyViewMode == MelodyViewMode.score) {
        int _beat = 0;
        int sectionIndex = 0;
        Section candidate = score.sections[sectionIndex];
        while (_beat + candidate.beatCount <= renderingBeat) {
          _beat += candidate.beatCount;
          renderingSectionBeat -= candidate.beatCount;
          sectionIndex += 1;
          if (sectionIndex < score.sections.length) {
            candidate = score.sections[sectionIndex];
          } else {
            candidate = null;
            break;
          }
        }
        renderingSection = candidate;
        // }
        if (renderingSection == null) {
          break;
        }
        if (renderingSectionBeat >= renderingSection.beatCount) {
          //TODO do this better...
          break;
        }

        // Draw the Section name if needed
        top = visibleRect().top;
        if (renderingSectionBeat == 0 && sectionHeight > 0) {
          //TODO Why does frame rate drop?
          double fontSize = sectionHeight * 0.6;
          double topOffset = sectionHeight * 0.05;
          if (fontSize <= 12) {
            topOffset -= 45 / fontSize;
            topOffset = max(-13, topOffset);
          }
//        print("fontSize=$fontSize topOffset=$topOffset");
          TextSpan span = TextSpan(
              text: renderingSection.name.isNotEmpty
                  ? renderingSection.name
                  : " Section ${renderingSection.id.substring(0, 5)}",
              style: TextStyle(
                  fontFamily: "VulfSans",
                  fontSize: fontSize,
                  fontWeight: FontWeight.w100,
                  color: renderingSection.name.isNotEmpty ? Colors.black : Colors.grey));
          TextPainter tp = TextPainter(
            text: span,
            strutStyle: StrutStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w800),
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, new Offset(left + standardBeatWidth * 0.08, top + topOffset));
        }
        top += sectionHeight;

        Harmony renderingHarmony = renderingSection.harmony;
        right = left + standardBeatWidth;
        String sectionName = renderingSection.name;
        if (sectionName == null || sectionName.isEmpty) {
          sectionName = renderingSection.id;
        }

//      canvas.drawImageRect(filledNotehead, Rect.fromLTRB(0, 0, 24, 24),
//        Rect.fromLTRB(startOffset, top, startOffset + spacing/2, top + spacing / 2), _tickPaint);
        Rect harmonyBounds = Rect.fromLTRB(left, top, left + standardBeatWidth, top + harmonyHeight);
        _renderHarmonyBeat(harmonyBounds, renderingSection, renderingSectionBeat, canvas);
        top = top + harmonyHeight;

//      print("renderingSectionBeat=$renderingSectionBeat");

        staves.value.forEach((staff) {
          staff.getParts(score, staves.value).forEach((part) {
            double partOffset = partTopOffsets.value.putIfAbsent(part.id, () => 0);
            List<Melody> melodiesToRender = renderingSection.melodies
                .where((melodyReference) => melodyReference.playbackType != MelodyReference_PlaybackType.disabled)
                .where((ref) => part.melodies.any((melody) => melody.id == ref.melodyId))
                .map((it) => score.melodyReferencedBy(it))
                .toList();
            //        canvas.save();
            //        canvas.translate(0, partOffset);
            Rect melodyBounds = Rect.fromLTRB(left, top + partOffset, right, top + partOffset + melodyHeight);
            // if (!drawContinuousColorGuide) {
            //   _renderSubdividedColorGuide(
            //     renderingHarmony, melodyBounds, renderingSection, renderingSectionBeat, canvas);
            // }
            _renderMelodies(melodiesToRender, canvas, melodyBounds, renderingSection, renderingSectionBeat,
                renderingBeat, left, staff, staves.value);
            //        canvas.restore();
          });
        });
      }
      left += standardBeatWidth;
      renderingBeat += 1;
    }
//    if (drawContinuousColorGuide) {
//      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
//    }
    final endTime = DateTime.now().millisecondsSinceEpoch;
//    print("MelodyPainter draw time from beat $startBeat, : ${endTime - startTime}ms");
  }

  void _renderMelodies(
      List<Melody> melodiesToRender,
      Canvas canvas,
      Rect melodyBounds,
      Section renderingSection,
      int renderingSectionBeat,
      int renderingBeat,
      double left,
      MusicStaff staff,
      Iterable<MusicStaff> staffConfiguration) {
    double blackOpacity = 0;
    if (melodyViewMode != MelodyViewMode.score && renderingSection.id != section.id) {
      blackOpacity = 0.12;
    }
    canvas.drawRect(
        melodyBounds, Paint()..color = Colors.black.withOpacity(blackOpacity /* * colorblockOpacityNotifier.value*/));

    var renderQueue = List<Melody>.from(melodiesToRender.where((it) => it != focusedMelody));
    renderQueue.sort((a, b) => -a.averageTone.compareTo(b.averageTone));
    renderQueue.removeWhere((element) => element.midiData.data.keys.isEmpty);
    int index = 0;
    Map<double, bool> averageToneToStemsUp = Map();
    while (renderQueue.isNotEmpty) {
      // Draw highest Melody stems up, lowest stems down, second lowest stems up, second highest
      // down. And repeat.
      Melody melody;
      bool stemsUp;
      switch ((index + 4) % 4) {
        case 0:
          melody = renderQueue.removeAt(0);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        case 1:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
          break;
        case 2:
          melody = renderQueue.removeAt(renderQueue.length - 1);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => true);
          break;
        default:
          melody = renderQueue.removeAt(0);
          stemsUp = averageToneToStemsUp.putIfAbsent(melody.averageTone, () => false);
      }

      _renderMelodyBeat(canvas, melody, melodyBounds, renderingSection, renderingSectionBeat, stemsUp,
          (focusedMelody == null) ? 1 : 0.2, renderQueue);
      index++;
    }

    if (focusedMelody != null) {
      final part = score.parts.firstWhere((p) => p.melodies.any((m) => m.id == focusedMelodyId));
      final parts = staff.getParts(score, staffConfiguration);
      if (parts.any((p) => p.id == part.id)) {
        double opacity = 1;
        if (!melodiesToRender.contains(focusedMelody)) {
          opacity = 0.6;
        }
        _renderMelodyBeat(
            canvas, focusedMelody, melodyBounds, renderingSection, renderingSectionBeat, true, opacity, renderQueue,
            renderLoopStarts: true);
      }
    }

    try {
      if (renderingBeat != 0) {
        _renderMeasureLines(renderingSection, renderingSectionBeat, melodyBounds, canvas);
      }
    } catch (e) {
      print("exception rendering measure lines: $e");
    }

    if (isCurrentScore && renderingSection == section && renderingSectionBeat == BeatScratchPlugin.currentBeat.value) {
      _renderCurrentBeat(canvas, melodyBounds, renderingSection, renderingSectionBeat, renderQueue, staff);
    } else if (isCurrentScore &&
            renderingSection == section &&
            renderingSectionBeat + firstBeatOfSection == highlightedBeat.value /* && BeatScratchPlugin.playing*/
        ) {
      canvas.drawRect(
          melodyBounds,
          Paint()
            ..style = PaintingStyle.fill
            ..color = sectionColor.value.withAlpha(55));
    }
  }

  void _renderStaffLines(Canvas canvas, bool drawContinuousColorGuide, Rect bounds) {
    if (notationOpacityNotifier.value > 0) {
      MelodyStaffLinesRenderer()
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..draw(canvas);
    }
    if (drawContinuousColorGuide && colorGuideAlpha > 0) {
      this.drawContinuousColorGuide(canvas, bounds.top - harmonyHeight, bounds.bottom);
    }
  }

  void _renderClefs(Canvas canvas, Rect bounds, MusicStaff staff) {
    if (notationOpacityNotifier.value > 0) {
      var clefs = (staff is DrumStaff || (staff is PartStaff && staff.part.isDrum))
          ? [Clef.drum_treble, Clef.drum_bass]
          : [Clef.treble, Clef.bass];
      MelodyClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha((255 * notationOpacityNotifier.value).toInt()))
        ..bounds = bounds
        ..clefs = clefs
        ..draw(canvas);
    }
    if (colorblockOpacityNotifier.value > 0) {
      MelodyPianoClefRenderer()
        ..xScale = xScale
        ..yScale = yScale
        ..alphaDrawerPaint = (Paint()..color = Colors.black.withAlpha(255 * colorblockOpacityNotifier.value ~/ 3))
        ..bounds = bounds
        ..draw(canvas);
    }

    if (staff.getParts(score, staves.value).any((element) => element.id == focusedPart.value?.id)) {
      Rect highlight = Rect.fromPoints(
          bounds.topLeft.translate(-bounds.width / 13, notationOpacityNotifier.value * bounds.height / 6),
          bounds.bottomRight.translate(0, notationOpacityNotifier.value * -bounds.height / 10));
      canvas.drawRect(highlight, Paint()..color = sectionColor.value.withAlpha(127));
    }

    String text;
    if (staff is PartStaff) {
      text = staff.part.midiName;
    } else if (staff is AccompanimentStaff) {
      text = "Accompaniment";
    } else {
      text = "Drums";
    }

    TextSpan span = new TextSpan(
        text: text,
        style: TextStyle(
            fontFamily: "VulfSans",
            fontSize: max(11, 20 * yScale),
            fontWeight: FontWeight.w800,
            color: colorblockOpacityNotifier.value > 0.5 ? Colors.black87 : Colors.black));
    TextPainter tp = new TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, bounds.topLeft.translate(5 * xScale, 7 * yScale));
  }

  Melody _colorboardDummyMelody = defaultMelody()
    ..id = "colorboardDummy"
    ..subdivisionsPerBeat = 1
    ..length = 1;
  Melody _keyboardDummyMelody = defaultMelody()
    ..id = "keyboardDummy"
    ..subdivisionsPerBeat = 1
    ..length = 1;

  void _renderCurrentBeat(Canvas canvas, Rect melodyBounds, Section renderingSection, int renderingSectionBeat,
      Iterable<Melody> otherMelodiesOnStaff, MusicStaff staff,
      {Paint backgroundPaint}) {
    canvas.drawRect(
        melodyBounds,
        backgroundPaint ?? Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black26);
    var staffParts = staff.getParts(score, staves.value);
    bool hasColorboardPart = staffParts.any((part) => part.id == colorboardPart.value?.id);
    bool hasKeyboardPart = staffParts.any((part) => part.id == keyboardPart.value?.id);
    if (hasColorboardPart || hasKeyboardPart) {
      _colorboardDummyMelody.setMidiDataFromSimpleMelody({0: colorboardNotesNotifier.value.toList()});
      _keyboardDummyMelody.setMidiDataFromSimpleMelody(
          {0: keyboardNotesNotifier.value.followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value).toList()});
      // Stem will be up
      double avgColorboardNote = colorboardNotesNotifier.value.isEmpty
          ? -100
          : colorboardNotesNotifier.value.reduce((a, b) => a + b) / colorboardNotesNotifier.value.length.toDouble();
      double avgKeyboardNote = keyboardNotesNotifier.value.isEmpty
          ? -100
          : keyboardNotesNotifier.value.reduce((a, b) => a + b) / keyboardNotesNotifier.value.length.toDouble();

      _keyboardDummyMelody.instrumentType = keyboardPart?.value?.instrument?.type ?? InstrumentType.harmonic;
      if (hasColorboardPart) {
        _renderMelodyBeat(canvas, _colorboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat,
            avgColorboardNote > avgKeyboardNote, 1, otherMelodiesOnStaff);
      }
      if (hasKeyboardPart) {
        _renderMelodyBeat(canvas, _keyboardDummyMelody, melodyBounds, renderingSection, renderingSectionBeat,
            avgColorboardNote <= avgKeyboardNote, 1, otherMelodiesOnStaff);
      }
    }
  }

  void _renderMeasureLines(Section renderingSection, int renderingSectionBeat, Rect melodyBounds, Canvas canvas) {
    double opacityFactor = 1;
    if (melodyViewMode != MelodyViewMode.score && renderingSection.id != section.id) {
      int rsIndex = score.sections.indexWhere((s) => s.id == renderingSection.id);
      if (rsIndex > 0 && renderingSectionBeat == 0 && score.sections[rsIndex - 1].id == section.id) {
      } else
        opacityFactor *= 0.25;
    }
    MelodyMeasureLinesRenderer()
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..notationAlpha = notationOpacityNotifier.value * opacityFactor
      ..colorblockAlpha = colorblockOpacityNotifier.value * opacityFactor
      ..overallBounds = melodyBounds
      ..draw(canvas, 1);
  }

  void _renderSubdividedColorGuide(
      Harmony renderingHarmony, Rect melodyBounds, Section renderingSection, int renderingSectionBeat, Canvas canvas) {
    try {
      Melody colorGuideMelody = focusedMelody;
      if (colorGuideMelody == null) {
        colorGuideMelody = Melody()
          ..id = uuid.v4()
          ..subdivisionsPerBeat = renderingHarmony.subdivisionsPerBeat
          ..length = renderingHarmony.length;
      }
      //          if(colorblockOpacityNotifier.value > 0) {
      MelodyColorGuide()
        ..overallBounds = melodyBounds
        ..section = renderingSection
        ..beatPosition = renderingSectionBeat
        ..section = renderingSection
        ..drawPadding = 3
        ..nonRootPadding = 3
        ..drawnColorGuideAlpha = colorGuideAlpha
        ..isUserChoosingHarmonyChord = false
        ..isMelodyReferenceEnabled = true
        ..melody = colorGuideMelody
        ..drawColorGuide(canvas);
      //          }
    } catch (t) {
      print("failed to draw colorguide: $t");
    }
  }

  void _renderHarmonyBeat(Rect harmonyBounds, Section renderingSection, int renderingSectionBeat, Canvas canvas) {
    HarmonyBeatRenderer()
      ..overallBounds = harmonyBounds
      ..section = renderingSection
      ..beatPosition = renderingSectionBeat
      ..draw(canvas);
  }

  _renderMelodyBeat(Canvas canvas, Melody melody, Rect melodyBounds, Section renderingSection, int renderingSectionBeat,
      bool stemsUp, double alpha, Iterable<Melody> otherMelodiesOnStaff,
      {bool renderLoopStarts = false}) {
    double opacityFactor = 1;
    if (melodyBounds.left < visibleRect().left + standardBeatWidth) {
      opacityFactor = max(0, min(1, (melodyBounds.left - visibleRect().left) / standardBeatWidth));
    }
    if (melodyViewMode != MelodyViewMode.score && renderingSection.id != section.id) {
      opacityFactor *= 0.25;
    }
    if (melody != null) {
      if (renderLoopStarts &&
          renderingSectionBeat % (melody.length / melody.subdivisionsPerBeat) == 0 &&
          renderingSection.id == section.id) {
        Rect highlight = Rect.fromPoints(melodyBounds.topLeft.translate(-melodyBounds.width / 13, 0),
            melodyBounds.bottomLeft.translate(melodyBounds.width / 13, 0));
        canvas.drawRect(highlight, Paint()..color = sectionColor.value.withAlpha(127));
      }
      try {
        if (colorblockOpacityNotifier.value > 0) {
          ColorblockMelodyRenderer()
            ..uiScale = xScale
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..colorblockAlpha = colorblockOpacityNotifier.value * alpha * opacityFactor
            ..drawPadding = 3
            ..nonRootPadding = 3
            ..isUserChoosingHarmonyChord = false
            ..isMelodyReferenceEnabled = true
            ..melody = melody
            ..draw(canvas);
        }
      } catch (e, s) {
        print("exception rendering colorblock: $e: \n$s");
      }
      try {
        if (notationOpacityNotifier.value > 0) {
          NotationMelodyRenderer()
            ..otherMelodiesOnStaff = otherMelodiesOnStaff
            ..xScale = xScale
            ..yScale = yScale
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..notationAlpha = notationOpacityNotifier.value * alpha * opacityFactor
            ..drawPadding = 3
            ..nonRootPadding = 3
            ..stemsUp = stemsUp
            ..isUserChoosingHarmonyChord = false
            ..isMelodyReferenceEnabled = true
            ..melody = melody
            ..draw(canvas);
        }
      } catch (e, s) {
        print("exception rendering notation: $e: \n$s");
      }
    }
  }

  drawContinuousColorGuide(Canvas canvas, double top, double bottom) {
    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor() - 2;

    final double startOffset = renderingBeat * standardBeatWidth;
    double left = startOffset;
    double chordLeft = left;
    Chord renderingChord;

    while (left < visibleRect().right + standardBeatWidth) {
      if (renderingBeat < 0) {
        left += standardBeatWidth;
        renderingBeat += 1;
        continue;
      }
      int renderingSectionBeat = renderingBeat;
      Section renderingSection = this.section;
      if (renderingSection == null) {
        int _beat = 0;
        Section candidate = score.sections[0];
        while (_beat + candidate.beatCount <= renderingBeat) {
          _beat += candidate.beatCount;
          renderingSectionBeat -= candidate.beatCount;
        }
        renderingSection = candidate;
      }
      Harmony renderingHarmony = renderingSection.harmony;
      double beatLeft = left;
      for (int renderingSubdivision in range(renderingSectionBeat * renderingHarmony.subdivisionsPerBeat,
          (renderingSectionBeat + 1) * renderingHarmony.subdivisionsPerBeat - 1)) {
        Chord chordAtSubdivision =
            renderingHarmony.changeBefore(renderingSubdivision) ?? cChromatic; //TODO Is this default needed?
        if (renderingChord == null) {
          renderingChord = chordAtSubdivision;
        }
        if (renderingChord != chordAtSubdivision) {
          Rect renderingRect = Rect.fromLTRB(chordLeft, top, left, bottom);
          try {
            ColorGuide()
              ..renderVertically = true
              ..alphaDrawerPaint = Paint()
              ..halfStepsOnScreen = 88
              ..normalizedDevicePitch = 0
              ..bounds = renderingRect
              ..chord = renderingChord
              ..drawPadding = 0
              ..nonRootPadding = 0
              ..drawnColorGuideAlpha = colorGuideAlpha
              ..drawColorGuide(canvas);
          } catch (t) {
            print("failed to draw colorguide: $t");
          }
          chordLeft = left;
        }
        renderingChord = chordAtSubdivision;
        left += standardBeatWidth / renderingHarmony.subdivisionsPerBeat;
      }
      left = beatLeft + standardBeatWidth;
      renderingBeat += 1;
    }
    Rect renderingRect = Rect.fromLTRB(chordLeft, top + harmonyHeight, left, bottom);
    try {
      ColorGuide()
        ..renderVertically = true
        ..alphaDrawerPaint = Paint()
        ..halfStepsOnScreen = 88
        ..normalizedDevicePitch = 0
        ..bounds = renderingRect
        ..chord = renderingChord
        ..drawPadding = 0
        ..nonRootPadding = 0
        ..drawnColorGuideAlpha = colorGuideAlpha
        ..drawColorGuide(canvas);
    } catch (t) {
      print("failed to draw colorguide: $t");
    }
  }

  @override
  bool shouldRepaint(MusicSystemPainter oldDelegate) {
    return false;
  }
}

class _NoBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class _LimitedScrollableScrollPhysics extends ScrollPhysics {
  final double minBound;
  final double maxBound;

  /// Creates scroll physics that does not let the user scroll.
  const _LimitedScrollableScrollPhysics({
    ScrollPhysics parent,
    this.minBound,
    this.maxBound,
  }) : super(parent: parent);

  @override
  _LimitedScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return _LimitedScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (minBound != null && maxBound != null) {
      return minBound <= position.pixels && position.pixels <= maxBound;
    } else if (minBound != null) {
      return minBound <= position.pixels;
    } else if (maxBound != null) {
      return position.pixels <= maxBound;
    }
    return true;
  }

// @override
// bool get allowImplicitScrolling => false;
}
