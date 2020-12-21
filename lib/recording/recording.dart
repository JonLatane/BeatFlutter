import 'dart:collection';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../util/bs_notifiers.dart';
import '../util/util.dart';
import '../util/proto_utils.dart';

/// Recording V2 uses a queue. [RecordedSegment] objects - basically the lowest-level data possible -
/// are sent to this singleton queue for processing.
class RecordedSegmentQueue {
  /// Gets the recording melody from your UI. Should be set in [State.initState] and [State.dispose].
  static Melody Function() getRecordingMelody;
  /// Should be set in [State.initState] and [State.dispose] for
  static Function(Melody) updateRecordingMelody;
  static Melody get recordingMelody => getRecordingMelody?.call();
  // static set recordingMelody(Melody melody) => updateRecordingMelody(melody);
  static final Queue<RecordedSegment> segments = ListQueue<RecordedSegment>();
  static final BSValueNotifier<bool> enabled = BSValueNotifier(false)
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
      try { segment = segments.removeFirst(); } catch(_) {}
      if (segment != null) _processSegment(segment);
      Future.delayed(Duration(milliseconds: BeatScratchPlugin.playing || segments.isNotEmpty ? 350 : 1000), () {
        _loop();
      });
    }
  }

  static _processSegment(RecordedSegment segment) {
    if (segment.recordedData.isEmpty) return;
    final melody = recordingMelody;
    if (melody != null) {
      RecordedSegment_RecordedBeat firstBeat = segment.beats.minBy((rb) => rb.timestamp.toInt());
      RecordedSegment_RecordedBeat secondBeat = segment.beats.maxBy((rb) => rb.timestamp.toInt());
      segment.recordedData.forEach((data) {
        _processSegmentData(segment, data, melody, firstBeat, secondBeat);
      });
      print("updateRecordingMelody?.call: ${melody.logString}");
      updateRecordingMelody?.call(melody);
      BeatScratchPlugin.updateMelody(melody);
    }
    //TODO adapt/fix/rewrite this Swift implementation
    //   if var melody = recordingMelody, let startTime = beatStartTime, let beat = recordingBeat {
    //     let endTime = CACurrentMediaTime()
    //     recordedData.forEach {
    //       let time: CFTimeInterval = $0.key
    //       let value: [UInt8] = $0.value
    //       let subdivisionsPerBeat = melody.subdivisionsPerBeat
    //       let length = melody.length
    //       let beatSize = (endTime - startTime) //* (Double(subdivisionsPerBeat + 1))/Double(subdivisionsPerBeat)
    //       let beatProgress = time - startTime
    //       let normalizedProgress = beatProgress/beatSize // Between 0-1 "maybe".
    //       var subdivision = Int32((normalizedProgress * Double(subdivisionsPerBeat)).rounded())
    //       subdivision += Int32(beat) * Int32(subdivisionsPerBeat)
    //       subdivision = (subdivision + Int32(length)) % Int32(length)
    //
    //       melody.midiData.data.processUpdate(subdivision) {
    //         var change = $0 ?? MidiChange()
    //         change.data.append(contentsOf: value)
    //         return change
    //       }
    //     }
    //   }
    // }
  }

  static _processSegmentData(RecordedSegment segment, RecordedSegment_RecordedData data, Melody melody,
      RecordedSegment_RecordedBeat firstBeat, RecordedSegment_RecordedBeat secondBeat) {
    // print("Processing RecordedData! Data: ${data.logString}");
    // print("First beat: ${firstBeat.logString}");
    // print("Second beat: ${secondBeat.logString}");
    int firstBeatSubdivision = firstBeat.beat * melody.subdivisionsPerBeat;
    int secondBeatSubdivision = secondBeat.beat * melody.subdivisionsPerBeat;
    double relativePosition = (data.timestamp.toDouble() - firstBeat.timestamp.toDouble()) /
      (secondBeat.timestamp.toDouble() - firstBeat.timestamp.toDouble());
    // print("firstBeatSubdivision=$firstBeatSubdivision; secondBeatSubdivision=$secondBeatSubdivision; relativePosition=$relativePosition");
    int targetSubdivision = firstBeatSubdivision + (relativePosition * melody.subdivisionsPerBeat).floor();
    MidiChange midiChange = melody.midiData.data.putIfAbsent(targetSubdivision, () => MidiChange()..data = []);
    midiChange.data.addAll(data.midiData);
    melody.midiData.data[targetSubdivision] = midiChange;
  }
}