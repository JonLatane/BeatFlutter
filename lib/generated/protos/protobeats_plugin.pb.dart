///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MidiSynthesizer extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiSynthesizer', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
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
}

class MidiController extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiController', createEmptyInstance: create)
    ..aOS(1, 'id')
    ..aOS(2, 'name')
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
}

class MidiSynthesizers extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiSynthesizers', createEmptyInstance: create)
    ..pc<MidiSynthesizer>(1, 'synthesizers', $pb.PbFieldType.PM, subBuilder: MidiSynthesizer.create)
    ..hasRequiredFields = false
  ;

  MidiSynthesizers._() : super();
  factory MidiSynthesizers() => create();
  factory MidiSynthesizers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiSynthesizers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiSynthesizers clone() => MidiSynthesizers()..mergeFromMessage(this);
  MidiSynthesizers copyWith(void Function(MidiSynthesizers) updates) => super.copyWith((message) => updates(message as MidiSynthesizers));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiSynthesizers create() => MidiSynthesizers._();
  MidiSynthesizers createEmptyInstance() => create();
  static $pb.PbList<MidiSynthesizers> createRepeated() => $pb.PbList<MidiSynthesizers>();
  @$core.pragma('dart2js:noInline')
  static MidiSynthesizers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiSynthesizers>(create);
  static MidiSynthesizers _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<MidiSynthesizer> get synthesizers => $_getList(0);
}

class MidiControllers extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('MidiControllers', createEmptyInstance: create)
    ..pc<MidiController>(1, 'controllers', $pb.PbFieldType.PM, subBuilder: MidiController.create)
    ..hasRequiredFields = false
  ;

  MidiControllers._() : super();
  factory MidiControllers() => create();
  factory MidiControllers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MidiControllers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  MidiControllers clone() => MidiControllers()..mergeFromMessage(this);
  MidiControllers copyWith(void Function(MidiControllers) updates) => super.copyWith((message) => updates(message as MidiControllers));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MidiControllers create() => MidiControllers._();
  MidiControllers createEmptyInstance() => create();
  static $pb.PbList<MidiControllers> createRepeated() => $pb.PbList<MidiControllers>();
  @$core.pragma('dart2js:noInline')
  static MidiControllers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MidiControllers>(create);
  static MidiControllers _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<MidiController> get controllers => $_getList(0);
}

