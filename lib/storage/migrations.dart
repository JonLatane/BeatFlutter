
import '../generated/protos/music.pb.dart';
import '../util/music_utils.dart';

extension Migrations on Score {
  migrate() {
    parts.forEach((p) => p.melodies.forEach((m) => m.instrumentType = p.instrument.type));
    _setBpmsOnSections();
    _separateNoteOnAndOffs();
  }

  _setBpmsOnSections() {
    double firstSeenBpm;
    for (Section section in sections) {
      if (section.tempo != null && section.tempo.bpm != null) {
        firstSeenBpm = section.tempo.bpm;
        break;
      }
    }
    sections.forEach((section) {
      if (section.tempo == null || section.tempo.bpm == null) {
        section.tempo = Tempo()..bpm = firstSeenBpm ?? 123;
      }
    });
  }
  _separateNoteOnAndOffs() {
    parts.expand((p) => p.melodies).forEach((melody) {
      melody.separateNoteOnAndOffs();
    });
  }
}