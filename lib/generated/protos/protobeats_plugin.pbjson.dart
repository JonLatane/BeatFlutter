///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use midiSynthesizerDescriptor instead')
const MidiSynthesizer$json = const {
  '1': 'MidiSynthesizer',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `MidiSynthesizer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiSynthesizerDescriptor = $convert.base64Decode('Cg9NaWRpU3ludGhlc2l6ZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGAoHZW5hYmxlZBgDIAEoCFIHZW5hYmxlZA==');
@$core.Deprecated('Use midiControllerDescriptor instead')
const MidiController$json = const {
  '1': 'MidiController',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `MidiController`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiControllerDescriptor = $convert.base64Decode('Cg5NaWRpQ29udHJvbGxlchIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRIYCgdlbmFibGVkGAMgASgIUgdlbmFibGVk');
@$core.Deprecated('Use midiDevicesDescriptor instead')
const MidiDevices$json = const {
  '1': 'MidiDevices',
  '2': const [
    const {'1': 'synthesizers', '3': 1, '4': 3, '5': 11, '6': '.MidiSynthesizer', '10': 'synthesizers'},
    const {'1': 'controllers', '3': 2, '4': 3, '5': 11, '6': '.MidiController', '10': 'controllers'},
  ],
};

/// Descriptor for `MidiDevices`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiDevicesDescriptor = $convert.base64Decode('CgtNaWRpRGV2aWNlcxI0CgxzeW50aGVzaXplcnMYASADKAsyEC5NaWRpU3ludGhlc2l6ZXJSDHN5bnRoZXNpemVycxIxCgtjb250cm9sbGVycxgCIAMoCzIPLk1pZGlDb250cm9sbGVyUgtjb250cm9sbGVycw==');
@$core.Deprecated('Use synthesizerAppDescriptor instead')
const SynthesizerApp$json = const {
  '1': 'SynthesizerApp',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'installed', '3': 2, '4': 1, '5': 8, '10': 'installed'},
    const {'1': 'storeLink', '3': 3, '4': 1, '5': 9, '10': 'storeLink'},
    const {'1': 'launchLink', '3': 4, '4': 1, '5': 9, '10': 'launchLink'},
  ],
};

/// Descriptor for `SynthesizerApp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List synthesizerAppDescriptor = $convert.base64Decode('Cg5TeW50aGVzaXplckFwcBISCgRuYW1lGAEgASgJUgRuYW1lEhwKCWluc3RhbGxlZBgCIAEoCFIJaW5zdGFsbGVkEhwKCXN0b3JlTGluaxgDIAEoCVIJc3RvcmVMaW5rEh4KCmxhdW5jaExpbmsYBCABKAlSCmxhdW5jaExpbms=');
@$core.Deprecated('Use controllerAppDescriptor instead')
const ControllerApp$json = const {
  '1': 'ControllerApp',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'installed', '3': 2, '4': 1, '5': 8, '10': 'installed'},
    const {'1': 'storeLink', '3': 3, '4': 1, '5': 9, '10': 'storeLink'},
    const {'1': 'launchLink', '3': 4, '4': 1, '5': 9, '10': 'launchLink'},
  ],
};

/// Descriptor for `ControllerApp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controllerAppDescriptor = $convert.base64Decode('Cg1Db250cm9sbGVyQXBwEhIKBG5hbWUYASABKAlSBG5hbWUSHAoJaW5zdGFsbGVkGAIgASgIUglpbnN0YWxsZWQSHAoJc3RvcmVMaW5rGAMgASgJUglzdG9yZUxpbmsSHgoKbGF1bmNoTGluaxgEIAEoCVIKbGF1bmNoTGluaw==');
@$core.Deprecated('Use midiAppsDescriptor instead')
const MidiApps$json = const {
  '1': 'MidiApps',
  '2': const [
    const {'1': 'synthesizers', '3': 1, '4': 3, '5': 11, '6': '.SynthesizerApp', '10': 'synthesizers'},
    const {'1': 'controllers', '3': 2, '4': 3, '5': 11, '6': '.ControllerApp', '10': 'controllers'},
  ],
};

