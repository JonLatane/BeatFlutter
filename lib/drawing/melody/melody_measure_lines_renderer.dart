import 'package:beatscratch_flutter_redux/drawing/melody/base_melody_renderer.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/music_theory.dart';
import 'package:flutter/material.dart';


class MelodyMeasureLinesRenderer extends BaseMelodyRenderer {
  @override bool showSteps = true;
  @override double normalizedDevicePitch = 0;

  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();
  

  draw(Canvas canvas, double strokeWidth) {
    canvas.save();
    canvas.translate(0, bounds.top);
    if(beatPosition % meter.defaultBeatsPerMeasure == 0) {
      drawTimewiseLineRelativeToBounds(
        canvas: canvas,
        strokeWidth: strokeWidth,
        startY: 0,
        stopY: bounds.height
      );
    }
    canvas.restore();
  }
}