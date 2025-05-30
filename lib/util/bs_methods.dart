import 'package:flutter/foundation.dart';

class BSMethod extends ChangeNotifier {
  call() => notifyListeners();
  notifyChange() => notifyListeners();
}

class BSValueMethod<T> extends ValueNotifier<T> {
  BSValueMethod(value) : super(value);
  call(value) => this.value = value;
}