/// Descriptor for `MidiApps`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiAppsDescriptor = $convert.base64Decode('CghNaWRpQXBwcxIzCgxzeW50aGVzaXplcnMYASADKAsyDy5TeW50aGVzaXplckFwcFIMc3ludGhlc2l6ZXJzEjAKC2NvbnRyb2xsZXJzGAIgAygLMg4uQ29udHJvbGxlckFwcFILY29udHJvbGxlcnM=');
@$core.Deprecated('Use midiNotesDescriptor instead')
const MidiNotes$json = const {
  '1': 'MidiNotes',
  '2': const [
    const {'1': 'midi_notes', '3': 1, '4': 3, '5': 13, '10': 'midiNotes'},
  ],
};

/// Descriptor for `MidiNotes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List midiNotesDescriptor = $convert.base64Decode('CglNaWRpTm90ZXMSHQoKbWlkaV9ub3RlcxgBIAMoDVIJbWlkaU5vdGVz');
@$core.Deprecated('Use registerMelodyDescriptor instead')
const RegisterMelody$json = const {
  '1': 'RegisterMelody',
  '2': const [
    const {'1': 'melody_id', '3': 1, '4': 1, '5': 9, '10': 'melodyId'},
    const {'1': 'part_id', '3': 2, '4': 1, '5': 9, '10': 'partId'},
  ],
};

/// Descriptor for `RegisterMelody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerMelodyDescriptor = $convert.base64Decode('Cg5SZWdpc3Rlck1lbG9keRIbCgltZWxvZHlfaWQYASABKAlSCG1lbG9keUlkEhcKB3BhcnRfaWQYAiABKAlSBnBhcnRJZA==');
@$core.Deprecated('Use playbackDescriptor instead')
const Playback$json = const {
  '1': 'Playback',
  '2': const [
    const {'1': 'mode', '3': 1, '4': 1, '5': 14, '6': '.Playback.Mode', '10': 'mode'},
  ],
  '4': const [Playback_Mode$json],
};

@$core.Deprecated('Use playbackDescriptor instead')
const Playback_Mode$json = const {
  '1': 'Mode',
  '2': const [
    const {'1': 'score', '2': 0},
    const {'1': 'section', '2': 1},
  ],
};

/// Descriptor for `Playback`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playbackDescriptor = $convert.base64Decode('CghQbGF5YmFjaxIiCgRtb2RlGAEgASgOMg4uUGxheWJhY2suTW9kZVIEbW9kZSIeCgRNb2RlEgkKBXNjb3JlEAASCwoHc2VjdGlvbhAB');
@$core.Deprecated('Use recordedSegmentDescriptor instead')
const RecordedSegment$json = const {
  '1': 'RecordedSegment',
  '2': const [
    const {'1': 'beats', '3': 1, '4': 3, '5': 11, '6': '.RecordedSegment.RecordedBeat', '10': 'beats'},
    const {'1': 'recorded_data', '3': 2, '4': 3, '5': 11, '6': '.RecordedSegment.RecordedData', '10': 'recordedData'},
  ],
  '3': const [RecordedSegment_RecordedBeat$json, RecordedSegment_RecordedData$json],
};

@$core.Deprecated('Use recordedSegmentDescriptor instead')
const RecordedSegment_RecordedBeat$json = const {
  '1': 'RecordedBeat',
  '2': const [
    const {'1': 'timestamp', '3': 1, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'beat', '3': 2, '4': 1, '5': 13, '10': 'beat'},
  ],
};

@$core.Deprecated('Use recordedSegmentDescriptor instead')
const RecordedSegment_RecordedData$json = const {
  '1': 'RecordedData',
  '2': const [
    const {'1': 'timestamp', '3': 1, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'midiData', '3': 2, '4': 1, '5': 12, '10': 'midiData'},
  ],
};

/// Descriptor for `RecordedSegment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordedSegmentDescriptor = $convert.base64Decode('Cg9SZWNvcmRlZFNlZ21lbnQSMwoFYmVhdHMYASADKAsyHS5SZWNvcmRlZFNlZ21lbnQuUmVjb3JkZWRCZWF0UgViZWF0cxJCCg1yZWNvcmRlZF9kYXRhGAIgAygLMh0uUmVjb3JkZWRTZWdtZW50LlJlY29yZGVkRGF0YVIMcmVjb3JkZWREYXRhGkAKDFJlY29yZGVkQmVhdBIcCgl0aW1lc3RhbXAYASABKARSCXRpbWVzdGFtcBISCgRiZWF0GAIgASgNUgRiZWF0GkgKDFJlY29yZGVkRGF0YRIcCgl0aW1lc3RhbXAYASABKARSCXRpbWVzdGFtcBIaCghtaWRpRGF0YRgCIAEoDFIIbWlkaURhdGE=');
