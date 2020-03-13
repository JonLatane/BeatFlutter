import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();
extension ContextUtils on BuildContext {
  bool get isTabletOrLandscape => MediaQuery.of(this).size.width > 500;
}