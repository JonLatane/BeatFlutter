import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();
extension ContextUtils on BuildContext {
  bool get isTablet => MediaQuery.of(this).size.width > 500 && MediaQuery.of(this).size.height > 500;
  bool get isTabletOrLandscapey => MediaQuery.of(this).size.width > 500;
  bool get isLandscape => MediaQuery.of(this).size.width > MediaQuery.of(this).size.height;
  bool get isPortrait => !isLandscape;
}