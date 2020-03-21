import 'package:unification/unification.dart';

import 'generated/protos/music.pb.dart';


extension NoteLetterTheory on NoteLetter {
  int get tone {
    switch (this) {
      case NoteLetter.C: { return 0; }
      case NoteLetter.D: { return 2; }
      case NoteLetter.E: { return 4; }
      case NoteLetter.F: { return 5; }
      case NoteLetter.G: { return 7; }
      case NoteLetter.A: { return 9; }
      case NoteLetter.B: { return 11; }
      default: { throw FormatException(); }
    }
  }
}

extension NoteSignTheory on NoteSign {
  int get toneOffset {
    switch (this) {
//      case NoteSign.none: { return 0; }
      case NoteSign.natural: { return 0; }
      case NoteSign.sharp: { return 1; }
      case NoteSign.flat: { return -1; }
      case NoteSign.double_sharp: { return 2; }
      case NoteSign.double_flat: { return -2; }
      default: { throw FormatException(); }
    }
  }
}

extension NoteTheory on NoteName {
  int get tone => noteLetter.tone + noteSign.toneOffset;
}

extension NoteConversions on int {
  List<NoteName> get noteNames => [];
  int get mod12 {
    int result = this;
    result = result % 12;
    while(result < 0) {
      result += 12;
    }
    return result;
  }
}

extension ChordTheory on Chord {
  /// Returns the nearest
  int closestTone(int tone) {
    int result;
    range(0, 11)
      .forEach((i) {
        if(result == null) {
          if (containsTone(tone - i)) {
            result = tone - i;
          }
          if (containsTone(tone + i)) {
            result = tone + i;
          }
        }
    });
    return result ?? rootNote.tone;
  }

  bool containsTone(int tone) {
    tone = tone.mod12;
    int root = rootNote.tone;
    if(root == 0) {
      return true;
    }
    int difference = (tone - root).mod12;
    if((extension_3 << difference) & 0x0001 == 1) {
      return true;
    }
    return false;
  }
}

extension HarmonyTheory on Harmony {
  int get beatCount => (length.toDouble() / subdivisionsPerBeat).ceil();
}

extension SectionTheory on Section {
  int get beatCount => harmony.beatCount;

  MelodyReference referenceTo(Melody melody) => (melody != null) ? melodies.firstWhere(
      (element) => element.melodyId == melody.id,
      orElse: () => _defaultMelodyReference(melody)
  ) : null;

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
  int get beatCount => sections.fold(0, (p,s) => p + s.beatCount);
}