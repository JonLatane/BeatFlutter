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
  static const MelodyType midi = MelodyType._(0, 'midi');
  static const MelodyType audio = MelodyType._(1, 'audio');

  static const $core.List<MelodyType> values = <MelodyType> [
    midi,
    audio,
  ];

  static final $core.Map<$core.int, MelodyType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MelodyType valueOf($core.int value) => _byValue[value];

  const MelodyType._($core.int v, $core.String n) : super(v, n);
}

class MelodyInterpretationType extends $pb.ProtobufEnum {
  static const MelodyInterpretationType fixed_nonadaptive = MelodyInterpretationType._(0, 'fixed_nonadaptive');
  static const MelodyInterpretationType fixed = MelodyInterpretationType._(1, 'fixed');
  static const MelodyInterpretationType relative_to_c = MelodyInterpretationType._(2, 'relative_to_c');
  static const MelodyInterpretationType relative_to_c_sharp = MelodyInterpretationType._(3, 'relative_to_c_sharp');
  static const MelodyInterpretationType relative_to_d = MelodyInterpretationType._(4, 'relative_to_d');
  static const MelodyInterpretationType relative_to_d_sharp = MelodyInterpretationType._(5, 'relative_to_d_sharp');
  static const MelodyInterpretationType relative_to_e = MelodyInterpretationType._(6, 'relative_to_e');
  static const MelodyInterpretationType relative_to_f = MelodyInterpretationType._(7, 'relative_to_f');
  static const MelodyInterpretationType relative_to_f_sharp = MelodyInterpretationType._(8, 'relative_to_f_sharp');
  static const MelodyInterpretationType relative_to_g = MelodyInterpretationType._(9, 'relative_to_g');
  static const MelodyInterpretationType relative_to_g_sharp = MelodyInterpretationType._(10, 'relative_to_g_sharp');
  static const MelodyInterpretationType relative_to_a = MelodyInterpretationType._(11, 'relative_to_a');
  static const MelodyInterpretationType relative_to_a_sharp = MelodyInterpretationType._(12, 'relative_to_a_sharp');
  static const MelodyInterpretationType relative_to_b = MelodyInterpretationType._(13, 'relative_to_b');

  static const $core.List<MelodyInterpretationType> values = <MelodyInterpretationType> [
    fixed_nonadaptive,
    fixed,
    relative_to_c,
    relative_to_c_sharp,
    relative_to_d,
    relative_to_d_sharp,
    relative_to_e,
    relative_to_f,
    relative_to_f_sharp,
    relative_to_g,
    relative_to_g_sharp,
    relative_to_a,
    relative_to_a_sharp,
    relative_to_b,
  ];

  static final $core.Map<$core.int, MelodyInterpretationType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static MelodyInterpretationType valueOf($core.int value) => _byValue[value];

  const MelodyInterpretationType._($core.int v, $core.String n) : super(v, n);
}

class Tempo_Transition extends $pb.ProtobufEnum {
  static const Tempo_Transition a_tempo = Tempo_Transition._(0, 'a_tempo');
  static const Tempo_Transition linear = Tempo_Transition._(1, 'linear');

  static const $core.List<Tempo_Transition> values = <Tempo_Transition> [
    a_tempo,
    linear,
  ];

  static final $core.Map<$core.int, Tempo_Transition> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Tempo_Transition valueOf($core.int value) => _byValue[value];

  const Tempo_Transition._($core.int v, $core.String n) : super(v, n);
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

