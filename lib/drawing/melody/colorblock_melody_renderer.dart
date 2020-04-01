import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'base_melody_renderer.dart';

class ColorblockMelodyRenderer extends BaseMelodyRenderer {
  @override
  bool showSteps = true;
  @override
  double normalizedDevicePitch = 0;

  @override
  double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  double colorblockAlpha;

  draw(Canvas canvas) {
    alphaDrawerPaint.strokeWidth = 0;
    bounds = overallBounds;
    canvas.save();
    canvas.translate(0, bounds.top);
    _renderSteps(canvas);
    double alphaMultiplier = (isMelodyReferenceEnabled) ? 1.0 : 2.0 / 3;
    _drawColorblockMelody(
        canvas: canvas,
        alpha: colorblockAlpha * alphaMultiplier,);

    canvas.restore();
  }

  /// Renders the dividers that separate A, A#, B, C, etc. visually to the user
  _renderSteps(Canvas canvas) {
    alphaDrawerPaint.color = Colors.black87.withAlpha((colorblockAlpha * 255 * 0.8).toInt());
    if (showSteps) {
      var linePosition = startPoint;// - 12 * halfStepWidth;
      while (linePosition < axisLength) {
        if (renderVertically) {
          canvas.drawLine(
            Offset(bounds.left, linePosition),
            Offset(bounds.right, linePosition),
            alphaDrawerPaint
          );
        } else {
          canvas.drawLine(
            Offset(linePosition, bounds.top),
            Offset(linePosition, bounds.bottom),
            alphaDrawerPaint
          );
        }
        linePosition += halfStepWidth;
      }
    }
  }

  _drawColorblockMelody(
      {Canvas canvas, double alpha}) {
    iterateSubdivisions(() {
      _drawColorblockNotes(canvas: canvas, elementPosition: elementPosition, alpha: alpha);
      drawRhythm(canvas, alpha);

    });
//    if (drawRhythm) {
//      double overallWidth = overallBounds.right - overallBounds.left;
//      bounds = Rect.fromLTRB(overallWidth, bounds.top, overallWidth, bounds.bottom);
//      this.drawRhythm(canvas, alphaSource);
//    }
  }

  _drawColorblockNotes({Canvas canvas, int elementPosition, double alpha}) {
    MelodicAttack element = melody.melodicData.data[elementPosition % melody.length];
    MelodicAttack nextElement = melody.melodicData.data[elementPosition % melody.length];
    bool isChange = element != null;
    alphaDrawerPaint.color =
        ((isChange) ? Color(0xAA212121) : Color(0xAA424242)).withAlpha((alpha * 255).toInt());

    List<int> tones = [];
    if (element != null) {
      tones = element.tones;
    }

    if (tones.isNotEmpty) {
      double leftMargin = (isChange) ? drawPadding.toDouble() : 0.0;
      double rightMargin = (nextElement != null) ? drawPadding.toDouble() : 0.0;
      tones.forEach((tone) {
        int realTone = tone; // + melody.offsetUnder(chord)
        double top = bounds.height - bounds.height * (realTone - lowestPitch) / 88;
        double bottom = bounds.height - bounds.height * (realTone - lowestPitch + 1) / 88;
        canvas.drawRect(
            Rect.fromLTRB(bounds.left + leftMargin, top, bounds.right - rightMargin, bottom), alphaDrawerPaint);
      });
    }
  }
}
