///
//  Generated code. Do not modify.
//  source: protos/music.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'music.pbenum.dart';

export 'music.pbenum.dart';

class NoteName extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('NoteName', createEmptyInstance: create)
    ..e<NoteLetter>(1, 'noteLetter', $pb.PbFieldType.OE, defaultOrMaker: NoteLetter.C, valueOf: NoteLetter.valueOf, enumValues: NoteLetter.values)
    ..e<NoteSign>(2, 'noteSign', $pb.PbFieldType.OE, defaultOrMaker: NoteSign.natural, valueOf: NoteSign.valueOf, enumValues: NoteSign.values)
    ..hasRequiredFields = false
  ;

  NoteName._() : super();
  factory NoteName() => create();
  factory NoteName.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NoteName.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  NoteName clone() => NoteName()..mergeFromMessage(this);
  NoteName copyWith(void Function(NoteName) updates) => super.copyWith((message) => updates(message as NoteName));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NoteName create() => NoteName._();
  NoteName createEmptyInstance() => create();
  static $pb.PbList<NoteName> createRepeated() => $pb.PbList<NoteName>();
  @$core.pragma('dart2js:noInline')
  static NoteName getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NoteName>(create);
  static NoteName _defaultInstance;

  @$pb.TagNumber(1)
  NoteLetter get noteLetter => $_getN(0);
  @$pb.TagNumber(1)
  set noteLetter(NoteLetter v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNoteLetter() => $_has(0);
  @$pb.TagNumber(1)
  void clearNoteLetter() => clearField(1);

  @$pb.TagNumber(2)
  NoteSign get noteSign => $_getN(1);
  @$pb.TagNumber(2)
  set noteSign(NoteSign v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasNoteSign() => $_has(1);
  @$pb.TagNumber(2)
  void clearNoteSign() => clearField(2);
}

class Chord extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Chord', createEmptyInstance: create)
    ..aOM<NoteName>(1, 'rootNote', subBuilder: NoteName.create)
    ..aOM<NoteName>(2, 'bassNote', subBuilder: NoteName.create)
    ..a<$core.int>(3, 'chroma', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  Chord._() : super();
  factory Chord() => create();
  factory Chord.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Chord.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Chord clone() => Chord()..mergeFromMessage(this);
  Chord copyWith(void Function(Chord) updates) => super.copyWith((message) => updates(message as Chord));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Chord create() => Chord._();
  Chord createEmptyInstance() => create();
  static $pb.PbList<Chord> createRepeated() => $pb.PbList<Chord>();
  @$core.pragma('dart2js:noInline')
  static Chord getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Chord>(create);
  static Chord _defaultInstance;

  @$pb.TagNumber(1)
  NoteName get rootNote => $_getN(0);
  @$pb.TagNumber(1)
  set rootNote(NoteName v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRootNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootNote() => clearField(1);
  @$pb.TagNumber(1)
  NoteName ensureRootNote() => $_ensure(0);

  @$pb.TagNumber(2)
  NoteName get bassNote => $_getN(1);
  @$pb.TagNumber(2)
  set bassNote(NoteName v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBassNote() => $_has(1);
  @$pb.TagNumber(2)
  void clearBassNote() => clearField(2);
  @$pb.TagNumber(2)
  NoteName ensureBassNote() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get chroma => $_getIZ(2);
  @$pb.TagNumber(3)
  set chroma($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasChroma() => $_has(2);
  @$pb.TagNumber(3)
  void clearChroma() => clearField(3);
}

class Tempo extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Tempo', createEmptyInstance: create)
    ..a<$core.double>(1, 'bpm', $pb.PbFieldType.OF)
    ..e<Tempo_Transition>(2, 'transition', $pb.PbFieldType.OE, defaultOrMaker: Tempo_Transition.a_tempo, valueOf: Tempo_Transition.valueOf, enumValues: Tempo_Transition.values)
    ..hasRequiredFields = false
  ;

  Tempo._() : super();
  factory Tempo() => create();
  factory Tempo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Tempo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Tempo clone() => Tempo()..mergeFromMessage(this);
  Tempo copyWith(void Function(Tempo) updates) => super.copyWith((message) => updates(message as Tempo));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Tempo create() => Tempo._();
  Tempo createEmptyInstance() => create();
  static $pb.PbList<Tempo> createRepeated() => $pb.PbList<Tempo>();
  @$core.pragma('dart2js:noInline')
  static Tempo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Tempo>(create);
  static Tempo _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get bpm => $_getN(0);
  @$pb.TagNumber(1)
  set bpm($core.double v) { $_setFloat(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBpm() => $_has(0);
  @$pb.TagNumber(1)
  void clearBpm() => clearField(1);

  @$pb.TagNumber(2)
  Tempo_Transition get transition => $_getN(1);
  @$pb.TagNumber(2)
  set transition(Tempo_Transition v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTransition() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransition() => clearField(2);
}

class Meter extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Meter', createEmptyInstance: create)
    ..a<$core.int>(1, 'defaultBeatsPerMeasure', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  Meter._() : super();
  factory Meter() => create();
  factory Meter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Meter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Meter clone() => Meter()..mergeFromMessage(this);
  Meter copyWith(void Function(Meter) updates) => super.copyWith((message) => updates(message as Meter));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Meter create() => Meter._();
  Meter createEmptyInstance() => create();
  static $pb.PbList<Meter> createRepeated() => $pb.PbList<Meter>();
  @$core.pragma('dart2js:noInline')
  static Meter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Meter>(create);
  static Meter _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get defaultBeatsPerMeasure => $_getIZ(0);
  @$pb.TagNumber(1)
  set defaultBeatsPerMeasure($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDefaultBeatsPerMeasure() => $_has(0);
  @$pb.TagNumber(1)
  void clearDefaultBeatsPerMeasure() => clearField(1);
}

class Harmony extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Harmony', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..a<$core.int>(2, 'subdivisionsPerBeat', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, 'length', $pb.PbFieldType.OU3)
    ..m<$core.int, Chord>(100, 'data', entryClassName: 'Harmony.DataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: Chord.create)
    ..hasRequiredFields = false
  ;

  Harmony._() : super();
  factory Harmony() => create();
  factory Harmony.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Harmony.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Harmony clone() => Harmony()..mergeFromMessage(this);
  Harmony copyWith(void Function(Harmony) updates) => super.copyWith((message) => updates(message as Harmony));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Harmony create() => Harmony._();
  Harmony createEmptyInstance() => create();
  static $pb.PbList<Harmony> createRepeated() => $pb.PbList<Harmony>();
  @$core.pragma('dart2js:noInline')
  static Harmony getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Harmony>(create);
  static Harmony _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get subdivisionsPerBeat => $_getIZ(1);
  @$pb.TagNumber(2)
  set subdivisionsPerBeat($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSubdivisionsPerBeat() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubdivisionsPerBeat() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get length => $_getIZ(2);
  @$pb.TagNumber(3)
  set length($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearLength() => clearField(3);

  @$pb.TagNumber(100)
  $core.Map<$core.int, Chord> get data => $_getMap(3);
}

enum Melody_Data {
  melodicData, 
  midiData, 
  notSet
}

class Melody extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Melody_Data> _Melody_DataByTag = {
    100 : Melody_Data.melodicData,
    101 : Melody_Data.midiData,
    0 : Melody_Data.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Melody', createEmptyInstance: create)
    ..oo(0, [100, 101])
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..a<$core.int>(3, 'subdivisionsPerBeat', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, 'length', $pb.PbFieldType.OU3)
    ..e<MelodyType>(5, 'type', $pb.PbFieldType.OE, defaultOrMaker: MelodyType.melodic, valueOf: MelodyType.valueOf, enumValues: MelodyType.values)
    ..e<InstrumentType>(6, 'instrumentType', $pb.PbFieldType.OE, defaultOrMaker: InstrumentType.harmonic, valueOf: InstrumentType.valueOf, enumValues: InstrumentType.values)
    ..e<MelodyInterpretationType>(7, 'interpretationType', $pb.PbFieldType.OE, defaultOrMaker: MelodyInterpretationType.fixed_nonadaptive, valueOf: MelodyInterpretationType.valueOf, enumValues: MelodyInterpretationType.values)
    ..aOM<MelodicData>(100, 'melodicData', subBuilder: MelodicData.create)
    ..aOM<MidiData>(101, 'midiData', subBuilder: MidiData.create)
    ..hasRequiredFields = false
  ;

  Melody._() : super();
  factory Melody() => create();
  factory Melody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Melody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Melody clone() => Melody()..mergeFromMessage(this);
  Melody copyWith(void Function(Melody) updates) => super.copyWith((message) => updates(message as Melody));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Melody create() => Melody._();
  Melody createEmptyInstance() => create();
  static $pb.PbList<Melody> createRepeated() => $pb.PbList<Melody>();
  @$core.pragma('dart2js:noInline')
  static Melody getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Melody>(create);
  static Melody _defaultInstance;

  Melody_Data whichData() => _Melody_DataByTag[$_whichOneof(0)];
  void clearData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get subdivisionsPerBeat => $_getIZ(2);
  @$pb.TagNumber(3)
  set subdivisionsPerBeat($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSubdivisionsPerBeat() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubdivisionsPerBeat() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get length => $_getIZ(3);
  @$pb.TagNumber(4)
  set length($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLength() => $_has(3);
  @$pb.TagNumber(4)
  void clearLength() => clearField(4);

  @$pb.TagNumber(5)
  MelodyType get type => $_getN(4);
  @$pb.TagNumber(5)
  set type(MelodyType v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasType() => $_has(4);
  @$pb.TagNumber(5)
  void clearType() => clearField(5);

  @$pb.TagNumber(6)
  InstrumentType get instrumentType => $_getN(5);
  @$pb.TagNumber(6)
  set instrumentType(InstrumentType v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasInstrumentType() => $_has(5);
  @$pb.TagNumber(6)
  void clearInstrumentType() => clearField(6);

  @$pb.TagNumber(7)
  MelodyInterpretationType get interpretationType => $_getN(6);
  @$pb.TagNumber(7)
  set interpretationType(MelodyInterpretationType v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasInterpretationType() => $_has(6);
  @$pb.TagNumber(7)
  void clearInterpretationType() => clearField(7);

  @$pb.TagNumber(100)
  MelodicData get melodicData => $_getN(7);
  @$pb.TagNumber(100)
  set melodicData(MelodicData v) { setField(100, v); }
  @$pb.TagNumber(100)
  $core.bool hasMelodicData() => $_has(7);
  @$pb.TagNumber(100)
  void clearMelodicData() => clearField(100);
  @$pb.TagNumber(100)
  MelodicData ensureMelodicData() => $_ensure(7);

  @$pb.TagNumber(101)
  MidiData get midiData => $_getN(8);
  @$pb.TagNumber(101)
  set midiData(MidiData v) { setField(101, v); }
  @$pb.TagNumber(101)
  $core.bool hasMidiData() => $_has(8);
  @$pb.TagNumber(101)
  void clearMidiData() => clearField(101);
  @$pb.TagNumber(101)
  MidiData ensureMidiData() => $_ensure(8);
}

class MelodicData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MelodicData', createEmptyInstance: create)
    ..m<$core.int, MelodicAttack>(1, 'data', entryClassName: 'MelodicData.DataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: MelodicAttack.create)
    ..hasRequiredFields = false
  ;

  MelodicData._() : super();
  factory MelodicData() => create();
  factory MelodicData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MelodicData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MelodicData clone() => MelodicData()..mergeFromMessage(this);
  MelodicData copyWith(void Function(MelodicData) updates) => super.copyWith((message) => updates(message as MelodicData));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MelodicData create() => MelodicData._();
  MelodicData createEmptyInstance() => create();
  static $pb.PbList<MelodicData> createRepeated() => $pb.PbList<MelodicData>();
  @$core.pragma('dart2js:noInline')
  static MelodicData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MelodicData>(create);
  static MelodicData _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, MelodicAttack> get data => $_getMap(0);
}

class MidiData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiData', createEmptyInstance: create)
    ..m<$core.int, MidiChange>(1, 'data', entryClassName: 'MidiData.DataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: MidiChange.create)
    ..hasRequiredFields = false
  ;

  MidiData._() : super();
  factory MidiData() => create();
  factory MidiData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiData clone() => MidiData()..mergeFromMessage(this);
  MidiData copyWith(void Function(MidiData) updates) => super.copyWith((message) => updates(message as MidiData));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiData create() => MidiData._();
  MidiData createEmptyInstance() => create();
  static $pb.PbList<MidiData> createRepeated() => $pb.PbList<MidiData>();
  @$core.pragma('dart2js:noInline')
  static MidiData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiData>(create);
  static MidiData _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.int, MidiChange> get data => $_getMap(0);
}

class MelodicAttack extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MelodicAttack', createEmptyInstance: create)
    ..p<$core.int>(1, 'tones', $pb.PbFieldType.PS3)
    ..a<$core.double>(2, 'velocity', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  MelodicAttack._() : super();
  factory MelodicAttack() => create();
  factory MelodicAttack.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MelodicAttack.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MelodicAttack clone() => MelodicAttack()..mergeFromMessage(this);
  MelodicAttack copyWith(void Function(MelodicAttack) updates) => super.copyWith((message) => updates(message as MelodicAttack));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MelodicAttack create() => MelodicAttack._();
  MelodicAttack createEmptyInstance() => create();
  static $pb.PbList<MelodicAttack> createRepeated() => $pb.PbList<MelodicAttack>();
  @$core.pragma('dart2js:noInline')
  static MelodicAttack getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MelodicAttack>(create);
  static MelodicAttack _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get tones => $_getList(0);

  @$pb.TagNumber(2)
  $core.double get velocity => $_getN(1);
  @$pb.TagNumber(2)
  set velocity($core.double v) { $_setFloat(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVelocity() => $_has(1);
  @$pb.TagNumber(2)
  void clearVelocity() => clearField(2);
}

class MidiChange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiChange', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  MidiChange._() : super();
  factory MidiChange() => create();
  factory MidiChange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiChange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiChange clone() => MidiChange()..mergeFromMessage(this);
  MidiChange copyWith(void Function(MidiChange) updates) => super.copyWith((message) => updates(message as MidiChange));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiChange create() => MidiChange._();
  MidiChange createEmptyInstance() => create();
  static $pb.PbList<MidiChange> createRepeated() => $pb.PbList<MidiChange>();
  @$core.pragma('dart2js:noInline')
  static MidiChange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiChange>(create);
  static MidiChange _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);
}

class Instrument extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Instrument', createEmptyInstance: create)
    ..aOS(1, 'name')
    ..e<InstrumentType>(2, 'type', $pb.PbFieldType.OE, defaultOrMaker: InstrumentType.harmonic, valueOf: InstrumentType.valueOf, enumValues: InstrumentType.values)
    ..a<$core.double>(3, 'volume', $pb.PbFieldType.OF)
    ..a<$core.int>(4, 'midiChannel', $pb.PbFieldType.OU3)
    ..a<$core.int>(5, 'midiInstrument', $pb.PbFieldType.OU3)
    ..a<$core.int>(6, 'midiGm2Msb', $pb.PbFieldType.OU3)
    ..a<$core.int>(7, 'midiGm2Lsb', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  Instrument._() : super();
  factory Instrument() => create();
  factory Instrument.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Instrument.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Instrument clone() => Instrument()..mergeFromMessage(this);
  Instrument copyWith(void Function(Instrument) updates) => super.copyWith((message) => updates(message as Instrument));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Instrument create() => Instrument._();
  Instrument createEmptyInstance() => create();
  static $pb.PbList<Instrument> createRepeated() => $pb.PbList<Instrument>();
  @$core.pragma('dart2js:noInline')
  static Instrument getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Instrument>(create);
  static Instrument _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  InstrumentType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(InstrumentType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get volume => $_getN(2);
  @$pb.TagNumber(3)
  set volume($core.double v) { $_setFloat(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVolume() => $_has(2);
  @$pb.TagNumber(3)
  void clearVolume() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get midiChannel => $_getIZ(3);
  @$pb.TagNumber(4)
  set midiChannel($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMidiChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearMidiChannel() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get midiInstrument => $_getIZ(4);
  @$pb.TagNumber(5)
  set midiInstrument($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMidiInstrument() => $_has(4);
  @$pb.TagNumber(5)
  void clearMidiInstrument() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get midiGm2Msb => $_getIZ(5);
  @$pb.TagNumber(6)
  set midiGm2Msb($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasMidiGm2Msb() => $_has(5);
  @$pb.TagNumber(6)
  void clearMidiGm2Msb() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get midiGm2Lsb => $_getIZ(6);
  @$pb.TagNumber(7)
  set midiGm2Lsb($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMidiGm2Lsb() => $_has(6);
  @$pb.TagNumber(7)
  void clearMidiGm2Lsb() => clearField(7);
}

class Part extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Part', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOM<Instrument>(3, 'instrument', subBuilder: Instrument.create)
    ..pc<Melody>(4, 'melodies', $pb.PbFieldType.PM, subBuilder: Melody.create)
    ..hasRequiredFields = false
  ;

  Part._() : super();
  factory Part() => create();
  factory Part.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Part.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Part clone() => Part()..mergeFromMessage(this);
  Part copyWith(void Function(Part) updates) => super.copyWith((message) => updates(message as Part));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Part create() => Part._();
  Part createEmptyInstance() => create();
  static $pb.PbList<Part> createRepeated() => $pb.PbList<Part>();
  @$core.pragma('dart2js:noInline')
  static Part getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Part>(create);
  static Part _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(3)
  Instrument get instrument => $_getN(1);
  @$pb.TagNumber(3)
  set instrument(Instrument v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasInstrument() => $_has(1);
  @$pb.TagNumber(3)
  void clearInstrument() => clearField(3);
  @$pb.TagNumber(3)
  Instrument ensureInstrument() => $_ensure(1);

  @$pb.TagNumber(4)
  $core.List<Melody> get melodies => $_getList(2);
}

class MelodyReference extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MelodyReference', createEmptyInstance: create)
    ..aOS(1, 'melodyId')
    ..e<MelodyReference_PlaybackType>(2, 'playbackType', $pb.PbFieldType.OE, defaultOrMaker: MelodyReference_PlaybackType.disabled, valueOf: MelodyReference_PlaybackType.valueOf, enumValues: MelodyReference_PlaybackType.values)
    ..a<$core.double>(3, 'volume', $pb.PbFieldType.OF)
    ..hasRequiredFields = false
  ;

  MelodyReference._() : super();
  factory MelodyReference() => create();
  factory MelodyReference.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MelodyReference.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MelodyReference clone() => MelodyReference()..mergeFromMessage(this);
  MelodyReference copyWith(void Function(MelodyReference) updates) => super.copyWith((message) => updates(message as MelodyReference));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MelodyReference create() => MelodyReference._();
  MelodyReference createEmptyInstance() => create();
  static $pb.PbList<MelodyReference> createRepeated() => $pb.PbList<MelodyReference>();
  @$core.pragma('dart2js:noInline')
  static MelodyReference getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MelodyReference>(create);
  static MelodyReference _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get melodyId => $_getSZ(0);
  @$pb.TagNumber(1)
  set melodyId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMelodyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMelodyId() => clearField(1);

  @$pb.TagNumber(2)
  MelodyReference_PlaybackType get playbackType => $_getN(1);
  @$pb.TagNumber(2)
  set playbackType(MelodyReference_PlaybackType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPlaybackType() => $_has(1);
  @$pb.TagNumber(2)
  void clearPlaybackType() => clearField(2);

  @$pb.TagNumber(3)
  $core.double get volume => $_getN(2);
  @$pb.TagNumber(3)
  set volume($core.double v) { $_setFloat(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVolume() => $_has(2);
  @$pb.TagNumber(3)
  void clearVolume() => clearField(3);
}

class Section extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Section', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..aOM<Harmony>(3, 'harmony', subBuilder: Harmony.create)
    ..aOM<Meter>(4, 'meter', subBuilder: Meter.create)
    ..aOM<Tempo>(5, 'tempo', subBuilder: Tempo.create)
    ..pc<MelodyReference>(100, 'melodies', $pb.PbFieldType.PM, subBuilder: MelodyReference.create)
    ..hasRequiredFields = false
  ;

  Section._() : super();
  factory Section() => create();
  factory Section.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Section.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Section clone() => Section()..mergeFromMessage(this);
  Section copyWith(void Function(Section) updates) => super.copyWith((message) => updates(message as Section));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Section create() => Section._();
  Section createEmptyInstance() => create();
  static $pb.PbList<Section> createRepeated() => $pb.PbList<Section>();
  @$core.pragma('dart2js:noInline')
  static Section getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Section>(create);
  static Section _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  Harmony get harmony => $_getN(2);
  @$pb.TagNumber(3)
  set harmony(Harmony v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasHarmony() => $_has(2);
  @$pb.TagNumber(3)
  void clearHarmony() => clearField(3);
  @$pb.TagNumber(3)
  Harmony ensureHarmony() => $_ensure(2);

  @$pb.TagNumber(4)
  Meter get meter => $_getN(3);
  @$pb.TagNumber(4)
  set meter(Meter v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasMeter() => $_has(3);
  @$pb.TagNumber(4)
  void clearMeter() => clearField(4);
  @$pb.TagNumber(4)
  Meter ensureMeter() => $_ensure(3);

  @$pb.TagNumber(5)
  Tempo get tempo => $_getN(4);
  @$pb.TagNumber(5)
  set tempo(Tempo v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTempo() => $_has(4);
  @$pb.TagNumber(5)
  void clearTempo() => clearField(5);
  @$pb.TagNumber(5)
  Tempo ensureTempo() => $_ensure(4);

  @$pb.TagNumber(100)
  $core.List<MelodyReference> get melodies => $_getList(5);
}

class Score extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Score', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..pc<Part>(3, 'parts', $pb.PbFieldType.PM, subBuilder: Part.create)
    ..pc<Section>(4, 'sections', $pb.PbFieldType.PM, subBuilder: Section.create)
    ..hasRequiredFields = false
  ;

  Score._() : super();
  factory Score() => create();
  factory Score.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Score.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Score clone() => Score()..mergeFromMessage(this);
  Score copyWith(void Function(Score) updates) => super.copyWith((message) => updates(message as Score));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Score create() => Score._();
  Score createEmptyInstance() => create();
  static $pb.PbList<Score> createRepeated() => $pb.PbList<Score>();
  @$core.pragma('dart2js:noInline')
  static Score getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Score>(create);
  static Score _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<Part> get parts => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<Section> get sections => $_getList(3);
}

