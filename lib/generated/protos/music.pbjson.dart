///
//  Generated code. Do not modify.
//  source: protos/music.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const NoteLetter$json = const {
  '1': 'NoteLetter',
  '2': const [
    const {'1': 'C', '2': 0},
    const {'1': 'D', '2': 1},
    const {'1': 'E', '2': 2},
    const {'1': 'F', '2': 3},
    const {'1': 'G', '2': 4},
    const {'1': 'A', '2': 5},
    const {'1': 'B', '2': 6},
  ],
};

const NoteSign$json = const {
  '1': 'NoteSign',
  '2': const [
    const {'1': 'natural', '2': 0},
    const {'1': 'flat', '2': 1},
    const {'1': 'double_flat', '2': 2},
    const {'1': 'sharp', '2': 3},
    const {'1': 'double_sharp', '2': 4},
  ],
};

const InstrumentType$json = const {
  '1': 'InstrumentType',
  '2': const [
    const {'1': 'harmonic', '2': 0},
    const {'1': 'drum', '2': 1},
  ],
};

const MelodyType$json = const {
  '1': 'MelodyType',
  '2': const [
    const {'1': 'melodic', '2': 0},
    const {'1': 'midi', '2': 1},
  ],
};

const NoteName$json = const {
  '1': 'NoteName',
  '2': const [
    const {'1': 'note_letter', '3': 1, '4': 1, '5': 14, '6': '.NoteLetter', '10': 'noteLetter'},
    const {'1': 'note_sign', '3': 2, '4': 1, '5': 14, '6': '.NoteSign', '10': 'noteSign'},
  ],
};

const NoteSpecification$json = const {
  '1': 'NoteSpecification',
  '2': const [
    const {'1': 'note_letter', '3': 1, '4': 1, '5': 14, '6': '.NoteLetter', '10': 'noteLetter'},
    const {'1': 'note_sign', '3': 2, '4': 1, '5': 14, '6': '.NoteSign', '10': 'noteSign'},
    const {'1': 'octave', '3': 3, '4': 1, '5': 17, '10': 'octave'},
  ],
};

const Chord$json = const {
  '1': 'Chord',
  '2': const [
    const {'1': 'root_note', '3': 1, '4': 1, '5': 11, '6': '.NoteName', '10': 'rootNote'},
    const {'1': 'bass_note', '3': 2, '4': 1, '5': 11, '6': '.NoteName', '10': 'bassNote'},
    const {'1': 'extension', '3': 3, '4': 1, '5': 13, '10': 'extension'},
  ],
};

const Harmony$json = const {
  '1': 'Harmony',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'subdivisions_per_beat', '3': 2, '4': 1, '5': 13, '10': 'subdivisionsPerBeat'},
    const {'1': 'length', '3': 3, '4': 1, '5': 13, '10': 'length'},
    const {'1': 'data', '3': 4, '4': 3, '5': 11, '6': '.Harmony.DataEntry', '10': 'data'},
  ],
  '3': const [Harmony_DataEntry$json],
};

const Harmony_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 17, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.Chord', '10': 'value'},
  ],
  '7': const {'7': true},
};

const MelodyAttack$json = const {
  '1': 'MelodyAttack',
  '2': const [
    const {'1': 'tones', '3': 1, '4': 3, '5': 17, '10': 'tones'},
    const {'1': 'velocity', '3': 2, '4': 1, '5': 2, '10': 'velocity'},
  ],
};

const MidiChange$json = const {
  '1': 'MidiChange',
  '2': const [
    const {'1': 'length', '3': 1, '4': 1, '5': 13, '10': 'length'},
    const {'1': 'data', '3': 2, '4': 3, '5': 13, '10': 'data'},
  ],
};

const Melody$json = const {
  '1': 'Melody',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'subdivisions_per_beat', '3': 3, '4': 1, '5': 13, '10': 'subdivisionsPerBeat'},
    const {'1': 'length', '3': 4, '4': 1, '5': 13, '10': 'length'},
    const {'1': 'type', '3': 5, '4': 1, '5': 14, '6': '.MelodyType', '10': 'type'},
    const {'1': 'instrument_type', '3': 6, '4': 1, '5': 14, '6': '.InstrumentType', '10': 'instrumentType'},
    const {'1': 'melodic_data', '3': 7, '4': 3, '5': 11, '6': '.Melody.MelodicDataEntry', '10': 'melodicData'},
    const {'1': 'midi_data', '3': 8, '4': 3, '5': 11, '6': '.Melody.MidiDataEntry', '10': 'midiData'},
  ],
  '3': const [Melody_MelodicDataEntry$json, Melody_MidiDataEntry$json],
};

const Melody_MelodicDataEntry$json = const {
  '1': 'MelodicDataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 17, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.MelodyAttack', '10': 'value'},
  ],
  '7': const {'7': true},
};

const Melody_MidiDataEntry$json = const {
  '1': 'MidiDataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 17, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.MidiChange', '10': 'value'},
  ],
  '7': const {'7': true},
};

const Instrument$json = const {
  '1': 'Instrument',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.InstrumentType', '10': 'type'},
    const {'1': 'volume', '3': 3, '4': 1, '5': 2, '10': 'volume'},
    const {'1': 'midi_channel', '3': 4, '4': 1, '5': 13, '10': 'midiChannel'},
    const {'1': 'midi_instrument', '3': 5, '4': 1, '5': 13, '10': 'midiInstrument'},
    const {'1': 'midi_gm2_msb', '3': 6, '4': 1, '5': 13, '10': 'midiGm2Msb'},
    const {'1': 'midi_gm2_lsb', '3': 7, '4': 1, '5': 13, '10': 'midiGm2Lsb'},
  ],
};

const Part$json = const {
  '1': 'Part',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'instrument', '3': 3, '4': 1, '5': 11, '6': '.Instrument', '10': 'instrument'},
    const {'1': 'melodies', '3': 4, '4': 3, '5': 11, '6': '.Melody', '10': 'melodies'},
  ],
};

const MelodyReference$json = const {
  '1': 'MelodyReference',
  '2': const [
    const {'1': 'melody_id', '3': 1, '4': 1, '5': 9, '10': 'melodyId'},
    const {'1': 'playback_type', '3': 2, '4': 1, '5': 14, '6': '.MelodyReference.PlaybackType', '10': 'playbackType'},
    const {'1': 'volume', '3': 3, '4': 1, '5': 2, '10': 'volume'},
  ],
  '4': const [MelodyReference_PlaybackType$json],
};

const MelodyReference_PlaybackType$json = const {
  '1': 'PlaybackType',
  '2': const [
    const {'1': 'disabled', '2': 0},
    const {'1': 'playback_indefinitely', '2': 1},
  ],
};

const Section$json = const {
  '1': 'Section',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'harmony', '3': 3, '4': 1, '5': 11, '6': '.Harmony', '10': 'harmony'},
    const {'1': 'melodies', '3': 4, '4': 3, '5': 11, '6': '.MelodyReference', '10': 'melodies'},
  ],
};

const Score$json = const {
  '1': 'Score',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'parts', '3': 3, '4': 3, '5': 11, '6': '.Part', '10': 'parts'},
    const {'1': 'sections', '3': 4, '4': 3, '5': 11, '6': '.Section', '10': 'sections'},
  ],
};

