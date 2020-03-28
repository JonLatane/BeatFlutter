import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:beatscratch_flutter_redux/drawing/harmony_beat_renderer.dart';
import 'package:beatscratch_flutter_redux/drawing/melody/colorblock_melody_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final double xScale;
  final double yScale;

  const MelodyRenderer({Key key, this.score, this.section, this.xScale, this.yScale}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(child:
    Container(height: heightFactor * widget.yScale, child:CustomScrollView(
      scrollDirection: Axis.horizontal,
      slivers: [
        new CustomSliverToBoxAdapter(
          setVisibleRect: (rect) { _visibleRect = rect; },
          child:CustomPaint(
            size: Size(width, heightFactor * widget.yScale),
            painter: new _MelodyPainter(
              score: widget.score,
              section: widget.section,
              xScale: widget.xScale,
              yScale: widget.yScale,
              visibleRect: () => _visibleRect,
              staffReferences: [
                _AccompanimentReference(),
                _DrumTrackReference()
              ]
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
}

class _StaffReference {
  final Part part;
  final bool isAccompaniment = false;
  double xPosition = 0.0;

  _StaffReference(this.part);
}

class _AccompanimentReference extends _StaffReference {
  @override bool isAccompaniment = true;
  _AccompanimentReference() : super(null);
}

class _DrumTrackReference extends _StaffReference {
  @override bool isAccompaniment = true;
  _DrumTrackReference() : super(null);
}

class _MelodyPainter extends CustomPainter {
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  final List<_StaffReference> staffReferences;
  bool get isViewingSection => section != null;
  int get numberOfBeats => isViewingSection ? section.harmony.beatCount : score.beatCount;
  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;
  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  _MelodyPainter({this.score, this.section, this.xScale, this.yScale,this.visibleRect, this.staffReferences, }) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  double get harmonyHeight => min(100,30 * yScale);

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    canvas.clipRect(rect);


    // Calculate from which Tick we should start drawing
    int beat = ((visibleRect().left - standardBeatWidth) / standardBeatWidth).floor();

    final double startOffset = beat * standardBeatWidth;
    double left = startOffset;
    double right;

    print("Drawing frame from beat=$beat");
    while (left < visibleRect().right + standardBeatWidth) {
      if(beat < 0) {
        left += standardBeatWidth;
        beat += 1;
        continue;
      }
      int renderingSectionBeat = beat;
      Section renderingSection = this.section;
      if(renderingSection == null) {
        int _beat = 0;
        Section candidate = score.sections[0];
        while(_beat + candidate.harmony.beatCount <= beat) {
          _beat += candidate.harmony.beatCount;
          renderingSectionBeat -= candidate.harmony.beatCount;
        }
        renderingSection = candidate;
      }
      right = left + standardBeatWidth;
      print("Drawing beat $beat out of section ${renderingSection.id} as beat $renderingSectionBeat");
      canvas.drawLine(Offset(left, 0), Offset(left, rect.height), _tickPaint);
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
      renderingSection.melodies.forEach((melodyReference) {
        Melody melody = score.melodyReferencedBy(melodyReference);
        ColorblockMelodyRenderer()
          ..overallBounds = melodyBounds
          ..section = renderingSection
          ..beatPosition = renderingSectionBeat
          ..section = renderingSection
          ..colorblockAlpha = 1
          ..drawPadding = 3
          ..nonRootPadding = 3
          ..drawnColorGuideAlpha = 255
          ..isUserChoosingHarmonyChord = false
          ..isMelodyReferenceEnabled = true
          ..melody = melody
          ..draw(canvas);
      });
      drawFilledNotehead(canvas, Rect.fromLTRB(left, top, left + standardBeatWidth / 2, top + standardBeatWidth / 2));



      left += standardBeatWidth;
      beat += 1;
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
