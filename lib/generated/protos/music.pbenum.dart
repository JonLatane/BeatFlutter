///
//  Generated code. Do not modify.
//  source: protos/music.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class NoteName extends $pb.ProtobufEnum {
  static const NoteName C = NoteName._(0, 'C');
  static const NoteName D = NoteName._(1, 'D');
  static const NoteName E = NoteName._(2, 'E');
  static const NoteName F = NoteName._(3, 'F');
  static const NoteName G = NoteName._(4, 'G');
  static const NoteName A = NoteName._(5, 'A');
  static const NoteName B = NoteName._(6, 'B');

  static const $core.List<NoteName> values = <NoteName> [
    C,
    D,
    E,
    F,
    G,
    A,
    B,
  ];

  static final $core.Map<$core.int, NoteName> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NoteName valueOf($core.int value) => _byValue[value];

  const NoteName._($core.int v, $core.String n) : super(v, n);
}

class NoteSign extends $pb.ProtobufEnum {
  static const NoteSign natural = NoteSign._(0, 'natural');
  static const NoteSign none = NoteSign._(1, 'none');
  static const NoteSign flat = NoteSign._(2, 'flat');
  static const NoteSign double_flat = NoteSign._(3, 'double_flat');
  static const NoteSign sharp = NoteSign._(4, 'sharp');
  static const NoteSign double_sharp = NoteSign._(5, 'double_sharp');

  static const $core.List<NoteSign> values = <NoteSign> [
    natural,
    none,
    flat,
    double_flat,
    sharp,
    double_sharp,
  ];

  static final $core.Map<$core.int, NoteSign> _byValue = $pb.ProtobufEnum.initByValue(values);
  static NoteSign valueOf($core.int value) => _byValue[value];

  const NoteSign._($core.int v, $core.String n) : super(v, n);
}

class MelodyType extends $pb.ProtobufEnum {
  static const MelodyType melody_harmonic = MelodyType._(0, 'melody_harmonic');
  static const MelodyType melody_drum = MelodyType._(1, 'melody_drum');
  static const MelodyType midi_harmonic = MelodyType._(2, 'midi_harmonic');
  static const MelodyType midi_drum = MelodyType._(3, 'midi_drum');

  static const $core.List<MelodyType> values = <MelodyType> [
    melody_harmonic,
    melody_drum,
    midi_harmonic,
    midi_drum,
  ];

  static final $core.Map<$core.int, MelodyType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MelodyType valueOf($core.int value) => _byValue[value];

  const MelodyType._($core.int v, $core.String n) : super(v, n);
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

