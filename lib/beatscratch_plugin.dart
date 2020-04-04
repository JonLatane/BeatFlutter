
import 'dart:typed_data';
import 'dart:js' as js;

import 'package:beatscratch_flutter_redux/generated/protos/protos.dart';
import 'package:dart_midi/dart_midi.dart';
import 'package:dart_midi/src/byte_writer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


/// The native platform side of the app is expected to maintain one [Score].
/// We can push [Part]s and [Melody]s to it. [pushScore] should be the first thing called
/// by any part of the UI.
class BeatScratchPlugin {
  static const MethodChannel _channel = const MethodChannel('BeatScratchPlugin');

  static void pushScore(Score score) {
    print("invoking pushScore");
    _channel.invokeMethod('pushScore', score.writeToBuffer());
  }

  /// Pushes or updates the [Part].
  static void pushPart(Part part) {
    print("invoking pushPart");
    _channel.invokeMethod('pushPart', part.writeToBuffer());
  }

  /// Pushes or updates the [Part].
  static void setColorboardPart(Part part) {
    print("invoking setColorboardPart");
    _channel.invokeMethod('setColorboardPart', part?.id);
  }

  /// Pushes or updates the [Part].
  static void setKeyboardPart(Part part) {
    print("invoking setKeyboardPart");
    _channel.invokeMethod('setKeyboardPart', part?.id);
  }

  static void deletePart(Part part) {
    _channel.invokeMethod('deletePart', part.id);
  }

  static void pushMelody(Part part, Melody melody) {
    _channel.invokeMethod('pushMelody', [part.id, melody.writeToBuffer()]);
  }

  static void updateMelody(Melody melody) {
    _channel.invokeMethod('updateMelody', melody.writeToBuffer());
  }

  static void deleteMelody(Melody melody) {
    _channel.invokeMethod('deleteMelody', melody.id);
  }

  static void playNote(int tone, int velocity, Part part) {
    ByteWriter writer = ByteWriter();
    NoteOnEvent()
      ..noteNumber = tone + 60
      ..velocity = velocity
      ..channel = part.instrument.midiChannel
      ..writeEvent(writer);
    sendMIDI(writer.buffer);
  }

  static void stopNote(int tone, int velocity, Part part) {
    ByteWriter writer = ByteWriter();
    NoteOffEvent()
      ..noteNumber = tone + 60
      ..velocity = velocity
      ..channel = part.instrument.midiChannel
      ..writeEvent(writer);
    sendMIDI(writer.buffer);
  }


  static void sendMIDI(List<int> bytes) {
    print("invoking sendMIDI");
    if(kIsWeb) {
      js.context.callMethod('sendMIDI', bytes);
//      js.context.callMethod('sendMIDI', bytes);
    } else {
      _channel.invokeMethod('sendMIDI', Uint8List.fromList(bytes));
    }
  }

  static Future<String> getScoreId() => _channel.invokeMethod<String>("getScoreId");

//  static Future<Person> get myPerson async {
//    final Uint8List rawData = await _channel.invokeMethod('getPlatformVersion');
//    final Person person = Person.fromBuffer(rawData);
//    return person;
//  }

  static Future<Melody> get recordedMelody async {
    final Uint8List rawData = await _channel.invokeMethod('getRecordedMelody');
    final Melody melody = Melody.fromBuffer(rawData);
    return melody;
  }
}