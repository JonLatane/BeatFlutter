import 'package:beatscratch_flutter_redux/drawing/melody/melody.dart';

import 'music_theory.dart';
import 'midi_theory.dart';
import 'keyboard.dart';

clearMutableCaches() {
  _mutableCaches.forEach((element) {
      element.clear();
  });
}

clearMutableCachesForMelody(String melodyId) {
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  MelodyTheory.tonesAtCache.removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.tonesInMeasureCache.removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  NotationMelodyRenderer.recentSignCache.removeWhere((key, value) => (key.arguments[0] as String).contains(melodyId));
  NotationMelodyRenderer.playbackNoteCache.removeWhere((key, value) => key.arguments[0] == melodyId);
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