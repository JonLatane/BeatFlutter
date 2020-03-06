///
//  Generated code. Do not modify.
//  source: protos/music.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class NoteLetter extends $pb.ProtobufEnum {
  static const NoteLetter C = NoteLetter._(0, 'C');
  static const NoteLetter D = NoteLetter._(1, 'D');
  static const NoteLetter E = NoteLetter._(2, 'E');
  static const NoteLetter F = NoteLetter._(3, 'F');
  static const NoteLetter G = NoteLetter._(4, 'G');
  static const NoteLetter A = NoteLetter._(5, 'A');
  static const NoteLetter B = NoteLetter._(6, 'B');

  static const $core.List<NoteLetter> values = <NoteLetter> [
    C,
    D,
    E,
    F,
    G,
    A,
    B,
  ];

  static final $core.Map<$core.int, NoteLetter> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NoteLetter valueOf($core.int value) => _byValue[value];

  const NoteLetter._($core.int v, $core.String n) : super(v, n);
}

class NoteSign extends $pb.ProtobufEnum {
  static const NoteSign natural = NoteSign._(0, 'natural');
  static const NoteSign flat = NoteSign._(1, 'flat');
  static const NoteSign double_flat = NoteSign._(2, 'double_flat');
  static const NoteSign sharp = NoteSign._(3, 'sharp');
  static const NoteSign double_sharp = NoteSign._(4, 'double_sharp');

  static const $core.List<NoteSign> values = <NoteSign> [
    natural,
    flat,
    double_flat,
    sharp,
    double_sharp,
  ];

  static final $core.Map<$core.int, NoteSign> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NoteSign valueOf($core.int value) => _byValue[value];

  const NoteSign._($core.int v, $core.String n) : super(v, n);
}

class InstrumentType extends $pb.ProtobufEnum {
  static const InstrumentType harmonic = InstrumentType._(0, 'harmonic');
  static const InstrumentType drum = InstrumentType._(1, 'drum');

  static const $core.List<InstrumentType> values = <InstrumentType> [
    harmonic,
    drum,
  ];

  static final $core.Map<$core.int, InstrumentType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static InstrumentType valueOf($core.int value) => _byValue[value];

  const InstrumentType._($core.int v, $core.String n) : super(v, n);
}

class MelodyType extends $pb.ProtobufEnum {
  static const MelodyType melodic = MelodyType._(0, 'melodic');
  static const MelodyType midi = MelodyType._(1, 'midi');

  static const $core.List<MelodyType> values = <MelodyType> [
    melodic,
    midi,
  ];

  static final $core.Map<$core.int, MelodyType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MelodyType valueOf($core.int value) => _byValue[value];

  const MelodyType._($core.int v, $core.String n) : super(v, n);
}

class MelodyReference_PlaybackType extends $pb.ProtobufEnum {
  static const MelodyReference_PlaybackType disabled = MelodyReference_PlaybackType._(0, 'disabled');
  static const MelodyReference_PlaybackType playback_indefinitely = MelodyReference_PlaybackType._(1, 'playback_indefinitely');

  static const $core.List<MelodyReference_PlaybackType> values = <MelodyReference_PlaybackType> [
    disabled,
    playback_indefinitely,
  ];

  static final $core.Map<$core.int, MelodyReference_PlaybackType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MelodyReference_PlaybackType valueOf($core.int value) => _byValue[value];

  const MelodyReference_PlaybackType._($core.int v, $core.String n) : super(v, n);
}

