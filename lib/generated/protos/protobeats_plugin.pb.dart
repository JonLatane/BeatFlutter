///
//  Generated code. Do not modify.
//  source: protos/protobeats_plugin.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class SendPartMIDI extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('SendPartMIDI', createEmptyInstance: create)
    ..aOS(1, 'partId')
    ..a<$core.List<$core.int>>(2, 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  SendPartMIDI._() : super();
  factory SendPartMIDI() => create();
  factory SendPartMIDI.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendPartMIDI.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  SendPartMIDI clone() => SendPartMIDI()..mergeFromMessage(this);
  SendPartMIDI copyWith(void Function(SendPartMIDI) updates) => super.copyWith((message) => updates(message as SendPartMIDI));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SendPartMIDI create() => SendPartMIDI._();
  SendPartMIDI createEmptyInstance() => create();
  static $pb.PbList<SendPartMIDI> createRepeated() => $pb.PbList<SendPartMIDI>();
  @$core.pragma('dart2js:noInline')
  static SendPartMIDI getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendPartMIDI>(create);
  static SendPartMIDI _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get partId => $_getSZ(0);
  @$pb.TagNumber(1)
  set partId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPartId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPartId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
}

