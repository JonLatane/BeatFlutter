import 'package:beatscratch_flutter_redux/drawing/melody/melody.dart';

import 'music_theory.dart';
import 'midi_theory.dart';
import 'keyboard.dart';

clearMutableCaches() {
  _mutableCaches.forEach((element) {
      element.clear();
  });
}

clearMutableCachesForMelody(String melodyId, {String sectionId, int beat, int sectionLengthBeats, double melodyLengthBeats}) {
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  MelodyTheory.tonesAtCache.removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.tonesInMeasureCache.removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  NotationMelodyRenderer.recentSignCache.removeWhere((key, value) => (key.arguments[0] as String).contains(melodyId));
  NotationMelodyRenderer.playbackNoteCache.removeWhere((key, value) => key.arguments[0] == melodyId);
  if(sectionId == null || beat == null || sectionLengthBeats == null || melodyLengthBeats == null) {
    NotationMelodyRenderer.notationRenderingCache.removeWhere((key, value) =>
      key.arguments[0] == melodyId || (key.arguments[1] as String).contains(melodyId));
  } else {
    NotationMelodyRenderer.notationRenderingCache.removeWhere((key, value) {
      String keySectionId = (key.arguments[2] as String);
      int keyBeat = key.arguments[3] as int;
      return keySectionId == sectionId
        && ( (keyBeat % melodyLengthBeats).round() == beat || (((keyBeat + 1) % sectionLengthBeats) % melodyLengthBeats).round() == beat ||
          (((keyBeat - 1 + sectionLengthBeats) % sectionLengthBeats) % melodyLengthBeats).round() == beat)
          && (key.arguments[0] == melodyId || (key.arguments[1] as String).contains(melodyId));
    });
  }

}

var _mutableCaches = [
  HarmonyTheory.changeBeforeCache,
  MelodyTheory.tonesAtCache,
  MelodyTheory.tonesInMeasureCache,
  MelodyTheory.averageToneCache,
  NotationMelodyRenderer.recentSignCache,
  NotationMelodyRenderer.playbackNoteCache,
  NotationMelodyRenderer.notationRenderingCache,
];

var _deterministicCaches = [
  MidiChangeTheory.noteOnsCache,
  ClefNotes.coversCache,
  ClefNotes.diatonicMaxCache,
  ClefNotes.diatonicMinCache,
  ClefNotes.ledgersToCache,
  KeyboardState.diatonicToneCache,
];