import 'dart:io';
import 'dart:typed_data';
import 'fake_js.dart'
  if(dart.library.js) 'dart:js';
import 'package:beatscratch_flutter_redux/generated/protos/protos.dart';
import 'package:dart_midi/dart_midi.dart';
import 'package:dart_midi/src/byte_writer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The native platform side of the app is expected to maintain one [Score].
/// We can push [Part]s and [Melody]s to it. [pushScore] should be the first thing called
/// by any part of the UI.
class BeatScratchPlugin {
  static bool _playing;
  static bool get playing {
    if(_playing == null) {
      _playing = false;
      _doSynthesizerStatusChangeLoop();
    }
    return _playing;
  }
  static _doPlayingChangedLoop() {
    Future.delayed(Duration(seconds:5), () {
//      checkPlaying();
      _doPlayingChangedLoop();
    });
  }
  
  static bool _isSynthesizerAvailable;
  static bool get isSynthesizerAvailable {
    if(_isSynthesizerAvailable == null) {
      _isSynthesizerAvailable = false;
      _doSynthesizerStatusChangeLoop();
    }
    return _isSynthesizerAvailable;
  }
  static VoidCallback onSynthesizerStatusChange;
  static _doSynthesizerStatusChangeLoop() {
    Future.delayed(Duration(seconds:5), () {
      _checkSynthesizerStatus();
      _doSynthesizerStatusChangeLoop();
    });
  }
  static ValueNotifier<Iterable<int>> pressedMidiControllerNotes = ValueNotifier([]);
  static MethodChannel _channel = MethodChannel('BeatScratchPlugin')
    ..setMethodCallHandler((call) {
      switch(call.method) {
        case "sendPressedMidiNotes":
          final Uint8List rawData = call.arguments;
          final MidiNotes response = MidiNotes.fromBuffer(rawData);
          pressedMidiControllerNotes.value = response.midiNotes.map((e) => e - 60).toSet();
//          print("dart: sendPressedMidiNotes: ${pressedMidiControllerNotes.value}");

          return Future.value(null);
          break;
        case "setSynthesizerAvailable":
          _isSynthesizerAvailable = call.arguments;
          onSynthesizerStatusChange?.call();
          return Future.value(null);
          break;
      }
      return Future.value(null);
    });

  static Iterable<MidiController> get midiControllers => [
    MidiController()
    ..id = "keyboard"
    ..name = "Keyboard",
    MidiController()
    ..id = "colorboard"
    ..name = "Colorboard"
  ];

  static Iterable<MidiSynthesizer> get midiSynthesizers => [
    MidiSynthesizer()
    ..id = "internal"
    ..name = "BeatScratch Synthesizer"
  ];

  static bool get supportsMelodyEditing {
    return Platform.isMacOS && kDebugMode;
  }

  static bool get supportsPlayback {
    return kDebugMode;
  }

  static void _checkSynthesizerStatus() async {
    bool resultStatus;
    if(kIsWeb) {
      resultStatus = context.callMethod('checkSynthesizerStatus', []);
    } else {
      resultStatus = await _channel.invokeMethod('checkSynthesizerStatus');
    }
    if(resultStatus == null) {
      print("Failed to retrieve Synthesizer Status from JS/Platform Channel");
      resultStatus = false;
    }
    _isSynthesizerAvailable = resultStatus;
    onSynthesizerStatusChange?.call();
  }

  static Future<List<MidiController>> get deviceMidiControllers async {
    if(kIsWeb) {
      return Future.value([]);
    } else {
      try {
        final Uint8List rawData = await _channel.invokeMethod('getMidiControllers');
        final MidiControllers response = MidiControllers.fromBuffer(rawData);
        return response.controllers.toList();
      } catch(e) {
        return Future.value([]);
      }
    }
  }

  static void resetAudioSystem() async {
    _isSynthesizerAvailable = false;
    onSynthesizerStatusChange?.call();
    if(kIsWeb) {
    } else {
      _channel.invokeMethod('resetAudioSystem');
    }
  }

  static void pushScore(Score score, {bool includeParts = true, includeSections = true}) async {
    print("invoking pushScore");
    if(!includeParts) {
      score = score.clone().copyWith((it) { it.parts.clear(); });
    }
    if(!includeSections) {
      score = score.clone().copyWith((it) { it.sections.clear(); });
    }
    _channel.invokeMethod('pushScore', score.clone().writeToBuffer());
  }

  /// Pushes or updates the [Part].
  static void pushPart(Part part, {bool includeMelodies = true}) async {
    if(!includeMelodies) {
      part = part.clone().copyWith((it) { it.melodies.clear(); });
    }

    if(kIsWeb) {
      context.callMethod('pushPart', [ part.writeToJson() ]);
    } else {
      _channel.invokeMethod('pushPart', part.clone().writeToBuffer());
    }
  }

  /// Pushes or updates the [Part].
  static void setColorboardPart(Part part) async {
    print("invoking setColorboardPart");
    _channel.invokeMethod('setColorboardPart', part?.id);
  }

  /// Pushes or updates the [Part].
  static void setKeyboardPart(Part part) async {
    print("invoking setKeyboardPart");
    _channel.invokeMethod('setKeyboardPart', part?.id);
  }

  static void deletePart(Part part) async {
    _channel.invokeMethod('deletePart', part.id);
  }

  static void pushMelody(Part part, Melody melody) async {
    _channel.invokeMethod('pushMelody', [part.id, melody.clone().writeToBuffer()]);
  }

  static void updateMelody(Melody melody) async {
    _channel.invokeMethod('updateMelody', melody.clone().writeToBuffer());
  }

  static void deleteMelody(Melody melody) async {
    _channel.invokeMethod('deleteMelody', melody.id);
  }

  /// Starts the playback thread
  static void play() async {
    _channel.invokeMethod('play');
    _playing = true;
    onSynthesizerStatusChange();
  }

  static void stop() async {
    _channel.invokeMethod('stop');
    _playing = false;
    onSynthesizerStatusChange();
  }
  static void pause() async {
    _channel.invokeMethod('pause');
    _playing = false;
    onSynthesizerStatusChange();
  }

  static void setBeat(int beat) async {
    _channel.invokeMethod('setBeat', beat);
  }

  /// CountIn beat timings are used to establish a starting tempo. Once *two* [countIn] beats
  /// are sent within the minimum beat window (30bpm, or 2s), a tempo is established in the BE.
  /// It is expected to continue playback at this point, with additional [tickBeat] or [countIn] calls
  /// updating the underlying tempo. [countInBeat] is expected to be < 0. Once the playback thread reaches
  /// the point that [countInBeat] == 0 - either "effectively" due to playback starting, or through a user
  /// tap on [tickBeat] to signify that the current beat is 0
  static void countIn(int countInBeat) async {
    print("Invoked countIn");
    _channel.invokeMethod('countIn', countInBeat);
  }

  static void tickBeat() async {
    _channel.invokeMethod('tickBeat');
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

  static void sendBeat(int beat) async {
//    print("invoking sendMIDI");
    if(kIsWeb) {
//      print("invoking sendMIDI as JavaScript with context $context");
      context.callMethod('sendBeat', [beat]);
    } else {
//      print("invoking sendMIDI through Platform Channel $_channel");
      _channel.invokeMethod('sendBeat', beat);
    }
  }


  static void sendMIDI(List<int> bytes) async {
//    print("invoking sendMIDI");
    if(kIsWeb) {
//      print("invoking sendMIDI as JavaScript with context $context");
      context.callMethod('sendMIDI', bytes);
    } else {
//      print("invoking sendMIDI through Platform Channel $_channel");
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