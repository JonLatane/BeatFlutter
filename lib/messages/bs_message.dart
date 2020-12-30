import 'package:flutter/material.dart';

class BSMessage {
  final Icon icon;
  final String message;
  final Duration timeout;
  bool visible = true;

  BSMessage({@required this.message, this.timeout = const Duration(milliseconds: 500), @required this.icon});
}
