import 'package:protobuf/protobuf.dart';

import 'fake_js.dart'
if(dart.library.js) 'dart:js';

extension ProtoUtils<T extends GeneratedMessage> on T {
  dynamic protoJsify() => JsObject.jsify(bsCopy().toProto3Json());
  T bsCopy() => clone();
  T deepRebuild(void Function(T) updates) {
    dynamic copy = clone();
    return copy.copyWith(updates);
  }

  String get logString =>  "\n  ${toString().replaceAll("\n", "\n  ")}";
}
