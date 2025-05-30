import 'dart:typed_data';

import 'package:dart_midi/dart_midi.dart';
// ignore: implementation_imports
import 'package:dart_midi/src/byte_writer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'generated/protos/protos.dart';
import 'messages/messages_ui.dart';
import 'recording/recording.dart';
import 'settings/settings_panel.dart';
import 'settings/settings_common.dart';
import 'util/fake_js.dart' if (dart.library.js) 'dart:js';
import 'util/music_utils.dart';
import 'util/proto_utils.dart';
import 'widget/my_platform.dart';

/// The native platform side of the app is expected to maintain one [Score].
/// We can push [Part]s and [Melody]s to it. [createScore] should be the first thing called
/// by any part of the UI.
class BeatScratchPlugin {
  static final bool supportsStorage = !MyPlatform.isWeb || kDebugMode;
  static final bool supportsRecording = !MyPlatform.isWeb || kDebugMode;
  static final bool supportsRecordingV2 = MyPlatform.isAppleOS;
  static final bool _supportsPlayback = true;
  static final int _playbackPreRenderBeats = MyPlatform.isWeb ? 2 : 0;
  static bool _playbackForceDisabled = false;
  static bool get supportsPlayback =>
      _supportsPlayback && !_playbackForceDisabled;
  static bool _countInInitiated = false;
  static bool get countInInitiated => _countInInitiated;

  static MethodChannel _channel = MethodChannel('BeatScratchPlugin')
    ..setMethodCallHandler((call) {
      switch (call.method) {
        case "sendPressedMidiNotes":
          final Uint8List rawData = call.arguments;
          final MidiNotes notes = MidiNotes.fromBuffer(rawData);
          pressedMidiControllerNotes.value =
              notes.midiNotes.map((e) => e - 60).toSet();
//          print("dart: sendPressedMidiNotes: ${pressedMidiControllerNotes.value}");
//           onSynthesizerStatusChange?.call();

          return Future.value(null);
          break;
        case "notifyBeatScratchAudioAvailable":
          _notifyBeatScratchAudioAvailable(call.arguments);
          return Future.value(null);
          break;
        case "notifyPlayingBeat":
          _notifyPlayingBeat(call.arguments);
          _countInInitiated = false;
          return Future.value(null);
          break;
        case "notifyPaused":
          _notifyPaused();
          onSynthesizerStatusChange();
          return Future.value(null);
          break;
        case "notifyCountInInitiated":
          _playing = false;
          _countInInitiated = true;
          onCountInInitiated?.call();
          return Future.value(null);
          break;
        case "notifyCurrentSection":
          _notifyCurrentSection(call.arguments);
          break;
        case "notifyStartedSection":
          _notifyStartedSection(call.arguments);
          break;
        case "notifyBpmMultiplier":
          _notifyBpmMultiplier(call.arguments);
          break;
        case "notifyUnmultipliedBpm":
          _notifyUnmultipliedBpm(call.arguments);
          break;
        case "notifyRecordedMelody":
          final Uint8List rawData = call.arguments;
          final Melody melody = Melody.fromBuffer(rawData);
          if (melody.separateNoteOnAndOffs()) {
            updateMelody(melody);
          }
          onRecordingMelodyUpdated(melody);
          return Future.value(null);
          break;
        case "notifyRecordedSegment":
          final Uint8List rawData = call.arguments;
          final RecordedSegment segment = RecordedSegment.fromBuffer(rawData);
          // print("Received RecordedSegment! Data:\n  ${segment.toString().replaceAll("\n", "\n  ")}");
          RecordedSegmentQueue.segments.add(segment);
          return Future.value(null);
          break;
        case "notifyMidiDevices":
          final Uint8List rawData = call.arguments;
          final MidiDevices devices = MidiDevices.fromBuffer(rawData);
          _notifyMidiDevices(devices);
          return Future.value(null);
          break;
        case "notifyScoreUrlOpened":
          _notifyScoreUrlOpened(call.arguments);
          return Future.value(null);
          break;
      }
      return Future.value(null);
    });

  static setupWebStuff() {
    if (MyPlatform.isWeb) {
      context["notifyPlayingBeat"] = _notifyPlayingBeat;
      context["notifyPaused"] = _notifyPaused;
      context["notifyCurrentSection"] = _notifyCurrentSection;
      context["notifyStartedSection"] = _notifyStartedSection;
      context["notifyBpmMultiplier"] = _notifyBpmMultiplier;
      context["notifyUnmultipliedBpm"] = _notifyUnmultipliedBpm;
      context["notifyMidiDevices"] = _notifyMidiDevices;
      context["notifyBeatScratchAudioAvailable"] =
          _notifyBeatScratchAudioAvailable;
      context["notifyScoreUrlOpened"] = _notifyScoreUrlOpened;
    }
  }

