import 'dart:collection';

import '../generated/protos/protobeats_plugin.pb.dart';
import '../util/bs_notifiers.dart';

class RecordedSegmentQueue {
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
      final segment = segments.removeFirst();
      if (segment != null) _processSegment(segment);
      Future.delayed(Duration(milliseconds: 100), () {
        _loop();
      });
    }
  }

  static _processSegment(RecordedSegment segment) {
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
}