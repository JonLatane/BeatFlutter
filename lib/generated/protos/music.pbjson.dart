///
//  Generated code. Do not modify.
//  source: protos/music.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use noteLetterDescriptor instead')
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

/// Descriptor for `NoteLetter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List noteLetterDescriptor = $convert.base64Decode('CgpOb3RlTGV0dGVyEgUKAUMQABIFCgFEEAESBQoBRRACEgUKAUYQAxIFCgFHEAQSBQoBQRAFEgUKAUIQBg==');
@$core.Deprecated('Use noteSignDescriptor instead')
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

/// Descriptor for `NoteSign`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List noteSignDescriptor = $convert.base64Decode('CghOb3RlU2lnbhILCgduYXR1cmFsEAASCAoEZmxhdBABEg8KC2RvdWJsZV9mbGF0EAISCQoFc2hhcnAQAxIQCgxkb3VibGVfc2hhcnAQBA==');
@$core.Deprecated('Use instrumentTypeDescriptor instead')
const InstrumentType$json = const {
  '1': 'InstrumentType',
  '2': const [
    const {'1': 'harmonic', '2': 0},
    const {'1': 'drum', '2': 1},
  ],
};

/// Descriptor for `InstrumentType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List instrumentTypeDescriptor = $convert.base64Decode('Cg5JbnN0cnVtZW50VHlwZRIMCghoYXJtb25pYxAAEggKBGRydW0QAQ==');
@$core.Deprecated('Use melodyTypeDescriptor instead')
const MelodyType$json = const {
  '1': 'MelodyType',
  '2': const [
    const {'1': 'midi', '2': 0},
    const {'1': 'audio', '2': 1},
  ],
};

/// Descriptor for `MelodyType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List melodyTypeDescriptor = $convert.base64Decode('CgpNZWxvZHlUeXBlEggKBG1pZGkQABIJCgVhdWRpbxAB');
@$core.Deprecated('Use melodyInterpretationTypeDescriptor instead')
const MelodyInterpretationType$json = const {
  '1': 'MelodyInterpretationType',
  '2': const [
    const {'1': 'fixed_nonadaptive', '2': 0},
    const {'1': 'fixed', '2': 1},
    const {'1': 'relative_to_c', '2': 2},
    const {'1': 'relative_to_c_sharp', '2': 3},
    const {'1': 'relative_to_d', '2': 4},
    const {'1': 'relative_to_d_sharp', '2': 5},
    const {'1': 'relative_to_e', '2': 6},
    const {'1': 'relative_to_f', '2': 7},
    const {'1': 'relative_to_f_sharp', '2': 8},
    const {'1': 'relative_to_g', '2': 9},
    const {'1': 'relative_to_g_sharp', '2': 10},
    const {'1': 'relative_to_a', '2': 11},
    const {'1': 'relative_to_a_sharp', '2': 12},
    const {'1': 'relative_to_b', '2': 13},
  ],
};

/// Descriptor for `MelodyInterpretationType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List melodyInterpretationTypeDescriptor = $convert.base64Decode('ChhNZWxvZHlJbnRlcnByZXRhdGlvblR5cGUSFQoRZml4ZWRfbm9uYWRhcHRpdmUQABIJCgVmaXhlZBABEhEKDXJlbGF0aXZlX3RvX2MQAhIXChNyZWxhdGl2ZV90b19jX3NoYXJwEAMSEQoNcmVsYXRpdmVfdG9fZBAEEhcKE3JlbGF0aXZlX3RvX2Rfc2hhcnAQBRIRCg1yZWxhdGl2ZV90b19lEAYSEQoNcmVsYXRpdmVfdG9fZhAHEhcKE3JlbGF0aXZlX3RvX2Zfc2hhcnAQCBIRCg1yZWxhdGl2ZV90b19nEAkSFwoTcmVsYXRpdmVfdG9fZ19zaGFycBAKEhEKDXJlbGF0aXZlX3RvX2EQCxIXChNyZWxhdGl2ZV90b19hX3NoYXJwEAwSEQoNcmVsYXRpdmVfdG9fYhAN');
@$core.Deprecated('Use intervalColorDescriptor instead')
const IntervalColor$json = const {
  '1': 'IntervalColor',
  '2': const [
    const {'1': 'major', '2': 0},
    const {'1': 'minor', '2': 1},
    const {'1': 'perfect', '2': 2},
    const {'1': 'augmented', '2': 3},
    const {'1': 'diminished', '2': 4},
  ],
};

