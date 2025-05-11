import 'dart:math';

import 'package:flutter/material.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../util/music_theory.dart';
import '../util/util.dart';

extension _HarmonyHighlight on Color {
  // ignore: unused_element
  Color withHighlight({bool isPlaying, bool isSelected, bool isFaded}) {
    int alpha = 187;
    if (isPlaying) {
      alpha = 255;
    } else if (isSelected) {
      alpha = 187;
//      when((beatSelectionAnimationPosition + (elementPosition * SelectedChordAnimation.steps).mod12).mod12) {
//        0, 3, 5, 7, 11 -> 127
//        else -> 255
//      }
    } else if (isFaded) {
      alpha = 41;
    }
    Color result = this.withAlpha(alpha);
    if (isPlaying) {
      if (isPlaying) {
        var hsv = HSVColor.fromColor(result);
        hsv = hsv.withSaturation(0.5);
      }
    }
    return result;
  }
}

int minor3 = int.parse("00100000000", radix: 2);
int major3 = int.parse("00010000000", radix: 2);
int dim5 = int.parse("00000100000", radix: 2);
int p5 = int.parse("00000010000", radix: 2);
int aug5 = int.parse("00000001000", radix: 2);
int minor7 = int.parse("00000000010", radix: 2);
int major7 = int.parse("00000000001", radix: 2);

extension _HarmonyColor on Chord {
  Color get uiColor {
//    return ChordColor.major.color;
    ChordColor chordColor = ChordColor.none;
    if (this.chroma & minor3 == minor3 && this.chroma & major3 != major3) {
      if (this.chroma & dim5 == dim5) {
        chordColor = ChordColor.diminished;
      } else {
        chordColor = ChordColor.minor;
      }
    } else if (this.chroma & major3 == major3) {
      if (this.chroma & minor7 == minor7 && this.chroma & major7 != major7) {
        chordColor = ChordColor.dominant;
      } else if (this.chroma & aug5 == aug5 && this.chroma & p5 != p5) {
        chordColor = ChordColor.augmented;
      } else {
        chordColor = ChordColor.major;
      }
    }
    return chordColor.color;
  }
}

class HarmonyBeatRenderer {
  Section section;

  Harmony get harmony => section.harmony;
  Meter get meter => section.meter;
  int beatPosition = 0;

  Iterable<int> get subdivisionRange => range(
      beatPosition * harmony.subdivisionsPerBeat,
      min(harmony.length, (beatPosition + 1) * harmony.subdivisionsPerBeat));

  Paint paint = Paint();

  Rect overallBounds = Rect.zero;
  Rect bounds = Rect.zero;
  double opacityFactor = 1;

//  private val hsv = FloatArray(3)
  draw(Canvas canvas) {
//  canvas.getClipBounds(overallBounds)
    double overallWidth = overallBounds.right - overallBounds.left;
    bounds = Rect.fromLTRB(overallBounds.left, overallBounds.top,
        overallBounds.right, overallBounds.bottom);

    paint.color = Color(0xFFFFFFFF).withOpacity(opacityFactor);
    canvas.drawRect(bounds, paint);
    var elementCount = subdivisionRange.length;
    subdivisionRange.toList().asMap().forEach((elementIndex, elementPosition) {
      bounds = Rect.fromLTRB(
          overallBounds.left + overallWidth * elementIndex / elementCount,
          overallBounds.top,
          overallBounds.left + overallWidth * (elementIndex + 1) / elementCount,
          overallBounds.bottom);
//        print("Drawing beat $beatPosition subdivision $elementIndex onto $bounds");

      // ignore: unused_local_variable
      bool isPlaying = false;
      /*section == BeatClockPaletteConsumer.section &&
  viewModel.paletteViewModel.playbackTick?.convertPatternIndex(
  from = BeatClockPaletteConsumer.ticksPerBeat,
  to = harmony
  ) == elementPosition*/
      // ignore: unused_local_variable
      bool isSelected =
          false; //viewModel?.selectedHarmonyElements?.contains(elementPosition) ?: false
      // ignore: unused_local_variable
      bool isFaded =
          false; //!isSelected && viewModel?.selectedHarmonyElements != null

      Chord chord = harmony.changeBefore(elementPosition);

      if (chord.chroma == 2047) {
        paint.color = chromaticSteps[elementPosition % chromaticSteps.length]
            .withOpacity(0.5 * opacityFactor);
      } else {
        paint.color = chord.uiColor;
      }

      canvas.drawRect(bounds, paint);

      _drawRhythm(canvas, elementIndex);
    });
//    bounds.apply {
//      left = overallBounds.right
//      right = overallBounds.right
//    }
//    canvas.drawRhythm(harmony, harmony?.subdivisionsPerBeat ?: 1)
  }

//  fun getPositionAndElement(x: Float): Pair<Int, Chord?>? {
//  return harmony?.let { harmony ->
//  val elementRange: IntRange = elementRange!!
//  val elementIndex: Int = (elementRange.size * x / width).toInt()
//  val elementPosition = Math.min(beatPosition * harmony.subdivisionsPerBeat + elementIndex, harmony.length - 1)
//  return elementPosition to harmony.changeBefore(elementPosition)
//  }
//  }

  _drawRhythm(Canvas canvas, int elementIndex) {
    // paint.color = Color(0xFF424242);
    double leftOffset = 1;
    if (elementIndex % harmony.subdivisionsPerBeat == 0) {
      leftOffset = 3;
      if ((beatPosition % meter.defaultBeatsPerMeasure) == 0) {
        leftOffset = 6;
      }
    }
    double rightOffset = 1;
    if (elementIndex % harmony.subdivisionsPerBeat ==
        harmony.subdivisionsPerBeat - 1) {
      leftOffset = 3;
      if ((beatPosition) % meter.defaultBeatsPerMeasure ==
          meter.defaultBeatsPerMeasure - 1) {
        leftOffset = 6;
      }
    }

    canvas.drawRect(
        Rect.fromLTRB(bounds.left + leftOffset, bounds.top,
            bounds.left + leftOffset, bounds.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTRB(bounds.right - rightOffset, bounds.top, bounds.right,
            bounds.bottom),
        paint);
  }
}
