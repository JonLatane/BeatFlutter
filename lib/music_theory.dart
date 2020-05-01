import 'package:beatscratch_flutter_redux/midi_theory.dart';
import 'package:unification/unification.dart';

import 'generated/protos/music.pb.dart';

extension NoteLetterTheory on NoteLetter {
  int get tone {
    switch (this) {
      case NoteLetter.C:
        {
          return 0;
        }
      case NoteLetter.D:
        {
          return 2;
        }
      case NoteLetter.E:
        {
          return 4;
        }
      case NoteLetter.F:
        {
          return 5;
        }
      case NoteLetter.G:
        {
          return 7;
        }
      case NoteLetter.A:
        {
          return 9;
        }
      case NoteLetter.B:
        {
          return 11;
        }
      default:
        {
          throw FormatException();
        }
    }
  }

  NoteLetter operator +(int increment) =>
    NoteLetter.values.firstWhere(
        (letter) => letter.value == (value + increment) % 7
    );
}

extension NoteSignTheory on NoteSign {
  int get toneOffset {
    switch (this) {
//      case NoteSign.none: { return 0; }
      case NoteSign.natural:
        return 0;
      case NoteSign.sharp:
        return 1;
      case NoteSign.flat:
        return -1;
      case NoteSign.double_sharp:
        return 2;
      case NoteSign.double_flat:
        return -2;
      default:
        throw FormatException();
    }
  }

  String get simpleString {
    switch (this) {
//      case NoteSign.none: { return 0; }
      case NoteSign.natural:
        return "";
      case NoteSign.sharp:
        return "#";
      case NoteSign.flat:
        return "b";
      case NoteSign.double_sharp:
        return "##";
      case NoteSign.double_flat:
        return "bb";
      default:
        throw FormatException();
    }
  }
}

extension NoteTheory on NoteName {
  int get tone => noteLetter.tone + noteSign.toneOffset;

  int get mod12 => tone.mod12;

  NoteLetter get letter => noteLetter;

  NoteSign get sign => noteSign;
}

extension NoteConversions on int {
  bool get isBlackKey => mod12 == 1 || mod12 == 3 || mod12 == 6 || mod12 == 8 || mod12 == 10;
  bool get isWhiteKey => !isBlackKey;
  int get mod12 {
    int result = this;
    result = result % 12;
    while (result < 0) {
      result += 12;
    }
    return result;
  }
  int get mod7 {
    int result = this;
    result = result % 7;
    while (result < 0) {
      result += 7;
    }
    return result;
  }
}

extension PatternIndexConversions on int {
  int convertPatternIndex({int fromSubdivisionsPerBeat, int toSubdivisionsPerBeat, int toLength = 1000000000}) {
    // In the storageContext of the "from" melody, in, say, sixteenth notes (subdivisionsPerBeat=4),
    // if this is 5, then currentBeat is 1.25.
    double fromBeat = this.toDouble() / fromSubdivisionsPerBeat;

    double toLengthBeats = toLength.toDouble() / toSubdivisionsPerBeat;
    double positionInToPattern = fromBeat % toLengthBeats;

    // This candidate for attack is the closest element index to the current tick
    int result = (positionInToPattern * toSubdivisionsPerBeat).floor();
    return result;
  }
}

extension ChordTheory on Chord {
  bool has(int halfStepsFromRoot) => containsTone(rootNote.tone + halfStepsFromRoot);
  bool get hasMin2 => has(1);
  bool get hasMaj2 => has(2);
  bool get hasAug2 => has(3) && hasMaj3;
  bool get hasMin3 => has(3) && !hasMaj3;
  bool get hasMaj3 => has(4);
  bool get hasPer4 => has(5);
  bool get hasAug4 => has(6) && !hasDim5;
  bool get hasDim5 => has(6) && !hasPer5 && (hasMin3 || hasMaj3 || hasPer4 || (hasMin2 && hasMin7));
  bool get hasPer5 => has(7);
  bool get hasAug5 => has(8) && !hasPer5 && (hasMaj6 || hasMaj3 || hasMaj7 || (!hasDim5 && hasMaj6));
  bool get hasMin6 => (has(8) && !hasAug5);
  bool get hasMaj6 => has(9) && !(hasDim5 && hasMin3);
  bool get hasDim7 => has(9) && (hasDim5 && hasMin3);
  bool get hasAug6 => has(10) && hasMaj7;
  bool get hasMin7 => has(10) && !hasMaj7;
  bool get hasMaj7 => has(11);