  static _notifyScoreUrlOpened(String url) {
    if (onOpenUrlFromSystem != null) {
      onOpenUrlFromSystem(url);
    } else {
      Future.delayed(Duration(milliseconds: 500), () {
        _notifyScoreUrlOpened(url);
      });
    }
  }

  static _notifyMidiDevices(MidiDevices devices) {
    connectedControllers = List.from(devices.controllers
        .where((it) => !MyPlatform.isIOS || it.name != "Session 1"));
    _connectedSynthesizers = List.from(devices.synthesizers);
    onSynthesizerStatusChange?.call();
  }

  static _notifyCurrentSection(String sectionId) {
    onSectionSelected(sectionId);
  }

  static _notifyStartedSection(String sectionId) {
    currentBeat.value = 0;
    onSectionSelected(sectionId);
  }

  static _notifyPlayingBeat(int beat) {
    // In case the user pauses and a beat comes in in a race condition
    if (_pausedTime == null ||
        DateTime.now().difference(_pausedTime).inMilliseconds > 75) {
      _playing = true;
    }
    currentBeat.value = beat;
    onSynthesizerStatusChange?.call();
  }

  static _notifyPaused() {
    _playing = false;
    onSynthesizerStatusChange?.call();
  }

  static _notifyBpmMultiplier(double bpmMultiplier) {
    _bpmMultiplier = bpmMultiplier;
    onSynthesizerStatusChange?.call();
  }

  static _notifyUnmultipliedBpm(double unmultipliedBpm) {
    BeatScratchPlugin.unmultipliedBpm = unmultipliedBpm;
    onSynthesizerStatusChange?.call();
  }

  static _notifyBeatScratchAudioAvailable(bool available) {
    _isBeatScratchAudioAvailable = available;
    onSynthesizerStatusChange?.call();
  }

  static bool _metronomeEnabled = true;
  static bool get metronomeEnabled => _metronomeEnabled;
  static set metronomeEnabled(bool value) {
    _metronomeEnabled = value;
    if (kIsWeb) {
      context.callMethod('setMetronomeEnabled', [value]);
    } else {
      _channel.invokeMethod('setMetronomeEnabled', value);
    }
  }

  static double _bpmMultiplier = 1.0;
  static double get bpmMultiplier => _bpmMultiplier;
  static set bpmMultiplier(double value) {
    _bpmMultiplier = value;
    try {
      if (kIsWeb) {
        context.callMethod('setBpmMultiplier', [value]);
      } else {
        _channel.invokeMethod('setBpmMultiplier', value);
      }
    } catch (any) {}
  }

  static double unmultipliedBpm = 123;
  static bool _playing;
  static bool get playing {
    if (_playing == null) {
      _playing = false;
      _doSynthesizerStatusChangeLoop();
    }
    return _playing;
  }

  static final ValueNotifier<int> currentBeat = ValueNotifier(0);

  static bool _isBeatScratchAudioAvailable;
  static bool get isSynthesizerAvailable {
    if (_isBeatScratchAudioAvailable == null) {
      _isBeatScratchAudioAvailable = false;
      _doSynthesizerStatusChangeLoop();
    }
    return _isBeatScratchAudioAvailable;
  }

  static VoidCallback onCountInInitiated;
  static VoidCallback onSynthesizerStatusChange;
  static Function(String) onOpenUrlFromSystem;
  static Function(String) onSectionSelected;
  static Function(Melody) onRecordingMelodyUpdated;
  static MessagesUI messagesUI;
  static _doSynthesizerStatusChangeLoop() {
    Future.delayed(Duration(seconds: 5), () {
      getApps();
      _checkBeatScratchAudioStatus();
      _doSynthesizerStatusChangeLoop();
    });
  }

  static ValueNotifier<Iterable<int>> pressedMidiControllerNotes =
      ValueNotifier([]);

  static List<MidiController> connectedControllers = [];
  static List<MidiController> get midiControllers =>
      [
        MidiController()
          ..id = "keyboard"
          ..name = "Keyboard"
          ..enabled = true
      ] +
      connectedControllers +
      [
        MidiController()
          ..id = "colorboard"
          ..name = "Colorboard"
          ..enabled = true
      ];

  static List<MidiSynthesizer> _connectedSynthesizers = [];
  static List<MidiSynthesizer> get midiSynthesizers {
    final connected = _connectedSynthesizers;
    if (supportsSynthesizerConfig) {
      return connected;
    }
    return [
          MidiSynthesizer()
            ..id = "internal"
            ..name = "BeatScratch\nAudio System"
            ..enabled = true
        ] +
        connected
            .where((it) => MyPlatform.isAndroid || MyPlatform.isDebug)
            .toList();
  }

