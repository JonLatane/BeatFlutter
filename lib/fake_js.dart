
var context = FakeJSContext();

class FakeJSContext {
  callMethod(String name, List args) => throw "What did you do?";
}

class JsObject {
  external factory JsObject.jsify(Object data);
}