import 'package:flutter/material.dart';

import '../../generated/protos/music.pb.dart';
import '../../util/music_notation_theory.dart';
import '../../util/util.dart';
import 'base_music_renderer.dart';

enum Clef { treble, bass, tenor_treble, drum_treble, drum_bass }

extension ClefNotes on Clef {
  List<NoteSpecification> get notes => clefNotes[this];

  static final Map<Clef, List<NoteSpecification>> clefNotes = {
    Clef.treble: [
      NoteSpecification.name(letter: NoteLetter.F, octave: 5),
      NoteSpecification.name(letter: NoteLetter.D, octave: 5),
      NoteSpecification.name(letter: NoteLetter.B, octave: 4),
      NoteSpecification.name(letter: NoteLetter.G, octave: 4),
      NoteSpecification.name(letter: NoteLetter.E, octave: 4),
    ],
    Clef.tenor_treble: [
      NoteSpecification.name(letter: NoteLetter.F, octave: 4),
      NoteSpecification.name(letter: NoteLetter.D, octave: 4),
      NoteSpecification.name(letter: NoteLetter.B, octave: 3),
      NoteSpecification.name(letter: NoteLetter.G, octave: 3),
      NoteSpecification.name(letter: NoteLetter.E, octave: 3),
    ],
    Clef.bass: [
      NoteSpecification.name(letter: NoteLetter.A, octave: 3),
      NoteSpecification.name(letter: NoteLetter.F, octave: 3),
      NoteSpecification.name(letter: NoteLetter.D, octave: 3),
      NoteSpecification.name(letter: NoteLetter.B, octave: 2),
      NoteSpecification.name(letter: NoteLetter.G, octave: 2),
    ],
    Clef.drum_treble: [
      NoteSpecification.name(letter: NoteLetter.F, octave: 5),
      NoteSpecification.name(letter: NoteLetter.D, octave: 5),
      NoteSpecification.name(letter: NoteLetter.B, octave: 4),
      NoteSpecification.name(letter: NoteLetter.G, octave: 4),
      NoteSpecification.name(letter: NoteLetter.E, octave: 4),
    ],
    Clef.drum_bass: [
      NoteSpecification.name(letter: NoteLetter.A, octave: 3),
      NoteSpecification.name(letter: NoteLetter.F, octave: 3),
      NoteSpecification.name(letter: NoteLetter.D, octave: 3),
      NoteSpecification.name(letter: NoteLetter.B, octave: 2),
      NoteSpecification.name(letter: NoteLetter.G, octave: 2),
    ]
  };

  static final List<NoteSpecification> ledgers = [
    NoteSpecification.name(letter: NoteLetter.C, octave: 4),
    NoteSpecification.name(letter: NoteLetter.A, octave: 5),
    NoteSpecification.name(letter: NoteLetter.C, octave: 6),
    NoteSpecification.name(letter: NoteLetter.E, octave: 6),
    NoteSpecification.name(letter: NoteLetter.G, octave: 6),
    NoteSpecification.name(letter: NoteLetter.B, octave: 6),
    NoteSpecification.name(letter: NoteLetter.D, octave: 7),
    NoteSpecification.name(letter: NoteLetter.F, octave: 7),
    NoteSpecification.name(letter: NoteLetter.A, octave: 7),
    NoteSpecification.name(letter: NoteLetter.C, octave: 8),
    NoteSpecification.name(letter: NoteLetter.E, octave: 8),
    NoteSpecification.name(letter: NoteLetter.G, octave: 8),
    NoteSpecification.name(letter: NoteLetter.B, octave: 8),
    NoteSpecification.name(letter: NoteLetter.E, octave: 2),
    NoteSpecification.name(letter: NoteLetter.C, octave: 2),
    NoteSpecification.name(letter: NoteLetter.A, octave: 1),
    NoteSpecification.name(letter: NoteLetter.F, octave: 1),
    NoteSpecification.name(letter: NoteLetter.D, octave: 1),
    NoteSpecification.name(letter: NoteLetter.B, octave: 0),
    NoteSpecification.name(letter: NoteLetter.G, octave: 0),
    NoteSpecification.name(letter: NoteLetter.E, octave: 0),
    NoteSpecification.name(letter: NoteLetter.C, octave: 0)
  ];

  static Map<Clef, int> diatonicMaxCache = Map();
  int get diatonicMax => diatonicMaxCache.putIfAbsent(
      this, () => notes.maxBy((it) => it.diatonicValue).diatonicValue);

  static Map<Clef, int> diatonicMinCache = Map();
  int get diatonicMin => diatonicMinCache.putIfAbsent(
      this, () => notes.minBy((it) => it.diatonicValue).diatonicValue);

  /// Indicates that the note can be drawn on this clef with no ledger lines
  static Map<ArgumentList, bool> coversCache = Map();
  bool covers(NoteSpecification note) => coversCache.putIfAbsent(
      ArgumentList([this, note.noteName, note.octave]),
      () => range(diatonicMax, diatonicMin).contains(note.diatonicValue));

  static Map<ArgumentList, Iterable<NoteSpecification>> ledgersToCache = Map();
  Iterable<NoteSpecification> ledgersTo(NoteSpecification note) =>
      ledgersToCache.putIfAbsent(
          ArgumentList([this, note.noteName, note.octave]),
          () => (note.diatonicValue > diatonicMax)
              ? ledgers.where((it) =>
                  it.diatonicValue > diatonicMax &&
                  it.diatonicValue <= note.diatonicValue)
              : ledgers.where((it) =>
                  it.diatonicValue < diatonicMin &&
                  it.diatonicValue >= note.diatonicValue));
}

class MelodyStaffLinesRenderer extends BaseMusicRenderer {
  @override
  double normalizedDevicePitch = 0;

  @override
  double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
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
