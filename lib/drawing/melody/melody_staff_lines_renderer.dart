import 'package:beatscratch_flutter_redux/drawing/melody/base_melody_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/music_notation_theory.dart';
import 'package:flutter/material.dart';

enum Clef { treble, bass, tenor_treble }
extension ClefNotes on Clef {
  List<NoteSpecification> get notes {
    switch(this) {
      case Clef.treble:
        return [
          NoteSpecification.name(letter: NoteLetter.F, octave: 5),
          NoteSpecification.name(letter: NoteLetter.D, octave: 5),
          NoteSpecification.name(letter: NoteLetter.B, octave: 4),
          NoteSpecification.name(letter: NoteLetter.G, octave: 4),
          NoteSpecification.name(letter: NoteLetter.E, octave: 4),
        ];
        break;
      case Clef.tenor_treble:
        return [
          NoteSpecification.name(letter: NoteLetter.F, octave: 4),
          NoteSpecification.name(letter: NoteLetter.D, octave: 4),
          NoteSpecification.name(letter: NoteLetter.B, octave: 3),
          NoteSpecification.name(letter: NoteLetter.G, octave: 3),
          NoteSpecification.name(letter: NoteLetter.E, octave: 3),
        ];
        break;
      case Clef.bass:
        return [
          NoteSpecification.name(letter: NoteLetter.A, octave: 3),
          NoteSpecification.name(letter: NoteLetter.F, octave: 3),
          NoteSpecification.name(letter: NoteLetter.D, octave: 3),
          NoteSpecification.name(letter: NoteLetter.B, octave: 2),
          NoteSpecification.name(letter: NoteLetter.G, octave: 2),
        ];
        break;
    }
    throw "Clef: that's illegal!";
  }
}

class MelodyStaffLinesRenderer extends BaseMelodyRenderer {
  @override bool showSteps = true;
  @override double normalizedDevicePitch = 0;

  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  List<Clef> clefs = [Clef.treble, Clef.bass];

  draw(Canvas canvas) {
    canvas.save();
    canvas.translate(0, bounds.top);
    clefs.expand((clef) => clef.notes).forEach((note) {
      drawPitchwiseLine(canvas: canvas, pointOnToneAxis: pointForNote(note));
    });
    canvas.restore();
  }
}