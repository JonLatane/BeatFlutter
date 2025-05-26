import '../generated/protos/music.pb.dart';
import '../util/proto_utils.dart';
import 'midi_theory.dart';
import 'util.dart';

const int defaultSectionBeats = 16;
const int defaultSectionSubdivisionsPerBeat = 4;
const int defaultMelodySubdivisionsPerBeat = 12;
const int defaultSectionLength =
    defaultSectionSubdivisionsPerBeat * defaultSectionBeats;

Chord cChromatic = Chord()
  ..rootNote = (NoteName()
    ..noteLetter = NoteLetter.C
    ..noteSign = NoteSign.natural)
  ..chroma = 2047;
Chord cMinor = Chord()
  ..rootNote = (NoteName()
    ..noteLetter = NoteLetter.C
    ..noteSign = NoteSign.natural)
  ..chroma = 274;

Melody baseMelody() => Melody()
  ..id = uuid.v4()
  ..type = MelodyType.midi
  ..interpretationType = MelodyInterpretationType.fixed
  ..midiData = MidiData();

Melody boomChick() => baseMelody()
  ..name = "Boom-Chick"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 1
  ..length = 2
  ..setMidiDataFromSimpleMelody({
    0: [-25],
    1: [-22]
  });

Melody boom() => baseMelody()
  ..name = "Boots"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 1
  ..length = 2
  ..setMidiDataFromSimpleMelody({
    0: [-25],
  });

Melody chick() => baseMelody()
  ..name = "Cats"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 1
  ..length = 2
  ..setMidiDataFromSimpleMelody({
    1: [-22]
  });

Melody tssst() => baseMelody()
  ..name = "And"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 2
  ..length = 2
  ..setMidiDataFromSimpleMelody({
    1: [-18]
  }, simpleVelocity: 84);

Melody tssstSwing() => baseMelody()
  ..name = "And (Swing)"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 3
  ..length = 3
  ..setMidiDataFromSimpleMelody({
    2: [-18]
  }, simpleVelocity: 84);

Melody tsstTsst() => baseMelody()
  ..name = "Ee-ah"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 4
  ..length = 4
  ..setMidiDataFromSimpleMelody({
    1: [-18],
    3: [-18]
  }, simpleVelocity: 42);

Melody tsstTsstSwing() => baseMelody()
  ..name = "Ee-ah (Swing)"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 6
  ..length = 6
  ..setMidiDataFromSimpleMelody({
    2: [-18],
    5: [-18]
  }, simpleVelocity: 42);

Melody thirteenOutOfThirtyTwo() => baseMelody()
  ..name = "13/32"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 8
  ..length = 32
  ..setMidiDataFromSimpleMelody({
    5: [-18],
  }, simpleVelocity: 127);

Melody fiveOutOfThirtyTwo() => baseMelody()
  ..name = "5/32"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 8
  ..length = 32
  ..setMidiDataFromSimpleMelody({
    13: [-18],
  }, simpleVelocity: 127);

Melody twentyOneOutOfThirtyTwo() => baseMelody()
  ..name = "21/32"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 8
  ..length = 32
  ..setMidiDataFromSimpleMelody({
    21: [-18],
  }, simpleVelocity: 127);

Melody twentyNineOutOfThirtyTwo() => baseMelody()
  ..name = "29/32"
  ..instrumentType = InstrumentType.drum
  ..interpretationType = MelodyInterpretationType.fixed_nonadaptive
  ..subdivisionsPerBeat = 8
  ..length = 32
  ..setMidiDataFromSimpleMelody({
    29: [-18],
  }, simpleVelocity: 127);

Melody odeToJoy() => baseMelody()
  ..name = "Ode to Joy"
  ..instrumentType = InstrumentType.harmonic
  ..subdivisionsPerBeat = 2
  ..length = 64
  ..setMidiDataFromSimpleMelody(Map.from({
    0: [4],
    2: [4],
    4: [5],
    6: [7],
    8: [7],
    10: [5],
    12: [4],
    14: [2],
    16: [0],
    18: [0],
    20: [2],
    22: [4],
    24: [4],
    27: [2],
    28: [2]
  })
    ..addAll({
      0: [4],
      2: [4],
      4: [5],
      6: [7],
      8: [7],
      10: [5],
      12: [4],
      14: [2],
      16: [0],
      18: [0],
      20: [2],
      22: [4],
      24: [2],
      27: [0],
      28: [0]
    }.map((key, value) => MapEntry(key + 32, value))));

