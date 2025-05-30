import '../util/midi_theory.dart';
import 'package:dart_midi/dart_midi.dart';
//ignore: implementation_imports
import 'package:dart_midi/src/byte_writer.dart';

import '../generated/protos/music.pb.dart';
import 'util.dart';

extension ScoreReKey on Score {
  reKeyMelodies({bool andParts: true}) {
    parts.forEach((part) {
      if (andParts) {
        part.id = uuid.v4();
      }
      part.melodies.forEach((melody) {
        String oldMelodyId = melody.id;
        String newMelodyId = uuid.v4();

        sections.forEach((section) {
          section.melodies.forEach((melodyReference) {
            if (melodyReference.melodyId == oldMelodyId) {
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

extension DeleteNotes on Melody {
  deleteMidiNote(int midiNote, int subdivision) {
    // First delete the NoteOnEvent here
    midiData.data[subdivision].midiEvents = midiData
        .data[subdivision].midiEvents
        .withoutNoteOnEvents(midiNote)
        .toList();

    // Find the NoteOff that corresponds and delete it
    int s = subdivision;
    do {
      var foundNoteOff = false;
      var midiChange = midiData.data[s];
      if (midiChange != null) {
        final midiEvents = midiChange.midiEvents;
        if (midiEvents.hasNoteOnEvent(midiNote) != null) {
          midiChange.midiEvents =
              midiEvents.withoutNoteOffEvents(midiNote).toList();
          foundNoteOff = true;
        }
      }
      if (foundNoteOff) {
        break;
      }
      s = (s + 1) % length;
    } while (s != subdivision);
  }

  deleteBeat(int beat) {
    var startSubdivision = (beat * subdivisionsPerBeat) % length;
    var subdivision = startSubdivision;
    do {
      var midiChange = midiData.data[subdivision];
      if (midiChange != null) {
        midiChange.noteOns.forEach((it) {
          deleteMidiNote(it.noteNumber, subdivision);
        });
      }
      subdivision = (subdivision + 1) % length;
    } while (subdivision != (startSubdivision + subdivisionsPerBeat) % length);
  }
}

extension SeparateNoteOnAndOff on Melody {
  bool separateNoteOnAndOffs() {
    bool madeChanges = false;
    if (type == MelodyType.midi && false) {
      midiData.data.keys.forEach((index) {
        MidiChange midiChange = midiData.data[index];
        int nextIndex = (index < midiData.data.length - 1) ? index + 1 : 0;
        MidiChange nextMidiChange = midiData.data[nextIndex] ?? MidiChange();

        ByteWriter writer = ByteWriter();
        ByteWriter nextWriter = ByteWriter();

        List<int> noteOns = [];

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
