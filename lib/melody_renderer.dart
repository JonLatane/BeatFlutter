import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:beatscratch_flutter_redux/drawing/harmony_beat_renderer.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/colorblock_melody_renderer.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody_color_guide.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/melody_staff_lines_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unification/unification.dart';
import 'drawing/color_guide.dart';
import 'drawing/drawing.dart';
import 'melody_view.dart';
import 'section_list.dart';
import 'part_melodies_view.dart';
import 'colorboard.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'util.dart';
import 'ui_models.dart';
import 'dummydata.dart';
import 'music_theory.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

const double unscaledStandardBeatWidth = 60.0;

class MelodyRenderer extends StatefulWidget {
  final Score score;
  final Section section;
  final Melody focusedMelody;
  final RenderingMode renderingMode;
  final double xScale;
  final double yScale;

  const MelodyRenderer({Key key, this.score, this.section, this.xScale, this.yScale, this.focusedMelody, this.renderingMode})
      : super(key: key);

  @override
  _MelodyRendererState createState() => _MelodyRendererState();
}

Rect _visibleRect = Rect.zero;

class _MelodyRendererState extends State<MelodyRenderer> with TickerProviderStateMixin {
  bool get isViewingSection => widget.section != null;

  int get numberOfBeats => isViewingSection ? widget.section.harmony.beatCount : widget.score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * widget.xScale;

  double get width => numberOfBeats * standardBeatWidth;

  ScrollController verticalController = ScrollController();
  static const double heightFactor = 800;

  AnimationController configurationChangeAnimationController;
  ValueNotifier<double> colorblockOpacityNotifier;
  ValueNotifier<double> notationOpacityNotifier;

  @override
  void initState() {
    super.initState();
    configurationChangeAnimationController = AnimationController(vsync: this,
      duration: Duration(milliseconds: 500));
    if(colorblockOpacityNotifier == null) colorblockOpacityNotifier = ValueNotifier(0);
    if(notationOpacityNotifier == null) notationOpacityNotifier = ValueNotifier(0);
  }

