import 'package:unification/unification.dart';

import 'generated/protos/music.pb.dart';
import 'music_theory.dart';
import 'util.dart';

class NoteSpecification {
  final NoteName noteName;
  final int octave;
  int get tone => noteName.tone + (octave - 4) * 12;
  NoteLetter get letter => noteName.noteLetter;
  NoteSign get sign => noteName.noteSign;
  int get diatonicValue => 7 * octave + letter.value;
  @override String toString() => "NoteSpecification:${noteName.noteLetter.name}${noteName.noteSign.simpleString}$octave";

  NoteSpecification({this.noteName, this.octave});

  NoteSpecification.name({NoteLetter letter, NoteSign sign = NoteSign.natural, int octave})
    : this(
    noteName: (NoteName()
      ..noteLetter = letter
      ..noteSign = sign),
    octave: octave);
}

extension HeptatonicConversions on int {
  static final Map<int, List<NoteSpecification>> _notesFor = range(-4, 12).map((octave) =>
    NoteLetter.values.map((letter) =>
      NoteSign.values.map((sign) => NoteSpecification.name(letter: letter, sign: sign, octave: octave))
    )).expand((i) => i).expand((i) => i).toList().groupBy(((note) => note.tone));

  NoteSpecification get naturalOrSharpNote => _notesFor[this].firstWhere(
      (note) => note.sign == NoteSign.natural, orElse: () => null
  ) ?? _notesFor[this].firstWhere((note) => note.sign == NoteSign.sharp);

  static final Map<Chord, Map<int, NoteSpecification>> _noteNameChordCache = Map();
  NoteSpecification nameNoteUnderChord(Chord chord) => _noteNameChordCache
    .putIfAbsent(chord, () => Map())
    .putIfAbsent(this, () => _nameNoteUnderChord(chord));

  NoteSpecification _nameNoteUnderChord(Chord chord) {
    NoteName rootNote = chord.rootNote;
    int difference = (this - rootNote.tone).mod12;
    switch (difference) {
      case 0:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter);
      case 1:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 1); // m2
      case 2:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 1); // M2
      case 3:
//        if(chord.hasAug9) {
//          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 1); // A2
//        } else {
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 2); // m3
//        }
      case 4:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 2); // M3
      case 5:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 3); // P4
      case 6:
//        if (chord.hasAug4) {
//          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 3); // A4
//        } else {
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 4); // d5
//        }
      case 7:
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 4); // P5
      case 8:
//        if(chord.hasAug5) {
//          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 4); // A5
//        } else {
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 5); // m6
//        }
      case 9:
//        if (chord.hasDiminished5 && chord.hasMinor3 && !chord.hasMinor7 && !chord.hasMajor7) {
//          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 5); // d7
//        } else {
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 5); // M6
//        }
      case 10:
//        if(chord.hasAug6) {
//          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 5); // A6
//        } else {
        return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 6); // m7
//        }
      case 11:
        if(rootNote.sign == NoteSign.double_sharp) {
          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter); // diminished 1 (for readability)
        } else {
          return _notesFor[this].firstWhere((it) => it.letter == rootNote.letter + 6); //M7
        }
        break;
      default:
        throw "impossible!";
    }
  }

  int playbackToneUnder(Chord chord, Melody melody) {
    if(melody.interpretationType != MelodyInterpretationType.fixed_nonadaptive) {
      int transposedTone = this + melody.offsetUnder(chord);
      return chord.closestTone(transposedTone);
    } else {
      return this;
    }
  }


}