/// Descriptor for `IntervalColor`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List intervalColorDescriptor = $convert.base64Decode('Cg1JbnRlcnZhbENvbG9yEgkKBW1ham9yEAASCQoFbWlub3IQARILCgdwZXJmZWN0EAISDQoJYXVnbWVudGVkEAMSDgoKZGltaW5pc2hlZBAE');
@$core.Deprecated('Use noteNameDescriptor instead')
const NoteName$json = const {
  '1': 'NoteName',
  '2': const [
    const {'1': 'note_letter', '3': 1, '4': 1, '5': 14, '6': '.NoteLetter', '10': 'noteLetter'},
    const {'1': 'note_sign', '3': 2, '4': 1, '5': 14, '6': '.NoteSign', '10': 'noteSign'},
  ],
};

/// Descriptor for `NoteName`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List noteNameDescriptor = $convert.base64Decode('CghOb3RlTmFtZRIsCgtub3RlX2xldHRlchgBIAEoDjILLk5vdGVMZXR0ZXJSCm5vdGVMZXR0ZXISJgoJbm90ZV9zaWduGAIgASgOMgkuTm90ZVNpZ25SCG5vdGVTaWdu');
@$core.Deprecated('Use chordDescriptor instead')
const Chord$json = const {
  '1': 'Chord',
  '2': const [
    const {'1': 'root_note', '3': 1, '4': 1, '5': 11, '6': '.NoteName', '10': 'rootNote'},
    const {'1': 'bass_note', '3': 2, '4': 1, '5': 11, '6': '.NoteName', '10': 'bassNote'},
    const {'1': 'chroma', '3': 3, '4': 1, '5': 13, '10': 'chroma'},
  ],
};

/// Descriptor for `Chord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chordDescriptor = $convert.base64Decode('CgVDaG9yZBImCglyb290X25vdGUYASABKAsyCS5Ob3RlTmFtZVIIcm9vdE5vdGUSJgoJYmFzc19ub3RlGAIgASgLMgkuTm90ZU5hbWVSCGJhc3NOb3RlEhYKBmNocm9tYRgDIAEoDVIGY2hyb21h');
@$core.Deprecated('Use tempoDescriptor instead')
const Tempo$json = const {
  '1': 'Tempo',
  '2': const [
    const {'1': 'bpm', '3': 1, '4': 1, '5': 2, '10': 'bpm'},
    const {'1': 'transition', '3': 2, '4': 1, '5': 14, '6': '.Tempo.Transition', '10': 'transition'},
  ],
  '4': const [Tempo_Transition$json],
};

@$core.Deprecated('Use tempoDescriptor instead')
const Tempo_Transition$json = const {
  '1': 'Transition',
  '2': const [
    const {'1': 'a_tempo', '2': 0},
    const {'1': 'linear', '2': 1},
  ],
};

/// Descriptor for `Tempo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tempoDescriptor = $convert.base64Decode('CgVUZW1wbxIQCgNicG0YASABKAJSA2JwbRIxCgp0cmFuc2l0aW9uGAIgASgOMhEuVGVtcG8uVHJhbnNpdGlvblIKdHJhbnNpdGlvbiIlCgpUcmFuc2l0aW9uEgsKB2FfdGVtcG8QABIKCgZsaW5lYXIQAQ==');
@$core.Deprecated('Use meterDescriptor instead')
const Meter$json = const {
  '1': 'Meter',
  '2': const [
    const {'1': 'default_beats_per_measure', '3': 1, '4': 1, '5': 13, '10': 'defaultBeatsPerMeasure'},
  ],
};

/// Descriptor for `Meter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List meterDescriptor = $convert.base64Decode('CgVNZXRlchI5ChlkZWZhdWx0X2JlYXRzX3Blcl9tZWFzdXJlGAEgASgNUhZkZWZhdWx0QmVhdHNQZXJNZWFzdXJl');
@$core.Deprecated('Use harmonyDescriptor instead')
const Harmony$json = const {
  '1': 'Harmony',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'subdivisions_per_beat', '3': 2, '4': 1, '5': 13, '10': 'subdivisionsPerBeat'},
    const {'1': 'length', '3': 3, '4': 1, '5': 13, '10': 'length'},
    const {'1': 'data', '3': 100, '4': 3, '5': 11, '6': '.Harmony.DataEntry', '10': 'data'},
  ],
  '3': const [Harmony_DataEntry$json],
};

