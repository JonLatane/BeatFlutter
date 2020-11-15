///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'protobeats_plugin.pbenum.dart';

export 'protobeats_plugin.pbenum.dart';

class MidiSynthesizer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiSynthesizer', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..aOB(3, 'enabled')
    ..hasRequiredFields = false
  ;

  MidiSynthesizer._() : super();
  factory MidiSynthesizer() => create();
  factory MidiSynthesizer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiSynthesizer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiSynthesizer clone() => MidiSynthesizer()..mergeFromMessage(this);
  MidiSynthesizer copyWith(void Function(MidiSynthesizer) updates) => super.copyWith((message) => updates(message as MidiSynthesizer));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiController', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
    ..aOB(3, 'enabled')
    ..hasRequiredFields = false
  ;

  MidiController._() : super();
  factory MidiController() => create();
  factory MidiController.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiController.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiController clone() => MidiController()..mergeFromMessage(this);
  MidiController copyWith(void Function(MidiController) updates) => super.copyWith((message) => updates(message as MidiController));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiDevices', createEmptyInstance: create)
    ..pc<MidiSynthesizer>(1, 'synthesizers', $pb.PbFieldType.PM, subBuilder: MidiSynthesizer.create)
    ..pc<MidiController>(2, 'controllers', $pb.PbFieldType.PM, subBuilder: MidiController.create)
    ..hasRequiredFields = false
  ;

  MidiDevices._() : super();
  factory MidiDevices() => create();
  factory MidiDevices.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiDevices.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiDevices clone() => MidiDevices()..mergeFromMessage(this);
  MidiDevices copyWith(void Function(MidiDevices) updates) => super.copyWith((message) => updates(message as MidiDevices));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('SynthesizerApp', createEmptyInstance: create)
    ..aOS(1, 'name')
    ..aOB(2, 'installed')
    ..aOS(3, 'storeLink', protoName: 'storeLink')
    ..aOS(4, 'launchLink', protoName: 'launchLink')
    ..hasRequiredFields = false
  ;

  SynthesizerApp._() : super();
  factory SynthesizerApp() => create();
  factory SynthesizerApp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SynthesizerApp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  SynthesizerApp clone() => SynthesizerApp()..mergeFromMessage(this);
  SynthesizerApp copyWith(void Function(SynthesizerApp) updates) => super.copyWith((message) => updates(message as SynthesizerApp));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('ControllerApp', createEmptyInstance: create)
    ..aOS(1, 'name')
    ..aOB(2, 'installed')
    ..aOS(3, 'storeLink', protoName: 'storeLink')
    ..aOS(4, 'launchLink', protoName: 'launchLink')
    ..hasRequiredFields = false
  ;

  ControllerApp._() : super();
  factory ControllerApp() => create();
  factory ControllerApp.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ControllerApp.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  ControllerApp clone() => ControllerApp()..mergeFromMessage(this);
  ControllerApp copyWith(void Function(ControllerApp) updates) => super.copyWith((message) => updates(message as ControllerApp));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiApps', createEmptyInstance: create)
    ..pc<SynthesizerApp>(1, 'synthesizers', $pb.PbFieldType.PM, subBuilder: SynthesizerApp.create)
    ..pc<ControllerApp>(2, 'controllers', $pb.PbFieldType.PM, subBuilder: ControllerApp.create)
    ..hasRequiredFields = false
  ;

  MidiApps._() : super();
  factory MidiApps() => create();
  factory MidiApps.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiApps.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiApps clone() => MidiApps()..mergeFromMessage(this);
  MidiApps copyWith(void Function(MidiApps) updates) => super.copyWith((message) => updates(message as MidiApps));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiNotes', createEmptyInstance: create)
    ..p<$core.int>(1, 'midiNotes', $pb.PbFieldType.PU3)
    ..hasRequiredFields = false
  ;

  MidiNotes._() : super();
  factory MidiNotes() => create();
  factory MidiNotes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiNotes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiNotes clone() => MidiNotes()..mergeFromMessage(this);
  MidiNotes copyWith(void Function(MidiNotes) updates) => super.copyWith((message) => updates(message as MidiNotes));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('RegisterMelody', createEmptyInstance: create)
    ..aOS(1, 'melodyId')
    ..aOS(2, 'partId')
    ..hasRequiredFields = false
  ;

  RegisterMelody._() : super();
  factory RegisterMelody() => create();
  factory RegisterMelody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RegisterMelody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  RegisterMelody clone() => RegisterMelody()..mergeFromMessage(this);
  RegisterMelody copyWith(void Function(RegisterMelody) updates) => super.copyWith((message) => updates(message as RegisterMelody));
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Playback', createEmptyInstance: create)
    ..e<Playback_Mode>(1, 'mode', $pb.PbFieldType.OE, defaultOrMaker: Playback_Mode.score, valueOf: Playback_Mode.valueOf, enumValues: Playback_Mode.values)
    ..hasRequiredFields = false
  ;

  Playback._() : super();
  factory Playback() => create();
  factory Playback.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Playback.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Playback clone() => Playback()..mergeFromMessage(this);
  Playback copyWith(void Function(Playback) updates) => super.copyWith((message) => updates(message as Playback));
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

