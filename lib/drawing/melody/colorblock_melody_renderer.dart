import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'base_melody_renderer.dart';
import '../../music_theory.dart';

class ColorblockMelodyRenderer extends BaseMelodyRenderer {
  double uiScale = 1;
  @override
  bool showSteps = true;
  @override
  double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  double colorblockAlpha;

  draw(Canvas canvas) {
    alphaDrawerPaint.strokeWidth = 0;
    bounds = overallBounds;
    canvas.save();
    canvas.translate(0, bounds.top);
    if (uiScale > 0.7) {
      _renderSteps(canvas);
    }
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
      if (uiScale > 0.19)
      drawRhythm(canvas, alpha * 0.5);

    });
//    if (drawRhythm) {
//      double overallWidth = overallBounds.right - overallBounds.left;
//      bounds = Rect.fromLTRB(overallWidth, bounds.top, overallWidth, bounds.bottom);
//      this.drawRhythm(canvas, alphaSource);
//    }
  }

  _drawColorblockNotes({Canvas canvas, int elementPosition, double alpha}) {
    alphaDrawerPaint.color =
       Color(0xFF212121).withAlpha((alpha * 255).toInt());

    List<int> tones = melody.tonesAt(elementPosition % melody.length).toList();
    bool isNoteStart = false;
    bool isNoteEnd = false;

    if (tones.isNotEmpty) {
      double leftMargin = (isNoteStart) ? drawPadding.toDouble() : 0.0;
      double rightMargin = (isNoteEnd) ? drawPadding.toDouble() : 0.0;
      tones.forEach((tone) {
        int realTone = tone; // + melody.offsetUnder(chord)
        if (melody.instrumentType != InstrumentType.drum) {
          alphaDrawerPaint.color =
            chromaticSteps[realTone.mod12].withAlpha((alpha * 255).toInt());
        }
        double top = bounds.height - bounds.height * (realTone - lowestPitch) / 88;
        double bottom = bounds.height - bounds.height * (realTone - lowestPitch + 1) / 88;
        canvas.drawRect(
            Rect.fromLTRB(bounds.left + leftMargin, top, bounds.right - rightMargin, bottom), alphaDrawerPaint);
      });
    }


    if (uiScale > 0.85) {
      tones = melody.noteOffsAt(elementPosition % melody.length).toList();

      if (tones.isNotEmpty) {
        double leftMargin = (isNoteStart) ? drawPadding.toDouble() : 0.0;
        double rightMargin = (isNoteEnd) ? drawPadding.toDouble() : 0.0;
        tones.forEach((tone) {
          int realTone = tone; // + melody.offsetUnder(chord)
          double top = bounds.height - bounds.height * (realTone - lowestPitch) / 88;
          double bottom = bounds.height - bounds.height * (realTone - lowestPitch + 1) / 88;
          canvas.drawRect(
            Rect.fromLTRB(
              bounds.left + leftMargin + xScale, top - xScale, bounds.right - rightMargin - xScale, bottom + xScale),
            Paint()
              ..strokeWidth = 1.2 * xScale
              ..style = PaintingStyle.stroke
              ..color = Colors.black.withOpacity(alphaDrawerPaint.color.opacity)
          );
        });
      }
    }
    alphaDrawerPaint.color =
      Color(0xFF212121).withAlpha((alpha * 255).toInt());
  }
}
