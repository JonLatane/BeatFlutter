import 'base_music_renderer.dart';
import '../../generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

class MelodyColorGuide extends BaseMusicRenderer {
  @override bool showSteps = true;
  @override double normalizedDevicePitch = 0;

  @override double get halfStepsOnScreen => (highestPitch - lowestPitch + 1).toDouble();

  @override
  drawColorGuide(Canvas canvas) {
    iterateSubdivisions(() {
      if(isCurrentlyPlayingBeat || isSelectedBeatInHarmony) {
        colorGuideAlpha = 255;
      } else if(isUserChoosingHarmonyChord && !isSelectedBeatInHarmony) {
        colorGuideAlpha = 69;
      } else if(melody.instrumentType == InstrumentType.drum) {
        colorGuideAlpha = 0;
      } else {
        colorGuideAlpha = 155;
      }
      super.drawColorGuide(canvas);
    });
  }
}