  static bool get _supportsSynthesizerConfig =>
      _connectedSynthesizers.isNotEmpty &&
      _connectedSynthesizers[0].id == 'internal';

  /// To add support for a platform in debug mode, have it return an "internal" synthesizer.
  /// To add that support in release mode, hardcode the appropriate [MyPlatform] check here.
  static bool get supportsSynthesizerConfig =>
      MyPlatform.isAndroid ||
      (MyPlatform.isAndroid && _supportsSynthesizerConfig);

  static void _checkBeatScratchAudioStatus() async {
    bool resultStatus;
    if (kIsWeb) {
      resultStatus = context.callMethod('checkBeatScratchAudioStatus', []);
    } else {
      resultStatus = await _channel.invokeMethod('checkBeatScratchAudioStatus');
    }
    if (resultStatus == null) {
      print("Failed to retrieve Synthesizer Status from JS/Platform Channel");
      resultStatus = false;
    }
    _isBeatScratchAudioAvailable = resultStatus;
    onSynthesizerStatusChange?.call();
  }

  static void resetAudioSystem() async {
    _isBeatScratchAudioAvailable = false;
    onSynthesizerStatusChange?.call();
    if (kIsWeb) {
    } else {
      _channel.invokeMethod('resetAudioSystem');
    }
  }

  static void createScore(Score score) async {
    _isBeatScratchAudioAvailable = false;
    onSynthesizerStatusChange?.call();
    _pushScore(score, 'createScore', includeParts: true, includeSections: true);
  }

  static void updateSections(Score score) async {
    _pushScore(score, 'updateSections',
        includeParts: false, includeSections: true);
  }

  static void _pushScore(Score score, String remoteMethod,
      {bool includeParts = true, includeSections = true}) async {
//    print("invoking $remoteMethod");
    if (!includeParts) {
      score = score.bsRebuild((it) {
        it.parts.clear();
      });
    }
    if (!includeSections) {
      score = score.bsRebuild((it) {
        it.sections.clear();
      });
    }
//    print("invoking $remoteMethod");
    if (kIsWeb) {
//      print("invoking $remoteMethod as JavaScript with context $context");
      context.callMethod(remoteMethod, [score.protoJsify()]);
    } else {
//      print("invoking $remoteMethod through Platform Channel $_channel");
      _channel.invokeMethod(remoteMethod, score.bsCopy().writeToBuffer());
    }
  }

  static void setPlaybackMode(Playback_Mode mode) {
    if (kIsWeb) {
      context.callMethod('setPlaybackMode', [mode.name]);
    } else {
      _channel.invokeMethod(
          'setPlaybackMode', (Playback()..mode = mode).writeToBuffer());
    }
  }

  static void createPart(Part part) {
    _pushPart(part, "createPart");
  }

  static void updatePartConfiguration(Part part) {
    _pushPart(part, "updatePartConfiguration");
  }

  /// Pushes or updates the [Part].
  static void _pushPart(Part part, String methodName,
      {bool includeMelodies = false}) async {
    if (!includeMelodies) {
      part = part.bsRebuild((it) {
        it.melodies.clear();
      });
    }

    if (kIsWeb) {
      context.callMethod(methodName, [part.protoJsify()]);
    } else {
      _channel.invokeMethod(methodName, part.bsCopy().writeToBuffer());
    }
  }

  static void setCurrentSection(Section section) async {
    if (kIsWeb) {
      context.callMethod('setCurrentSection', [section?.id]);
    } else {
      _channel.invokeMethod('setCurrentSection', section?.id);
    }
  }

  /// Assigns all external MIDI controllers to the given part.
  static void setKeyboardPart(Part part) async {
    if (kIsWeb) {
      context.callMethod('setKeyboardPart', [part?.id]);
    } else {
      _channel.invokeMethod('setKeyboardPart', part?.id);
    }
  }

  static void deletePart(Part part) async {
    if (kIsWeb) {
      context.callMethod('deletePart', [part.id]);
    } else {
      _channel.invokeMethod('deletePart', part.id);
    }
  }

  static void createMelody(Part part, Melody melody) async {
    if (kIsWeb) {
      context.callMethod('createMelody', [part.id, melody.protoJsify()]);
    } else {
      await _channel.invokeMethod('newMelody', melody.bsCopy().writeToBuffer());
      _channel.invokeMethod(
          'registerMelody',
          (RegisterMelody()
                ..melodyId = melody.id
                ..partId = part.id)
              .writeToBuffer());
    }
  }

  static void updateMelody(Melody melody) async {
    if (kIsWeb) {
      context.callMethod('updateMelody', [melody.protoJsify()]);
    } else {
      _channel.invokeMethod('updateMelody', melody.bsCopy().writeToBuffer());
    }
  }

