import 'package:flutter/material.dart';

import '../colors.dart';
import '../util/music_theory.dart';
import 'canvas_tone_drawer.dart';

class ColorGuide extends CanvasToneDrawer {
  late int colorGuideAlpha;
  late int drawPadding;
  late int nonRootPadding;
  late int drawnColorGuideAlpha;
  Iterable<int> pressedNotes = [];

  drawColorGuide(Canvas canvas) {
    if (colorGuideAlpha == 0) {
      return;
    }
    alphaDrawerPaint.preserveProperties(() {
      var halfStepPhysicalDistance = axisLength / halfStepsOnScreen;
      visiblePitches.forEach((visiblePitch) {
        var tone = visiblePitch.tone;
        var toneBounds = visiblePitch.bounds;
        var toneInChord = chord.closestTone(tone);
        alphaDrawerPaint.color =
            chromaticSteps[(toneInChord - chord.rootNote.tone).mod12]
                .withAlpha(drawnColorGuideAlpha);
        var extraPadding =
            (toneInChord.mod12 == chord.rootNote.tone) ? 0 : nonRootPadding;
        if (renderVertically) {
          canvas.drawRect(
              Rect.fromLTRB(
                  toneBounds.left + drawPadding + extraPadding,
                  toneBounds.top,
                  toneBounds.right - drawPadding - extraPadding,
                  toneBounds.bottom),
              alphaDrawerPaint);
          if (tone == toneInChord) {
            alphaDrawerPaint.color = Color(0x11212121)
                .withAlpha((drawnColorGuideAlpha * 0.1).toInt());
            canvas.drawRect(
                Rect.fromLTRB(
                    toneBounds.left,
                    toneBounds.top - .183 * halfStepPhysicalDistance,
                    toneBounds.right,
                    toneBounds.bottom + .183 * halfStepPhysicalDistance),
                alphaDrawerPaint);
          }
          if (pressedNotes.contains(tone)) {
            alphaDrawerPaint.color = Color(0x11212121)
                .withAlpha((drawnColorGuideAlpha * 0.3).toInt());
            canvas.drawRect(
                Rect.fromLTRB(
                    toneBounds.left,
                    toneBounds.top - .183 * halfStepPhysicalDistance,
                    toneBounds.right,
                    toneBounds.bottom + .183 * halfStepPhysicalDistance),
                alphaDrawerPaint);
          }
        } else {
          // Horizontal rendering
          canvas.drawRect(
              Rect.fromLTRB(
                  toneBounds.left,
                  toneBounds.top + drawPadding + extraPadding,
                  toneBounds.right,
                  toneBounds.bottom - drawPadding - extraPadding),
              alphaDrawerPaint);
          if (tone == toneInChord) {
            alphaDrawerPaint.color = Color(0x11212121)
                .withAlpha((drawnColorGuideAlpha * 0.1).toInt());
            canvas.drawRect(
                Rect.fromLTRB(
                    toneBounds.left + .183 * halfStepPhysicalDistance,
                    toneBounds.top + drawPadding + extraPadding,
                    toneBounds.right - .183 * halfStepPhysicalDistance,
                    toneBounds.bottom - drawPadding - extraPadding),
                alphaDrawerPaint);
          }
          if (pressedNotes.contains(tone)) {
            alphaDrawerPaint.color = Color(0x11212121)
                .withAlpha((drawnColorGuideAlpha * 0.3).toInt());
            canvas.drawRect(
                Rect.fromLTRB(
                    toneBounds.left + .183 * halfStepPhysicalDistance,
                    toneBounds.top + drawPadding + extraPadding,
                    toneBounds.right - .183 * halfStepPhysicalDistance,
                    toneBounds.bottom - drawPadding - extraPadding),
                alphaDrawerPaint);
          }
          if (tone.mod12 == 0) {
//            alphaDrawerPaint.color = Colors.black;
            TextSpan span = new TextSpan(
                text: (4 + (tone / 12)).toInt().toString(),
                style: TextStyle(
                    fontFamily: "VulfSans",
                    fontWeight: FontWeight.w500,
                    color: Colors.white));
            TextPainter tp = new TextPainter(
              text: span,
              strutStyle: StrutStyle(
                  fontFamily: "VulfSans", fontWeight: FontWeight.w800),
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            );
            tp.layout();
            tp.paint(
                canvas,
                new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4,
                    toneBounds.bottom - 30));
          }
        }
      });
    });
  }
}
