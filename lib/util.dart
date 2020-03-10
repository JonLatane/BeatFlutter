import 'package:flutter/material.dart';

extension ContextUtils on BuildContext {
  bool get isTabletOrLandscape => MediaQuery.of(this).size.width > 500;
}