  /// Returns the nearest
  int closestTone(int tone) {
    int result;
    range(0, 11).forEach((i) {
      if (result == null) {
        if (containsTone(tone - i)) {
          result = tone - i;
        }
        if (containsTone(tone + i)) {
          result = tone + i;
        }
      }
    });
    if(chroma != 2047) {
//      print("closest to $tone for ${this.toString().replaceAll("\n", "")} is $result");
    }
    return result ?? rootNote.tone;
  }

  bool containsTone(int tone) {
    tone = tone.mod12;
    int root = rootNote.tone;
    if (root == tone) {
      return true;
    }
    int difference = (tone - root).mod12;
    if ((chroma >> 11 - difference) & 0x0001 == 1) {
      return true;
    }
    return false;
  }
}

extension HarmonyTheory on Harmony {
  int get beatCount => (length.toDouble() / subdivisionsPerBeat).ceil();

  Chord changeBefore(int subdivision) {
    final int initialSubdivision = subdivision;
    Chord result = data[subdivision];
    while (result == null) {
      subdivision = subdivision - 1;
      if (subdivision < 0) {
        subdivision += length;
      }
      result = data[subdivision];
    }
    return result;
  }
}

extension MelodyTheory on Melody {
  Iterable<int> get tones => (type == MelodyType.melodic)
    ? melodicData.data.values.expand((it) => it.tones)
    : midiData.data.values.expand((it) => it.noteOns.map((e) => e.noteNumber - 60));
  double get averageTone => tones.length == 0 ? 0 : tones.reduce((a, b) => a + b) / tones.length.toDouble();
  Iterable<int> tonesAt(int elementPosition) {
    if (type == MelodyType.melodic) {
     return melodicData.data[elementPosition]?.tones ?? [];
    } else {
      final data = midiData.data[elementPosition];
      if(data != null) {
        final midiEvents = data.midiEvents;
        final convertedData = data.noteOns.map((e) => e.noteNumber - 60);
        return convertedData;
      }
      return [];
    }
  }

  int offsetUnder(Chord chord) {
    int result = 0;
    if (interpretationType != MelodyInterpretationType.fixed && interpretationType != MelodyInterpretationType.fixed_nonadaptive) {
      int root = chord.rootNote.tone.mod12;
      if (root > 6) {
        result = root - 12;
      } else {
        result = root;
      }
    }
    return result;
  }

  MelodicAttack melodicAttackBefore(int subdivision) {
    final int initialSubdivision = subdivision;
    MelodicAttack result = melodicData.data[subdivision];
    while (result == null) {
      subdivision = subdivision - 1;
      if (subdivision < 0) {
        subdivision += length;
      }
      result = melodicData.data[subdivision];
    }
    return result;
  }

  MidiChange midiChangeBefore(int subdivision) {
    final int initialSubdivision = subdivision;
    MidiChange result = midiData.data[subdivision];
    while (result == null) {
      subdivision = subdivision - 1;
      if (subdivision < 0) {
        subdivision += length;
      }
      result = midiData.data[subdivision];
    }
    return result;
  }
}

extension SectionTheory on Section {
  String get convenientName => (name.isEmpty) ? name : "Section ${id.substring(0, 5)}";
  int get beatCount => harmony.beatCount;

  MelodyReference referenceTo(Melody melody) =>
    (melody != null)
      ? melodies.firstWhere((element) => element.melodyId == melody.id, orElse: () => _defaultMelodyReference(melody))
      : null;

  MelodyReference _defaultMelodyReference(Melody melody) {
    var result = MelodyReference()
      ..melodyId = melody.id
      ..playbackType = MelodyReference_PlaybackType.disabled
      ..volume = 0.5;
    melodies.add(result);
    return result;
  }
}

extension PartTheory on Part {
//  String get convenientName => (name.isEmpty) ? name : "Part ${id.substring(0, 5)}";
  bool get isDrum => instrument.type == InstrumentType.drum;
  bool get isHarmonic => instrument.type == InstrumentType.harmonic;
  String get midiName => isDrum ? "Drums" : midiInstruments[instrument.midiInstrument];
}

extension ScoreTheory on Score {
  int get beatCount => sections.fold(0, (p, s) => p + s.beatCount);

  Melody melodyReferencedBy(MelodyReference ref) =>
    parts.fold(null, (previousValue, part) =>
    previousValue ?? part.melodies.firstWhere(
        (melody) => melody.id == ref.melodyId,
      orElse: () => null
    )
    );
}
