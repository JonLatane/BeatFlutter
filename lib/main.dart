import 'dart:math';

import 'package:beatscratch_flutter_redux/storage/universe_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings/settings.dart';
import 'universe_view/universe_view.dart';

import 'recording/recording.dart';
import 'package:fluro/fluro.dart' as Fluro;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

import 'beatscratch_plugin.dart';
import 'cache_management.dart';
import 'colors.dart';
import 'export/export.dart';
import 'generated/protos/music.pb.dart';
import 'generated/protos/protobeats_plugin.pb.dart';
import 'main_toolbars.dart';
import 'messages/messages.dart';
import 'music_view/music_view.dart';
import 'layers_view/melody_menu_browser.dart';
import 'layers_view/layers_view.dart';
import 'storage/migrations.dart';
import 'storage/score_manager.dart';
import 'storage/score_picker.dart';
import 'storage/url_conversions.dart';
import 'ui_models.dart';
import 'util/bs_methods.dart';
import 'util/dummydata.dart';
import 'util/music_theory.dart';
import 'util/proto_utils.dart';
import 'util/util.dart';
import 'widget/color_filtered_image_asset.dart';
import 'widget/colorboard.dart';
import 'widget/keyboard.dart';
import 'widget/my_buttons.dart';
import 'widget/my_platform.dart';
import 'widget/section_list.dart';

final app = MyApp();

void main() => runApp(app);

const Color foo = Color.fromRGBO(0xF9, 0x37, 0x30, .1);

const Map<int, Color> swatch = {
  //createSwatch(0xF9, 0x37, 0x30);
  50: Color.fromRGBO(0x00, 0x00, 0x00, .1),
  100: Color.fromRGBO(0x00, 0x00, 0x00, .2),
  200: Color.fromRGBO(0x00, 0x00, 0x00, .3),
  300: Color.fromRGBO(0x00, 0x00, 0x00, .4),
  400: Color.fromRGBO(0x00, 0x00, 0x00, .5),
  500: Color.fromRGBO(0x00, 0x00, 0x00, .6),
  600: Color.fromRGBO(0x00, 0x00, 0x00, .7),
  700: Color.fromRGBO(0x00, 0x00, 0x00, .8),
  800: Color.fromRGBO(0x00, 0x00, 0x00, .9),
  900: Color.fromRGBO(0x00, 0x00, 0x00, 1),
};

ScoreManager _scoreManager = ScoreManager();
UniverseManager _universeManager = UniverseManager();
AppSettings _appSettings = AppSettings();
var baseHandler = Fluro.Handler(
    handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return MyHomePage(title: 'BeatScratch', initialScore: defaultScore());
  // return UsersScreen(params["scoreData"][0]);
});
var scoreRouteHandler = Fluro.Handler(
    handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String scoreData = params["scoreData"][0];
  Score score;
  try {
    score = scoreFromUrlHashValue(scoreData);
  } catch (any) {
    score = defaultScore();
  }

  return MyHomePage(title: 'BeatScratch', initialScore: score);
  // return UsersScreen(params["scoreData"][0]);
});
var pastebinRouteHandler = Fluro.Handler(
    handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String pastebinCode = params["pasteBinData"][0];
  return MyHomePage(
    title: 'BeatScratch',
    initialScore: defaultScore(),
    pastebinCode: pastebinCode,
  );
  // return UsersScreen(params["scoreData"][0]);
});

final Fluro.FluroRouter router = Fluro.FluroRouter()
  ..define("/",
      handler: baseHandler, transitionType: Fluro.TransitionType.material)
  ..define("/s/:pasteBinData",
      handler: pastebinRouteHandler,
      transitionType: Fluro.TransitionType.material)
  ..define("/score/:scoreData",
      handler: scoreRouteHandler,
      transitionType: Fluro.TransitionType.material);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
