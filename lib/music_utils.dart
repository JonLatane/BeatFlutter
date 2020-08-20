import 'package:beatscratch_flutter_redux/midi_theory.dart';
import 'package:unification/unification.dart';

import 'generated/protos/music.pb.dart';
import 'util.dart';

extension ScoreReKey on Score {
  reKeyMelodies() {
    parts.forEach((part) {
      part.melodies.forEach((melody) {
        String oldMelodyId = melody.id;
        String newMelodyId = uuid.v4();

        sections.forEach((section) {
          section.melodies.forEach((melodyReference) {
            if(melodyReference.melodyId == oldMelodyId) {
              melodyReference.melodyId = newMelodyId;
            }
          });
        });

        melody.id = newMelodyId;
      });
      part.id = uuid.v4();
    });
    sections.forEach((section) {
      section.id = uuid.v4();
    });
  }
}