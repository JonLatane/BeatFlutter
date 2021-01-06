import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:unification/unification.dart';

import '../color_guide.dart';
import '../canvas_tone_drawer.dart';
import '../../util/music_theory.dart';
import '../../util/music_notation_theory.dart';

class BaseMusicRenderer extends ColorGuide {
  @override final bool renderVertically = true;
  @override final double normalizedDevicePitch = 0;
  Rect overallBounds;
  Melody melody;
  int elementPosition;
  bool isCurrentlyPlayingBeat;
  bool isSelectedBeatInHarmony;
  Section section;
  bool isUserChoosingHarmonyChord;
  bool isMelodyReferenceEnabled;
  int beatPosition = 0;
  double xScale = 1;
  double yScale = 1;
  // Used for notation. Logically, if an octave is to have the same "scale" chromatically or diatonically, the letter
  // step must be 12/7 of the half step in size.
  double get letterStepSize => halfStepWidth * 12 / 7;
  bool get isFinalBeat => (beatPosition + 1) % meter.defaultBeatsPerMeasure == 0;
  double get minScale => min(xScale, yScale);


  Harmony get harmony => section.harmony;
  Meter get meter => section.meter;
  Iterable<int> get subdivisionRange => range(
    beatPosition * melody.subdivisionsPerBeat,
    (beatPosition + 1) * melody.subdivisionsPerBeat
  );

  Chord get chord {
    int harmonyPosition = elementPosition.convertPatternIndex(
      fromSubdivisionsPerBeat: melody.subdivisionsPerBeat,
      toSubdivisionsPerBeat: harmony.subdivisionsPerBeat
    );
    Chord result = harmony.changeBefore(harmonyPosition);
    //info("Chord at $elementPosition is $result")
    return result;
  }

  ///doesn't work for [renderVertically]=false.
  drawTimewiseLineRelativeToBounds(
  {Canvas canvas, bool leftSide = true, double alpha = 1, double strokeWidth = 1, double startY, double stopY, double percentThrough = 0, Offset offset = Offset.zero}) {
    double oldStrokeWidth = alphaDrawerPaint.strokeWidth;
    alphaDrawerPaint.strokeMiterLimit;
    alphaDrawerPaint.preserveProperties(() {
      alphaDrawerPaint.color = Color(0xFF000000).withAlpha((alpha * 255).toInt());
      alphaDrawerPaint.strokeWidth = strokeWidth;
      double x = (leftSide) ? bounds.left : bounds.right;
      x += percentThrough * bounds.width;
      canvas.drawLine(Offset(x, startY) + offset, Offset(x, stopY) + offset, alphaDrawerPaint);
      alphaDrawerPaint.strokeWidth = oldStrokeWidth;
    });
  }

  drawPitchwiseLine({Canvas canvas, double pointOnToneAxis, double left, double right }) {
    if (renderVertically) {
      canvas.drawLine(
        Offset(left ?? bounds.left, pointOnToneAxis),
        Offset(right ?? bounds.right, pointOnToneAxis,),
        alphaDrawerPaint
      );
    } else {
      canvas.drawLine(
        Offset(pointOnToneAxis, bounds.top),
        Offset(pointOnToneAxis, bounds.bottom,),
        alphaDrawerPaint
      );
    }
  }

  drawRhythm(Canvas canvas, double alphaSource) {
//    print("drawing rhythm at $elementPosition");
    drawTimewiseLineRelativeToBounds(
      canvas: canvas,
      strokeWidth: (elementPosition % melody.subdivisionsPerBeat == 0) ? 2 : 1,
      startY: 0,
      stopY: bounds.height,
      alpha: alphaSource
    );
  }

  iterateSubdivisions(Function block) {
    int elementCount = subdivisionRange.length;
    double overallWidth = overallBounds.right - overallBounds.left;
    elementPosition = beatPosition * melody.subdivisionsPerBeat;
//    print("subdivisionRange=$subdivisionRange");
    subdivisionRange.toList().asMap().forEach((elementIndex, elementPosition) {
      bounds = Rect.fromLTRB(
        overallBounds.left + overallWidth * elementIndex / elementCount,
        overallBounds.top,
        overallBounds.left + (overallWidth * (elementIndex + 1) / elementCount),
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
      this.elementPosition++;
    });
  }

  double centerOfTone(int tone) => startPoint - (bottomMostNote + tone - 9.5) * halfStepWidth;

  double pointFor({NoteLetter letter, int octave}) {
    double middleC = centerOfTone(0);
    double result = middleC - letterStepSize * (((octave - 4) * 7) + letter.value);
    return result;
  }

  double pointForNote(NoteSpecification note) => pointFor(letter: note.noteName.noteLetter, octave: note.octave);
}
