import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import 'base_melody_renderer.dart';

class ColorblockMelodyRenderer extends BaseMelodyRenderer {
  @override bool showSteps = true;
  @override bool renderVertically = true;
  @override double normalizedDevicePitch = 0;
  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  double colorblockAlpha;
  draw(Canvas canvas) {
    alphaDrawerPaint.strokeWidth = 0;
    bounds = overallBounds;
    renderSteps(canvas);
    if(melody != null) {
      double alphaMultiplier = (isMelodyReferenceEnabled) ? 1.0 : 2.0/3;
      drawColorblockMelody(
        canvas: canvas,
        stepNoteAlpha: (0xAA * colorblockAlpha * alphaMultiplier).toInt(),
        drawRhythm: true,
        alphaSource: colorblockAlpha * alphaMultiplier
      );
    }

    drawColorblockMelody(canvas: canvas, stepNoteAlpha: 255, drawRhythm: true, );

// Draw a background if no melody is focused
//if(focusedMelody == null) {
//canvas.drawColorblockMelody(
//oneBeatMelody.apply { subdivisionsPerBeat = harmony.subdivisionsPerBeat},
//stepNoteAlpha = 0,
//drawColorGuide = when(val viewType = viewType) {
//is ViewType.PartView -> !viewType.part.drumTrack
//is ViewType.DrumPart -> false
//else                                        -> true
//},
//alphaSource = colorblockAlpha
//)
//}
//
//sectionMelodiesOfPartType.forEach { otherMelody ->
//canvas.drawColorblockMelody(
//otherMelody,
//stepNoteAlpha = if (viewModel.openedMelody == null) 255 else 66,
//drawColorGuide = false,
//drawRhythm = false,
//alphaSource = colorblockAlpha
//)
//}
}


drawColorblockMelody({Canvas canvas, int stepNoteAlpha, bool drawRhythm = false, bool drawColorGuide = true, double alphaSource = 1})
  {
    iterateSubdivisions(() {
      if(!drawColorGuide) {
        colorGuideAlpha = 0;
      } else if(isCurrentlyPlayingBeat || isSelectedBeatInHarmony) {
        colorGuideAlpha = 255;
      } else if(isUserChoosingHarmonyChord && !isSelectedBeatInHarmony) {
        colorGuideAlpha = 69;
      } else if(melody.instrumentType == InstrumentType.drum) {
        colorGuideAlpha = 0;
      } else {
        colorGuideAlpha = 155;
      }
      colorGuideAlpha = (colorGuideAlpha * alphaSource).toInt();
      this.drawColorGuide(canvas);
      drawColorblockNotes(canvas: canvas, elementPosition: elementPosition, drawAlpha: stepNoteAlpha, alphaSource: alphaSource);
      if(drawRhythm) {
        this.drawRhythm(canvas, alphaSource);
      }
    });
    if(drawRhythm) {
      double overallWidth = overallBounds.right - overallBounds.left;
      bounds = Rect.fromLTRB(overallWidth, bounds.top, overallWidth, bounds.bottom);
      this.drawRhythm(canvas, alphaSource);
    }
}



  drawColorblockNotes({Canvas canvas, int elementPosition, int drawAlpha = 0xAA, double alphaSource}) {
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
      double leftMargin = (isChange) ? drawPadding : 0;
      double rightMargin = (nextElement != null) ? drawPadding : 0;
      tones.forEach((tone) {
        int realTone = tone; // + melody.offsetUnder(chord)
        double top = bounds.height - bounds.height * (realTone - lowestPitch) / 88;
        double bottom = bounds.height - bounds.height * (realTone - lowestPitch + 1) / 88;
        canvas.drawRect(Rect.fromLTRB(
          bounds.left + leftMargin,
          top,
          bounds.right - rightMargin,
          bottom),
          alphaDrawerPaint
        );
      });
    }
  }
}