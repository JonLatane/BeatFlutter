import 'dart:async';
import 'dart:typed_data';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

const double unscaledStandardBeatWidth = 20.0;

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
class _MelodyRendererState extends State<MelodyRenderer> {
  bool get isViewingSection => widget.section != null;
  int get numberOfBeats => isViewingSection ? widget.section.harmony.beatCount : widget.score.beatCount;
  double get standardBeatWidth => unscaledStandardBeatWidth * widget.xScale;
  double get width => numberOfBeats * standardBeatWidth;



  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: Axis.horizontal,
      slivers: [
        new CustomSliverToBoxAdapter(
          setVisibleRect: (rect) { _visibleRect = rect; },
          child: _MelodyPaint(
            score: widget.score,
            section: widget.section,
            xScale: widget.xScale,
            yScale: widget.yScale,
            visibleRect: () => _visibleRect,
            width: width,
          ),
        )
      ],
    );
  }
}

class _MelodyPaint extends CustomPaint {
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final double width;
  final Rect Function() visibleRect;


  _MelodyPaint({this.width, this.score, this.section, this.xScale, this.yScale,this.visibleRect,})
      : super(
          size: Size(width, 60.0),
          painter: new _MelodyPainter(
            score: score,
            section: section,
            xScale: xScale,
            yScale: yScale,
            visibleRect: visibleRect,
          ),
        );
}

class _MelodyPainter extends CustomPainter {
  final Score score;
  final Section section;
  final double xScale;
  final double yScale;
  final Rect Function() visibleRect;
  bool get isViewingSection => section != null;
  int get numberOfBeats => isViewingSection ? section.harmony.beatCount : score.beatCount;
  double get standardBeatWidth => unscaledStandardBeatWidth * xScale;
  double get width => standardBeatWidth * numberOfBeats;
  Paint _tickPaint = Paint()..style = PaintingStyle.fill;

  _MelodyPainter({this.score, this.section, this.xScale, this.yScale,this.visibleRect, }) {
    _tickPaint.color = Colors.black;
    _tickPaint.strokeWidth = 2.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
//    canvas.clipRect(rect);

    // Extend drawing window to compensate for element sizes - avoids lines at either end "popping" into existence
    var extend = _tickPaint.strokeWidth / 2.0;

    // Calculate from which Tick we should start drawing
    var tick = ((visibleRect().left - extend) / standardBeatWidth).floor();

    var startOffset = tick * standardBeatWidth;
    var o1 = new Offset(startOffset, 0.0);
    var o2 = new Offset(startOffset, rect.height);

    while (o1.dx < visibleRect().right + extend) {
      canvas.drawLine(o1, o2, _tickPaint);
      double top = ((o1.dx * 59 % width)/ width) * rect.height;
      drawFilledNotehead(canvas, Rect.fromLTRB(o1.dx, top, o1.dx + standardBeatWidth / 2, top + standardBeatWidth / 2));
//      canvas.drawImageRect(filledNotehead, Rect.fromLTRB(0, 0, 24, 24),
//        Rect.fromLTRB(startOffset, top, startOffset + spacing/2, top + spacing / 2), _tickPaint);
      o1 = o1.translate(standardBeatWidth, 0.0);
      o2 = o2.translate(standardBeatWidth, 0.0);
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