@$core.Deprecated('Use harmonyDescriptor instead')
const Harmony_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 17, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.Chord', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Harmony`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List harmonyDescriptor = $convert.base64Decode('CgdIYXJtb255Eg4KAmlkGAEgASgJUgJpZBIyChVzdWJkaXZpc2lvbnNfcGVyX2JlYXQYAiABKA1SE3N1YmRpdmlzaW9uc1BlckJlYXQSFgoGbGVuZ3RoGAMgASgNUgZsZW5ndGgSJgoEZGF0YRhkIAMoCzISLkhhcm1vbnkuRGF0YUVudHJ5UgRkYXRhGj8KCURhdGFFbnRyeRIQCgNrZXkYASABKBFSA2tleRIcCgV2YWx1ZRgCIAEoCzIGLkNob3JkUgV2YWx1ZToCOAE=');
@$core.Deprecated('Use melodyDescriptor instead')
const Melody$json = const {
  '1': 'Melody',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'subdivisions_per_beat', '3': 3, '4': 1, '5': 13, '10': 'subdivisionsPerBeat'},
    const {'1': 'length', '3': 4, '4': 1, '5': 13, '10': 'length'},
    const {'1': 'type', '3': 5, '4': 1, '5': 14, '6': '.MelodyType', '10': 'type'},
    const {'1': 'instrument_type', '3': 6, '4': 1, '5': 14, '6': '.InstrumentType', '10': 'instrumentType'},
    const {'1': 'interpretation_type', '3': 7, '4': 1, '5': 14, '6': '.MelodyInterpretationType', '10': 'interpretationType'},
    const {'1': 'transpose', '3': 8, '4': 1, '5': 17, '10': 'transpose'},
    const {'1': 'midi_data', '3': 101, '4': 1, '5': 11, '6': '.MidiData', '9': 0, '10': 'midiData'},
  ],
  '8': const [
    const {'1': 'data'},
  ],
};

/// Descriptor for `Melody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List melodyDescriptor = $convert.base64Decode('CgZNZWxvZHkSDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSMgoVc3ViZGl2aXNpb25zX3Blcl9iZWF0GAMgASgNUhNzdWJkaXZpc2lvbnNQZXJCZWF0EhYKBmxlbmd0aBgEIAEoDVIGbGVuZ3RoEh8KBHR5cGUYBSABKA4yCy5NZWxvZHlUeXBlUgR0eXBlEjgKD2luc3RydW1lbnRfdHlwZRgGIAEoDjIPLkluc3RydW1lbnRUeXBlUg5pbnN0cnVtZW50VHlwZRJKChNpbnRlcnByZXRhdGlvbl90eXBlGAcgASgOMhkuTWVsb2R5SW50ZXJwcmV0YXRpb25UeXBlUhJpbnRlcnByZXRhdGlvblR5cGUSHAoJdHJhbnNwb3NlGAggASgRUgl0cmFuc3Bvc2USKAoJbWlkaV9kYXRhGGUgASgLMgkuTWlkaURhdGFIAFIIbWlkaURhdGFCBgoEZGF0YQ==');
@$core.Deprecated('Use midiDataDescriptor instead')
const MidiData$json = const {
  '1': 'MidiData',
  '2': const [
    const {'1': 'data', '3': 1, '4': 3, '5': 11, '6': '.MidiData.DataEntry', '10': 'data'},
  ],
  '3': const [MidiData_DataEntry$json],
};

