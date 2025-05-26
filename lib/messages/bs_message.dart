import 'package:flutter/material.dart';

class BSMessage {
  final String? id;
  final Icon icon;
  final String message;
  final Duration timeout;
  bool visible = false;

  BSMessage({
    this.id,
    required this.message,
    this.timeout = const Duration(milliseconds: 500),
    required this.icon,
  });
}
