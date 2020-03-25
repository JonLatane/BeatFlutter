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

class OnScreenNote {
  int tone = 0;
  bool pressed = false;
  double bottom = 0;
  double top = 0;
  double center = 0;

  OnScreenNote({this.tone, this.pressed, this.bottom, this.top, this.center});
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

  //  dip(value: double): Int
  //fun dip(value: Int): Int
  bool showSteps;
  Chord chord = Chord()
    ..rootNote = NoteName()
    ..chroma = 2047;
  double normalizedDevicePitch;

  /// Renders the dividers that separate A, A#, B, C, etc. visually to the user
  renderSteps(Canvas canvas) {
    alphaDrawerPaint.color = Colors.black87;
    if (showSteps) {
      var linePosition = startPoint - 12 * halfStepWidth;
      while (linePosition < axisLength) {
        if (renderVertically) {
          canvas.drawLine(
            Offset(bounds.left, linePosition),
            Offset(bounds.right, linePosition),
            Paint()
          );
        } else {
          canvas.drawLine(
            Offset(linePosition, bounds.top),
            Offset(linePosition, bounds.bottom),
            Paint()
          );
        }
        linePosition += halfStepWidth;
      }
    }
  }

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

  double get orientationRange =>
    highestPitch - lowestPitch + 1 - halfStepsOnScreen;

  double get bottomMostPoint =>
    lowestPitch + (normalizedDevicePitch * orientationRange);

  int get bottomMostNote => bottomMostPoint.floor();

  double get halfStepPhysicalDistance => axisLength / halfStepsOnScreen;

  double get startPoint =>
    (bottomMostNote - bottomMostPoint) * halfStepPhysicalDistance;

  List<OnScreenNote> get onScreenNotes {
    List<OnScreenNote> result = List();
    // This "point" is under the same scale as bottomMostNote; i.e. 0.5f is a "quarter step"
    // (in scrolling distance) past middle C, regardless of the scale level.
    double halfStepPhysicalDistance = axisLength / halfStepsOnScreen;
    double startPoint = (bottomMostNote - bottomMostPoint) *
      halfStepPhysicalDistance;
    OnScreenNote currentScreenNote = OnScreenNote(
      tone: bottomMostNote,
      //chord.closestTone(bottomMostNote),
      pressed: false,
      bottom: 0,
      center: 0,
      top: startPoint
    );
    range(bottomMostNote, bottomMostNote + halfStepsOnScreen.toInt() + 2)
      .forEach((tone) {
      int toneInChord = tone; //chord.closestTone(tone);
      if (toneInChord == tone) {
        currentScreenNote.center =
          currentScreenNote.top + (0.5 * halfStepPhysicalDistance);
      }
      if (toneInChord != currentScreenNote.tone) {
        result.add(currentScreenNote);
        currentScreenNote = OnScreenNote(
          tone: toneInChord,
          pressed: false,
          bottom: currentScreenNote.top,
          top: currentScreenNote.top,
          center: currentScreenNote.top + (0.5 * halfStepPhysicalDistance)
        );
      }
      currentScreenNote.top += halfStepPhysicalDistance;
    });
    result.add(currentScreenNote);
    return result;
  }
}