  static void deleteMelody(Melody melody) async {
    if (kIsWeb) {
      context.callMethod('deleteMelody', [melody.id]);
    } else {
      _channel.invokeMethod('deleteMelody', melody.id);
    }
  }

  /// When set to null, disables recording. When set to a melody,
  /// any notes played while playback is running are to be recorded into this
  /// [Melody]. Implementation-wise: this is just done by passing the [Melody.id].
  /// This applies to notes played either with a physical MIDI controller on
  /// the native side or from [sendMIDI] in the plugin.
  static void setRecordingMelody(Melody melody) async {
    if (kIsWeb) {
      context.callMethod('setRecordingMelody', [melody?.id]);
    } else {
      _channel.invokeMethod('setRecordingMelody', melody?.id);
    }
  }

  /// Starts the playback thread
  static void play() {
    _playing = true;
    _countInInitiated = false;
    _play();
  }

  static void _play() async {
    if (kIsWeb) {
      context.callMethod('play', []);
      messagesUI?.sendMessage(
          message: "Web playback isn't great. Download the app!",
          isError: true);
      messagesUI?.sendMessage(
        message: "You may have to play the Keyboard to play.",
      );
    } else {
      _channel.invokeMethod('play');
    }
    onSynthesizerStatusChange();
  }

  static void stop() async {
    if (kIsWeb) {
      context.callMethod('stop', []);
    } else {
      _channel.invokeMethod('stop');
    }
    _stopUIPlayback();
  }

  static void pause() {
    _pause();
    _stopUIPlayback();
  }

  static DateTime _pausedTime;
  static void _stopUIPlayback() {
    _playing = false;
    onSynthesizerStatusChange();
    _pausedTime = DateTime.now();
  }

  static void _pause() async {
    if (kIsWeb) {
      context.callMethod('pause', []);
      // Disable the playback button for 2 beats.
      _playbackForceDisabled = true;
      onSynthesizerStatusChange();
      Future.delayed(
          Duration(
              milliseconds: (60000 /
                      (_playbackPreRenderBeats *
                          bpmMultiplier *
                          unmultipliedBpm))
                  .floor()), () {
        _playbackForceDisabled = false;
        onSynthesizerStatusChange();
      });
    } else {
      _channel.invokeMethod('pause');
    }
    onSynthesizerStatusChange();
  }

  static void setBeat(int beat) async {
    currentBeat.value = beat;
    if (kIsWeb) {
      context.callMethod('setBeat', [beat]);
    } else {
      _channel.invokeMethod('setBeat', beat);
    }
  }

  /// CountIn beat timings are used to establish a starting tempo. Once *two* [countIn] beats
  /// are sent within the minimum beat window (30bpm, or 2s), a tempo is established in the BE.
  /// It is expected to continue playback at this point, with additional [tickBeat] or [countIn] calls
  /// updating the underlying tempo. [countInBeat] is expected to be < 0. Once the playback thread reaches
  /// the point that [countInBeat] == 0 - either "effectively" due to playback starting, or through a user
  /// tap on [tickBeat] to signify that the current beat is 0
  static void countIn(int countInBeat) async {
    print("Invoked countIn");
    if (kIsWeb) {
      context.callMethod('countIn', [countInBeat]);
    } else {
      _channel.invokeMethod('countIn', countInBeat);
    }
  }

  static void tickBeat() async {
    if (kIsWeb) {
      context.callMethod('tickBeat', []);
    } else {
      _channel.invokeMethod('tickBeat');
    }
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

  static void sendMIDI(List<int> bytes) async {
//    print("invoking sendMIDI");
    if (kIsWeb) {
//      print("invoking sendMIDI as JavaScript with context $context");
      context.callMethod('sendMIDI', bytes);
    } else {
//      print("invoking sendMIDI through Platform Channel $_channel");
      _channel.invokeMethod('sendMIDI', Uint8List.fromList(bytes));
    }
  }

  static Future<String> getScoreId() async =>
      _channel.invokeMethod<String>("getScoreId");

  static Future<Melody> get recordedMelody async {
    final Uint8List rawData = await _channel.invokeMethod('getRecordedMelody');
    final Melody melody = Melody.fromBuffer(rawData);
    return melody;
  }

  static updateSynthesizerConfig(MidiSynthesizer synthesizer) async {
    if (supportsSynthesizerConfig) {
//    print("invoking sendMIDI");
      if (kIsWeb) {
//      print("invoking sendMIDI as JavaScript with context $context");
        context.callMethod('updateSynthesizerConfig', synthesizer.protoJsify());
      } else {
//      print("invoking sendMIDI through Platform Channel $_channel");
        _channel.invokeMethod(
            'updateSynthesizerConfig', synthesizer.bsCopy().writeToBuffer());
      }
    }
  }
}