  @override
  Widget build(BuildContext context) {
    String key = widget.score.id;
    if(widget.section != null) {
      key = widget.section.toString();
    }
    double colorblockOpacityValue = (widget.renderingMode == RenderingMode.colorblock) ? 1 : 0;
    double notationOpacityValue = (widget.renderingMode == RenderingMode.notation) ? 1 : 0;
    Animation animation1;
    animation1 = Tween<double>(begin: colorblockOpacityNotifier.value, end: colorblockOpacityValue)
      .animate(configurationChangeAnimationController)
      ..addListener(() {
        colorblockOpacityNotifier.value = animation1.value;
//                setState(() {});
      });
    Animation animation2;
    animation2 = Tween<double>(begin: notationOpacityNotifier.value, end: notationOpacityValue)
      .animate(configurationChangeAnimationController)
      ..addListener(() {
        notationOpacityNotifier.value = animation2.value;
//                setState(() {});
      });
    configurationChangeAnimationController.forward(from:0);
    return SingleChildScrollView(
        key: Key(key),
        child: Container(
            height: heightFactor * widget.yScale,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: [
                new CustomSliverToBoxAdapter(
                  setVisibleRect: (rect) {
                    _visibleRect = rect;
                  },
                  child: CustomPaint(
                    size: Size(width, heightFactor * widget.yScale),
                    painter: new _MelodyPainter(
                        score: widget.score,
                        section: widget.section,
                        xScale: widget.xScale,
                        yScale: widget.yScale,
                        focusedMelody: widget.focusedMelody,
                        colorblockOpacityNotifier: colorblockOpacityNotifier,
                        notationOpacityNotifier: notationOpacityNotifier,
                        visibleRect: () => _visibleRect,
                        staffReferences: [_AccompanimentReference(), _DrumTrackReference()]),
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
}

class _StaffReference {
  final Part part;
  final bool isAccompaniment = false;
  double xPosition = 0.0;

  _StaffReference(this.part);
}

class _AccompanimentReference extends _StaffReference {
  @override
  bool isAccompaniment = true;

  _AccompanimentReference() : super(null);
}

class _DrumTrackReference extends _StaffReference {
  @override
  bool isAccompaniment = true;

  _DrumTrackReference() : super(null);
}

class _MelodyPainter extends CustomPainter {
  final Melody focusedMelody;
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  final List<_StaffReference> staffReferences;
  final ValueNotifier<double> colorblockOpacityNotifier;
  final ValueNotifier<double> notationOpacityNotifier;

  bool get isViewingSection => section != null;

  int get numberOfBeats => isViewingSection ? section.harmony.beatCount : score.beatCount;

  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;

  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;
  int get colorGuideAlpha => (255 * colorblockOpacityNotifier.value).toInt();

  _MelodyPainter(
      {this.score, this.section, this.xScale, this.yScale, this.visibleRect, this.staffReferences, this.focusedMelody,
        this.colorblockOpacityNotifier, this.notationOpacityNotifier}) : super(
    repaint: Listenable.merge([colorblockOpacityNotifier, notationOpacityNotifier])
  ) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100, 30 * yScale);

  @override
  void paint(Canvas canvas, Size size) {
    bool drawContinuousColorGuide = xScale <= 1;
    var rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    final double startOffset = renderingBeat * standardBeatWidth;
    double left = startOffset;
    double right;

    MelodyStaffLinesRenderer()
      ..bounds = visibleRect()//Rect.fromLTRB(visibleRect().left, visibleRect().top + harmonyHeight, visibleRect().right, visibleRect().bottom)
      ..draw(canvas);
    if (drawContinuousColorGuide) {
      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
    }

    print("Drawing frame from beat=$renderingBeat. Colorblock alpha is ${colorblockOpacityNotifier.value}. Notation alpha is ${notationOpacityNotifier.value}");
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
        int sectionIndex = 0;
        Section candidate = score.sections[sectionIndex];
        while (_beat + candidate.beatCount <= renderingBeat) {
          _beat += candidate.beatCount;
          renderingSectionBeat -= candidate.beatCount;
          sectionIndex += 1;
          if(sectionIndex < score.sections.length) {
            candidate = score.sections[sectionIndex];
          } else {
            candidate = null;
            break;
          }
        }
        renderingSection = candidate;
      }
      if(renderingSection == null) {
        break;
      }
      Harmony renderingHarmony = renderingSection.harmony;
      right = left + standardBeatWidth;
      String sectionName = renderingSection.name;
      if(sectionName == null || sectionName.isEmpty) {
        sectionName = renderingSection.id;
      }
//      print("Drawing beat $renderingBeat out of section $sectionName as beat $renderingSectionBeat");
//      canvas.drawLine(Offset(left, 0), Offset(left, rect.height), _tickPaint);
      double top = visibleRect().top;
//      canvas.drawImageRect(filledNotehead, Rect.fromLTRB(0, 0, 24, 24),
//        Rect.fromLTRB(startOffset, top, startOffset + spacing/2, top + spacing / 2), _tickPaint);
      Rect harmonyBounds = Rect.fromLTRB(left, top, left + standardBeatWidth, top + harmonyHeight);
      HarmonyBeatRenderer()
        ..overallBounds = harmonyBounds
        ..section = renderingSection
        ..beatPosition = renderingSectionBeat
        ..draw(canvas);
      top = top + harmonyHeight;

      Rect melodyBounds = Rect.fromLTRB(left, top, right, visibleRect().bottom);
      if (!drawContinuousColorGuide) {
        try {
          Melody colorGuideMelody = focusedMelody;
          if (colorGuideMelody == null) {
            colorGuideMelody = Melody()
              ..id = uuid.v4()
              ..subdivisionsPerBeat = renderingHarmony.subdivisionsPerBeat
              ..length = renderingHarmony.length;
          }
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
        } catch(t) {
          print("failed to draw colorguide: $t");
        }
      }
      renderingSection.melodies
        .where((melodyReference) => melodyReference.playbackType != MelodyReference_PlaybackType.disabled)
        .forEach((melodyReference) {
        Melody melody = score.melodyReferencedBy(melodyReference);
        if(melody != null) {
          ColorblockMelodyRenderer()
            ..overallBounds = melodyBounds
            ..section = renderingSection
            ..beatPosition = renderingSectionBeat
            ..section = renderingSection
            ..colorblockAlpha = colorblockOpacityNotifier.value
            ..drawPadding = 3
            ..nonRootPadding = 3
            ..isUserChoosingHarmonyChord = false
            ..isMelodyReferenceEnabled = true
            ..melody = melody
            ..draw(canvas);
        }
      });
      drawFilledNotehead(canvas, Rect.fromLTRB(left, top, left + standardBeatWidth / 2, top + standardBeatWidth / 2));

      left += standardBeatWidth;
      renderingBeat += 1;
    }
//    if (drawContinuousColorGuide) {
//      this.drawContinuousColorGuide(canvas, visibleRect().top, visibleRect().bottom);
//    }
  }

  drawContinuousColorGuide(Canvas canvas, double top, double bottom) {
    // Calculate from which beat we should start drawing
    int renderingBeat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

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
      for(int renderingSubdivision in range(
        renderingSectionBeat * renderingHarmony.subdivisionsPerBeat,
        (renderingSectionBeat + 1) * renderingHarmony.subdivisionsPerBeat - 1
      )) {
        Chord chordAtSubdivision =
          renderingHarmony.changeBefore(renderingSubdivision) ?? cChromatic; //TODO Is this default needed?
        if (renderingChord == null) {
          renderingChord = chordAtSubdivision;
        }
        if (renderingChord != chordAtSubdivision) {
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
          } catch(t) {
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
    } catch(t) {
      print("failed to draw colorguide: $t");
    }
  }

  drawFilledNotehead(Canvas canvas, Rect rect) {
//    canvas.drawRect(rect, _tickPaint);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.58171824);
    var target = rect.shift(-rect.center);
    target = Rect.fromCenter(center: target.center, width: target.width, height: target.height * 0.7777777);
    canvas.drawOval(target, _tickPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MelodyPainter oldDelegate) {
    return false;
  }
}
