///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Playback_Mode extends $pb.ProtobufEnum {
  static const Playback_Mode score = Playback_Mode._(0, 'score');
  static const Playback_Mode section = Playback_Mode._(1, 'section');

  static const $core.List<Playback_Mode> values = <Playback_Mode> [
    score,
    section,
  ];

  static final $core.Map<$core.int, Playback_Mode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Playback_Mode valueOf($core.int value) => _byValue[value];

  const Playback_Mode._($core.int v, $core.String n) : super(v, n);
}

