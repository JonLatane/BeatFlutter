///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'protobeats_plugin.pbenum.dart';

export 'protobeats_plugin.pbenum.dart';

class MidiSynthesizer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MidiSynthesizer', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabled')
    ..hasRequiredFields = false
  ;

  MidiSynthesizer._() : super();
  factory MidiSynthesizer() => create();
  factory MidiSynthesizer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiSynthesizer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MidiSynthesizer clone() => MidiSynthesizer()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MidiSynthesizer copyWith(void Function(MidiSynthesizer) updates) => super.copyWith((message) => updates(message as MidiSynthesizer)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiSynthesizer create() => MidiSynthesizer._();
  MidiSynthesizer createEmptyInstance() => create();
  static $pb.PbList<MidiSynthesizer> createRepeated() => $pb.PbList<MidiSynthesizer>();
  @$core.pragma('dart2js:noInline')
  static MidiSynthesizer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiSynthesizer>(create);
  static MidiSynthesizer _defaultInstance;

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
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => clearField(3);
}

class MidiController extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MidiController', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabled')
    ..hasRequiredFields = false
  ;

  MidiController._() : super();
  factory MidiController() => create();
  factory MidiController.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiController.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MidiController clone() => MidiController()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MidiController copyWith(void Function(MidiController) updates) => super.copyWith((message) => updates(message as MidiController)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiController create() => MidiController._();
  MidiController createEmptyInstance() => create();
  static $pb.PbList<MidiController> createRepeated() => $pb.PbList<MidiController>();
  @$core.pragma('dart2js:noInline')
  static MidiController getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiController>(create);
  static MidiController _defaultInstance;

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
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => clearField(3);
}

class MidiDevices extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MidiDevices', createEmptyInstance: create)
    ..pc<MidiSynthesizer>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'synthesizers', $pb.PbFieldType.PM, subBuilder: MidiSynthesizer.create)
    ..pc<MidiController>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'controllers', $pb.PbFieldType.PM, subBuilder: MidiController.create)
    ..hasRequiredFields = false
  ;

  MidiDevices._() : super();
  factory MidiDevices() => create();
  factory MidiDevices.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiDevices.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MidiDevices clone() => MidiDevices()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MidiDevices copyWith(void Function(MidiDevices) updates) => super.copyWith((message) => updates(message as MidiDevices)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiDevices create() => MidiDevices._();
  MidiDevices createEmptyInstance() => create();
  static $pb.PbList<MidiDevices> createRepeated() => $pb.PbList<MidiDevices>();
  @$core.pragma('dart2js:noInline')
  static MidiDevices getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiDevices>(create);
  static MidiDevices _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<MidiSynthesizer> get synthesizers => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<MidiController> get controllers => $_getList(1);
}

