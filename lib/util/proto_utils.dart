import 'package:protobuf/protobuf.dart';

import 'fake_js.dart'
if(dart.library.js) 'dart:js';

extension ProtoUtils<T extends GeneratedMessage> on T {
  dynamic protoJsify() => JsObject.jsify(bsCopy().toProto3Json());
  T bsCopy() {
    return deepCopy();
  }
  T bsRebuild(Function(T) updates) {
    return (deepCopy()..freeze()).rebuild((t) => updates(t)).deepCopy() as T;
  }

  String get logString =>  "\n  ${toString().replaceAll("\n", "\n  ")}";
}
