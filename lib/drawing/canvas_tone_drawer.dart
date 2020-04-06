import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
//import 'sizeutil.dart';
import '../generated/protos/music.pb.dart';
import 'package:unification/unification.dart';
import '../music_theory.dart';

extension PreserveColor on Paint {
  preserveColor(VoidCallback callback) {
    var color = this.color;
    callback();
    this.color = color;
  }
}

class VisiblePitch {
  int tone = 0;
  Rect bounds = Rect.fromLTRB(0, 0, 0, 0);

  VisiblePitch(this.tone, this.bounds);
}

class CanvasToneDrawer {
  static const int BOTTOM = -39; // Top C on an 88-key piano
  static const int TOP = 48; // Bottom A, ditto

  Paint alphaDrawerPaint = Paint();

  /// Represent the bounds for whatever is to be drawn
  Rect bounds;
  bool renderVertically;
  double get axisLength => renderVertically ? bounds.height : bounds.width;
  double halfStepsOnScreen;

  int get highestPitch => TOP;

  int get lowestPitch => BOTTOM;

  double get halfStepWidth => axisLength / halfStepsOnScreen;
  double get diatonicStepWidth => halfStepWidth * 12 / 7;

  //  dip(value: double): Int
  //fun dip(value: Int): Int
  bool showSteps;
  Chord chord = Chord()
    ..rootNote = NoteName()
    ..chroma = 2047;
  double normalizedDevicePitch;



  List<VisiblePitch> get visiblePitches {
    List<VisiblePitch> result = List();
    double orientationRange = highestPitch - lowestPitch + 1 -
      halfStepsOnScreen;
    // This "point" is under the same scale as bottomMostNote; i.e. 0.5f is a "quarter step"
    // (in scrolling distance) past middle C, regardless of the scale level.
    double bottomMostPoint = lowestPitch +
      (normalizedDevicePitch * orientationRange);
    double halfStepPhysicalDistance = axisLength / halfStepsOnScreen;
    range(bottomMostNote, min(highestPitch + 1,bottomMostNote + halfStepsOnScreen.toInt() + 2))
      .forEach((tone) {
      // Tone may not be in chord...
      Rect visiblePitchBounds = renderVertically ?
      Rect.fromLTRB(
        this.bounds.left,
        this.bounds.bottom -
          (tone - bottomMostPoint) * halfStepPhysicalDistance,
        this.bounds.right,
        this.bounds.bottom -
          (1 + tone - bottomMostPoint) * halfStepPhysicalDistance
      ) :
      Rect.fromLTRB(
        this.bounds.left + (tone - bottomMostPoint) * halfStepPhysicalDistance,
        this.bounds.top,
        this.bounds.left +
          (1 + tone - bottomMostPoint) * halfStepPhysicalDistance,
        this.bounds.bottom
      );
      result.add(VisiblePitch(tone, visiblePitchBounds));
    });
    return result;
  }

  List<VisiblePitch> get visibleDiatonicPitches {
    List<VisiblePitch> result = List();
    double orientationRange = highestPitch - lowestPitch + 1 -
      halfStepsOnScreen;
    // This "point" is under the same scale as bottomMostNote; i.e. 0.5f is a "quarter step"
    // (in scrolling distance) past middle C, regardless of the scale level.
    double bottomMostPoint = lowestPitch +
      (normalizedDevicePitch * orientationRange);
    double diatonicStepDistance = (axisLength / halfStepsOnScreen) * 12.0/7;
    range(bottomMostWhiteKey, min(highestPitch + 1,bottomMostNote + halfStepsOnScreen.toInt() + 2))
      .where((tone) => tone.isWhiteKey)
      .forEach((tone) {
      // Tone may not be in chord...
      double leftOffset = 0;
      switch(tone.mod12) {
        case 0:
          leftOffset = 0;
          break;
        case 2:
          leftOffset = -0.165;
          break;
        case 4:
          leftOffset = -0.33;
          break;
        case 5:
          leftOffset = 0.088;
          break;
        case 7:
          leftOffset = -0.08;
          break;
        case 9:
          leftOffset = -0.245;
          break;
        case 11:
          leftOffset = -0.415;
          break;
      }
      Rect visiblePitchBounds = Rect.fromLTRB(
        leftOffset * diatonicStepDistance + this.bounds.left + (tone - bottomMostPoint) * halfStepPhysicalDistance,
        this.bounds.top,
        leftOffset * diatonicStepDistance + this.bounds.left + (tone - bottomMostPoint) * halfStepPhysicalDistance + diatonicStepDistance,
        this.bounds.bottom
      );
      result.add(VisiblePitch(tone, visiblePitchBounds));
    });
    return result;
  }

  double get orientationRange =>
    highestPitch - lowestPitch + 1 - halfStepsOnScreen;

  double get bottomMostPoint =>
    lowestPitch + (normalizedDevicePitch * orientationRange);

  int get bottomMostNote => bottomMostPoint.floor();
  int get bottomMostWhiteKey => (bottomMostNote.isWhiteKey) ? bottomMostNote : bottomMostNote - 1;

  double get halfStepPhysicalDistance => axisLength / halfStepsOnScreen;

  double get startPoint =>
    (bottomMostNote - bottomMostPoint) * halfStepPhysicalDistance;
}