import 'package:beatscratch_flutter_redux/colors.dart';

import 'base_music_renderer.dart';
import 'package:flutter/material.dart';

import '../../widget/keyboard.dart';

class MelodyPianoClefRenderer extends BaseMusicRenderer {
  @override
  bool showSteps = true;

  @override
  double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();

  draw(Canvas canvas) {
    canvas.save();
    canvas.clipRect(bounds);
    canvas.drawColor(musicBackgroundColor, BlendMode.color);
    canvas.translate(bounds.left, bounds.top);
//    canvas.rotate(0.1);
    canvas.rotate(-1.5707);
    canvas.translate(-bounds.height, 0);
    // var color = alphaDrawerPaint.color;
//    print("color");
    KeyboardRenderer()
      ..renderLettersAndNumbers = false
      ..highestPitch = highestPitch
      ..lowestPitch = lowestPitch
      ..pressedNotes = []
      ..alphaDrawerPaint = alphaDrawerPaint
      ..renderVertically = false
      ..alphaDrawerPaint = alphaDrawerPaint
      ..halfStepsOnScreen = halfStepsOnScreen
      ..bounds =
          Rect.fromPoints(Offset.zero, Offset(bounds.height, bounds.width))
//      ..bounds = bounds.translate(-bounds.left, -bounds.top)
      ..draw(canvas);
    canvas.restore();
  }
}
