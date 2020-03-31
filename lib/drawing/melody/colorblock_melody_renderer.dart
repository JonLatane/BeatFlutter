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
    renderSteps(canvas);
    double alphaMultiplier = (isMelodyReferenceEnabled) ? 1.0 : 2.0 / 3;
    _drawColorblockMelody(
        canvas: canvas,
        stepNoteAlpha: (0xAA * colorblockAlpha * alphaMultiplier).toInt(),
        drawRhythm: true,
        alphaSource: colorblockAlpha * alphaMultiplier);

    canvas.restore();
  }

  _drawColorblockMelody(
      {Canvas canvas, int stepNoteAlpha, bool drawRhythm = false, bool drawColorGuide = true, double alphaSource = 1}) {
    iterateSubdivisions(() {
      _drawColorblockNotes(
          canvas: canvas, elementPosition: elementPosition, drawAlpha: stepNoteAlpha, alphaSource: alphaSource);
      if (drawRhythm) {
        this.drawRhythm(canvas, alphaSource);
      }
    });
//    if (drawRhythm) {
//      double overallWidth = overallBounds.right - overallBounds.left;
//      bounds = Rect.fromLTRB(overallWidth, bounds.top, overallWidth, bounds.bottom);
//      this.drawRhythm(canvas, alphaSource);
//    }
  }

  _drawColorblockNotes({Canvas canvas, int elementPosition, int drawAlpha = 0xAA, double alphaSource}) {
    MelodicAttack element = melody.melodicData.data[elementPosition % melody.length];
    MelodicAttack nextElement = melody.melodicData.data[elementPosition % melody.length];
    bool isChange = element != null;
    alphaDrawerPaint.color =
        ((isChange) ? Color(0xAA212121) : Color(0xAA424242)).withAlpha((alphaSource * drawAlpha).toInt());

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
