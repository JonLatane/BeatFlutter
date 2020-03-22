import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

//import 'sizeutil.dart';
import '../generated/protos/music.pb.dart';
import 'package:unification/unification.dart';
import '../music_theory.dart';
import '../colors.dart';
import 'canvas_tone_drawer.dart';

extension WithAlpha on Color {
  Color withAlpha(int alpha) => Color.fromARGB(alpha, red, green, blue);
}

class ColorGuide extends CanvasToneDrawer {
  int colorGuideAlpha;
  int drawPadding;
  int nonRootPadding;
  int drawnColorGuideAlpha;

  drawColorGuide(Canvas canvas) {
    alphaDrawerPaint.preserveColor(() {
      var halfStepPhysicalDistance = axisLength / halfStepsOnScreen;
      visiblePitches.forEach((visiblePitch) {
        var tone = visiblePitch.tone;
        var toneBounds = visiblePitch.bounds;
        var toneInChord = chord.closestTone(tone);
        alphaDrawerPaint.color = chromaticSteps[(toneInChord - chord.rootNote.tone).mod12]
          .withAlpha(drawnColorGuideAlpha);
        var extraPadding = (toneInChord.mod12 == chord.rootNote.tone) ? 0 : nonRootPadding;
        if (renderVertically) {
          canvas.drawRect(
              Rect.fromLTRB(toneBounds.left + drawPadding + extraPadding, toneBounds.top,
                  toneBounds.right - drawPadding - extraPadding, toneBounds.bottom),
              alphaDrawerPaint);
          if (tone == toneInChord) {
            alphaDrawerPaint.color = Color(0x11212121);
            canvas.drawRect(
                Rect.fromLTRB(toneBounds.left, toneBounds.top - .183 * halfStepPhysicalDistance, toneBounds.right,
                    toneBounds.bottom + .183 * halfStepPhysicalDistance),
                alphaDrawerPaint);
          }
        } else {
          canvas.drawRect(
              Rect.fromLTRB(toneBounds.left, toneBounds.top + drawPadding + extraPadding, toneBounds.right,
                  toneBounds.bottom - drawPadding - extraPadding),
              alphaDrawerPaint);
          if (tone == toneInChord) {
            alphaDrawerPaint.color = Color(0x11212121);
            canvas.drawRect(
                Rect.fromLTRB(
                    toneBounds.left + .183 * halfStepPhysicalDistance,
                    toneBounds.top + drawPadding + extraPadding,
                    toneBounds.right - .183 * halfStepPhysicalDistance,
                    toneBounds.bottom - drawPadding - extraPadding),
                alphaDrawerPaint);
          }
          if(tone.mod12 == 0) {
//            alphaDrawerPaint.color = Colors.black;
            TextSpan span = new TextSpan(text: (4 + (tone/12)).toInt().toString());
            TextPainter tp = new TextPainter(strutStyle: StrutStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w900),
              text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr,);
            tp.layout();
            tp.paint(canvas, new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4, toneBounds.bottom - 30));
          }
        }
      });
    });
  }
}
