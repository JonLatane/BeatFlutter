import 'dart:collection';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../util/util.dart';
import '../util/proto_utils.dart';
import '../util/music_theory.dart';
import '../util/music_utils.dart';

/// Recording V2 uses a queue. [RecordedSegment] objects - basically the lowest-level data possible -
/// are sent to this singleton queue for processing.
class RecordedSegmentQueue {
  /// Gets the recording melody from your UI. Should be set in [State.initState] and [State.dispose].
  static Melody Function() getRecordingMelody;

  /// Should be set in [State.initState] and [State.dispose] for
  static Function(Melody) updateRecordingMelody;
  static Melody get recordingMelody => getRecordingMelody.call();
  // static set recordingMelody(Melody melody) => updateRecordingMelody(melody);
  static final Queue<RecordedSegment> segments = ListQueue<RecordedSegment>();
  static final BSValueMethod<bool> enabled = BSValueMethod(false)
    ..addListener(() {
      if (!enabled.value) {
        segments.clear();
      } else {
        _loop();
      }
    });

  static _loop() async {
    if (enabled.value) {
      var segment;
      try {
        segment = segments.removeFirst();
      } catch (_) {}
      if (segment != null) _processSegment(segment);
      Future.delayed(
          Duration(
              milliseconds: BeatScratchPlugin.playing || segments.isNotEmpty
                  ? 350
                  : 1000), () {
        _loop();
      });
    }
  }

  static _processSegment(RecordedSegment segment) {
    if (segment.recordedData.isEmpty) return;
    final melody = recordingMelody;
    RecordedSegment_RecordedBeat firstBeat =
        segment.beats.minBy((rb) => rb.timestamp.toInt());
    RecordedSegment_RecordedBeat secondBeat =
        segment.beats.maxBy((rb) => rb.timestamp.toInt());
    segment.recordedData.forEach((data) {
      _processSegmentData(segment, data, melody, firstBeat, secondBeat);
    });
    print("applying PostProcessing: separateNoteOnAndOffs()");
    melody.separateNoteOnAndOffs();
    print("updateRecordingMelody?.call: ${melody.logString}");
    updateRecordingMelody?.call(melody);
    BeatScratchPlugin.updateMelody(melody);
  }

  static _processSegmentData(
      RecordedSegment segment,
      RecordedSegment_RecordedData data,
      Melody melody,
      RecordedSegment_RecordedBeat firstBeat,
      RecordedSegment_RecordedBeat secondBeat) {
    // print("Processing RecordedData! Data: ${data.logString}");
    // print("First beat: ${firstBeat.logString}");
    // print("Second beat: ${secondBeat.logString}");
    int firstBeatSubdivision = firstBeat.beat * melody.subdivisionsPerBeat;
    // int secondBeatSubdivision = secondBeat.beat * melody.subdivisionsPerBeat;
    double relativePosition =
        (data.timestamp.toDouble() - firstBeat.timestamp.toDouble()) /
            (secondBeat.timestamp.toDouble() - firstBeat.timestamp.toDouble());
    // print("firstBeatSubdivision=$firstBeatSubdivision; secondBeatSubdivision=$secondBeatSubdivision; relativePosition=$relativePosition");
    int targetSubdivision = firstBeatSubdivision +
        (relativePosition * melody.subdivisionsPerBeat).round();
    targetSubdivision = targetSubdivision.bsMod(melody.length);
    MidiChange midiChange = melody.midiData.data
        .putIfAbsent(targetSubdivision, () => MidiChange()..data = []);
    midiChange.data.addAll(data.midiData);
    melody.midiData.data[targetSubdivision] = midiChange;
  }
}