//    debugPaintSizeEnabled = true;
    MyHomePage home;
    try {
      home = MyHomePage(title: 'BeatScratch', initialScore: defaultScore());
    } catch (e) {
      print(e);
    }
    return MaterialApp(
      key: Key('BeatScratch'),
      title: 'BeatScratch',
      onGenerateTitle: (context) => 'BeatScratch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
              selectionColor: chromaticSteps[0].withOpacity(0.5),
              selectionHandleColor: chromaticSteps[0]),
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: MaterialColor(0xFF212121, swatch),
          platform: TargetPlatform.iOS,
          fontFamily: 'VulfSans'),
      onGenerateRoute: router.generator,
      home: home,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.initialScore, this.pastebinCode})
      : super(key: key);

  final String title;
  final Score initialScore;
  final String pastebinCode;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score score;
  InteractionMode interactionMode = InteractionMode.universe;
  SplitMode _splitMode;

  SplitMode get splitMode => _splitMode;

  set splitMode(SplitMode value) {
    _splitMode = value;
    if (_musicViewSizeFactor != 0) {
      if (value == SplitMode.half && interactionMode.isEdit) {
        _musicViewSizeFactor = 0.5;
      } else {
        _musicViewSizeFactor = 1;
      }
    }
  }

  MusicViewMode _musicViewMode = MusicViewMode.score;

  MusicViewMode get musicViewMode => _musicViewMode;

  set musicViewMode(MusicViewMode value) {
    _musicViewMode = value;
    if (value != MusicViewMode.melody) {
      selectedMelody = null;
    }
    if (value != MusicViewMode.part) {
      selectedPart = null;
    }
  }

  RenderingMode get renderingMode => _appSettings.renderingMode;
  set renderingMode(RenderingMode rm) => _appSettings.renderingMode = rm;

  bool _recordingMelody = false;
  bool _softKeyboardVisible = false;

  bool get recordingMelody => _recordingMelody;

  set recordingMelody(value) {
    _recordingMelody = value;
    if (value) {
      BeatScratchPlugin.setRecordingMelody(selectedMelody);
      _showMusicView();
    } else {
      BeatScratchPlugin.setRecordingMelody(null);
    }
    if (BeatScratchPlugin.supportsRecordingV2) {
      RecordedSegmentQueue.enabled.value = value;
    }
  }

  Section _currentSection; //

  Section get currentSection => _currentSection;

  set currentSection(Section section) {
    BeatScratchPlugin.setCurrentSection(section);
    BeatScratchPlugin.currentBeat.value =
        min(section.beatCount - 1, BeatScratchPlugin.currentBeat.value);
    _currentSection = section;
    if (recordingMelody &&
        section.referenceTo(selectedMelody).playbackType ==
            MelodyReference_PlaybackType.disabled) {
      recordingMelody = false;
    }
    if (MyPlatform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: sectionColor,
      ));
    }
  }

  int _tapInBeat;
  bool showViewOptions = false;
  bool _wasKeyboardShowingWhenMidiConfigurationOpened = false;
  bool _wasColorboardShowingWhenMidiConfigurationOpened = false;
  bool _wereViewOptionsShowingWhenMidiConfigurationOpened = false;
  ScorePickerMode scorePickerMode = ScorePickerMode.universe;
  bool _showScorePicker = true;

  bool get showScorePicker => _showScorePicker;

  set showScorePicker(bool value) {
    _showScorePicker = value;
    if (value) {
      exportUI.visible = false;
    }
  }

  bool showMidiConfiguration = false;
  bool showKeyboard = true;
  bool _showTapInBar = false;
  bool _bottomTapInBar = false;
  bool _showKeyboardConfiguration = false;
  bool _enableColorboard = false;

  get enableColorboard => _enableColorboard;

  set enableColorboard(bool value) {
    _enableColorboard = value;
    _showColorboardConfiguration = value;
    showColorboard = value;
  }

  bool showColorboard = false;
  bool _showColorboardConfiguration = false;
  Part _keyboardPart;

  Part get keyboardPart => _keyboardPart;

  set keyboardPart(Part part) {
    _keyboardPart = part;
    if (part == null) {
      showKeyboard = false;
    }
    BeatScratchPlugin.setKeyboardPart(part);
  }

  Part _colorboardPart;

  Part get colorboardPart => _colorboardPart;

  set colorboardPart(Part part) {
    _colorboardPart = part;
    if (part == null) {
      showColorboard = false;
    }
//    BeatScratchPlugin.setColorboardPart(part);
  }

  ValueNotifier<Iterable<int>> colorboardNotesNotifier;
  ValueNotifier<Iterable<int>> keyboardNotesNotifier;
  ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;
  int keyboardChordBase;
  Set<int> keyboardChordNotes = Set();
  ValueNotifier<Chord> keyboardChordNotifier;

  bool get melodyViewVisible => _musicViewSizeFactor > 0;

  double _musicViewSizeFactor = 1.0;

  bool showWebWarning = false; //kIsWeb || kDebugMode;

  double get webWarningHeight => showWebWarning ? 60 : 0;
  bool get showDownloadLinks => _appSettings.showWebDownloadLinks;
  set showDownloadLinks(v) => _appSettings.showWebDownloadLinks = v;

  double get downloadLinksHeight => showDownloadLinks ? 60 : 0;

  bool get showBeatCounts => _appSettings.showBeatsBadges;
  set showBeatCounts(bool v) => _appSettings.showBeatsBadges = v;

  _showMusicView() {
    if (interactionMode.isEdit) {
      if (splitMode == SplitMode.half) {
        _musicViewSizeFactor = 0.5;
      } else {
        _musicViewSizeFactor = 1;
      }
    } else {
      _musicViewSizeFactor = 1;
    }
  }

  _hideMusicView() {
    setState(() {
      _musicViewSizeFactor = 0;
      _prevSelectedMelody = selectedMelody;
      if (_prevSelectedMelody == null) {
        _prevSelectedPart = selectedPart;
      }
      selectedMelody = null;
      recordingMelody = false;
      selectedPart = null;
      musicViewMode = MusicViewMode.none;
    });
  }

  toggleMelodyViewDisplayMode() {
    setState(() {
      if (splitMode == SplitMode.half) {
        splitMode = SplitMode.full;
      } else {
        splitMode = SplitMode.half;
      }
      _showMusicView();
    });
  }

  bool get hasPrioritizedMIDIController =>
      _appSettings.controllersReplacingKeyboard.any((nameOrId) =>
          BeatScratchPlugin.midiControllers
              .map((c) => c.nameOrId)
              .contains(nameOrId));
  bool hadPriotizedMIDIController = false;

  _setKeyboardPart(Part part) {
    setState(() {
      bool wasAssignedByPartCreation = keyboardPart == null;
      keyboardPart = part;
      if (part != null &&
          !wasAssignedByPartCreation &&
          !hasPrioritizedMIDIController) {
        showKeyboard = true;
      }
    });
  }

  _setColorboardPart(Part part) {
    setState(() {
      bool wasAssignedByPartCreation = colorboardPart == null;
      colorboardPart = part;
      if (part != null && !wasAssignedByPartCreation) {
        showColorboard = true;
      }
    });
  }

  Melody _selectedMelody;

  Melody get selectedMelody => _selectedMelody;

  set selectedMelody(Melody selectedMelody) {
    _selectedMelody = selectedMelody;
    if (selectedMelody != null) {
      Part part = score.parts
          .firstWhere((p) => p.melodies.any((m) => m.id == selectedMelody.id));
      if (part != null) {
        keyboardPart = part;
      }
    } else {
      recordingMelody = false;
    }
  }

  Part _selectedPart;

  Part get selectedPart => _selectedPart;

  set selectedPart(Part selectedPart) {
    _selectedPart = selectedPart;
    if (selectedPart != null) {
      keyboardPart = selectedPart;
    }
  }

  Part _viewingPart;

  Part get viewingPart => _viewingPart;

  set viewingPart(Part viewingPart) {
    _viewingPart = viewingPart;
    if (viewingPart != null) {
      keyboardPart = viewingPart;
    }
  }

  List<SectionList> _sectionLists = [];

  Color get sectionColor => currentSection.color.color;

  _selectOrDeselectMelody(Melody melody, {bool hideMusicOnDeselect: true}) {
    setState(() {
      if (selectedMelody != melody) {
        selectedMelody = melody;
        _prevSelectedMelody = melody;
        _prevSelectedPart = null;
        if (recordingMelody) {
          BeatScratchPlugin.setRecordingMelody(melody);
        }
        musicViewMode = MusicViewMode.melody;
        _showMusicView();
      } else {
        selectedMelody = null;
        recordingMelody = false;
        if (hideMusicOnDeselect) {
          _hideMusicView();
        } else {
          final part = score.parts
              .firstWhere((p) => p.melodies.any((m) => m.id == melody.id));
          _selectOrDeselectPart(part, hideMusicOnDeselect: hideMusicOnDeselect);
        }
      }
    });
  }

  _selectOrDeselectPart(Part part, {bool hideMusicOnDeselect: true}) {
    setState(() {
      print("yay");
      if (selectedPart != part) {
        selectedPart = part;
        _prevSelectedPart = part;
        _prevSelectedMelody = null;
        recordingMelody = false;
        musicViewMode = MusicViewMode.part;
        _showMusicView();
      } else {
        if (hideMusicOnDeselect) {
          _hideMusicView();
        } else {
          if (musicViewMode == MusicViewMode.melody) {
            _selectOrDeselectMelody(selectedMelody,
                hideMusicOnDeselect: hideMusicOnDeselect);
          } else {
            selectedPart = null;
            _prevSelectedPart = null;
            musicViewMode = MusicViewMode.section;
          }
        }
      }
    });
  }

  _toggleReferenceDisabled(MelodyReference ref) {
    if (ref.playbackType == MelodyReference_PlaybackType.disabled) {
      setState(() {
        ref.playbackType = MelodyReference_PlaybackType.playback_indefinitely;
      });
    } else {
      setState(() {
        ref.playbackType = MelodyReference_PlaybackType.disabled;
        if (selectedMelody != null &&
            ref != null &&
            ref.melodyId == selectedMelody.id) {
          recordingMelody = false;
        }
      });
    }
    BeatScratchPlugin.updateSections(score);
  }

  _setReferenceVolume(MelodyReference ref, double volume) {
    setState(() {
      ref.volume = volume;
    });
    BeatScratchPlugin.updateSections(score);
  }

  _setPartVolume(Part part, double volume) {
    setState(() {
      part.instrument.volume = volume;
    });
    BeatScratchPlugin.updatePartConfiguration(part);
  }

  _setSectionName(Section section, String name) {
    setState(() {
      section.name = name;
    });
  }

  _setMelodyName(Melody melody, String name) {
    setState(() {
      melody.name = name;
    });
  }

  _viewMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.score);
    setState(() {
      // showSections = false;
      showDuplicateScoreWarning = false;
      universeViewUI.visible = false;
      interactionMode = InteractionMode.view;
      if (scorePickerMode == ScorePickerMode.universe ||
          scorePickerMode == ScorePickerMode.none) {
        _closeScorePicker();
      }
      recordingMelody = false;
      musicViewMode = MusicViewMode.score;
      selectedMelody = null;
      _showMusicView();
    });
  }

  _universeMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.score);
    setState(() {
      if (interactionMode != InteractionMode.universe) {
        // showSections = false;
        showDuplicateScoreWarning = false;
        if (BeatScratchPlugin.supportsStorage) {
          saveCurrentScore(delay: slowAnimationDuration * 2);
        }
        interactionMode = InteractionMode.universe;
        universeViewUI.visible = true;
        recordingMelody = false;
        musicViewMode = MusicViewMode.score;
        selectedMelody = null;
        _showMusicView();
        exportUI.visible = false;

        // Show score picker in universe mode, but only load data into
        // it after a delay
        scorePickerMode = ScorePickerMode.none;
        _showScorePicker = true;
        Future.delayed(slowAnimationDuration, () {
          setState(() {
            if (interactionMode.isUniverse) {
              scorePickerMode = ScorePickerMode.universe;
            }
          });
        });
      }
    });
  }

  Part _prevSelectedPart;
  Melody _prevSelectedMelody;

  _editMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.section);
    setState(() {
      // _universeManager.currentUniverseScore = "";
      universeViewUI.visible = false;
      if (interactionMode.isEdit) {
        if (selectedMelody != null) {
          _prevSelectedMelody = selectedMelody;
          _prevSelectedPart = null;
          _hideMusicView();
        } else if (selectedPart != null) {
          _prevSelectedMelody = null;
          _prevSelectedPart = selectedPart;
          _hideMusicView();
        } else if (musicViewMode == MusicViewMode.section) {
          _prevSelectedMelody = null;
          _prevSelectedPart = null;
          _hideMusicView();
        } else {
          if (_prevSelectedMelody != null) {
            _selectOrDeselectMelody(_prevSelectedMelody);
          } else if (_prevSelectedPart != null) {
            _selectOrDeselectPart(_prevSelectedPart);
          } else {
            _selectSection(currentSection);
          }
        }
      } else {
        if (_scoreManager.currentScoreName == ScoreManager.UNIVERSE_SCORE ||
            _scoreManager.currentScoreName == ScoreManager.WEB_SCORE ||
            _scoreManager.currentScoreName == ScoreManager.PASTED_SCORE) {
          setState(() {
            scorePickerMode = ScorePickerMode.none;
            _showScorePicker = false;
            if (!MyPlatform.isWeb) {
              showDuplicateScoreWarning = true;
            }
          });
        } else {
          _closeScorePicker();
        }
        if (exportUI.visible) {
          exportUI.visible = false;
        }
        if (!showSections) {
          Future.delayed(slowAnimationDuration, () {
            setState(() {
              if (interactionMode.isEdit && !showSections) {
                verticalSectionList = context.isTabletOrLandscapey;
                showSections = true;
              }
            });
          });
        }
        if (_prevSelectedMelody != null) {
          _selectOrDeselectMelody(_prevSelectedMelody);
        } else if (_prevSelectedPart != null) {
          _selectOrDeselectPart(_prevSelectedPart);
        } else {
          musicViewMode = MusicViewMode.section;
        }
        interactionMode = InteractionMode.edit;
        // showSections = true;
        _showMusicView();
      }
    });
  }

  _toggleViewOptions() {
    setState(() {
      showViewOptions = !showViewOptions;
    });
  }

  _toggleKeyboard() {
    setState(() {
      if (_showKeyboardConfiguration) {
        _showKeyboardConfiguration = false;
      } else {
        showKeyboard = !showKeyboard;
        if (!showKeyboard) {
          _showKeyboardConfiguration = false;
        }
      }
    });
  }

  _toggleColorboard() {
    setState(() {
      if (_showColorboardConfiguration) {
        _showColorboardConfiguration = false;
      } else {
        showColorboard = !showColorboard;
        if (!showColorboard) {
          _showColorboardConfiguration = false;
        }
      }
    });
  }

  _selectSection(Section section) {
    setState(() {
      if (currentSection == section &&
          interactionMode == InteractionMode.edit) {
        recordingMelody = false;
        if (musicViewMode != MusicViewMode.section) {
          musicViewMode = MusicViewMode.section;
          _prevSelectedMelody = null;
          _prevSelectedPart = null;
          _showMusicView();
        } else {
          if (!melodyViewVisible) {
            _showMusicView();
          } else {
            _hideMusicView();
          }
        }
      } else {
        currentSection = section;
      }
    });
  }

  bool _wasLandscapeUI = false;
  bool get _landscapePhoneUI => context.isLandscape && context.isPhone;
  bool _wasLandscapePhoneUI = false;

  bool get _scalableUI => context.isTabletOrLandscapey && !_landscapePhoneUI;

  bool get _portraitPhoneUI => !_landscapePhoneUI && !_scalableUI;

  BuildContext nativeDeviceOrientationReaderContext;

  NativeDeviceOrientation get _nativeOrientation {
    try {
      return NativeDeviceOrientationReader.orientation(
          nativeDeviceOrientationReaderContext);
    } catch (any) {
      return NativeDeviceOrientation.portraitUp;
    }
  }

  double get _leftNotchPadding =>
      _nativeOrientation == NativeDeviceOrientation.landscapeRight
          ? MediaQuery.of(context).padding.left * 5 / 8
          : MediaQuery.of(context).padding.left * 5 / 7;

  double get _rightNotchPadding =>
      _nativeOrientation == NativeDeviceOrientation.landscapeLeft
          ? MediaQuery.of(context).padding.right / 4
          : MediaQuery.of(context).padding.right * 5 / 8;

  double get _bottomNotchPadding =>
      _nativeOrientation == NativeDeviceOrientation.portraitUp
          ? MediaQuery.of(context).padding.bottom * 3 / 4
          : 0;

  double get _topNotchPaddingReal => MediaQuery.of(context).padding.top;

  double get _secondToolbarHeight => _portraitPhoneUI
      ? interactionMode.isEdit ||
              interactionMode.isView ||
              interactionMode.isUniverse ||
              showViewOptions
          ? 36
          : 0
      : 0;

  double get _landscapePhoneBeatscratchToolbarWidth =>
      _landscapePhoneUI ? 48 : 0;

  double get _landscapePhoneSecondToolbarWidth => _landscapePhoneUI ? 48 : 0;

  double get _midiSettingsHeight => showMidiConfiguration ? 175 : 0;

  Axis get _scorePickerScrollDirection =>
      context.isTabletOrLandscapey ? Axis.vertical : Axis.horizontal;
  double _scorePickerWidth(BuildContext context) => showScorePicker
      ? _scorePickerScrollDirection == Axis.horizontal
          ? MediaQuery.of(context).size.width
          : min(
              max(interactionMode.isUniverse ? 305 : 365,
                  MediaQuery.of(context).size.width / 4),
              450)
      : 0.0;
  double _scorePickerHeight(BuildContext context) => showScorePicker
      ? _scorePickerScrollDirection == Axis.horizontal
          ? _horizontalScorePickerHeight(context)
          : MediaQuery.of(context).size.height - universeViewUIHeight
      : 0.0;
  double _horizontalScorePickerHeight(BuildContext context) => showScorePicker
      ? interactionMode.isUniverse
          ? universeViewUI.signingIn
              ? 0
              : max(
                  152,
                  flexibleAreaHeight(context) *
                      (flexibleAreaHeight(context) < 600
                          ? flexibleAreaHeight(context) < 500
                              ? 0.4
                              : 0.45
                          : 0.5))
          : min(
              flexibleAreaHeight(context) * 0.66,
              210.0 +
                  (context.isLandscapePhone
                      ? (showKeyboard ^ showColorboard)
                          ? -30
                          : 40
                      : 65))
      : 0.0;

  bool _isLandscapePhone = false;

  double get _colorboardHeight => showColorboard
      ? _isLandscapePhone
          ? showKeyboard
              ? 115
              : 150
          : 150
      : 0;

  double get _keyboardHeight => showKeyboard
      ? _isLandscapePhone
          ? showColorboard
              ? 115
              : 150
          : 150
      : 0;

  bool _savingScore = false;

  set pasteFailed(bool value) {
    messagesUI.sendMessage(message: "Paste Failed!", isError: true);
  }

  double get _tapInBarHeight => showTapInBar && !_bottomTapInBar
      ? (_isLandscapePhone)
          ? 0
          : 44
      : 0;

  double get _bottomTapInBarHeight => showTapInBar && _bottomTapInBar ? 44 : 0;

  double get _landscapeTapInBarWidth => showTapInBar && !_bottomTapInBar
      ? (_isLandscapePhone)
          ? 44
          : 0
      : 0;
  bool _forceShowTapInBar = false;

  bool get showTapInBar =>
      _showTapInBar || _forceShowTapInBar || recordingMelody;

  bool showSections = false;
  bool _useVerticalSectionList = false;
  bool get forceHorizontalSectionList =>
      showScorePicker && _scorePickerScrollDirection == Axis.vertical;
  bool get verticalSectionList =>
      _useVerticalSectionList && !forceHorizontalSectionList;
  set verticalSectionList(bool value) => _useVerticalSectionList = value;

  double get verticalSectionListWidth =>
      showSections && verticalSectionList ? 165 : 0;

  double get horizontalSectionListHeight =>
      showSections && !verticalSectionList ? 36 : 0;

  ExportUI exportUI;
  MessagesUI messagesUI;
  UniverseViewUI universeViewUI;
  double get universeViewUIHeight => universeViewUI.height(context,
      keyboardHeight: _keyboardHeight, settingsHeight: _midiSettingsHeight);
  BSMethod scrollToCurrentBeat;
  BSMethod refreshUniverseData;
  BSMethod bluetoothScan;
  BSMethod duplicateCurrentScore;

  @override
  void initState() {
    super.initState();
    scrollToCurrentBeat = BSMethod();
    refreshUniverseData = BSMethod();
    bluetoothScan = BSMethod();
    duplicateCurrentScore = BSMethod();
    messagesUI = MessagesUI(setState);
    universeViewUI = UniverseViewUI(setState, _universeManager)
      ..messagesUI = messagesUI
      ..refreshUniverseData = refreshUniverseData
      ..refreshUniverseData = refreshUniverseData;
    _universeManager
      ..refreshUniverseData = refreshUniverseData
      ..messagesUI = messagesUI
      ..scoreManager = _scoreManager;
    BeatScratchPlugin.messagesUI = messagesUI;
    exportUI = ExportUI()..messagesUI = messagesUI;
    BeatScratchPlugin.setupWebStuff();
    showBeatCounts = false;
    score = widget.initialScore;
    _currentSection = widget.initialScore.sections[0];
    _scoreManager.doOpenScore = doOpenScore;
    if (widget.pastebinCode != null) {
      _scoreManager.loadPastebinScoreIntoUI(widget.pastebinCode, onFail: () {
        messagesUI.sendMessage(message: "Failed to load URL!", isError: true);
      });
    } else if (MyPlatform.isWeb) {
      BeatScratchPlugin.createScore(score);
    }
    if (MyPlatform.isMobile) {
      KeyboardVisibility.onChange.listen((bool visible) {
        setState(() {
          _softKeyboardVisible = visible;
        });
      });
    }
//    BeatScratchPlugin.createScore(_score);
    BeatScratchPlugin.onSectionSelected = (sectionId) {
      setState(() {
        currentSection =
            score.sections.firstWhere((section) => section.id == sectionId);
      });
    };
    BeatScratchPlugin.onSynthesizerStatusChange = () {
      setState(() {});
    };
    BeatScratchPlugin.onOpenUrlFromSystem = onOpenUrlFromSystem;
    BeatScratchPlugin.onCountInInitiated = () {
      setState(() {
        _tapInBeat = -2;
        _forceShowTapInBar = true;
      });
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          _tapInBeat = null;
          _forceShowTapInBar = false;
        });
      });
    };
    BeatScratchPlugin.onRecordingMelodyUpdated = (melody) {
      setState(() {
//        final midiData = melody.midiData;
        final part = score.parts
            .firstWhere((p) => p.melodies.any((m) => m.id == melody.id));
        final index = part.melodies.indexWhere((m) => m.id == melody.id);
//        print("Replacing ${part.melodies[index]} with $melody");
        part.melodies[index].midiData = melody.midiData;
//        clearMutableCaches();
        clearMutableCachesForMelody(
          melody.id,
//          beat: BeatScratchPlugin.currentBeat.value,
//          sectionId: currentSection.id,
//          sectionLengthBeats: currentSection.beatCount,
//          melodyLengthBeats: melody.realBeatCount
        );
//        _score.parts.expand((s) => s.melodies).firstWhere((m) => m.id == melody.id).midiData = melody.midiData;
      });
    };
    RecordedSegmentQueue.getRecordingMelody = () =>
        musicViewMode == MusicViewMode.melody && recordingMelody
            ? selectedMelody
            : null;
    RecordedSegmentQueue.updateRecordingMelody =
        BeatScratchPlugin.onRecordingMelodyUpdated;
    keyboardPart = score.parts.firstWhere((part) => true, orElse: () => null);
    colorboardPart = score.parts.firstWhere(
        (part) => part.instrument.type == InstrumentType.harmonic,
        orElse: () => null);

    colorboardNotesNotifier = ValueNotifier(Set());
    keyboardNotesNotifier = ValueNotifier(Set());
    bluetoothControllerPressedNotes = ValueNotifier(Map());
    keyboardNotesNotifier.addListener(() {
      final notes = keyboardNotesNotifier.value;
      if (notes.isEmpty) {
        keyboardChordBase = null;
      }
      if (keyboardChordBase == null && notes.length == 1) {
        keyboardChordBase = notes.first;
      }
      keyboardChordNotes.addAll(notes.map((n) => n.mod12));
    });

    duplicateCurrentScore.addListener(() {
      _doShowScorePicker(ScorePickerMode.duplicate);
      _viewMode();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppSettings.initializingState = false;
      Future.delayed(
          Duration(seconds: 10), () => MelodyMenuBrowser.loadScoreData());
    });
  }

  doOpenScore(Score scoreToOpen) {
    scoreToOpen.migrate();
    MelodyMenuBrowser.loadScoreData();
    if (_scoreManager.currentScoreName != ScoreManager.UNIVERSE_SCORE &&
        interactionMode.isUniverse) {
      _viewMode();
    }
    setState(() {
      BeatScratchPlugin.createScore(scoreToOpen);
      score = scoreToOpen;
      clearMutableCaches();
      currentSection = scoreToOpen.sections.first;
      if (scorePickerMode == ScorePickerMode.create &&
          scoreToOpen.parts.length == 2 &&
          scoreToOpen.parts[0].instrument.midiInstrument == 0 &&
          scoreToOpen.parts[1].isDrum &&
          scoreToOpen.parts.fold(true,
              (bool hasNoMelodies, p) => hasNoMelodies && p.melodies.isEmpty)) {
        interactionMode = InteractionMode.edit;
        Future.delayed(slowAnimationDuration, () {
          _selectOrDeselectPart(scoreToOpen.parts[0]);
        });
      }
      if (interactionMode.isEdit) {
        musicViewMode = MusicViewMode.section;
      }
      selectedMelody = null;
      selectedPart = null;
      _prevSelectedMelody = null;
      _prevSelectedPart = null;
      keyboardPart = scoreToOpen.parts.first;
      colorboardPart = scoreToOpen.parts.firstWhere(
          (Part p) => p.instrument.type != InstrumentType.drum,
          orElse: null);
      exportUI.export.score = scoreToOpen;
    });
  }

  @override
  void dispose() {
    colorboardNotesNotifier.dispose();
    keyboardNotesNotifier.dispose();
    scrollToCurrentBeat.dispose();
    universeViewUI.dispose();
    super.dispose();
  }

  onOpenUrlFromSystem(String scoreUrl) {
    print("Opening URL: $scoreUrl");
    closeWebView();

    if (_universeManager.tryAuthentication(scoreUrl)) {
      return;
    }

    saveCurrentScore();
    bool failed = false;
    Future.delayed(slowAnimationDuration, () {
      _scoreManager.loadFromScoreUrl(scoreUrl,
          newScoreDefaultFilename: ScoreManager.WEB_SCORE,
          newScoreNameSuffix: ScoreManager.FROM_WEB,
          currentScoreToSave: score, onSuccess: (_) {
        setState(() {
          scorePickerMode = ScorePickerMode.duplicate;
          showScorePicker = true;
          _viewMode();
        });
      }, onFail: () {
        failed = true;
        setState(() {
          messagesUI.sendMessage(
              message: "Failed to open Score Link!", isError: true);
        });
      });

      Future.delayed(slowAnimationDuration, () {
        if (!failed) {
          messagesUI.sendMessage(
            message: "Opened linked score!",
          );
        }
      });
    });
  }

  // ignore: missing_return
  Future<bool> _onWillPop() async {
    if (!_goBack()) {
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to exit BeatScratch?'),
              actions: <Widget>[
                MyFlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: new Text('No'),
                ),
                MyFlatButton(
                  color: sectionColor,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: new Text('Yes, exit'),
                ),
              ],
            ),
          )) ??
          false;
    }
  }

  bool _goBack() {
    if (interactionMode.isEdit && _musicViewSizeFactor > 0) {
      setState(() {
        _hideMusicView();
      });
      return true;
    } else if (showMidiConfiguration ||
        _showKeyboardConfiguration ||
        _showColorboardConfiguration) {
      setState(() {
        if (showMidiConfiguration) {
          showKeyboard &= _wasKeyboardShowingWhenMidiConfigurationOpened;
          showColorboard &= _wasColorboardShowingWhenMidiConfigurationOpened;
        }
        showMidiConfiguration = false;
        _showKeyboardConfiguration = false;
        _showColorboardConfiguration = false;
      });
      return true;
    } else if (showKeyboard || showColorboard) {
      setState(() {
        showKeyboard = false;
        showColorboard = false;
      });
      return true;
    } else if (interactionMode.isEdit) {
      _viewMode();
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (splitMode == null) {
      splitMode = (context.isTablet) ? SplitMode.half : SplitMode.full;
      verticalSectionList = context.isTablet || context.isLandscapePhone;
    }
    if (hasPrioritizedMIDIController && !hadPriotizedMIDIController) {
      showKeyboard = false;
    }
    hadPriotizedMIDIController = hasPrioritizedMIDIController;
    _isLandscapePhone = context.isLandscapePhone;
    // if (editingMelody && _isPhone) {
    //   verticalSectionList = context.isLandscape;
    // }
    if (context.isLandscape) {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    if (BeatScratchPlugin.playing) {
      _tapInBeat = null;
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
    if (!_landscapePhoneUI) {
      _bottomTapInBar = true;
    } else if (!_wasLandscapePhoneUI) {
      _bottomTapInBar = false;
    }
    _wasLandscapePhoneUI = _landscapePhoneUI;
    // if (showSections) {
    if (context.isLandscape && !_wasLandscapeUI) {
      verticalSectionList = true;
    } else if (!context.isLandscape && _wasLandscapeUI) {
      verticalSectionList = false;
    }
    // }
    _wasLandscapeUI = context.isLandscape;
//    var top = MediaQuery.of(context).size.height - _colorboardHeight - _keyboardHeight;
//    var bottom = MediaQuery.of(context).size.height;
//    var right = MediaQuery.of(context).size.width;
//    var left = 0.0;
//    SystemChannels.platform.invokeMethod("SystemGestures.setSystemGestureExclusionRects", <Map<String, int>>[
//      {"left": left.toInt(), "top": top.toInt(), "right": 10, "bottom": bottom.toInt()},
//      {"left": (right - 10).toInt(), "top": top.toInt(), "right": right.toInt(), "bottom": bottom.toInt()},
//    ]);
    // Map<LogicalKeySet, Intent> shortcuts = {LogicalKeySet(LogicalKeyboardKey.escape): Intent.doNothing};

    theUI(BuildContext context) => Stack(children: [
          Row(
            children: [
              if (_landscapePhoneUI)
                AnimatedContainer(
                    duration: animationDuration, width: _leftNotchPadding),
              Expanded(
                // fit: FlexFit.loose,
                child: Stack(children: [
                  Column(children: [
                    if (context.isPortraitPhone)
                      universeViewUI.build(
                          context: context,
                          sectionColor: sectionColor,
                          keyboardHeight: _keyboardHeight,
                          settingsHeight: _midiSettingsHeight,
                          showDownloads: ((MyPlatform.isWeb) &&
                                  !showDownloadLinks)
                              ? () => setState(() => showDownloadLinks = true)
                              : null),
                    _duplicateScoreWarning(),
                    Expanded(
                        child: Row(
                      children: [
                        if (_scorePickerScrollDirection == Axis.vertical)
                          Column(
                            children: [
                              if (!context.isPortraitPhone)
                                AnimatedContainer(
                                    duration: animationDuration,
                                    height: universeViewUIHeight,
                                    width: _scorePickerWidth(context),
                                    key: ValueKey(
                                        "UniverseViewUI-landscapephone-${context.isLandscapePhone}"),
                                    child: universeViewUI.build(
                                        context: context,
                                        sectionColor: sectionColor,
                                        keyboardHeight: _keyboardHeight,
                                        settingsHeight: _midiSettingsHeight,
                                        showDownloads: ((MyPlatform.isWeb) &&
                                                !showDownloadLinks)
                                            ? () => setState(
                                                () => showDownloadLinks = true)
                                            : null)),
                              Expanded(child: _scorePicker(context)),
                              // AnimatedContainer(
                              //     duration: animationDuration,
                              //     height: (_landscapePhoneUI ? 0 : 48) +
                              //         _secondToolbarHeight +
                              //         _midiSettingsHeight +
                              //         messagesUI.height(context) +
                              //         _colorboardHeight +
                              //         _keyboardHeight +
                              //         _bottomNotchPadding +
                              //         _tapInBarHeight +
                              //         _bottomTapInBarHeight)
                            ],
                          ),
                        Expanded(
                            child: Column(children: [
                          _downloadBanner(context),
                          if (_scorePickerScrollDirection == Axis.horizontal)
                            _scorePicker(context),
                          exportUI.build(
                              context: context,
                              setState: setState,
                              currentSection: currentSection),
                          _universeScoreTitle(),
                          _horizontalSectionList(),
                          Expanded(
                              child: Row(children: [
                            _verticalSectionList(),
                            Expanded(child: _layersAndMusicView(context))
                          ])),
                        ])),
                      ],
                    )),
                    AnimatedContainer(
                        duration: animationDuration,
                        height: (_landscapePhoneUI ? 0 : 48) +
                            _secondToolbarHeight +
                            _midiSettingsHeight +
                            messagesUI.height(context) +
                            _colorboardHeight +
                            _keyboardHeight +
                            _bottomNotchPadding +
                            _tapInBarHeight +
                            _bottomTapInBarHeight)
                  ]),
                  Column(children: [
                    Expanded(child: SizedBox()),
                    Opacity(
                        opacity: 0.8,
                        child: messagesUI.build(context: context)),
                    if (_portraitPhoneUI) _toolbarsInColumn(context),
                    if (_scalableUI) _toolbarsInRow(context),
                    // if (_portraitPhoneUI || _landscapePhoneUI) _scorePicker(context),
                    // if (_portraitPhoneUI) _tempoConfigurationBar(context),
                    _settingsPanel(context),
                    // _pasteFailedBar(context),
                    _colorboard(context),
                    if (!_landscapePhoneUI) _tapInBar(context),
                    _keyboard(context),
                    _tapInBar(context, bottom: true),
                    Container(height: _bottomNotchPadding),
                  ])
                ]),
              ),
              AnimatedContainer(
                  duration: animationDuration,
                  width: _landscapePhoneSecondToolbarWidth,
                  child: createSecondToolbar(vertical: true)),
              if (_landscapePhoneUI) _tapInBar(context, vertical: true),
              if (_landscapePhoneUI) createBeatScratchToolbar(vertical: true),
              Container(width: _rightNotchPadding),
            ],
          ),
          Column(children: [
            Expanded(child: SizedBox()),
            // Listener overlay to block accidental input to keyboard/tempo bar
            // if software keyboard is open in landscape/fullscreen (Android)
            if (_softKeyboardVisible)
              Container(
                  color: Colors.black54,
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  child: Listener(
                    onPointerDown: (event) {
                      print("got input");
                    },
                    onPointerMove: (event) {
                      print("got input");
                    },
                    onPointerUp: (event) {
                      print("got input");
                    },
                    onPointerCancel: (event) {
                      print("got input");
                    },
                  ))
          ])
          //]),
        ]);
    Widget theUIWithOrientation(BuildContext context) {
      if (MyPlatform.isAndroid || MyPlatform.isIOS) {
        return NativeDeviceOrientationReader(
          builder: (context) {
            nativeDeviceOrientationReaderContext = context;
            return theUI(context);
          },
        );
      } else {
        return theUI(context);
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
        ),
        child: WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: subBackgroundColor,
                appBar: PreferredSize(
                    preferredSize:
                        Size.fromHeight(0.0), // here the desired height
                    child: AppBar(
                        // Here we take the value from the MyHomePage object that was created by
                        // the App.build method, and use it to set our appbar title.
                        //title: Row(Text(widget.title)])
                        )),
                body: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(new FocusNode());
                  },
                  child: theUIWithOrientation(context),
                ))));
  }

  double get universeScoreTitleHeight => interactionMode.isUniverse ? 40 : 0;

  AnimatedContainer _universeScoreTitle() {
    Color foregroundColor, backgroundColor;
    bool showShareButton;
    if (_universeManager.currentUniverseScore == "") {
      foregroundColor = Colors.white;
      backgroundColor = Colors.grey;
      showShareButton = true;
    } else {
      foregroundColor = musicForegroundColor;
      backgroundColor = musicBackgroundColor;
      showShareButton = false;
    }
    final scoreFuture = _universeManager.currentUniverseScoreFuture;
    return AnimatedContainer(
        duration: animationDuration,
        height: universeScoreTitleHeight,
        color: backgroundColor,
        child: Row(
          children: [
            AnimatedContainer(
                width: showShareButton ? 0 : universeScoreTitleHeight,
                duration: animationDuration,
                child: MyFlatButton(
                  padding: EdgeInsets.zero,
                  onPressed: _universeManager.redditUsername.isNotEmpty
                      ? () {
                          bool oldValue = _universeManager
                              .currentUniverseScoreFuture?.likes;
                          setState(() {
                            if (oldValue == true) {
                              scoreFuture?.likes = null;
                              scoreFuture?.voteCount -= 1;
                            } else {
                              scoreFuture?.likes = true;
                              scoreFuture?.voteCount +=
                                  oldValue == null ? 1 : 2;
                            }
                            _universeManager.vote(
                                scoreFuture?.fullName, scoreFuture?.likes);
                          });
                        }
                      : null,
                  color: scoreFuture?.likes == true
                      ? chromaticSteps[11]
                      : Colors.transparent,
                  child: Align(
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                          opacity: showShareButton ? 0 : 1,
                          duration: animationDuration,
                          child: Icon(Icons.arrow_upward,
                              color: _universeManager.isAuthenticated
                                  ? scoreFuture?.likes == true
                                      ? chromaticSteps[11].textColor()
                                      : chromaticSteps[11]
                                  : musicForegroundColor.withOpacity(0.5)))),
                )),
            AnimatedContainer(
                width: showShareButton ? 0 : universeScoreTitleHeight * 1,
                duration: animationDuration,
                child: Align(
                    alignment: Alignment.center,
                    child: Text(scoreFuture?.voteCount?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: musicForegroundColor,
                            fontWeight: FontWeight.w800)))),
            AnimatedContainer(
                width: showShareButton ? 0 : universeScoreTitleHeight,
                duration: animationDuration,
                child: MyFlatButton(
                  padding: EdgeInsets.zero,
                  onPressed: _universeManager.redditUsername.isNotEmpty
                      ? () {
                          bool oldValue = _universeManager
                              .currentUniverseScoreFuture?.likes;
                          setState(() {
                            if (oldValue == false) {
                              scoreFuture?.likes = null;
                              scoreFuture.voteCount += 1;
                            } else {
                              scoreFuture?.likes = false;
                              scoreFuture.voteCount -= oldValue == null ? 1 : 2;
                            }
                            _universeManager.vote(
                                scoreFuture?.fullName, scoreFuture?.likes);
                          });
                        }
                      : null,
                  color: scoreFuture?.likes == false
                      ? chromaticSteps[10]
                      : Colors.transparent,
                  child: Align(
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                          opacity: showShareButton ? 0 : 1,
                          duration: animationDuration,
                          child: Icon(Icons.arrow_downward,
                              color: _universeManager.isAuthenticated
                                  ? scoreFuture?.likes == false
                                      ? chromaticSteps[10].textColor()
                                      : chromaticSteps[10]
                                  : musicForegroundColor.withOpacity(0.5)))),
                )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(score.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w100)),
              ),
            ),
            AnimatedContainer(
                width: showShareButton ? universeScoreTitleHeight : 0,
                duration: animationDuration,
                child: MyFlatButton(
                    padding: EdgeInsets.zero,
                    onPressed:
                        _universeManager.isAuthenticated && !MyPlatform.isWeb
                            ? () {
                                showUniverseUpload(context, score, sectionColor,
                                    _universeManager, duplicateCurrentScore);
                              }
                            : null,
                    child: Align(
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                          opacity: showShareButton ? 1 : 0,
                          duration: animationDuration,
                          child: Icon(Icons.upload,
                              color: _universeManager.isAuthenticated &&
                                      !MyPlatform.isWeb
                                  ? chromaticSteps[0]
                                  : Colors.white.withOpacity(0.5))),
                    ))),
            AnimatedContainer(
                width: showShareButton ? 0 : universeScoreTitleHeight,
                duration: animationDuration,
                child: MyFlatButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (_appSettings.enableApollo) {
                      launchURL(
                          scoreFuture.commentUrl
                              .replaceAll("https://", "apollo://"),
                          forceSafariVC: false);
                    } else {
                      launchURL(scoreFuture.commentUrl, forceSafariVC: false);
                    }
                  },
                  child: Align(
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                          opacity: showShareButton ? 0 : 1,
                          duration: animationDuration,
                          child: Icon(FontAwesomeIcons.commentDots,
                              color: chromaticSteps[0]))),
                ))
          ],
        ));
  }

  bool showDuplicateScoreWarning = false;
  double get duplicateScoreWarningHeight => showDuplicateScoreWarning ? 44 : 0;
  Widget _duplicateScoreWarning() {
    Color foregroundColor = Colors.white, backgroundColor = chromaticSteps[7];
    double sensitivity = 7;

    return GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > sensitivity) {
            // Down swipe
          } else if (details.delta.dy < -sensitivity) {
            // Up swipe
            if (showDuplicateScoreWarning) {
              HapticFeedback.lightImpact();
              setState(() {
                showDuplicateScoreWarning = false;
              });
            }
          }
        },
        child: AnimatedOpacity(
            duration: animationDuration,
            opacity: showDuplicateScoreWarning ? 1 : 0,
            child: AnimatedContainer(
                duration: animationDuration,
                height: duplicateScoreWarningHeight,
                color: backgroundColor,
                child: Row(
                  children: [
                    SizedBox(width: 4),
                    Icon(Icons.warning, color: chromaticSteps[5]),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: RichText(
                          text: ScorePickerState.duplicateWarningText(
                              TextStyle(
                                  color: foregroundColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100),
                              score,
                              _scoreManager),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                        height: 36,
                        child: MyFlatButton(
                            color: subBackgroundColor,
                            padding: EdgeInsets.symmetric(
                                vertical: 3, horizontal: 3),
                            onPressed: () {
                              setState(() {
                                scorePickerMode = ScorePickerMode.duplicate;
                                _showScorePicker = true;
                                showDuplicateScoreWarning = false;
                                splitMode = SplitMode.full;
                                if (context.isLandscapePhone) {
                                  showKeyboard = false;
                                }
                              });
                            },
                            child: Row(children: [
                              // SizedBox(width: 5),
                              Transform.translate(
                                  offset: Offset(0, 0),
                                  child: Icon(FontAwesomeIcons.codeBranch,
                                      color: Colors.white)),
                              Text("Duplicate",
                                  style: TextStyle(color: Colors.white))
                            ]))),
                    SizedBox(width: 2),
                    Container(
                        height: 36,
                        width: context.isTablet ? null : 36,
                        child: MyFlatButton(
                          color: chromaticSteps[5],
                          padding: context.isTablet
                              ? EdgeInsets.only(left: 2, right: 4)
                              : EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              showDuplicateScoreWarning = false;
                            });
                          },
                          child: context.isTablet
                              ? Row(children: [
                                  // SizedBox(width: 5),
                                  Transform.translate(
                                      offset: Offset(0, 0),
                                      child: Icon(Icons.close,
                                          color: Colors.black)),

                                  Text("Okay",
                                      style: TextStyle(color: Colors.black))
                                ])
                              : Transform.translate(
                                  offset: Offset(0, 0),
                                  child:
                                      Icon(Icons.close, color: Colors.black)),
                          // SizedBox(width: 5),
                        )),
                    SizedBox(width: 4),
                  ],
                ))));
  }

  AnimatedContainer _verticalSectionList() {
    return AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        width: verticalSectionListWidth,
        child: createSectionList(scrollDirection: Axis.vertical));
  }

  AnimatedContainer _horizontalSectionList() {
    return AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        height: horizontalSectionListHeight,
        child: createSectionList(scrollDirection: Axis.horizontal));
  }

  static const EdgeInsets _bannerPadding =
      EdgeInsets.symmetric(vertical: 20, horizontal: 15);

  Widget _downloadBanner(BuildContext context) {
    return AnimatedOpacity(
        duration: animationDuration,
        opacity: downloadLinksHeight == 0 ? 0 : 1,
        child: AnimatedContainer(
            duration: animationDuration,
            height: downloadLinksHeight,
            color: subBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  flex: 0,
                  child: SizedBox(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        MyFlatButton(
                            onPressed: () {
                              launchURL(
                                  "https://apps.apple.com/us/app/beatscratch/id1509788448");
                            },
                            padding: EdgeInsets.all(0),
                            child: Image.asset("assets/app_store.png",
                                width: 120, height: 40, fit: BoxFit.fitHeight)),
                        SizedBox(width: 3),
                        MyFlatButton(
                            onPressed: () {
                              launchURL(
                                  "https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux");
                            },
                            padding: EdgeInsets.all(0),
                            child: Image.asset(
                                "assets/play_en_badge_web_generic.png",
                                width: 140,
                                height: 60,
                                fit: BoxFit.fitHeight)),
                        SizedBox(width: 5),
                        Container(
                            width: 120,
                            height: 40,
                            padding: EdgeInsets.only(right: 5),
                            child: MyFlatButton(
                                color: Colors.white,
                                onPressed: () {
                                  launchURL(
                                      "https://www.dropbox.com/s/71jclv5a5tgd1c7/BeatFlutter.tar.bz2?dl=1");
                                },
                                padding: EdgeInsets.all(0),
                                child: Stack(children: [
                                  Align(
                                      alignment: Alignment.bottomRight,
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              right: 5, bottom: 2),
                                          child: Text("macOS",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.w400)))),
                                  Align(
                                      alignment: Alignment.topLeft,
                                      child: Padding(
                                          padding:
                                              EdgeInsets.only(top: 2, left: 5),
                                          child: Text("Download For",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w400))))
                                ]))),
                        Padding(
                            padding: EdgeInsets.only(right: 5, left: 3),
                            child: MyRaisedButton(
                                padding: _bannerPadding,
                                onPressed: () {
                                  launchURL(
                                      "https://beatscratch.io/platforms.html");
                                },
                                child: Text("Platform Feature Comparison"))),
                      ])),
                ),
                Expanded(
                  flex: 0,
                  child: SizedBox(),
                ),
                Container(
                    width: 48,
                    child: MyFlatButton(
                      padding: EdgeInsets.zero,
                      child: Icon(Icons.close, color: Colors.white),
                      onPressed: () =>
                          setState(() => showDownloadLinks = false),
                    ))
              ],
            )));
  }

  Widget _tapInBar(
    BuildContext context, {
    bool vertical = false,
    bool bottom = false,
  }) {
    bool playing = BeatScratchPlugin.playing;
    int tapInBeat = _tapInBeat;
    bool isDisplayed = (!vertical && !bottom && _tapInBarHeight != 0) ||
        (vertical && _landscapeTapInBarWidth != 0) ||
        (bottom && _bottomTapInBarHeight != 0);
    final double tapInFirstSize =
        !playing && (vertical || tapInBeat == null) ? 42 : 0;
    final double tapInSecondSize =
        !BeatScratchPlugin.playing && (_tapInBeat == null || _tapInBeat <= -2)
            ? 42
            : 0;
    final audioButtonColor =
        BeatScratchPlugin.metronomeEnabled ? sectionColor : Colors.grey;
    Widget tapInBarInstructions({bool withText = true, bool withIcon = true}) =>
        Stack(children: [
          AnimatedOpacity(
              duration: animationDuration,
              opacity: isDisplayed && !BeatScratchPlugin.playing ? 1 : 0,
              child: Row(children: [
                if (withIcon)
                  Icon(
                      recordingMelody
                          ? Icons.fiber_manual_record
                          : Icons.play_arrow,
                      color: Colors.grey),
                SizedBox(width: 5),
                if (withText)
                  Expanded(
                    child: Text(
                        BeatScratchPlugin.supportsPlayback
                            ? "Tap in ${(!MyPlatform.isWeb && BeatScratchPlugin.connectedControllers.isNotEmpty) ? "here or with damper/pitch wheel" : "here"} to ${recordingMelody ? "record" : "play"}"
                            : "Playback not supported",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: BeatScratchPlugin.supportsPlayback
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.w100)),
                  )
              ])),
          AnimatedOpacity(
              duration: animationDuration,
              opacity: isDisplayed && BeatScratchPlugin.playing ? 1 : 0,
              child: Row(children: [
                Icon(
                    recordingMelody
                        ? Icons.fiber_manual_record
                        : Icons.play_arrow,
                    color: recordingMelody
                        ? chromaticSteps[7]
                        : chromaticSteps[0]),
                SizedBox(width: 5),
                if (withText)
                  Text(
                      recordingMelody && BeatScratchPlugin.supportsRecording
                          ? "Recording"
                          : !recordingMelody &&
                                  BeatScratchPlugin.supportsPlayback
                              ? "Playing"
                              : "${recordingMelody ? "Recording" : "Playback"} doesn't actually work yet...",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w100))
              ]))
        ]);
    Widget tapInBarTapArea() {
      onFirstTap() {
        BeatScratchPlugin.countIn(-2);
        setState(() {
          _tapInBeat = -2;
          HapticFeedback.lightImpact();
        });
        Future.delayed(Duration(seconds: 3), () {
          setState(() {
            _tapInBeat = null;
          });
        });
      }

      onSecondTap() {
        BeatScratchPlugin.countIn(-1);
        HapticFeedback.lightImpact();
        setState(() {
          _tapInBeat = null;
        });
      }

      bool hasStartedTapIn() => _tapInBeat == -2;

      final contents = [
        AnimatedOpacity(
          duration: animationDuration,
          opacity: tapInFirstSize != 0 && showTapInBar && isDisplayed ? 1 : 0,
          child: AnimatedContainer(
              duration: animationDuration,
              padding:
                  vertical ? EdgeInsets.only(top: 3) : EdgeInsets.only(left: 5),
              height: vertical ? tapInFirstSize : null,
              width: vertical ? null : tapInFirstSize,
              child: MyRaisedButton(
                color: buttonBackgroundColor,
                child: Text(
                    !playing && tapInBeat == null
                        ? (currentSection.meter.defaultBeatsPerMeasure - 1)
                            .toString()
                        : "",
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed:
                    tapInBeat == null && BeatScratchPlugin.supportsPlayback
                        ? () {}
                        : null,
                padding: EdgeInsets.zero,
              )),
        ),
        AnimatedOpacity(
          duration: animationDuration,
          opacity: tapInSecondSize != 0 && showTapInBar ? 1 : 0,
          child: AnimatedContainer(
              duration: Duration(milliseconds: 35),
              padding:
                  vertical ? EdgeInsets.only(top: 5) : EdgeInsets.only(left: 5),
              height: vertical ? tapInSecondSize : null,
              width: vertical ? null : tapInSecondSize,
              child: MyRaisedButton(
                color: buttonBackgroundColor,
                child: Text(
                    currentSection.meter.defaultBeatsPerMeasure.toString(),
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: hasStartedTapIn() ? () {} : null,
                padding: EdgeInsets.zero,
              )),
        ),
        if (!vertical)
          Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: tapInBarInstructions(withText: !_portraitPhoneUI))),
        if (vertical)
          Container(
              height: 36,
              child: Stack(
                children: [
                  Center(
                      child: Transform.translate(
                          offset: Offset(7, -3),
                          child: tapInBarInstructions(withText: false))),
                  Center(
                      child: Transform.translate(
                          offset: Offset(0, 8),
                          child: Text("Tap",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100))))
                ],
              ))
      ];

      return Listener(
          onPointerDown: (event) {
            if (!playing && !hasStartedTapIn()) {
              // print("onFirstTap");
              onFirstTap();
            } else if (!playing) {
              // print("onSecondTap");
              onSecondTap();
            } else {
              // print("pausing");
              BeatScratchPlugin.pause();
            }
          },
          child: MyFlatButton(
              onPressed: () {},
              lightHighlight: true,
              padding: EdgeInsets.zero,
              child: IgnorePointer(
                  child: vertical
                      ? Column(children: contents)
                      : Row(children: contents))));
    }

    final contents = [
      if (!vertical) Expanded(flex: 2, child: tapInBarTapArea()),
      if (vertical) tapInBarTapArea(),
      // if (vertical) SizedBox(height: 15),
      if (vertical)
        Expanded(
            flex: 2,
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity: isDisplayed ? 1 : 0,
                child: _tempoConfigurationBar(context, vertical: true))),
      if (vertical) SizedBox(height: 3),
      if (!_portraitPhoneUI && !vertical)
        AnimatedOpacity(
            duration: animationDuration,
            opacity: isDisplayed ? 1 : 0,
            child: _tempoConfigurationBar(context)),
      if (_portraitPhoneUI && !vertical)
        Expanded(
          flex: 3,
          child: AnimatedOpacity(
              duration: animationDuration,
              opacity: isDisplayed ? 1 : 0,
              child: _tempoConfigurationBar(context)),
        ),
      Container(
          height: 42,
          width: 42,
          padding: EdgeInsets.only(right: vertical ? 0 : 5),
          child: AnimatedOpacity(
              duration: animationDuration,
              opacity: showTapInBar && isDisplayed ? 1 : 0,
              child: MyRaisedButton(
                padding: EdgeInsets.zero,
                color: audioButtonColor,
                child: Stack(
                  children: [
                    Transform.translate(
                        offset: Offset(-3.5, 3.5),
                        child: Transform.scale(
                          scale: 0.7,
                          child: ColorFilteredImageAsset(
                              imageSource: "assets/metronome.png",
                              imageColor: audioButtonColor.textColor()),
                        )),
                    Transform.translate(
                        offset: Offset(17, -4),
                        child: Transform.scale(
                            scale: 0.55,
                            child: Icon(
                                BeatScratchPlugin.metronomeEnabled
                                    ? Icons.volume_up
                                    : Icons.not_interested,
                                color: audioButtonColor.textColor()))),
                  ],
                ),
                onPressed: BeatScratchPlugin.supportsPlayback
                    ? () {
                        setState(() {
                          BeatScratchPlugin.metronomeEnabled =
                              !BeatScratchPlugin.metronomeEnabled;
                        });
                      }
                    : null,
              ))),
      if (vertical) SizedBox(height: 3),
    ];
    return AnimatedContainer(
        padding:
            vertical ? EdgeInsets.only(right: 2) : EdgeInsets.only(bottom: 1),
        duration: animationDuration,
        width: vertical ? _landscapeTapInBarWidth : null,
        height: vertical
            ? null
            : bottom
                ? _bottomTapInBarHeight
                : _tapInBarHeight,
        color: subBackgroundColor,
        child: vertical ? Column(children: contents) : Row(children: contents));
  }

  final double _tempoIncrementFactor = 1.01;
  Color get buttonBackgroundColor =>
      _appSettings.darkMode ? musicBackgroundColor : Colors.grey.shade500;
  Widget _tempoConfigurationBar(BuildContext context, {bool vertical = false}) {
    final minValue = min(0.1, BeatScratchPlugin.bpmMultiplier);
    final maxValue = max(2.0, BeatScratchPlugin.bpmMultiplier);
    final buttonWidth = 30.0;
    return RotatedBox(
        quarterTurns: vertical ? 3 : 0,
        child: AnimatedOpacity(
            duration: animationDuration,
            opacity: _showTapInBar ? 1 : 0,
            child: AnimatedContainer(
                duration: animationDuration,
                height: _portraitPhoneUI ? 34 : null,
                width: !_portraitPhoneUI ? (_showTapInBar ? 300 : 0) : null,
                padding: _scalableUI || _landscapePhoneUI
                    ? EdgeInsets.zero
                    : EdgeInsets.only(bottom: 2, top: 0),
                child: Row(children: [
                  if (!_scalableUI) SizedBox(width: 5),
                  Container(
                      width: buttonWidth,
                      child: MyRaisedButton(
                          color: buttonBackgroundColor,
                          padding: EdgeInsets.all(0),
                          child: RotatedBox(
                              quarterTurns: vertical ? 1 : 0,
                              child: Icon(Icons.keyboard_arrow_down_rounded)),
                          onPressed: BeatScratchPlugin.bpmMultiplier /
                                      _tempoIncrementFactor >=
                                  minValue
                              ? () {
                                  var newValue =
                                      BeatScratchPlugin.bpmMultiplier;
                                  newValue /= _tempoIncrementFactor;
                                  BeatScratchPlugin.bpmMultiplier =
                                      max(minValue, min(2.0, newValue));
                                  BeatScratchPlugin.onSynthesizerStatusChange();
                                }
                              : null)),
                  Expanded(
                      child: MySlider(
                          max: maxValue,
                          min: minValue,
                          value: max(minValue,
                              min(maxValue, BeatScratchPlugin.bpmMultiplier)),
                          activeColor: Colors.white,
                          onChanged: (value) {
                            BeatScratchPlugin.bpmMultiplier = value;
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          })),
                  Container(
                      width: buttonWidth,
                      child: MyRaisedButton(
                          color: buttonBackgroundColor,
                          padding: EdgeInsets.all(0),
                          child: RotatedBox(
                              quarterTurns: vertical ? 1 : 0,
                              child: Icon(Icons.keyboard_arrow_up_rounded)),
                          onPressed: BeatScratchPlugin.bpmMultiplier *
                                      _tempoIncrementFactor <=
                                  maxValue
                              ? () {
                                  var newValue =
                                      BeatScratchPlugin.bpmMultiplier;
                                  newValue *= _tempoIncrementFactor;
                                  BeatScratchPlugin.bpmMultiplier =
                                      max(minValue, min(maxValue, newValue));
                                  BeatScratchPlugin.onSynthesizerStatusChange();
                                }
                              : null)),
                  SizedBox(width: 5),
                  Container(
                      width: buttonWidth,
                      child: MyRaisedButton(
                          color: buttonBackgroundColor,
                          padding: EdgeInsets.all(0),
                          child: RotatedBox(
                              quarterTurns: vertical ? 1 : 0,
                              child: Text("x1",
                                  maxLines: 1, overflow: TextOverflow.fade)),
                          onPressed: () {
                            BeatScratchPlugin.bpmMultiplier = 1;
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          })),
                  SizedBox(width: 5)
                ]))));
  }

  Widget _toolbarsInRow(BuildContext context) {
    return Container(
        height: 48,
        child: Row(
          children: <Widget>[
            Expanded(
                flex: 2, child: createBeatScratchToolbar(leftHalfOnly: true)),
            Container(
                height: 36,
                child: AnimatedContainer(
                    duration: animationDuration,
                    width: MediaQuery.of(context).size.width / 2,
                    child: createSecondToolbar())),
            Expanded(
                flex: 3, child: createBeatScratchToolbar(rightHalfOnly: true)),
          ],
        ));
  }

  Widget _toolbarsInColumn(BuildContext context) {
    return Column(children: <Widget>[
      createBeatScratchToolbar(),
      AnimatedContainer(
          duration: animationDuration,
          height: _secondToolbarHeight,
          child: createSecondToolbar())
    ]);
  }

  BeatScratchToolbar createBeatScratchToolbar(
          {bool vertical = false,
          bool leftHalfOnly = false,
          bool rightHalfOnly = false}) =>
      BeatScratchToolbar(
          score: score,
          universeManager: _universeManager,
          savingScore: _savingScore,
          appSettings: _appSettings,
          messagesUI: messagesUI,
          currentSection: currentSection,
          currentPart: keyboardPart,
          scoreManager: _scoreManager,
          currentScoreName:
              MyPlatform.isWeb ? score.name : _scoreManager.currentScoreName,
          sectionColor: sectionColor,
          viewMode: _viewMode,
          universeMode: _universeMode,
          editMode: _editMode,
          toggleViewOptions: _toggleViewOptions,
          interactionMode: interactionMode,
          musicViewMode: musicViewMode,
          routeToCurrentScore: (String pastebinCode) {
            router.navigateTo(context, "/s/$pastebinCode");
          },
          vertical: vertical,
          showSections: showSections,
          verticalSections: verticalSectionList,
          refreshUniverseData: refreshUniverseData,
          togglePlaying: () {
            setState(() {
              if (!BeatScratchPlugin.playing) {
                BeatScratchPlugin.play();
              } else {
                BeatScratchPlugin.pause();
              }
            });
          },
          toggleSectionListDisplayMode: (forward) {
            setState(() {
              if (forceHorizontalSectionList) {
                if (forward) {
                  showSections = !showSections;
                } else {
                  HapticFeedback.heavyImpact();
                  Future.delayed(Duration(milliseconds: 50), () {
                    HapticFeedback.heavyImpact();
                  });
                }
              } else {
                if (forward) {
                  showSections = !showSections;
                  // if (!showSections) {
                  //   showSections = true;
                  //   verticalSectionList = true;
                  // } else if (!verticalSectionList) {
                  //   showSections = false;
                  //   verticalSectionList = true;
                  // } else {
                  //   verticalSectionList = false;
                  // }
                } else {
                  verticalSectionList = !verticalSectionList;
                  if (!showSections) {
                    showSections = true;
                  }
                  // if (!showSections) {
                  //   showSections = true;
                  //   verticalSectionList = false;
                  // } else if (verticalSectionList) {
                  //   showSections = false;
                  //   verticalSectionList = false;
                  // } else {
                  //   verticalSectionList = true;
                  // }
                }
              }
              // }
            });
          },
          renderingMode: renderingMode,
          setRenderingMode: (value) {
            setState(() {
              renderingMode = value;
            });
          },
          showScorePicker: _doShowScorePicker,
          showMidiInputSettings: () {
            setState(() {
              _wasKeyboardShowingWhenMidiConfigurationOpened = showKeyboard;
              _wasColorboardShowingWhenMidiConfigurationOpened = showColorboard;
              _wereViewOptionsShowingWhenMidiConfigurationOpened =
                  showViewOptions;
              showMidiConfiguration = true;
              showViewOptions = true;
              if (keyboardPart != null && showKeyboard) {
                _showKeyboardConfiguration = true;
              }
              if (_enableColorboard &&
                  colorboardPart != null &&
                  showColorboard) {
                _showColorboardConfiguration = true;
              }
            });
          },
          showBeatCounts: showBeatCounts,
          toggleShowBeatCounts: () {
            setState(() {
              showBeatCounts = !showBeatCounts;
            });
          },
          saveCurrentScore: saveCurrentScore,
          pasteScore: () async {
            ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data == null) {
              setState(() {
                pasteFailed = true;
              });
              return;
            }
            String scoreUrl = data.text;
            _scoreManager.loadFromScoreUrl(scoreUrl,
                currentScoreToSave: this.score, onFail: () {
              setState(() {
                pasteFailed = true;
              });
            }, onSuccess: (scoreName) {
              setState(() {
                scorePickerMode = ScorePickerMode.duplicate;
                showScorePicker = true;
                messagesUI.sendMessage(
                  message: "Pasted ${score.name}!",
                );
                _viewMode();
              });
            });
          },
          export: () {
            if (interactionMode.isView) {
              setState(() {
                exportUI.visible = true;
                showScorePicker = false;
              });
            } else {
              _viewMode();
              Future.delayed(slowAnimationDuration, () {
                setState(() {
                  exportUI.visible = true;
                  showScorePicker = false;
                });
              });
            }
          },
          openMelody: selectedMelody,
          openPart: selectedPart,
          prevMelody: _prevSelectedMelody,
          prevPart: _prevSelectedPart,
          isMelodyViewOpen: _musicViewSizeFactor != 0,
          leftHalfOnly: leftHalfOnly,
          rightHalfOnly: rightHalfOnly,
          showDownloads: showDownloadLinks,
          toggleShowDownloads: () => setState(() {
                showDownloadLinks = !showDownloadLinks;
              }),
          editObject: editObject);

  editObject(object) {
    setState(() {
      if (object is Melody) {
        if (!interactionMode.isEdit) {
          _editMode();
        }
        if (selectedMelody != object) {
          _selectOrDeselectMelody(object);
        }
      } else if (object is Part) {
        if (!interactionMode.isEdit) {
          _editMode();
        }
        if (selectedPart != object) {
          _selectOrDeselectPart(object);
        }
      } else if (object is Section) {
        if (selectedMelody != null) {
          _selectOrDeselectMelody(selectedMelody);
        }
        if (selectedPart != null) {
          _selectOrDeselectPart(selectedPart);
        }
        musicViewMode = MusicViewMode.section;
        if (!interactionMode.isEdit) {
          _editMode();
        }
        if (_musicViewSizeFactor == 0) {
          _showMusicView();
        }
      }
    });
  }

  _doShowScorePicker(mode) {
    setState(() {
      if ((interactionMode.isUniverse && mode != ScorePickerMode.universe) ||
          (interactionMode != InteractionMode.view &&
              mode != ScorePickerMode.show)) {
        scorePickerMode = ScorePickerMode.none;
        _viewMode();
        Future.delayed(slowAnimationDuration, () {
          setState(() {
            scorePickerMode = mode;
            showScorePicker = true;
          });
        });
      } else {
        scorePickerMode = mode;
        showScorePicker = true;
      }
    });
  }

  SecondToolbar createSecondToolbar({bool vertical = false}) => SecondToolbar(
      vertical: vertical,
      appSettings: _appSettings,
      setAppState: setState,
      recordingMelody: recordingMelody,
      enableColorboard: enableColorboard,
      toggleKeyboard: keyboardPart != null ? _toggleKeyboard : null,
      toggleKeyboardConfiguration: keyboardPart != null
          ? () {
              setState(() {
                showKeyboard = true;
                _showKeyboardConfiguration = !_showKeyboardConfiguration;
              });
            }
          : null,
      toggleColorboard: colorboardPart != null ? _toggleColorboard : null,
      toggleColorboardConfiguration: colorboardPart != null
          ? () {
              setState(() {
                showColorboard = true;
                _showColorboardConfiguration = !_showColorboardConfiguration;
              });
            }
          : null,
      showKeyboard: showKeyboard,
      showColorboard: showColorboard,
      interactionMode: interactionMode,
      showViewOptions: showViewOptions,
      showColorboardConfiguration: _showColorboardConfiguration,
      showKeyboardConfiguration: _showKeyboardConfiguration,
      sectionColor: sectionColor,
      toggleTempoConfiguration: () {
        setState(() {
          _showTapInBar = !_showTapInBar;
        });
      },
      showTempoConfiguration: _showTapInBar,
      visible: (_secondToolbarHeight != null && _secondToolbarHeight != 0) ||
          (_landscapePhoneSecondToolbarWidth != null &&
              _landscapePhoneSecondToolbarWidth != 0) ||
          _scalableUI,
      tempoLongPress: _landscapePhoneUI
          ? () {
              setState(() {
                if (!_showTapInBar) {
                  _showTapInBar = true;
                  _bottomTapInBar = true;
                } else {
                  _bottomTapInBar = !_bottomTapInBar;
                }
              });
            }
          : null,
      rewind: () {
        BeatScratchPlugin.setBeat(0);
        scrollToCurrentBeat();
      });

  SectionList createSectionList({Axis scrollDirection = Axis.horizontal}) {
    SectionList result = SectionList(
      appSettings: _appSettings,
      sectionColor: sectionColor,
      score: score,
      setState: setState,
      scrollDirection: scrollDirection,
      currentSection: currentSection,
      selectSection: _selectSection,
      insertSection: (s) => _insertSection(s, withNewColor: true),
      showSectionBeatCounts: showBeatCounts,
      toggleShowSectionBeatCounts: () {
        setState(() {
          showBeatCounts = !showBeatCounts;
        });
      },
      allowReordering: interactionMode.isEdit,
    );
    _sectionLists.add(result);
    return result;
  }

  saveCurrentScore({Duration delay}) {
    final score = this.score;
    final scoreFile = _scoreManager.currentScoreFile;
    print("Saving score ${score.name} to ${scoreFile.path.split('/').last}...");
    doSave() {
      setState(() {
        _savingScore = true;
      });
      print(
          "REALLY Saving score ${score.name} to ${scoreFile.path.split('/').last}...");
      _scoreManager
          .saveScoreFile(scoreFile, score)
          .then((_) => Future.delayed(animationDuration * 2, () {
                setState(() {
                  _savingScore = false;
                });
              }));
    }

    if (delay == null) {
      Future.microtask(doSave);
    } else {
      Future.delayed(delay, doSave);
    }
  }

  double beatScratchToolbarHeight(BuildContext context) =>
      context.isLandscapePhone ? 0 : 48;
  double beatScratchToolbarWidth(BuildContext context) =>
      context.isLandscapePhone ? 48 : 0;

  double flexibleAreaHeight(BuildContext context) {
    var data = MediaQuery.of(context);
    double result = data.size.height -
        data.padding.top -
        // kToolbarHeight -
        _secondToolbarHeight -
        _midiSettingsHeight -
        _colorboardHeight -
        _keyboardHeight -
        // messagesUI.height(context) -
        horizontalSectionListHeight -
        _tapInBarHeight -
        webWarningHeight -
        _bottomNotchPadding -
        exportUI.height -
        universeViewUIHeight -
        downloadLinksHeight -
        _topNotchPaddingReal -
        _bottomTapInBarHeight -
        // universeScoreTitleHeight -
        duplicateScoreWarningHeight -
        beatScratchToolbarHeight(context);
    // if (context.isPortraitPhone) {
    //   result -= universeScoreTitleHeight;
    // }
    return result;
  }

  Widget _layersAndMusicView(BuildContext context) {
    var data = MediaQuery.of(context);
    double fullHeight = flexibleAreaHeight(context);
    if (_scorePickerScrollDirection == Axis.horizontal) {
      fullHeight -= _scorePickerHeight(context);
    }
    if (context.isPortraitPhone) {
      fullHeight -= universeScoreTitleHeight;
    }
    double fullWidth = data.size.width -
        verticalSectionListWidth -
        _leftNotchPadding -
        _rightNotchPadding -
        _landscapeTapInBarWidth -
        _landscapePhoneSecondToolbarWidth -
        _landscapePhoneBeatscratchToolbarWidth;
    if (_scorePickerScrollDirection == Axis.vertical) {
      fullWidth -= _scorePickerWidth(context);
    }

    final landscapeLayersWidth = fullWidth * (1 - _musicViewSizeFactor);
    final portraitMelodyHeight = fullHeight * _musicViewSizeFactor;

    Widget layersView(context, width, height,
        {bool bottomShadow = false, bool rightShadow = false}) {
      return Stack(
        children: [
          _layersView(context, width, height),
          if (rightShadow)
            IgnorePointer(
                child: Row(
              children: [
                Expanded(child: SizedBox()),
                Column(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                          curve: Curves.easeInOut,
                          duration: slowAnimationDuration,
                          width: min(20, landscapeLayersWidth),
                          // color: Colors.black,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment(0.0,
                                  0.0), // 10% of the width, so there are ten blinds.
                              colors: [
                                const Color(0xff212121),
                                const Color(0x00212121)
                              ], // red to yellow
                              tileMode: TileMode
                                  .clamp, // repeats the gradient over the canvas
                            ),
                          ),
                          child: SizedBox()),
                    ),
                  ],
                ),
              ],
            )),
          if (bottomShadow)
            IgnorePointer(
                child: Column(
              children: [
                Expanded(child: SizedBox()),
                Row(
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                          curve: Curves.easeInOut,
                          duration: slowAnimationDuration,
                          height: min(20, portraitMelodyHeight),
                          // color: Colors.black,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment(0.0,
                                  0.0), // 10% of the width, so there are ten blinds.
                              colors: [
                                const Color(0xff212121),
                                const Color(0x00212121)
                              ], // red to yellow
                              tileMode: TileMode
                                  .clamp, // repeats the gradient over the canvas
                            ),
                          ),
                          child: SizedBox()),
                    ),
                  ],
                ),
              ],
            )),
          IgnorePointer(
              child: Row(children: [
            Expanded(
                child: Column(children: [
              Expanded(
                  child: AnimatedContainer(
                      duration: animationDuration,
                      curve: Curves.easeInOut,
                      color: musicBackgroundColor
                          .withOpacity(_musicViewSizeFactor < 1 ? 0 : 1)))
            ]))
          ]))
        ],
      );
    }

    return Stack(children: [
      (context.isPortrait)
          ? Column(children: [
              Expanded(
                child: layersView(
                    context, fullWidth, fullHeight * (1 - _musicViewSizeFactor),
                    bottomShadow: true),
              ),
              AnimatedContainer(
                curve: Curves.easeOutQuart,
                duration: slowAnimationDuration,
                padding:
                    EdgeInsets.only(top: (_musicViewSizeFactor == 1) ? 0 : 5),
                height: portraitMelodyHeight,
                child: _musicView(
                  context,
                  fullWidth,
                  fullHeight * _musicViewSizeFactor,
                ),
              )
            ])
          : Row(children: [
              AnimatedContainer(
                curve: Curves.easeInOut,
                duration: slowAnimationDuration,
                width: landscapeLayersWidth,
                child: layersView(context, fullWidth, fullHeight,
                    rightShadow: true),
              ),
              Expanded(
                  child: AnimatedContainer(
                      duration: animationDuration,
                      padding: EdgeInsets.only(
                          left: (_musicViewSizeFactor == 1) ? 0 : 5),
                      child: _musicView(context,
                          fullWidth * _musicViewSizeFactor, fullHeight)))
            ])
    ]);
  }

  Widget _layersView(
      BuildContext context, double availableWidth, double availableHeight) {
    return LayersView(
        key: ValueKey("main-part-melodies-view"),
        appSettings: _appSettings,
        musicViewMode: musicViewMode,
        superSetState: setState,
        currentSection: currentSection,
        score: score,
        sectionColor: sectionColor,
        selectMelody: _selectOrDeselectMelody,
        selectPart: _selectOrDeselectPart,
        selectedMelody: selectedMelody,
        selectedPart: selectedPart,
        toggleEditingMelody: () {
          setState(() {
            recordingMelody = !recordingMelody;
          });
        },
        toggleMelodyReference: _toggleReferenceDisabled,
        setReferenceVolume: _setReferenceVolume,
        setPartVolume: _setPartVolume,
        setColorboardPart: _setColorboardPart,
        setKeyboardPart: _setKeyboardPart,
        colorboardPart: colorboardPart,
        keyboardPart: keyboardPart,
        editingMelody: recordingMelody,
        hideMelodyView: _hideMusicView,
        availableWidth: availableWidth,
        height: availableHeight,
        enableColorboard: enableColorboard,
        showBeatCounts: showBeatCounts,
        showViewOptions: showViewOptions,
        scoreManager: _scoreManager,
        shiftUpZoomControls: context.isLandscapePhone &&
            MyPlatform.isMobile &&
            !showKeyboard &&
            !showColorboard &&
            _musicViewSizeFactor == 0.5);
  }

  Widget _musicView(BuildContext context, double width, double height) {
    return MusicView(
        key: ValueKey("main-melody-view"),
        appSettings: _appSettings,
        enableColorboard: enableColorboard,
        superSetState: setState,
        melodyViewSizeFactor: _musicViewSizeFactor,
        musicViewMode: musicViewMode,
        score: score,
        currentSection: currentSection,
        colorboardNotesNotifier: colorboardNotesNotifier,
        keyboardNotesNotifier: keyboardNotesNotifier,
        bluetoothControllerPressedNotes: bluetoothControllerPressedNotes,
        melody: selectedMelody,
        part: selectedPart,
        sectionColor: sectionColor,
        splitMode: splitMode,
        renderingMode: renderingMode,
        toggleSplitMode: toggleMelodyViewDisplayMode,
        closeMelodyView: _hideMusicView,
        toggleMelodyReference: _toggleReferenceDisabled,
        setReferenceVolume: _setReferenceVolume,
        recordingMelody: recordingMelody,
        toggleRecording: () {
          setState(() {
            recordingMelody = !recordingMelody;
          });
        },
        setPartVolume: _setPartVolume,
        setMelodyName: _setMelodyName,
        setSectionName: _setSectionName,
        setKeyboardPart: _setKeyboardPart,
        setColorboardPart: _setColorboardPart,
        colorboardPart: colorboardPart,
        keyboardPart: keyboardPart,
        height: height,
        width: width,
        scrollToCurrentBeat: scrollToCurrentBeat,
        deletePart: (part) {
          setState(() {
            _selectSection(currentSection);
            score.parts.remove(part);
            if (part == this.keyboardPart) {
              this.keyboardPart = score.parts.first;
            }
            if (part == this.colorboardPart) {
              this.colorboardPart = null;
            }
            score.sections.forEach((section) {
              section.melodies.removeWhere(
                  (ref) => part.melodies.any((m) => m.id == ref.melodyId));
            });
            selectedPart = null;
            _prevSelectedPart = null;
            BeatScratchPlugin.deletePart(part);
          });
        },
        deleteMelody: (melody) {
          setState(() {
            Part part = this.score.parts.firstWhere(
                (part) => part.melodies.any((m) => m.id == melody.id));
            _selectOrDeselectPart(part);
          });
          Future.delayed(slowAnimationDuration, () {
            setState(() {
              BeatScratchPlugin.deleteMelody(melody);
              score.parts.forEach((part) {
                part.melodies.removeWhere((m) => m.id == melody.id);
              });
              score.sections.forEach((section) {
                section.melodies
                    .removeWhere((ref) => ref.melodyId == melody.id);
              });
            });
          });
        },
        deleteSection: (section) {
          setState(() {
            if (section.id == this.currentSection.id) {
              int index =
                  this.score.sections.indexWhere((s) => s.id == section.id);
              if (index > 0) {
                index = index - 1;
              } else {
                index = index + 1;
              }
              this.currentSection = this.score.sections[index];
            }
            score.sections.removeWhere((s) => s.id == section.id);
          });
          BeatScratchPlugin.updateSections(score);
        },
        selectBeat: (beat) {
          // if (interactionMode.isView) {
          int seekingBeat = 0;
          int sectionIndex = 0;
          Section section = score.sections[sectionIndex++];
          while (beat - seekingBeat >= section.beatCount) {
            seekingBeat += section.beatCount;
            section = score.sections[sectionIndex++];
          }
//          print("Setting section to $section and beat to ${beat - seekingBeat}");
          setState(() {
            currentSection = section;
          });
          BeatScratchPlugin.setBeat(beat - seekingBeat);
          // } else {
          //   BeatScratchPlugin.setBeat(beat);
          // }
        },
        addPart: score.parts.length < 5 &&
                (!context.isLandscapePhone || splitMode != SplitMode.half)
            ? () {
                Part part = newPartFor(score);
                score.parts.insert(0, part);
                BeatScratchPlugin.createPart(part);
                keyboardPart = part;
                _selectOrDeselectPart(part);
              }
            : null,
        cloneCurrentSection: () {
          if (currentSection.name == null ||
              currentSection.name.trim().isEmpty) {
            String prefix = "Section";
            while (score.sections.any((s) => s.name.startsWith("$prefix "))) {
              prefix = "$prefix'";
            }
            currentSection.name = "$prefix 1";
          }
          Section section = currentSection.bsCopy();
          section.id = uuid.v4();
          final match = RegExp(
            r"^(.*?)(\d*)\s*$",
          ).allMatches(section.name).first;
          String prefix = match.group(1);
          prefix = prefix.trim();
          int number = int.tryParse(match.group(2)) ?? 1;
          while (score.sections.any((s) => s.name == section.name)) {
            section.name = "$prefix ${++number}";
          }
          section.melodies.clear();
          section.melodies
              .addAll(currentSection.melodies.map((e) => e.bsCopy()));
          _insertSection(section);
          section.tempo = Tempo()..bpm = currentSection.tempo.bpm;
        },
        requestRenderingMode: (mode) {
          setState(() {
            renderingMode = mode;
          });
        },
        showViewOptions: showViewOptions,
        selectOrDeselectPart: (part) {
          _selectOrDeselectPart(part, hideMusicOnDeselect: false);
        },
        selectOrDeselectMelody: (melody) {
          _selectOrDeselectMelody(melody);
        },
        showBeatCounts: showBeatCounts,
        createMelody: (part, newMelody, andRecord) {
          setState(() {
            //final newMelody = defaultMelody(sectionBeats: currentSection.beatCount);
            part.melodies.insert(0, newMelody);
            BeatScratchPlugin.createMelody(part, newMelody);
            final reference = currentSection.referenceTo(newMelody);
            _toggleReferenceDisabled(reference);
            BeatScratchPlugin.updateSections(score);
            Future.delayed(slowAnimationDuration, () {
              if (andRecord) {
                recordingMelody = true;
              }
              _selectOrDeselectMelody(newMelody, hideMusicOnDeselect: false);
            });
          });
        },
        showingSectionList: showSections);
  }

  _insertSection(Section newSection, {bool withNewColor = false}) {
    if (withNewColor) {
      newSection.color = IntervalColor.values[
          (IntervalColor.values.indexOf(currentSection.color) + 1) %
              IntervalColor.values.length];
    }
    int currentSectionIndex = score.sections.indexOf(currentSection);
    score.sections.insert(currentSectionIndex + 1, newSection);
    BeatScratchPlugin.updateSections(score);
    _selectSection(newSection);
  }

  Widget _settingsPanel(BuildContext context) {
    bool visible = _midiSettingsHeight > 0;
    return Column(
      children: [
        AnimatedContainer(
            curve: Curves.easeInOut,
            duration: animationDuration,
            padding: EdgeInsets.only(left: 5),
            height: visible ? 26 : 0,
            child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: animationDuration,
                  child: Row(
                    children: [
                      Transform.translate(
                          offset: Offset(0, 1.5),
                          child: Icon(Icons.settings, color: Colors.white)),
                      SizedBox(width: 3),
                      Text("Settings",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ))),
        AnimatedContainer(
            curve: Curves.easeInOut,
            duration: animationDuration,
            height: visible ? max(0, _midiSettingsHeight - 26) : 0,
            width: MediaQuery.of(context).size.width,
            color: subBackgroundColor,
            child: SettingsPanel(
              appSettings: _appSettings,
              universeManager: _universeManager,
              messagesUI: messagesUI,
              sectionColor: sectionColor,
              bluetoothScan: bluetoothScan,
              visible: showMidiConfiguration,
              enableColorboard: enableColorboard,
              bluetoothControllerPressedNotes: bluetoothControllerPressedNotes,
              setColorboardEnabled: (value) {
                setState(() {
                  enableColorboard = value;
                });
              },
              close: () {
                setState(() {
                  showMidiConfiguration = false;
                  _showKeyboardConfiguration = false;
                  _showColorboardConfiguration = false;
                  showKeyboard &=
                      _wasKeyboardShowingWhenMidiConfigurationOpened;
                  showColorboard &=
                      _wasColorboardShowingWhenMidiConfigurationOpened;
                  showViewOptions &=
                      _wereViewOptionsShowingWhenMidiConfigurationOpened;
                });
              },
              toggleKeyboardConfig: () {
                setState(() {
                  if (!_showKeyboardConfiguration) {
                    _wasKeyboardShowingWhenMidiConfigurationOpened =
                        showKeyboard;
                    showKeyboard = true;
                  } else if (!_wasKeyboardShowingWhenMidiConfigurationOpened) {
                    showKeyboard = false;
                  }
                  _showKeyboardConfiguration = !_showKeyboardConfiguration;
                });
              },
              toggleColorboardConfig: () {
                setState(() {
                  if (!_showColorboardConfiguration) {
                    _wasColorboardShowingWhenMidiConfigurationOpened =
                        showColorboard;
                    showColorboard = true;
                  } else if (!_wasColorboardShowingWhenMidiConfigurationOpened) {
                    showColorboard = false;
                  }
                  _showColorboardConfiguration = !_showColorboardConfiguration;
                });
              },
              keyboardPart: keyboardPart,
            )),
      ],
    );
  }

  AnimatedContainer _scorePicker(BuildContext context) {
    final width = _scorePickerWidth(context);
    final height = _scorePickerHeight(context);

    return AnimatedContainer(
        key: ValueKey("ScorePicker-$_scorePickerScrollDirection"),
        padding: EdgeInsets
            .zero, //(!_scalableUI) ? EdgeInsets.only(top: 5) : EdgeInsets.zero,
        curve: Curves.easeInOut,
        duration: animationDuration,
        height: height,
        width: width,
        color: subBackgroundColor,
        child: ScorePicker(
          scoreManager: _scoreManager,
          universeManager: _universeManager,
          appSettings: _appSettings,
          mode: scorePickerMode,
          sectionColor: sectionColor,
          openedScore: score,
          width: width,
          height: height,
          requestKeyboardFocused: (focused) {
            setState(() {});
          },
          requestMode: (mode) {
            setState(() {
              scorePickerMode = mode;
            });
          },
          close: () => _closeScorePicker(waitForSave: true),
          refreshUniverseData: refreshUniverseData,
          scrollDirection: _scorePickerScrollDirection,
        ));
  }

  _closeScorePicker({bool waitForSave = false, bool onlyIfShowMode = false}) {
    doClose() {
      setState(() {
        if (!onlyIfShowMode || scorePickerMode == ScorePickerMode.show) {
          scorePickerMode = ScorePickerMode.none;
          showScorePicker = false;
        }
      });
    }

    doCloseButWaitForSave() {
      if (_savingScore) {
        Future.delayed(Duration(milliseconds: 1500), () {
          doCloseButWaitForSave();
        });
      } else {
        doClose();
      }
    }

    if (waitForSave) {
      doCloseButWaitForSave();
    } else {
      doClose();
    }
  }

  AnimatedContainer _keyboard(BuildContext context) {
    return AnimatedContainer(
        curve: Curves.easeInOut,
        duration: animationDuration,
        height: _keyboardHeight,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Keyboard(
          width: MediaQuery.of(context).size.width -
              _landscapePhoneBeatscratchToolbarWidth -
              _leftNotchPadding -
              _rightNotchPadding -
              _landscapePhoneSecondToolbarWidth -
              _landscapeTapInBarWidth,
          appSettings: _appSettings,
          leftMargin: /*_landscapePhoneBeatscratchToolbarWidth + */ _leftNotchPadding,
          part: keyboardPart,
          height: _keyboardHeight,
          showConfiguration: _showKeyboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: keyboardNotesNotifier,
          bluetoothControllerPressedNotes: bluetoothControllerPressedNotes,
          distanceFromBottom: _bottomTapInBarHeight + _bottomNotchPadding,
          closed: !showKeyboard,
          closeKeyboard: showKeyboard ? _toggleKeyboard : () {},
        ));
  }

  AnimatedContainer _colorboard(BuildContext context) {
    return AnimatedContainer(
        curve: Curves.easeInOut,
        duration: animationDuration,
        height: _colorboardHeight,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Colorboard(
          width: MediaQuery.of(context).size.width -
              _landscapePhoneBeatscratchToolbarWidth -
              _leftNotchPadding -
              _rightNotchPadding -
              _landscapePhoneSecondToolbarWidth,
          leftMargin:
              _landscapePhoneBeatscratchToolbarWidth + _leftNotchPadding,
          part: colorboardPart,
          height: _colorboardHeight,
          showConfiguration: _showColorboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: colorboardNotesNotifier,
          distanceFromBottom:
              _keyboardHeight + _bottomTapInBarHeight + _bottomNotchPadding,
        ));
  }
}
