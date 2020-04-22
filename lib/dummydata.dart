import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quiver/iterables.dart';
import 'drawing/sizeutil.dart';
import 'generated/protos/music.pb.dart';
import 'midi_theory.dart';
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
  ..type = MelodyType.midi
  ..instrumentType = InstrumentType.harmonic
  ..interpretationType = MelodyInterpretationType.fixed
  ..subdivisionsPerBeat = 2
  ..length = 64
  ..setMidiDataFromSimpleMelody(Map.from({
    0:  [4],  2: [4],  4: [5],  6: [7],
    8:  [7], 10: [5], 12: [4], 14: [2],
    16: [0], 18: [0], 20: [2], 22: [4],
    24: [4], 27: [2], 28: [2]
  })..addAll({
    0:  [4],  2: [4],  4: [5],  6: [7],
    8:  [7], 10: [5], 12: [4], 14: [2],
    16: [0], 18: [0], 20: [2], 22: [4],
    24: [2], 27: [0], 28: [0]
  }.map((key, value) => MapEntry(key + 32, value))));

Melody boomChick() => Melody()
  ..id = uuid.v4()
  ..type = MelodyType.midi
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed
  ..subdivisionsPerBeat = 1
  ..length = 2
  ..setMidiDataFromSimpleMelody({
    0: [-25], 1: [-22]
  })
;

Melody defaultMelody() => Melody()
  ..id = uuid.v4()
  ..type = MelodyType.melodic
  ..instrumentType = InstrumentType.harmonic
  ..interpretationType = MelodyInterpretationType.fixed
  ..subdivisionsPerBeat = 4
  ..length = 64
  ..melodicData = MelodicData();

Harmony defaultHarmony() =>
  Harmony()
    ..id = uuid.v4()
    ..subdivisionsPerBeat = 4
    ..length = 128
    ..data.addAll({
      0: cChromatic,
//      32: cMinor,
    });

Section defaultSection() => Section()
  ..id = uuid.v4()
  ..meter = (Meter()..defaultBeatsPerMeasure = 4)
  ..tempo = (Tempo()..bpm = 123)
  ..harmony = defaultHarmony();

Score defaultScore() => Score()
  ..id = uuid.v4()
  ..sections.addAll([
    defaultSection(),
  ])
  ..parts.addAll([
    newPartFor(Score()),
    newDrumPart()
  ]);

extension MidiThings on Score {
  bool usesChannel(int channel) => parts.any((part) => part.instrument.midiChannel == channel);
}
Part newPartFor(Score score) {
  Part part = Part()
    ..id = uuid.v4()
    ..instrument = (Instrument()
      ..midiInstrument = score.parts.any((part) => part.instrument.midiInstrument == 0)
        ? (score.parts.any((part) => part.instrument.midiInstrument == 34)
        ? (score.parts.any((part) => part.instrument.midiInstrument == 25)
        ? (score.parts.any((part) => part.instrument.midiInstrument == 4)
        ? (72) : 4) : 25) : 34) : 0
      ..midiChannel = (range(0,8).toList() + range(10,15).toList())
        .firstWhere((channel) => !score.usesChannel(channel))
      ..volume = 0.5
      ..type = InstrumentType.harmonic);
  return part;
}

Part newDrumPart() {
  Part part = Part()
    ..id = uuid.v4()
    ..instrument = (Instrument()
      ..name = ""//"Drums"
      ..volume = 0.5
      ..midiChannel = 9
      ..type = InstrumentType.drum);
  return part;
}