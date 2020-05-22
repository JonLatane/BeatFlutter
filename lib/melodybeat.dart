import 'package:flutter/material.dart';
import 'drawing/sizeutil.dart';

class MelodyBeat extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width > 1.0 && size.height > 1.0) {
      print(">1.9");
      SizeUtil.size = size;
    }
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue
      ..isAntiAlias = true;
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
