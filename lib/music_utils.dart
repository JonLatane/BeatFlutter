import 'package:beatscratch_flutter_redux/midi_theory.dart';
import 'package:dart_midi/dart_midi.dart';
import 'package:unification/unification.dart';
import 'package:dart_midi/src/byte_writer.dart';

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

extension SeparateNoteOnAndOff on Melody {
  bool separateNoteOnAndOffs() {
    bool madeChanges = false;
    if(type == MelodyType.midi) {
      midiData.data.keys.forEach((index) {
        MidiChange midiChange =  midiData.data[index];
        int nextIndex = (index < midiData.data.length - 1) ? index + 1 : 0;
        MidiChange nextMidiChange =  midiData.data[nextIndex] ?? MidiChange();

        ByteWriter writer = ByteWriter();
        ByteWriter nextWriter = ByteWriter();

        List<int> noteOns = List();

        midiChange.midiEvents.forEach((midiEvent) {
          if (midiEvent is NoteOnEvent) {
            midiEvent.writeEvent(writer);
            noteOns.add(midiEvent.noteNumber);
          } else if (midiEvent is NoteOffEvent) {
            if (!noteOns.contains(midiEvent.noteNumber)) {
              midiEvent.writeEvent(writer);
            } else {
              madeChanges = true;
              midiEvent.writeEvent(nextWriter);
            }
          }
        });

        nextWriter.buffer.addAll(nextMidiChange.data ?? []);
        midiChange.data = writer.buffer;
        nextMidiChange.data = nextWriter.buffer;
      });
    }
    return madeChanges;
  }
}