import 'package:beatscratch_flutter_redux/export/export.dart';
import 'package:beatscratch_flutter_redux/generated/protos/protos.dart';
import 'package:dart_midi/dart_midi.dart';
// ignore: implementation_imports
import 'package:dart_midi/src/byte_writer.dart';
import '../ui_models.dart';
import '../util/music_theory.dart';
import '../util/midi_theory.dart';
import '../util/util.dart';
import '../widget/my_buttons.dart';

extension ScoreMidiExport on Score {
  MidiFile exportMidi(BSExport export) {
    if (parts.isEmpty || sections.isEmpty) return null;
    final firstSection = sections.first;
    final List<List<MidiEvent>> tracks = parts.map((part) => [
      SetTempoEvent()
        ..microsecondsPerBeat = (60000000 / firstSection.tempo.bpm).round(),
      ProgramChangeMidiEvent()
        ..channel = part.instrument.midiChannel
        ..programNumber = part.instrument.midiInstrument
    ]).toList();
    final MidiHeader header = MidiHeader(ticksPerBeat: 24,);
    int startTick = 0;
    sections.forEach((section) {
      section.exportMidi(this, startTick, export, tracks, header);
      startTick += 24 * section.beatCount;
    });
    final result = MidiFile(tracks, header);
    return result;
  }
}

extension SectionMidiExport on Section {
  exportMidi(Score score, int startTick, BSExport export, List<List<MidiEvent>> tracks, MidiHeader header) {
    score.parts.asMap().forEach((index, part) {
      final track = tracks[index];
      if (score.sections.first != this && export.sectionId == null) {
        track.add(SetTempoEvent()
          ..microsecondsPerBeat = (60000000 / tempo.bpm).round()
          ..deltaTime = startTick);
      }
      melodies.where((r) => r.isEnabled).forEach((ref) {
        final melody = score.melodyReferencedBy(ref);
        if (melody.type == MelodyType.midi) {
          melody.midiData.data.forEach((subdivision, midiChange) {
            final events = midiChange.midiEvents;
            final absoluteBeat = (subdivision.toDouble() / melody.subdivisionsPerBeat).floor();
            final convertedTickOfBeat = Base24Conversion.map[melody.subdivisionsPerBeat]
              [subdivision % melody.subdivisionsPerBeat];
            final absoluteTick = startTick + 24 * absoluteBeat + convertedTickOfBeat;
            events.map((midiEvent) {
              if (midiEvent is NoteOnEvent) midiEvent.channel = part.instrument.midiChannel;
              if (midiEvent is NoteOffEvent) midiEvent.channel = part.instrument.midiChannel;
              return midiEvent..deltaTime = absoluteTick;
            }).forEach((midiEvent) {
              track.add(midiEvent);
            });
          });
        }
      });
      track.sort((a,b) => a.deltaTime.compareTo(b.deltaTime));
    });
  }
}
