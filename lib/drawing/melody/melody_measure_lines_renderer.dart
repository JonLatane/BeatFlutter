import 'package:beatscratch_flutter_redux/drawing/melody/base_melody_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import '../../music_notation_theory.dart';
import '../../util.dart';
import 'melody_staff_lines_renderer.dart';


class MelodyMeasureLinesRenderer extends BaseMelodyRenderer {
  @override bool showSteps = true;
  @override double normalizedDevicePitch = 0;
  double notationAlpha = 0;
  double colorblockAlpha = 0;

  List<Clef> clefs = [Clef.treble, Clef.bass];

  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  

  draw(Canvas canvas, double strokeWidth) {
    bounds = overallBounds;
    if(beatPosition % meter.defaultBeatsPerMeasure == 0) {
      canvas.save();
      canvas.translate(0, bounds.top);
      try {
//        print("drawing measure line");
        NoteSpecification highestDiatonicNote = clefs.expand((clef) => clef.notes).maxBy((e) => e.diatonicValue);
        NoteSpecification lowestDiatonicNote = clefs.expand((clef) => clef.notes).minBy((e) => e.diatonicValue);
        drawTimewiseLineRelativeToBounds(
          canvas: canvas,
          leftSide: true,
          alpha: notationAlpha,
          strokeWidth: strokeWidth,
          startY: pointForNote(highestDiatonicNote),
          stopY: pointForNote(lowestDiatonicNote),
        );
        drawTimewiseLineRelativeToBounds(
          canvas: canvas,
          leftSide: true,
          alpha: colorblockAlpha,
          strokeWidth: strokeWidth * 2,
          startY: pointForNote(NoteSpecification.name(letter: NoteLetter.G, octave: 0)),
          stopY: pointForNote(NoteSpecification.name(letter: NoteLetter.C, octave: 8)),
        );
      } catch(e) {
        print(e);
      }
      canvas.restore();
    }
  }
}