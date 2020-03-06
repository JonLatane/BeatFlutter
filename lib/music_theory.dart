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

extension NoteTheory on Note {
  int get tone => noteLetter.tone + noteSign.toneOffset;
}

extension NoteConversions on int {
  List<Note> get noteNames => [];
}

extension ChordTheory on Chord {
  /// Returns the nearest
  int closestTone(int tone) {

  }
}