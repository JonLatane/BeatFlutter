import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/sizeutil.dart';
import 'generated/protos/music.pb.dart';
import 'util.dart';

Chord cChromatic = Chord()
  ..rootNote = (NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.natural)
  ..chroma = 2047;
Chord cMinor = Chord()
  ..rootNote = (NoteName()..noteLetter = NoteLetter.C..noteSign = NoteSign.natural)
  ..chroma = 274;
MelodicAttack _note(int tone) => MelodicAttack()..tones.add(tone)..velocity = 1;
Melody odeToJoy() => Melody()
  ..id = uuid.v4()
  ..type = MelodyType.melodic
  ..instrumentType = InstrumentType.harmonic
  ..subdivisionsPerBeat = 2
  ..length = 32
  ..melodicData = (MelodicData()..data.addAll({
    0: _note(4), 2: _note(4), 4: _note(5), 6: _note(7), 8: _note(7), 10: _note(5), 12: _note(4), 14: _note(2),
    16: _note(0), 18: _note(0), 20: _note(2), 22: _note(4), 24: _note(4), 27: _note(2), 28: _note(2)
  }))
;
var section1 = Section()
  ..id = uuid.v4()
  ..name = ""
  ..harmony = (
    Harmony()
      ..id = uuid.v4()
      ..meter = (Meter()..defaultBeatsPerMeasure = 4)
      ..subdivisionsPerBeat = 4
      ..length = 64
      ..data.addAll({0: cChromatic, 32: cMinor})
  );
var score = Score()
  ..sections.addAll([
    section1,
  ]);