import 'drawing/music/music.dart';

import 'util/music_theory.dart';
import 'util/midi_theory.dart';
import 'widget/keyboard.dart';

clearMutableCaches() {
  _mutableCaches.forEach((element) {
    element.clear();
  });
}

clearMutableCachesForSection(String sectionId) {
  NotationMusicRenderer.notationRenderingCache
      .removeWhere((key, value) => key.arguments[2] == sectionId);
}

clearMutableCachesForMelody(String melodyId,
    {String sectionId,
    int beat,
    int sectionLengthBeats,
    double melodyLengthBeats}) {
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  MelodyTheory.tonesAtCache
      .removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.tonesInMeasureCache
      .removeWhere((key, value) => key.arguments[0] == melodyId);
  MelodyTheory.averageToneCache.removeWhere((key, value) => key == melodyId);
  NotationMusicRenderer.recentSignCache.removeWhere(
      (key, value) => (key.arguments[0] as String).contains(melodyId));
  NotationMusicRenderer.playbackNoteCache
      .removeWhere((key, value) => key.arguments[0] == melodyId);
  if (sectionId == null ||
      beat == null ||
      sectionLengthBeats == null ||
      melodyLengthBeats == null) {
    NotationMusicRenderer.notationRenderingCache.removeWhere((key, value) =>
        key.arguments[0] == melodyId ||
        (key.arguments[1] as String).contains(melodyId));
  } else {
    NotationMusicRenderer.notationRenderingCache.removeWhere((key, value) {
      String keySectionId = (key.arguments[2] as String);
      int keyBeat = key.arguments[3] as int;
      return keySectionId == sectionId &&
          ((keyBeat % melodyLengthBeats).round() == beat ||
              (((keyBeat + 1) % sectionLengthBeats) % melodyLengthBeats)
                      .round() ==
                  beat ||
              (((keyBeat - 1 + sectionLengthBeats) % sectionLengthBeats) %
                          melodyLengthBeats)
                      .round() ==
                  beat) &&
          (key.arguments[0] == melodyId ||
              (key.arguments[1] as String).contains(melodyId));
    });
  }
}

var _mutableCaches = [
  HarmonyTheory.changeBeforeCache,
  MelodyTheory.tonesAtCache,
  MelodyTheory.tonesInMeasureCache,
  MelodyTheory.averageToneCache,
  NotationMusicRenderer.recentSignCache,
  NotationMusicRenderer.playbackNoteCache,
  NotationMusicRenderer.notationRenderingCache,
];

// ignore: unused_element
var _deterministicCaches = [
  MidiChangeTheory.midiEventsCache,
  ClefNotes.coversCache,
  ClefNotes.diatonicMaxCache,
  ClefNotes.diatonicMinCache,
  ClefNotes.ledgersToCache,
  KeyboardState.diatonicToneCache,
];
