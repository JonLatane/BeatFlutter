import 'package:beatscratch_flutter_redux/drawing/color_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/drawing.dart';

class Colorboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return CustomPaint(painter: ColorboardPainter());
  }
}

class ColorboardPainter extends CustomPainter {
  ColorGuide colorGuide = ColorGuide();
  @override
  void paint(Canvas canvas, Size size) {
    var rect = Offset.zero & size;
    var gradient = RadialGradient(
      center: const Alignment(0.7, -0.6),
      radius: 0.2,
      colors: [const Color(0xFFFFFF00), const Color(0xFF0099FF)],
      stops: [0.4, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      // Annotate a rectangle containing the picture of the sun
      // with the label "Sun". When text to speech feature is enabled on the
      // device, a user will be able to locate the sun on this picture by
      // touch.
      var rect = Offset.zero & size;
      var width = size.shortestSide * 0.4;
      rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
      return [
        CustomPainterSemantics(
          rect: rect,
          properties: SemanticsProperties(
            label: 'Sun',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

// Since this Sky painter has no fields, it always paints
// the same thing and semantics information is the same.
// Therefore we return false here. If we had fields (set
// from the constructor) then we would return true if any
// of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(ColorboardPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(ColorboardPainter oldDelegate) => false;

  @override
  Paint alphaDrawerPaint;

  @override
  double axisLength;

  @override
  Rect bounds;

  @override
  double halfStepsOnScreen;

  @override
  int lowestPitch;

  @override
  bool renderVertically;

  @override
  // TODO: implement halfStepWidth
  double get halfStepWidth => throw UnimplementedError();

  @override
  // TODO: implement highestPitch
  int get highestPitch => throw UnimplementedError();
}