Melody odeToJoyA() => baseMelody()
  ..name = "Ode to Joy A"
  ..instrumentType = InstrumentType.harmonic
  ..subdivisionsPerBeat = 2
  ..length = 32
  ..setMidiDataFromSimpleMelody(Map.from({
    0: [4],
    2: [4],
    4: [5],
    6: [7],
    8: [7],
    10: [5],
    12: [4],
    14: [2],
    16: [0],
    18: [0],
    20: [2],
    22: [4],
    24: [4],
    27: [2],
    28: [2]
  }));

Melody odeToJoyB() => baseMelody()
  ..name = "Ode to Joy B"
  ..instrumentType = InstrumentType.harmonic
  ..subdivisionsPerBeat = 2
  ..length = 32
  ..setMidiDataFromSimpleMelody(Map.from({
    0: [4],
    2: [4],
    4: [5],
    6: [7],
    8: [7],
    10: [5],
    12: [4],
    14: [2],
    16: [0],
    18: [0],
    20: [2],
    22: [4],
    24: [2],
    27: [0],
    28: [0]
  }));

final defaultSubdivisionsPerBeat = 4;

Melody defaultMelody({int? sectionBeats}) => baseMelody()
  ..subdivisionsPerBeat = defaultSubdivisionsPerBeat
  ..length = (sectionBeats ?? defaultSectionBeats) * defaultSubdivisionsPerBeat
  ..interpretationType = MelodyInterpretationType.fixed
  ..type = MelodyType.midi
  ..midiData = MidiData();

Harmony defaultHarmony() => Harmony()
  ..id = uuid.v4()
  ..subdivisionsPerBeat = defaultSectionSubdivisionsPerBeat
  ..length = defaultSectionLength
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
  ..parts.addAll([newPartFor(Score()), newDrumPart()]);

Score melodyPreview(Melody melody, Part part, Section section) {
  melody = melody.bsRebuild((it) {
    it.id = "MelodyPreview-Melody-${melody.id}-${part.id}-{$section.id}";
  });
  part = part.bsRebuild((it) {
    it.id = "MelodyPreview-Part-${melody.id}-${part.id}-{$section.id}";
    it.melodies.clear();
    it.melodies.add(melody);
  });
  section = section.bsRebuild((it) {
    it.id = "MelodyPreview-Section-${melody.id}-${part.id}-{$section.id}";
    it.melodies.clear();
    it.melodies.add(MelodyReference()
      ..melodyId = melody.id
      ..playbackType = MelodyReference_PlaybackType.playback_indefinitely
      ..volume = 1);
  });
  Score result = Score();
  result.parts.add(part);
  result.sections.add(section);
  return result;
}

Score sectionPreview(Score score, Section section) {
  Score result = Score();
  result.parts.addAll(score.parts);
  result.sections.add(section);
  return result;
}

Score partPreview(Score score, Part part, Section section) {
  Score result = Score();
  result.parts.add(part);
  result.sections.add(section);
  return result;
}

extension MidiThings on Score {
  bool usesChannel(int channel) =>
      parts.any((part) => part.instrument.midiChannel == channel);
}

Part newPartFor(Score score) {
  Part part = Part()
    ..id = uuid.v4()
    ..instrument = (Instrument()
      ..midiInstrument = score.parts.any((part) =>
              part.instrument.midiInstrument == 0 &&
              part.instrument.type != InstrumentType.drum)
          ? (score.parts.any((part) => part.instrument.midiInstrument == 34)
              ? (score.parts.any((part) => part.instrument.midiInstrument == 25)
                  ? (score.parts
                          .any((part) => part.instrument.midiInstrument == 4)
                      ? (72)
                      : 4)
                  : 25)
              : 34)
          : 0
      ..midiChannel = (range(0, 8).toList() + range(10, 15).toList())
          .firstWhere((channel) => !score.usesChannel(channel))
      ..volume = 0.5
      ..type = InstrumentType.harmonic);
  return part;
}

Part newDrumPart() {
  Part part = Part()
    ..id = uuid.v4()
    ..instrument = (Instrument()
      ..name = "" //"Drums"
      ..volume = 0.5
      ..midiChannel = 9
      ..type = InstrumentType.drum);
  return part;
}
