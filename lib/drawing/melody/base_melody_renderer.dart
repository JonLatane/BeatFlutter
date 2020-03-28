import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:unification/unification.dart';

import '../color_guide.dart';
import '../canvas_tone_drawer.dart';
import '../../music_theory.dart';

class BaseMelodyRenderer extends ColorGuide {
  Rect overallBounds;
  Melody melody;
  int elementPosition;
  bool isCurrentlyPlayingBeat;
  bool isSelectedBeatInHarmony;
  Section section;
  bool isUserChoosingHarmonyChord;
  bool isMelodyReferenceEnabled;
  int beatPosition = 0;

  Harmony get harmony => section.harmony;
  List<int> get subdivisionRange => rangeList(beatPosition * melody.subdivisionsPerBeat,
    min(melody.length, (beatPosition + 1) * melody.subdivisionsPerBeat));

  Chord get chord {
    int harmonyPosition = elementPosition.convertPatternIndex(
      fromSubdivisionsPerBeat: melody.subdivisionsPerBeat,
      toSubdivisionsPerBeat: harmony.subdivisionsPerBeat
    );
    Chord result = harmony.changeBefore(harmonyPosition);
    //info("Chord at $elementPosition is $result")
    return result;
  }

  drawHorizontalLineInBounds(
  {Canvas canvas, bool leftSide = true, double alphaSource = 1, double strokeWidth = 1, double startY, double stopY}) {
    double oldStrokeWidth = alphaDrawerPaint.strokeWidth;
    alphaDrawerPaint.preserveColor(() {
      alphaDrawerPaint.color = Color(0xFF000000).withAlpha((alphaSource * 255).toInt());
      alphaDrawerPaint.strokeWidth = strokeWidth;
      double x = (leftSide) ? bounds.left : bounds.right;
      canvas.drawLine(Offset(x, startY), Offset(x, stopY), alphaDrawerPaint);
      alphaDrawerPaint.strokeWidth = oldStrokeWidth;
    });
  }

  drawRhythm(Canvas canvas, double alphaSource) {
    drawHorizontalLineInBounds(
      canvas: canvas,
      strokeWidth: (elementPosition % melody.subdivisionsPerBeat == 0) ? 5 : 1,
      startY: bounds.top,
      stopY: bounds.bottom
    );
  }

  iterateSubdivisions(Function block) {
    int elementCount = subdivisionRange.length;
    double overallWidth = overallBounds.right - overallBounds.left;
    elementPosition = beatPosition * melody.subdivisionsPerBeat;
    subdivisionRange.asMap().forEach((elementIndex, elementPosition) {
      bounds = Rect.fromLTRB(
        overallWidth * elementIndex / elementCount,
        overallBounds.top,
        (overallWidth * (elementIndex + 1) / elementCount),
        overallBounds.bottom
      );
      isCurrentlyPlayingBeat = false;
  //      BeatClockPaletteConsumer.section == section &&
  //        viewModel.paletteViewModel.playbackTick?.convertPatternIndex(
  //          fromSubdivisionsPerBeat = BeatClockPaletteConsumer.ticksPerBeat,
  //          toSubdivisionsPerBeat = melody.subdivisionsPerBeat
  //        ) == elementPosition
      isSelectedBeatInHarmony = false;
  //    viewModel.paletteViewModel.harmonyViewModel.selectedHarmonyElements
  //      ?.contains(elementPosition.convertPatternIndex(melody, harmony))
  //      ?: false
      block();
      elementPosition++;
    });
  }
}