class SynthesizerApp extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SynthesizerApp', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'installed')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'storeLink', protoName: 'storeLink')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'launchLink', protoName: 'launchLink')
    ..hasRequiredFields = false
  ;

  SynthesizerApp._() : super();
  factory SynthesizerApp() => create();
  factory SynthesizerApp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SynthesizerApp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SynthesizerApp clone() => SynthesizerApp()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SynthesizerApp copyWith(void Function(SynthesizerApp) updates) => super.copyWith((message) => updates(message as SynthesizerApp)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SynthesizerApp create() => SynthesizerApp._();
  SynthesizerApp createEmptyInstance() => create();
  static $pb.PbList<SynthesizerApp> createRepeated() => $pb.PbList<SynthesizerApp>();
  @$core.pragma('dart2js:noInline')
  static SynthesizerApp getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SynthesizerApp>(create);
  static SynthesizerApp _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get installed => $_getBF(1);
  @$pb.TagNumber(2)
  set installed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInstalled() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstalled() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get storeLink => $_getSZ(2);
  @$pb.TagNumber(3)
  set storeLink($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStoreLink() => $_has(2);
  @$pb.TagNumber(3)
  void clearStoreLink() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get launchLink => $_getSZ(3);
  @$pb.TagNumber(4)
  set launchLink($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLaunchLink() => $_has(3);
  @$pb.TagNumber(4)
  void clearLaunchLink() => clearField(4);
}

class ControllerApp extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ControllerApp', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'installed')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'storeLink', protoName: 'storeLink')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'launchLink', protoName: 'launchLink')
    ..hasRequiredFields = false
  ;

  ControllerApp._() : super();
  factory ControllerApp() => create();
  factory ControllerApp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ControllerApp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ControllerApp clone() => ControllerApp()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ControllerApp copyWith(void Function(ControllerApp) updates) => super.copyWith((message) => updates(message as ControllerApp)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ControllerApp create() => ControllerApp._();
  ControllerApp createEmptyInstance() => create();
  static $pb.PbList<ControllerApp> createRepeated() => $pb.PbList<ControllerApp>();
  @$core.pragma('dart2js:noInline')
  static ControllerApp getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ControllerApp>(create);
  static ControllerApp _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get installed => $_getBF(1);
  @$pb.TagNumber(2)
  set installed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInstalled() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstalled() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get storeLink => $_getSZ(2);
  @$pb.TagNumber(3)
  set storeLink($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStoreLink() => $_has(2);
  @$pb.TagNumber(3)
  void clearStoreLink() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get launchLink => $_getSZ(3);
  @$pb.TagNumber(4)
  set launchLink($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLaunchLink() => $_has(3);
  @$pb.TagNumber(4)
  void clearLaunchLink() => clearField(4);
}

class MidiApps extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MidiApps', createEmptyInstance: create)
    ..pc<SynthesizerApp>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'synthesizers', $pb.PbFieldType.PM, subBuilder: SynthesizerApp.create)
    ..pc<ControllerApp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'controllers', $pb.PbFieldType.PM, subBuilder: ControllerApp.create)
    ..hasRequiredFields = false
  ;

  MidiApps._() : super();
  factory MidiApps() => create();
  factory MidiApps.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiApps.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MidiApps clone() => MidiApps()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MidiApps copyWith(void Function(MidiApps) updates) => super.copyWith((message) => updates(message as MidiApps)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiApps create() => MidiApps._();
  MidiApps createEmptyInstance() => create();
  static $pb.PbList<MidiApps> createRepeated() => $pb.PbList<MidiApps>();
  @$core.pragma('dart2js:noInline')
  static MidiApps getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiApps>(create);
  static MidiApps _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SynthesizerApp> get synthesizers => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<ControllerApp> get controllers => $_getList(1);
}

class MidiNotes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MidiNotes', createEmptyInstance: create)
    ..p<$core.int>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'midiNotes', $pb.PbFieldType.PU3)
    ..hasRequiredFields = false
  ;

  MidiNotes._() : super();
  factory MidiNotes() => create();
  factory MidiNotes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiNotes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MidiNotes clone() => MidiNotes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MidiNotes copyWith(void Function(MidiNotes) updates) => super.copyWith((message) => updates(message as MidiNotes)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiNotes create() => MidiNotes._();
  MidiNotes createEmptyInstance() => create();
  static $pb.PbList<MidiNotes> createRepeated() => $pb.PbList<MidiNotes>();
  @$core.pragma('dart2js:noInline')
  static MidiNotes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiNotes>(create);
  static MidiNotes _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get midiNotes => $_getList(0);
}

class RegisterMelody extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RegisterMelody', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'melodyId')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'partId')
    ..hasRequiredFields = false
  ;

  RegisterMelody._() : super();
  factory RegisterMelody() => create();
  factory RegisterMelody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RegisterMelody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RegisterMelody clone() => RegisterMelody()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RegisterMelody copyWith(void Function(RegisterMelody) updates) => super.copyWith((message) => updates(message as RegisterMelody)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RegisterMelody create() => RegisterMelody._();
  RegisterMelody createEmptyInstance() => create();
  static $pb.PbList<RegisterMelody> createRepeated() => $pb.PbList<RegisterMelody>();
  @$core.pragma('dart2js:noInline')
  static RegisterMelody getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RegisterMelody>(create);
  static RegisterMelody _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get melodyId => $_getSZ(0);
  @$pb.TagNumber(1)
  set melodyId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMelodyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMelodyId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get partId => $_getSZ(1);
  @$pb.TagNumber(2)
  set partId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPartId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPartId() => clearField(2);
}

class Playback extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Playback', createEmptyInstance: create)
    ..e<Playback_Mode>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mode', $pb.PbFieldType.OE, defaultOrMaker: Playback_Mode.score, valueOf: Playback_Mode.valueOf, enumValues: Playback_Mode.values)
    ..hasRequiredFields = false
  ;

  Playback._() : super();
  factory Playback() => create();
  factory Playback.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Playback.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Playback clone() => Playback()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Playback copyWith(void Function(Playback) updates) => super.copyWith((message) => updates(message as Playback)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Playback create() => Playback._();
  Playback createEmptyInstance() => create();
  static $pb.PbList<Playback> createRepeated() => $pb.PbList<Playback>();
  @$core.pragma('dart2js:noInline')
  static Playback getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Playback>(create);
  static Playback _defaultInstance;

  @$pb.TagNumber(1)
  Playback_Mode get mode => $_getN(0);
  @$pb.TagNumber(1)
  set mode(Playback_Mode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => clearField(1);
}

class RecordedSegment_RecordedBeat extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordedSegment.RecordedBeat', createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'beat', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  RecordedSegment_RecordedBeat._() : super();
  factory RecordedSegment_RecordedBeat() => create();
  factory RecordedSegment_RecordedBeat.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RecordedSegment_RecordedBeat.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RecordedSegment_RecordedBeat clone() => RecordedSegment_RecordedBeat()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RecordedSegment_RecordedBeat copyWith(void Function(RecordedSegment_RecordedBeat) updates) => super.copyWith((message) => updates(message as RecordedSegment_RecordedBeat)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordedSegment_RecordedBeat create() => RecordedSegment_RecordedBeat._();
  RecordedSegment_RecordedBeat createEmptyInstance() => create();
  static $pb.PbList<RecordedSegment_RecordedBeat> createRepeated() => $pb.PbList<RecordedSegment_RecordedBeat>();
  @$core.pragma('dart2js:noInline')
  static RecordedSegment_RecordedBeat getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordedSegment_RecordedBeat>(create);
  static RecordedSegment_RecordedBeat _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get beat => $_getIZ(1);
  @$pb.TagNumber(2)
  set beat($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBeat() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeat() => clearField(2);
}

class RecordedSegment_RecordedData extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordedSegment.RecordedData', createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'midiData', $pb.PbFieldType.OY, protoName: 'midiData')
    ..hasRequiredFields = false
  ;

  RecordedSegment_RecordedData._() : super();
  factory RecordedSegment_RecordedData() => create();
  factory RecordedSegment_RecordedData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RecordedSegment_RecordedData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RecordedSegment_RecordedData clone() => RecordedSegment_RecordedData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RecordedSegment_RecordedData copyWith(void Function(RecordedSegment_RecordedData) updates) => super.copyWith((message) => updates(message as RecordedSegment_RecordedData)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordedSegment_RecordedData create() => RecordedSegment_RecordedData._();
  RecordedSegment_RecordedData createEmptyInstance() => create();
  static $pb.PbList<RecordedSegment_RecordedData> createRepeated() => $pb.PbList<RecordedSegment_RecordedData>();
  @$core.pragma('dart2js:noInline')
  static RecordedSegment_RecordedData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordedSegment_RecordedData>(create);
  static RecordedSegment_RecordedData _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(1)
  set timestamp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTimestamp() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get midiData => $_getN(1);
  @$pb.TagNumber(2)
  set midiData($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMidiData() => $_has(1);
  @$pb.TagNumber(2)
  void clearMidiData() => clearField(2);
}

class RecordedSegment extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RecordedSegment', createEmptyInstance: create)
    ..pc<RecordedSegment_RecordedBeat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'beats', $pb.PbFieldType.PM, subBuilder: RecordedSegment_RecordedBeat.create)
    ..pc<RecordedSegment_RecordedData>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'recordedData', $pb.PbFieldType.PM, subBuilder: RecordedSegment_RecordedData.create)
    ..hasRequiredFields = false
  ;

  RecordedSegment._() : super();
  factory RecordedSegment() => create();
  factory RecordedSegment.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RecordedSegment.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RecordedSegment clone() => RecordedSegment()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RecordedSegment copyWith(void Function(RecordedSegment) updates) => super.copyWith((message) => updates(message as RecordedSegment)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RecordedSegment create() => RecordedSegment._();
  RecordedSegment createEmptyInstance() => create();
  static $pb.PbList<RecordedSegment> createRepeated() => $pb.PbList<RecordedSegment>();
  @$core.pragma('dart2js:noInline')
  static RecordedSegment getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordedSegment>(create);
  static RecordedSegment _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RecordedSegment_RecordedBeat> get beats => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<RecordedSegment_RecordedData> get recordedData => $_getList(1);
}

