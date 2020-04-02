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
  int get mod12 {
    int result = this;
    result = result % 12;
    while (result < 0) {
      result += 12;
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
//    print("closest to $tone for ${this.toString().replaceAll("\n", "")} is $result");
    return result ?? rootNote.tone;
  }

  bool containsTone(int tone) {
    tone = tone.mod12;
    int root = rootNote.tone;
    if (root == tone) {
      return true;
    }
    int difference = (tone - root).mod12 - 1;
    if ((chroma >> difference) & 0x0001 == 1) {
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
  int offsetUnder(Chord chord) {
    int result = 0;
    if (interpretationType != MelodyInterpretationType.fixed) {
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
