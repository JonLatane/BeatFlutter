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

class Note extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Note', createEmptyInstance: create)
    ..e<NoteLetter>(1, 'noteLetter', $pb.PbFieldType.OE, defaultOrMaker: NoteLetter.C, valueOf: NoteLetter.valueOf, enumValues: NoteLetter.values)
    ..e<NoteSign>(2, 'noteSign', $pb.PbFieldType.OE, defaultOrMaker: NoteSign.natural, valueOf: NoteSign.valueOf, enumValues: NoteSign.values)
    ..hasRequiredFields = false
  ;

  Note._() : super();
  factory Note() => create();
  factory Note.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Note.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Note clone() => Note()..mergeFromMessage(this);
  Note copyWith(void Function(Note) updates) => super.copyWith((message) => updates(message as Note));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Note create() => Note._();
  Note createEmptyInstance() => create();
  static $pb.PbList<Note> createRepeated() => $pb.PbList<Note>();
  @$core.pragma('dart2js:noInline')
  static Note getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Note>(create);
  static Note _defaultInstance;

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
    ..aOM<Note>(1, 'rootNote', subBuilder: Note.create)
    ..aOM<Note>(2, 'bassNote', subBuilder: Note.create)
    ..a<$core.int>(3, 'extension', $pb.PbFieldType.OU3)
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
  Note get rootNote => $_getN(0);
  @$pb.TagNumber(1)
  set rootNote(Note v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRootNote() => $_has(0);
  @$pb.TagNumber(1)
  void clearRootNote() => clearField(1);
  @$pb.TagNumber(1)
  Note ensureRootNote() => $_ensure(0);

  @$pb.TagNumber(2)
  Note get bassNote => $_getN(1);
  @$pb.TagNumber(2)
  set bassNote(Note v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBassNote() => $_has(1);
  @$pb.TagNumber(2)
  void clearBassNote() => clearField(2);
  @$pb.TagNumber(2)
  Note ensureBassNote() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get extension_3 => $_getIZ(2);
  @$pb.TagNumber(3)
  set extension_3($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasExtension_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearExtension_3() => clearField(3);
}

class Harmony extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Harmony', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..a<$core.int>(2, 'subdivisionsPerBeat', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, 'length', $pb.PbFieldType.OU3)
    ..m<$core.int, Chord>(4, 'data', entryClassName: 'Harmony.DataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: Chord.create)
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

  @$pb.TagNumber(4)
  $core.Map<$core.int, Chord> get data => $_getMap(3);
}

class MelodyAttack extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MelodyAttack', createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  MelodyAttack._() : super();
  factory MelodyAttack() => create();
  factory MelodyAttack.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MelodyAttack.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MelodyAttack clone() => MelodyAttack()..mergeFromMessage(this);
  MelodyAttack copyWith(void Function(MelodyAttack) updates) => super.copyWith((message) => updates(message as MelodyAttack));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MelodyAttack create() => MelodyAttack._();
  MelodyAttack createEmptyInstance() => create();
  static $pb.PbList<MelodyAttack> createRepeated() => $pb.PbList<MelodyAttack>();
  @$core.pragma('dart2js:noInline')
  static MelodyAttack getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MelodyAttack>(create);
  static MelodyAttack _defaultInstance;
}

class MidiChange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiChange', createEmptyInstance: create)
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
}

class Melody extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Melody', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..a<$core.int>(3, 'subdivisionsPerBeat', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, 'length', $pb.PbFieldType.OU3)
    ..e<MelodyType>(5, 'type', $pb.PbFieldType.OE, defaultOrMaker: MelodyType.melody_harmonic, valueOf: MelodyType.valueOf, enumValues: MelodyType.values)
    ..m<$core.int, MelodyAttack>(6, 'attackData', entryClassName: 'Melody.AttackDataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: MelodyAttack.create)
    ..m<$core.int, MidiChange>(7, 'midiData', entryClassName: 'Melody.MidiDataEntry', keyFieldType: $pb.PbFieldType.OS3, valueFieldType: $pb.PbFieldType.OM, valueCreator: MidiChange.create)
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
  $core.Map<$core.int, MelodyAttack> get attackData => $_getMap(5);

  @$pb.TagNumber(7)
  $core.Map<$core.int, MidiChange> get midiData => $_getMap(6);
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
    ..pc<MelodyReference>(4, 'melodies', $pb.PbFieldType.PM, subBuilder: MelodyReference.create)
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
  $core.List<MelodyReference> get melodies => $_getList(3);
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

