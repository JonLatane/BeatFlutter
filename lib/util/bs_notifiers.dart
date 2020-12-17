import 'package:flutter/foundation.dart';

class BSNotifier extends ChangeNotifier {
  call() => notifyListeners();
  notifyChange() => notifyListeners();
}

class BSValueNotifier<T> extends ValueNotifier<T> {
  BSValueNotifier(value) : super(value);
  call(value) => this.value = value;
}