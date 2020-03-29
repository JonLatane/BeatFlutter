
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/services.dart';

/// The native platform side of the app is expected to maintain one [Score].
/// We can push [Part]s and [Melody]s to it. [pushScore] should be the first thing called
/// by any part of the UI.
class PlatformChannelPlugin {
  static const MethodChannel _channel = const MethodChannel('PlatformChannelPlugin');

  static void pushScore(Score score) {
    _channel.invokeMethod('pushScore', score.writeToBuffer());
  }

  /// Pushes or updates the [Part].
  static void pushPart(Part part) {
    _channel.invokeMethod('pushPart', part.writeToBuffer());
  }

  static void pushMelody(Part part, Melody melody) {
    _channel.invokeMethod('pushMelody', [part.id, melody.writeToBuffer()]);
  }

  static void updateMelody(Melody melody) {
    _channel.invokeMethod('updateMelody', melody.writeToBuffer());
  }

  static void playNote(int tone, int velocity, Part part) {
    _channel.invokeMethod('playNote', [velocity, part.id]);
  }

  static void stopNote(int tone, int velocity, Part part) {
    _channel.invokeMethod('pushScore', [velocity, part.id]);
  }

//  static Future<Person> get myPerson async {
//    final Uint8List rawData = await _channel.invokeMethod('getPlatformVersion');
//    final Person person = Person.fromBuffer(rawData);
//    return person;
//  }
}