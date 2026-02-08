import 'package:beatscratch_flutter_redux/midi/byte_reader.dart';
import 'package:beatscratch_flutter_redux/midi/byte_writer.dart';
import 'package:beatscratch_flutter_redux/midi/midi_events.dart';
import 'package:beatscratch_flutter_redux/midi/midi_file.dart';
import 'package:beatscratch_flutter_redux/midi/midi_header.dart';
import 'package:beatscratch_flutter_redux/midi/midi_parser.dart';

import '../export/export.dart';
import '../generated/protos/protos.dart';
import '../util/music_theory.dart';
import '../util/midi_theory.dart';

extension ScoreMidiExport on Score {
  MidiFile? exportMidi(BSExport export) {
    if (parts.isEmpty || sections.isEmpty) return null;
    final List<MidiEvent> track = parts
        .where((p) => export.includesPart(p))
        .map<MidiEvent>((part) => (ProgramChangeMidiEvent()
          ..channel = part.instrument.midiChannel
          ..programNumber = part.instrument.midiInstrument))
        .toList();

    int currentTick = 0;
    sections.where((s) => export.includesSection(s)).forEach((section) {
      section.exportMidi(this, currentTick, export, track);
      currentTick += 24 * section.beatCount;
    });
    track.add(EndOfTrackEvent()..deltaTime = currentTick);

    // Now we've actually been storing "absolute" times in deltaTime; now we update them to be real deltaTimes.
    track.sort((a, b) => a.deltaTime.compareTo(b.deltaTime));
    int lastEventTime = 0;
    for (MidiEvent midiEvent in track) {
      int eventTime = midiEvent.deltaTime;
      midiEvent.deltaTime = midiEvent.deltaTime - lastEventTime;
      lastEventTime = eventTime;
    }

    print("Track assembled");
    final result = MidiFile(
        [track], MidiHeader(ticksPerBeat: 24, format: 0, numTracks: 1));
    return result;
  }
}

extension SectionMidiExport on Section {
  exportMidi(
      Score score, int startTick, BSExport export, List<MidiEvent> track) {
    track.add(SetTempoEvent()
      ..microsecondsPerBeat =
          ((60000000 / tempo.bpm) / export.tempoMultiplier).round()
      ..deltaTime = startTick);
    score.parts.asMap().forEach((index, part) {
      melodies
          .where((r) =>
              r.isEnabled && part.melodies.any((m) => m.id == r.melodyId))
          .forEach((ref) {
        final melody = score.melodyReferencedBy(ref);
        if (melody == null) return;
        if (melody.type == MelodyType.midi) {
          int startBeat = 0;
          while (startBeat < beatCount) {
            melody.midiData.data.forEach((subdivision, midiChange) {
              final events = midiChange.midiEvents.map((e) => e.copyOfEvent());
              final absoluteBeat =
                  (subdivision.toDouble() / melody.subdivisionsPerBeat).floor();
              final convertedTickOfBeat =
                  Base24Conversion.map[melody.subdivisionsPerBeat]![
                      subdivision % melody.subdivisionsPerBeat];
              final absoluteTick = 24 * startBeat +
                  startTick +
                  24 * absoluteBeat +
                  convertedTickOfBeat;
              events.map((midiEvent) {
                if (midiEvent is NoteOnEvent)
                  midiEvent.channel = part.instrument.midiChannel;
                if (midiEvent is NoteOffEvent)
                  midiEvent.channel = part.instrument.midiChannel;
                return midiEvent..deltaTime = absoluteTick;
              }).forEach((midiEvent) {
                track.add(midiEvent);
              });
            });
            final beatCount = melody.beatCount;
            startBeat += beatCount;
          }
        }
      });
    });
  }
}

final ByteWriter _w = ByteWriter()
  ..writeVarInt(0)
  ..writeUInt8(0x80)
  ..writeUInt8(0x00)
  ..writeUInt8(0x01);

final MidiParser _parser = MidiParser()..readEvent(ByteReader(_w.buffer));

extension<T extends MidiEvent> on T {
  T copyOfEvent() {
    ByteWriter w = ByteWriter()..writeVarInt(0);
    writeEvent(w);
    return _parser.readEvent(ByteReader(w.buffer)) as T;
  }
}