@$core.Deprecated('Use midiDataDescriptor instead')
const MidiData_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 17, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.MidiChange', '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `MidiData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiDataDescriptor = $convert.base64Decode('CghNaWRpRGF0YRInCgRkYXRhGAEgAygLMhMuTWlkaURhdGEuRGF0YUVudHJ5UgRkYXRhGkQKCURhdGFFbnRyeRIQCgNrZXkYASABKBFSA2tleRIhCgV2YWx1ZRgCIAEoCzILLk1pZGlDaGFuZ2VSBXZhbHVlOgI4AQ==');
@$core.Deprecated('Use melodicAttackDescriptor instead')
const MelodicAttack$json = const {
  '1': 'MelodicAttack',
  '2': const [
    const {'1': 'tones', '3': 1, '4': 3, '5': 17, '10': 'tones'},
    const {'1': 'velocity', '3': 2, '4': 1, '5': 2, '10': 'velocity'},
  ],
};

/// Descriptor for `MelodicAttack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List melodicAttackDescriptor = $convert.base64Decode('Cg1NZWxvZGljQXR0YWNrEhQKBXRvbmVzGAEgAygRUgV0b25lcxIaCgh2ZWxvY2l0eRgCIAEoAlIIdmVsb2NpdHk=');
@$core.Deprecated('Use midiChangeDescriptor instead')
const MidiChange$json = const {
  '1': 'MidiChange',
  '2': const [
    const {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `MidiChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiChangeDescriptor = $convert.base64Decode('CgpNaWRpQ2hhbmdlEhIKBGRhdGEYASABKAxSBGRhdGE=');
@$core.Deprecated('Use instrumentDescriptor instead')
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
    const {'1': 'sound_fonts', '3': 8, '4': 1, '5': 11, '6': '.SoundFonts', '10': 'soundFonts'},
  ],
};

/// Descriptor for `Instrument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List instrumentDescriptor = $convert.base64Decode('CgpJbnN0cnVtZW50EhIKBG5hbWUYASABKAlSBG5hbWUSIwoEdHlwZRgCIAEoDjIPLkluc3RydW1lbnRUeXBlUgR0eXBlEhYKBnZvbHVtZRgDIAEoAlIGdm9sdW1lEiEKDG1pZGlfY2hhbm5lbBgEIAEoDVILbWlkaUNoYW5uZWwSJwoPbWlkaV9pbnN0cnVtZW50GAUgASgNUg5taWRpSW5zdHJ1bWVudBIgCgxtaWRpX2dtMl9tc2IYBiABKA1SCm1pZGlHbTJNc2ISIAoMbWlkaV9nbTJfbHNiGAcgASgNUgptaWRpR20yTHNiEiwKC3NvdW5kX2ZvbnRzGAggASgLMgsuU291bmRGb250c1IKc291bmRGb250cw==');
@$core.Deprecated('Use soundFontsDescriptor instead')
const SoundFonts$json = const {
  '1': 'SoundFonts',
  '2': const [
    const {'1': 'sound_fonts', '3': 1, '4': 3, '5': 11, '6': '.SoundFont', '10': 'soundFonts'},
  ],
};

/// Descriptor for `SoundFonts`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List soundFontsDescriptor = $convert.base64Decode('CgpTb3VuZEZvbnRzEisKC3NvdW5kX2ZvbnRzGAEgAygLMgouU291bmRGb250Ugpzb3VuZEZvbnRz');
@$core.Deprecated('Use soundFontDescriptor instead')
const SoundFont$json = const {
  '1': 'SoundFont',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'key_switches', '3': 2, '4': 3, '5': 11, '6': '.KeySwitch', '10': 'keySwitches'},
  ],
};

/// Descriptor for `SoundFont`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List soundFontDescriptor = $convert.base64Decode('CglTb3VuZEZvbnQSEgoEbmFtZRgBIAEoCVIEbmFtZRItCgxrZXlfc3dpdGNoZXMYAiADKAsyCi5LZXlTd2l0Y2hSC2tleVN3aXRjaGVz');
@$core.Deprecated('Use keySwitchDescriptor instead')
const KeySwitch$json = const {
  '1': 'KeySwitch',
  '2': const [
    const {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `KeySwitch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keySwitchDescriptor = $convert.base64Decode('CglLZXlTd2l0Y2gSFAoFbGFiZWwYASABKAlSBWxhYmVs');
@$core.Deprecated('Use partDescriptor instead')
const Part$json = const {
  '1': 'Part',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'instrument', '3': 3, '4': 1, '5': 11, '6': '.Instrument', '10': 'instrument'},
    const {'1': 'melodies', '3': 4, '4': 3, '5': 11, '6': '.Melody', '10': 'melodies'},
  ],
};

/// Descriptor for `Part`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List partDescriptor = $convert.base64Decode('CgRQYXJ0Eg4KAmlkGAEgASgJUgJpZBIrCgppbnN0cnVtZW50GAMgASgLMgsuSW5zdHJ1bWVudFIKaW5zdHJ1bWVudBIjCghtZWxvZGllcxgEIAMoCzIHLk1lbG9keVIIbWVsb2RpZXM=');
@$core.Deprecated('Use melodyReferenceDescriptor instead')
const MelodyReference$json = const {
  '1': 'MelodyReference',
  '2': const [
    const {'1': 'melody_id', '3': 1, '4': 1, '5': 9, '10': 'melodyId'},
    const {'1': 'playback_type', '3': 2, '4': 1, '5': 14, '6': '.MelodyReference.PlaybackType', '10': 'playbackType'},
    const {'1': 'volume', '3': 3, '4': 1, '5': 2, '10': 'volume'},
  ],
  '4': const [MelodyReference_PlaybackType$json],
};

@$core.Deprecated('Use melodyReferenceDescriptor instead')
const MelodyReference_PlaybackType$json = const {
  '1': 'PlaybackType',
  '2': const [
    const {'1': 'disabled', '2': 0},
    const {'1': 'playback_indefinitely', '2': 1},
  ],
};

/// Descriptor for `MelodyReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List melodyReferenceDescriptor = $convert.base64Decode('Cg9NZWxvZHlSZWZlcmVuY2USGwoJbWVsb2R5X2lkGAEgASgJUghtZWxvZHlJZBJCCg1wbGF5YmFja190eXBlGAIgASgOMh0uTWVsb2R5UmVmZXJlbmNlLlBsYXliYWNrVHlwZVIMcGxheWJhY2tUeXBlEhYKBnZvbHVtZRgDIAEoAlIGdm9sdW1lIjcKDFBsYXliYWNrVHlwZRIMCghkaXNhYmxlZBAAEhkKFXBsYXliYWNrX2luZGVmaW5pdGVseRAB');
@$core.Deprecated('Use sectionDescriptor instead')
const Section$json = const {
  '1': 'Section',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'harmony', '3': 3, '4': 1, '5': 11, '6': '.Harmony', '10': 'harmony'},
    const {'1': 'meter', '3': 4, '4': 1, '5': 11, '6': '.Meter', '10': 'meter'},
    const {'1': 'tempo', '3': 5, '4': 1, '5': 11, '6': '.Tempo', '10': 'tempo'},
    const {'1': 'key', '3': 6, '4': 1, '5': 11, '6': '.NoteName', '10': 'key'},
    const {'1': 'transpose', '3': 7, '4': 1, '5': 17, '10': 'transpose'},
    const {'1': 'color', '3': 8, '4': 1, '5': 14, '6': '.IntervalColor', '10': 'color'},
    const {'1': 'melodies', '3': 100, '4': 3, '5': 11, '6': '.MelodyReference', '10': 'melodies'},
  ],
};

/// Descriptor for `Section`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sectionDescriptor = $convert.base64Decode('CgdTZWN0aW9uEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEiIKB2hhcm1vbnkYAyABKAsyCC5IYXJtb255UgdoYXJtb255EhwKBW1ldGVyGAQgASgLMgYuTWV0ZXJSBW1ldGVyEhwKBXRlbXBvGAUgASgLMgYuVGVtcG9SBXRlbXBvEhsKA2tleRgGIAEoCzIJLk5vdGVOYW1lUgNrZXkSHAoJdHJhbnNwb3NlGAcgASgRUgl0cmFuc3Bvc2USJAoFY29sb3IYCCABKA4yDi5JbnRlcnZhbENvbG9yUgVjb2xvchIsCghtZWxvZGllcxhkIAMoCzIQLk1lbG9keVJlZmVyZW5jZVIIbWVsb2RpZXM=');
@$core.Deprecated('Use scoreDescriptor instead')
const Score$json = const {
  '1': 'Score',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'parts', '3': 3, '4': 3, '5': 11, '6': '.Part', '10': 'parts'},
    const {'1': 'sections', '3': 4, '4': 3, '5': 11, '6': '.Section', '10': 'sections'},
  ],
};

/// Descriptor for `Score`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scoreDescriptor = $convert.base64Decode('CgVTY29yZRIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIbCgVwYXJ0cxgDIAMoCzIFLlBhcnRSBXBhcnRzEiQKCHNlY3Rpb25zGAQgAygLMgguU2VjdGlvblIIc2VjdGlvbnM=');
