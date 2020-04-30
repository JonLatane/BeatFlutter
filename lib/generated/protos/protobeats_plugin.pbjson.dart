///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const MidiSynthesizer$json = const {
  '1': 'MidiSynthesizer',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

const MidiController$json = const {
  '1': 'MidiController',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

const MidiSynthesizers$json = const {
  '1': 'MidiSynthesizers',
  '2': const [
    const {'1': 'synthesizers', '3': 1, '4': 3, '5': 11, '6': '.MidiSynthesizer', '10': 'synthesizers'},
  ],
};

const MidiControllers$json = const {
  '1': 'MidiControllers',
  '2': const [
    const {'1': 'controllers', '3': 1, '4': 3, '5': 11, '6': '.MidiController', '10': 'controllers'},
  ],
};

const MidiNotes$json = const {
  '1': 'MidiNotes',
  '2': const [
    const {'1': 'midi_notes', '3': 1, '4': 3, '5': 13, '10': 'midiNotes'},
  ],
};

const RegisterMelody$json = const {
  '1': 'RegisterMelody',
  '2': const [
    const {'1': 'melody_id', '3': 1, '4': 1, '5': 9, '10': 'melodyId'},
    const {'1': 'part_id', '3': 2, '4': 1, '5': 9, '10': 'partId'},
  ],
};

const Playback$json = const {
  '1': 'Playback',
  '2': const [
    const {'1': 'mode', '3': 1, '4': 1, '5': 14, '6': '.Playback.Mode', '10': 'mode'},
  ],
  '4': const [Playback_Mode$json],
};

const Playback_Mode$json = const {
  '1': 'Mode',
  '2': const [
    const {'1': 'score', '2': 0},
    const {'1': 'section', '2': 1},
  ],
};

