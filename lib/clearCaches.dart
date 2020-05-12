import 'package:beatscratch_flutter_redux/drawing/melody/melody.dart';

import 'music_theory.dart';
import 'midi_theory.dart';
import 'keyboard.dart';

clearMutableCaches() {
  _mutableCaches.forEach((element) {
      element.clear();
  });
}

var _mutableCaches = [
  HarmonyTheory.changeBeforeCache,
  MelodyTheory.tonesAtCache,
  MelodyTheory.tonesInMeasureCache,
  MelodyTheory.averageToneCache,
  NotationMelodyRenderer.recentSignCache,
  NotationMelodyRenderer.playbackNoteCache
];

var _deterministicCaches = [
  MidiChangeTheory.noteOnsCache,
  ClefNotes.coversCache,
  ClefNotes.diatonicMaxCache,
  ClefNotes.diatonicMinCache,
  ClefNotes.ledgersToCache,
  KeyboardState.diatonicToneCache,
];