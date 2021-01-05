import 'dart:math';

import 'package:beatscratch_flutter_redux/recording/recording.dart';
import 'package:fluro/fluro.dart' as Fluro;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'beatscratch_plugin.dart';
import 'cache_management.dart';
import 'colors.dart';
import 'export/export.dart';
import 'generated/protos/music.pb.dart';
import 'generated/protos/protobeats_plugin.pb.dart';
import 'main_toolbars.dart';
import 'messages/messages.dart';
import 'settings/midi_settings.dart';
import 'music_view/music_view.dart';
import 'layers_view/melody_menu_browser.dart';
import 'layers_view/layers_view.dart';
import 'storage/migrations.dart';
import 'storage/score_manager.dart';
import 'storage/score_picker.dart';
import 'storage/url_conversions.dart';
import 'ui_models.dart';
import 'util/dummydata.dart';
import 'util/music_theory.dart';
import 'util/proto_utils.dart';
import 'util/util.dart';
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
String webScoreName = "Empty Web Score";
var baseHandler = Fluro.Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  return MyHomePage(title: MyPlatform.isAndroid ? 'BeatFlutter' : 'BeatScratch', initialScore: defaultScore());
  // return UsersScreen(params["scoreData"][0]);
});
var scoreRouteHandler = Fluro.Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String scoreData = params["scoreData"][0];
  Score score;
  try {
    score = scoreFromUrlHashValue(scoreData);
    webScoreName = score.name;
  } catch (any) {
    score = defaultScore();
  }

  return MyHomePage(title: MyPlatform.isAndroid ? 'BeatFlutter' : 'BeatScratch', initialScore: score);
  // return UsersScreen(params["scoreData"][0]);
});
var pastebinRouteHandler = Fluro.Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
  String pastebinCode = params["pasteBinData"][0];
  return MyHomePage(
    title: MyPlatform.isAndroid ? 'BeatFlutter' : 'BeatScratch',
    initialScore: defaultScore(),
    pastebinCode: pastebinCode,
  );
  // return UsersScreen(params["scoreData"][0]);
});

final Fluro.Router router = Fluro.Router()
  ..define("/", handler: baseHandler, transitionType: Fluro.TransitionType.material)
  ..define("/s/:pasteBinData", handler: pastebinRouteHandler, transitionType: Fluro.TransitionType.material)
  ..define("/score/:scoreData", handler: scoreRouteHandler, transitionType: Fluro.TransitionType.material);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
//    debugPaintSizeEnabled = true;
    return MaterialApp(
      key: Key(MyPlatform.isWeb ? "BeatScratch: $webScoreName" : 'BeatScratch'),
      title: MyPlatform.isAndroid ? 'BeatFlutter' : 'BeatScratch',
      onGenerateTitle: (context) => false
          ? "BeatScratch: $webScoreName"
          : MyPlatform.isAndroid
              ? 'BeatFlutter'
              : 'BeatScratch',
      theme: ThemeData(
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
      home: MyHomePage(title: 'BeatFlutter', initialScore: defaultScore()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.initialScore, this.pastebinCode}) : super(key: key);

  final String title;
  final Score initialScore;
  final String pastebinCode;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score score;
  InteractionMode interactionMode = InteractionMode.view;
  SplitMode _splitMode;

  SplitMode get splitMode => _splitMode;

  set splitMode(SplitMode value) {
    _splitMode = value;
    if (_melodyViewSizeFactor != 0) {
      if (value == SplitMode.half && interactionMode == InteractionMode.edit) {
        _melodyViewSizeFactor = 0.5;
      } else {
        _melodyViewSizeFactor = 1;
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

  RenderingMode renderingMode = RenderingMode.notation;

  bool _editingMelody = false;
  bool _softKeyboardVisible = false;

  bool _isSoftwareKeyboardVisible = false;

  double get bottomKeyboardPadding => context.isLandscapePhone
      ? (showKeyboard ^ showColorboard)
          ? -30
          : 40
      : 65;

  bool get editingMelody => _editingMelody;

  set editingMelody(value) {
    _editingMelody = value;
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
    BeatScratchPlugin.currentBeat.value = min(section.beatCount - 1, BeatScratchPlugin.currentBeat.value);
    _currentSection = section;
    if (editingMelody && section.referenceTo(selectedMelody).playbackType == MelodyReference_PlaybackType.disabled) {
      editingMelody = false;
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
  }

  int _recordingBeat;
  int _tapInBeat;
  bool showViewOptions = false;
  bool _wasKeyboardShowingWhenMidiConfigurationOpened = false;
  bool _wasColorboardShowingWhenMidiConfigurationOpened = false;
  bool _wereViewOptionsShowingWhenMidiConfigurationOpened = false;
  ScorePickerMode scorePickerMode = ScorePickerMode.none;
  bool _showScorePicker = false;

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

  bool get melodyViewVisible => _melodyViewSizeFactor > 0;

  double _melodyViewSizeFactor = 1.0;

  bool showWebWarning = kIsWeb || kDebugMode;

  double get webWarningHeight => showWebWarning ? 60 : 0;
  bool showDownloadLinks = false;

  double get downloadLinksHeight => showDownloadLinks ? 60 : 0;

  bool showBeatCounts;

  _showMusicView() {
    if (interactionMode == InteractionMode.edit) {
      if (splitMode == SplitMode.half) {
        _melodyViewSizeFactor = 0.5;
      } else {
        _melodyViewSizeFactor = 1;
      }
    } else {
      _melodyViewSizeFactor = 1;
    }
  }

  _hideMusicView() {
    setState(() {
      _melodyViewSizeFactor = 0;
      _prevSelectedMelody = selectedMelody;
      if (_prevSelectedMelody == null) {
        _prevSelectedPart = selectedPart;
      }
      selectedMelody = null;
      editingMelody = false;
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

  _setKeyboardPart(Part part) {
    setState(() {
      bool wasAssignedByPartCreation = keyboardPart == null;
      keyboardPart = part;
      if (part != null && !wasAssignedByPartCreation) {
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
      Part part = score.parts.firstWhere((p) => p.melodies.any((m) => m.id == selectedMelody.id));
      if (part != null) {
        keyboardPart = part;
      }
    } else {
      editingMelody = false;
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

  Color get sectionColor => sectionColors[score.sections.indexOf(currentSection) % sectionColors.length];

  _selectOrDeselectMelody(Melody melody, {bool hideMusicOnDeselect: true}) {
    setState(() {
      if (selectedMelody != melody) {
        selectedMelody = melody;
        _prevSelectedMelody = melody;
        _prevSelectedPart = null;
        if (editingMelody) {
          BeatScratchPlugin.setRecordingMelody(melody);
        }
        musicViewMode = MusicViewMode.melody;
        _showMusicView();
      } else {
        selectedMelody = null;
        editingMelody = false;
        if (hideMusicOnDeselect) {
          _hideMusicView();
        } else {
          final part = score.parts.firstWhere((p) => p.melodies.any((m) => m.id == melody.id));
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
        editingMelody = false;
        musicViewMode = MusicViewMode.part;
        _showMusicView();
      } else {
        if (hideMusicOnDeselect) {
          _hideMusicView();
        } else {
          if (musicViewMode == MusicViewMode.melody) {
            _selectOrDeselectMelody(selectedMelody, hideMusicOnDeselect: hideMusicOnDeselect);
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
        if (selectedMelody != null && ref != null && ref.melodyId == selectedMelody.id) {
          editingMelody = false;
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

  _doNothing() {}

  _viewMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.score);
    setState(() {
      interactionMode = InteractionMode.view;
      editingMelody = false;
      if (!_scalableUI) {
        showViewOptions = false;
        _showTapInBar = false;
      }
      musicViewMode = MusicViewMode.score;
      selectedMelody = null;
      _showMusicView();
    });
  }

  Part _prevSelectedPart;
  Melody _prevSelectedMelody;

  _editMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.section);
    setState(() {
      if (interactionMode == InteractionMode.edit) {
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
        // if (_melodyViewSizeFactor == 0) {
        //   _selectSection(currentSection);
        // } else if (_melodyViewSizeFactor == 0.5) {
        //   setState(() {splitMode = SplitMode.full;});
        // } else {
        //   setState(() {splitMode = SplitMode.half;});
        // }
      } else {
        interactionMode = InteractionMode.edit;
        if (_prevSelectedMelody != null) {
          _selectOrDeselectMelody(_prevSelectedMelody);
        } else if (_prevSelectedPart != null) {
          _selectOrDeselectPart(_prevSelectedPart);
        } else {
          musicViewMode = MusicViewMode.section;
        }
        _showMusicView();
//        _hideMelodyView();
      }
    });
  }

  _toggleViewOptions() {
    setState(() {
      showViewOptions = !showViewOptions;
      if (!showViewOptions) {
        _showTapInBar = false;
      }
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
      if (currentSection == section) {
        editingMelody = false;
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

  bool get _landscapePhoneUI => context.isLandscape && context.isPhone;
  bool _wasLandscapePhoneUI = false;

  bool get _scalableUI => context.isTabletOrLandscapey && !_landscapePhoneUI;

  bool get _portraitPhoneUI => !_landscapePhoneUI && !_scalableUI;

  BuildContext nativeDeviceOrientationReaderContext;

  NativeDeviceOrientation get _nativeOrientation {
    try {
      return NativeDeviceOrientationReader.orientation(nativeDeviceOrientationReaderContext);
    } catch (any) {
      return NativeDeviceOrientation.portraitUp;
    }
  }

  double get _leftNotchPadding => _nativeOrientation == NativeDeviceOrientation.landscapeRight
      ? MediaQuery.of(context).padding.left * 5 / 8
      : MediaQuery.of(context).padding.left * 5 / 7;

  double get _rightNotchPadding => _nativeOrientation == NativeDeviceOrientation.landscapeLeft
      ? MediaQuery.of(context).padding.right / 4
      : MediaQuery.of(context).padding.right * 5 / 8;

  double get _bottomNotchPadding =>
      _nativeOrientation == NativeDeviceOrientation.portraitUp ? MediaQuery.of(context).padding.bottom * 3 / 4 : 0;

  double get _topNotchPaddingReal => MediaQuery.of(context).padding.top;

  double get _secondToolbarHeight => _portraitPhoneUI
      ? interactionMode == InteractionMode.edit || showViewOptions
          ? 36
          : 0
      : 0;

  double get _landscapePhoneBeatscratchToolbarWidth => _landscapePhoneUI ? 48 : 0;

  double get _landscapePhoneSecondToolbarWidth =>
      _landscapePhoneUI && (interactionMode == InteractionMode.edit || showViewOptions) ? 48 : 0;

  double get _midiSettingsHeight => showMidiConfiguration ? 175 : 0;

  double get _scorePickerHeight => showScorePicker ? 210 + bottomKeyboardPadding : 0;

  bool _isPhone = false;
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

  bool get _showStatusBar => BeatScratchPlugin.isSynthesizerAvailable;

  double get _statusBarHeight => _showStatusBar
      ? 0
      : _isLandscapePhone
          ? 25
          : 30;
  bool _savingScore = false;

  double get _savingScoreHeight => !_savingScore
      ? 0
      : _isLandscapePhone
          ? 25
          : 30;

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

  bool get showTapInBar => _showTapInBar || _forceShowTapInBar;

  bool verticalSectionList = false;

  double get verticalSectionListWidth => interactionMode == InteractionMode.edit && verticalSectionList ? 165 : 0;

  double get horizontalSectionListHeight => interactionMode == InteractionMode.edit && !verticalSectionList ? 36 : 0;

  AnimationController loadingAnimationController;
  ExportUI exportUI;
  MessagesUI messagesUI;

  @override
  void initState() {
    super.initState();
    messagesUI = MessagesUI(setState);
    exportUI = ExportUI()..messagesUI = messagesUI;
    BeatScratchPlugin.setupWebStuff();
    showBeatCounts = false;
    score = widget.initialScore;
    _currentSection = widget.initialScore.sections[0];
    _scoreManager.doOpenScore = (Score scoreToOpen) {
      scoreToOpen.migrate();
      MelodyMenuBrowser.loadScoreData();
      setState(() {
        BeatScratchPlugin.createScore(scoreToOpen);
        score = scoreToOpen;
        clearMutableCaches();
        currentSection = scoreToOpen.sections.first;
        musicViewMode = interactionMode == InteractionMode.view ? MusicViewMode.score : MusicViewMode.section;
        selectedMelody = null;
        selectedPart = null;
        keyboardPart = scoreToOpen.parts.first;
        colorboardPart =
            scoreToOpen.parts.firstWhere((Part p) => p.instrument.type != InstrumentType.drum, orElse: null);
        exportUI.export.score = scoreToOpen;
      });
    };
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
        currentSection = score.sections.firstWhere((section) => section.id == sectionId);
      });
    };
    BeatScratchPlugin.onSynthesizerStatusChange = () {
      setState(() {});
    };
    BeatScratchPlugin.onLoadScoreFromLink = (scoreUrl) {
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
            messagesUI.sendMessage(message: "Failed to open Score Link!", isError: true);
          });
        });

        Future.delayed(slowAnimationDuration, () {
          if (!failed) {
            messagesUI.sendMessage(message: "Opened linked score!",);
          }
        });
      });
    };
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
        final part = score.parts.firstWhere((p) => p.melodies.any((m) => m.id == melody.id));
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
    RecordedSegmentQueue.getRecordingMelody =
        () => musicViewMode == MusicViewMode.melody && editingMelody ? selectedMelody : null;
    RecordedSegmentQueue.updateRecordingMelody = BeatScratchPlugin.onRecordingMelodyUpdated;
    keyboardPart = score.parts.firstWhere((part) => true, orElse: () => null);
    colorboardPart =
        score.parts.firstWhere((part) => part.instrument.type == InstrumentType.harmonic, orElse: () => null);

    colorboardNotesNotifier = ValueNotifier(Set());
    keyboardNotesNotifier = ValueNotifier(Set());

    loadingAnimationController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 10), () => MelodyMenuBrowser.loadScoreData());
    });
  }

  @override
  void dispose() {
    loadingAnimationController.dispose();
    colorboardNotesNotifier.dispose();
    keyboardNotesNotifier.dispose();
    super.dispose();
  }

  // ignore: missing_return
  Future<bool> _onWillPop() async {
    if (!_goBack()) {
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to exit BeatFlutter?'),
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
    if (interactionMode == InteractionMode.edit && _melodyViewSizeFactor > 0) {
      setState(() {
        _hideMusicView();
      });
      return true;
    } else if (showMidiConfiguration || _showKeyboardConfiguration || _showColorboardConfiguration) {
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
    } else if (interactionMode == InteractionMode.edit) {
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
    _isPhone = context.isPhone;
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
//    var top = MediaQuery.of(context).size.height - _colorboardHeight - _keyboardHeight;
//    var bottom = MediaQuery.of(context).size.height;
//    var right = MediaQuery.of(context).size.width;
//    var left = 0.0;
//    SystemChannels.platform.invokeMethod("SystemGestures.setSystemGestureExclusionRects", <Map<String, int>>[
//      {"left": left.toInt(), "top": top.toInt(), "right": 10, "bottom": bottom.toInt()},
//      {"left": (right - 10).toInt(), "top": top.toInt(), "right": right.toInt(), "bottom": bottom.toInt()},
//    ]);
    Map<LogicalKeySet, Intent> shortcuts = {LogicalKeySet(LogicalKeyboardKey.escape): Intent.doNothing};
    theUI(BuildContext context) => Stack(children: [
          Row(
            children: [
              if (_landscapePhoneUI) AnimatedContainer(duration: animationDuration, width: _leftNotchPadding),
              Expanded(
                // fit: FlexFit.loose,
                child: Column(children: [
                  _webBanner(context),
                  _downloadBanner(context),
                  _scorePicker(context),
                  exportUI.build(context: context, setState: setState, currentSection: currentSection),
                  _horizontalSectionList(),
                  Expanded(
                      child: Row(children: [_verticalSectionList(), Expanded(child: _layersAndMusicView(context))])),
                  if (_portraitPhoneUI) _toolbarsInColumn(context),
                  if (_scalableUI) _toolbarsInRow(context),
                  // if (_portraitPhoneUI || _landscapePhoneUI) _scorePicker(context),
                  // if (_portraitPhoneUI) _tempoConfigurationBar(context),
                  _midiSettings(context),
                  // _pasteFailedBar(context),
                  messagesUI.build(context: context),
                  _savingScoreBar(context),
                  _audioSystemWorkingBar(context),
                  _colorboard(context),
                  if (!_landscapePhoneUI) _tapInBar(context),
                  _keyboard(context),
                  _tapInBar(context, bottom: true),
                  Container(height: _bottomNotchPadding),
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

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            resizeToAvoidBottomPadding: false,
            backgroundColor: Color(0xFF424242),
            appBar: PreferredSize(
                preferredSize: Size.fromHeight(0.0), // here the desired height
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
            )));
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

  static const EdgeInsets _bannerPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 15);

  Widget _webBanner(BuildContext context) {
    bool isWeb = MyPlatform.isWeb;
    bool hideDownloadLinkButton = showDownloadLinks || !showWebWarning || !isWeb;
    return AnimatedContainer(
        duration: animationDuration,
        height: webWarningHeight,
        color: Color(0xFF212121),
        child: Row(children: [
          Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
              child: SingleChildScrollView(
                  child: Column(children: [
                Align(
                    child: Text("BeatScratch",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                Align(
                    child: Row(children: [
                  if (isWeb)
                    Text("Web", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text("Preview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w100)),
                ])),
              ]))),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    AnimatedContainer(
                        duration: animationDuration,
                        width: hideDownloadLinkButton ? 0 : 180,
                        child: Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: MyRaisedButton(
                                padding: _bannerPadding,
                                onPressed: showDownloadLinks
                                    ? null
                                    : () {
                                        setState(() {
                                          showDownloadLinks = true;
                                        });
                                      },
                                child: Text("Download App")))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                            "BeatScratch is pre-release software.\nBugs and missing features abound." +
                                (isWeb ? "\nmacOS/iOS/Android apps have recording and better performance." : ""),
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))),
//        Expanded(child:SizedBox()),
                    AnimatedContainer(
                        duration: animationDuration,
                        width: max(
                            0,
                            MediaQuery.of(context).size.width -
                                (isWeb ? 792 : 620) -
                                (hideDownloadLinkButton ? 0 : 180)),
                        child: SizedBox()),
                    Padding(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        child: MyRaisedButton(
                            padding: _bannerPadding,
                            onPressed: () {
                              launchURL("https://beatscratch.io/privacy.html");
                            },
                            child: Text("Privacy"))),
                    Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: MyRaisedButton(
                            padding: _bannerPadding,
                            onPressed: () {
                              launchURL("https://beatscratch.io/usage.html");
                            },
                            child: Text("Docs"))),
                  ]))),
          Padding(
              padding: EdgeInsets.only(right: 5),
              child: MyRaisedButton(
                  padding: _bannerPadding,
                  color: sectionColor,
                  onPressed: () {
                    setState(() {
                      showWebWarning = false;
                      showDownloadLinks = false;
                    });
                  },
                  child: Text("OK!"))),
        ]));
  }

  Widget _downloadBanner(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: downloadLinksHeight,
        color: Color(0xFF212121),
        child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  MyFlatButton(
                      onPressed: () {
//                _launchURL("https://play.google.com/store/apps/details?id=io.beatscratch.beatscratch_flutter_redux");
                        launchURL("https://play.google.com/apps/testing/io.beatscratch.beatscratch_flutter_redux");
                      },
                      padding: EdgeInsets.all(0),
                      child: Image.asset("assets/play_en_badge_web_generic.png")),
                  Transform.translate(
                      offset: Offset(-5, 0),
                      child: MyFlatButton(
                          onPressed: () {
                            launchURL("https://testflight.apple.com/join/dXJr9JJs");
                          },
                          padding: EdgeInsets.all(0),
                          child: Image.asset("assets/testflight-badge.png"))),
                  Container(
                      width: 120,
                      height: 40,
                      padding: EdgeInsets.only(right: 5),
                      child: MyFlatButton(
                          color: Colors.white,
                          onPressed: () {
                            launchURL("https://www.dropbox.com/s/71jclv5a5tgd1c7/BeatFlutter.tar.bz2?dl=1");
                          },
                          padding: EdgeInsets.all(0),
                          child: Stack(children: [
                            Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                    padding: EdgeInsets.only(right: 5, bottom: 2),
                                    child: Text("macOS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)))),
                            Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                    padding: EdgeInsets.only(top: 2, left: 5),
                                    child: Text("Download For",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400))))
                          ]))),
                  Padding(
                      padding: EdgeInsets.only(right: 5, left: 5),
                      child: MyRaisedButton(
                          padding: _bannerPadding,
                          onPressed: () {
                            launchURL("https://beatscratch.io/platforms.html");
                          },
                          child: Text("Platform Feature Comparison"))),
                ]))));
  }

  Widget _audioSystemWorkingBar(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: _statusBarHeight,
        color: Color(0xFF212121),
        child: Row(children: [
          SizedBox(width: 5),
          AnimatedOpacity(
              duration: animationDuration,
              opacity: _showStatusBar ? 0 : 1,
              child: Icon(Icons.warning, size: 18, color: chromaticSteps[5])),
          SizedBox(width: 5),
          Text("BeatScratch Synthesizer is loading...",
              style: TextStyle(
                color: Colors.white,
              ))
        ]));
  }

  Widget _savingScoreBar(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: _savingScoreHeight,
        color: Color(0xFF212121),
        child: Row(children: [
          SizedBox(width: 5),
          AnimatedOpacity(
              duration: animationDuration,
              opacity: _savingScore ? 1 : 0,
              child: Icon(Icons.info, size: 18, color: chromaticSteps[0])),
          SizedBox(width: 5),
          Text("Saving score...",
              style: TextStyle(
                color: Colors.white,
              ))
        ]));
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
    final double tapInFirstSize = !playing && tapInBeat == null ? 42 : 0;
    final double tapInSecondSize = !BeatScratchPlugin.playing && (_tapInBeat == null || _tapInBeat <= -2) ? 42 : 0;
    tapInBarInstructions({bool withText = true, bool withIcon = true}) => Stack(children: [
          AnimatedOpacity(
              duration: animationDuration,
              opacity: isDisplayed && !BeatScratchPlugin.playing ? 1 : 0,
              child: Row(children: [
                if (withIcon) Icon(editingMelody ? Icons.fiber_manual_record : Icons.play_arrow, color: Colors.grey),
                if (withText) SizedBox(width: 5),
                if (withText)
                  Expanded(
                    child: Text(
                        BeatScratchPlugin.supportsPlayback
                            ? "Tap in ${(!MyPlatform.isWeb && BeatScratchPlugin.connectedControllers.isNotEmpty) ? "here or with damper/pitch wheel" : "here"} to ${editingMelody ? "record" : "play"}"
                            : "Playback not supported",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: BeatScratchPlugin.supportsPlayback ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w100)),
                  )
              ])),
          AnimatedOpacity(
              duration: animationDuration,
              opacity: isDisplayed && BeatScratchPlugin.playing ? 1 : 0,
              child: Row(children: [
                Icon(editingMelody ? Icons.fiber_manual_record : Icons.play_arrow,
                    color: editingMelody ? chromaticSteps[7] : chromaticSteps[0]),
                if (withText) SizedBox(width: 5),
                if (withText)
                  Text(
                      editingMelody && BeatScratchPlugin.supportsRecording
                          ? "Recording"
                          : !editingMelody && BeatScratchPlugin.supportsPlayback
                              ? "Playing"
                              : "${editingMelody ? "Recording" : "Playback"} doesn't actually work yet...",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100))
              ]))
        ]);
    final contents = [
      AnimatedOpacity(
        duration: animationDuration,
        opacity: tapInFirstSize != 0 && showTapInBar && isDisplayed ? 1 : 0,
        child: AnimatedContainer(
            duration: Duration(milliseconds: 35),
            padding: vertical ? EdgeInsets.only(top: 3) : EdgeInsets.only(left: 5),
            height: vertical ? tapInFirstSize : null,
            width: vertical ? null : tapInFirstSize,
            child: Listener(
                onPointerDown: (event) {
                  BeatScratchPlugin.countIn(-2);
                  setState(() {
                    _tapInBeat = -2;
                  });
                  Future.delayed(Duration(seconds: 3), () {
                    setState(() {
                      _tapInBeat = null;
                    });
                  });
                },
                child: MyRaisedButton(
                  child: Text(
                      !playing && tapInBeat == null ? (currentSection.meter.defaultBeatsPerMeasure - 1).toString() : "",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: tapInBeat == null && BeatScratchPlugin.supportsPlayback ? () {} : null,
                  padding: EdgeInsets.zero,
                ))),
      ),
      AnimatedOpacity(
        duration: animationDuration,
        opacity: tapInSecondSize != 0 && showTapInBar ? 1 : 0,
        child: AnimatedContainer(
            duration: Duration(milliseconds: 35),
            padding: vertical ? EdgeInsets.only(top: 5) : EdgeInsets.only(left: 5),
            height: vertical ? tapInSecondSize : null,
            width: vertical ? null : tapInSecondSize,
            child: Listener(
                onPointerDown: (event) {
                  BeatScratchPlugin.countIn(-1);
                  setState(() {
                    _tapInBeat = null;
                  });
//              Future.delayed(Duration(seconds: 3), () {
//                setState(() {
//                  _tapInBeat = null;
//                });
//              });
                },
                child: MyRaisedButton(
                  child: Text(currentSection.meter.defaultBeatsPerMeasure.toString(),
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _tapInBeat == -2 ? () {} : null,
                  padding: EdgeInsets.zero,
                ))),
      ),
      if (_scalableUI) Expanded(child: Padding(padding: EdgeInsets.only(left: 7), child: tapInBarInstructions())),
      if (vertical) SizedBox(height: 15),
      if (vertical)
        Expanded(
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity: isDisplayed ? 1 : 0,
                child: _tempoConfigurationBar(context, vertical: true))),
      if (vertical) SizedBox(height: 3),
      if (!_portraitPhoneUI && !vertical)
        AnimatedOpacity(
            duration: animationDuration, opacity: isDisplayed ? 1 : 0, child: _tempoConfigurationBar(context)),
      if (_portraitPhoneUI && !vertical)
        Expanded(
          child: AnimatedOpacity(
              duration: animationDuration, opacity: isDisplayed ? 1 : 0, child: _tempoConfigurationBar(context)),
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
                color: BeatScratchPlugin.metronomeEnabled ? sectionColor : Colors.grey,
                child: Stack(
                  children: [
                    Transform.translate(
                        offset: Offset(-3.5, 3.5),
                        child: Transform.scale(scale: 0.7, child: Image.asset('assets/metronome.png'))),
                    Transform.translate(
                        offset: Offset(17, -4),
                        child: Transform.scale(
                            scale: 0.55,
                            child: Icon(BeatScratchPlugin.metronomeEnabled ? Icons.volume_up : Icons.not_interested))),
                  ],
                ),
                onPressed: BeatScratchPlugin.supportsPlayback
                    ? () {
                        setState(() {
                          BeatScratchPlugin.metronomeEnabled = !BeatScratchPlugin.metronomeEnabled;
                        });
                      }
                    : null,
              ))),
      if (vertical) SizedBox(height: 3),
    ];
    return AnimatedContainer(
        padding: vertical ? EdgeInsets.only(right: 2) : EdgeInsets.only(bottom: 1),
        duration: animationDuration,
        width: vertical ? _landscapeTapInBarWidth : null,
        height: vertical
            ? null
            : bottom
                ? _bottomTapInBarHeight
                : _tapInBarHeight,
        color: Color(0xFF424242),
        child: vertical ? Column(children: contents) : Row(children: contents));
  }

  final double _tempoIncrementFactor = 1.01;

  Widget _tempoConfigurationBar(BuildContext context, {bool vertical = false}) {
    final minValue = min(0.1, BeatScratchPlugin.bpmMultiplier);
    final maxValue = max(2.0, BeatScratchPlugin.bpmMultiplier);
    return RotatedBox(
        quarterTurns: vertical ? 3 : 0,
        child: AnimatedOpacity(
            duration: animationDuration,
            opacity: _showTapInBar ? 1 : 0,
            child: AnimatedContainer(
                duration: animationDuration,
                height: _portraitPhoneUI ? 34 : null,
                width: !_portraitPhoneUI ? (_showTapInBar ? 300 : 0) : null,
                padding: _scalableUI || _landscapePhoneUI ? EdgeInsets.zero : EdgeInsets.only(bottom: 2, top: 0),
                child: Row(children: [
                  if (!_scalableUI) SizedBox(width: 5),
                  Container(
                      width: 25,
                      child: MyRaisedButton(
                          padding: EdgeInsets.all(0),
                          child: RotatedBox(
                              quarterTurns: vertical ? 1 : 0, child: Icon(Icons.keyboard_arrow_down_rounded)),
                          onPressed: BeatScratchPlugin.bpmMultiplier / _tempoIncrementFactor >= minValue
                              ? () {
                                  var newValue = BeatScratchPlugin.bpmMultiplier;
                                  newValue /= _tempoIncrementFactor;
                                  BeatScratchPlugin.bpmMultiplier = max(minValue, min(2.0, newValue));
                                  BeatScratchPlugin.onSynthesizerStatusChange();
                                }
                              : null)),
                  Expanded(
                      child: MySlider(
                          max: maxValue,
                          min: minValue,
                          value: max(minValue, min(maxValue, BeatScratchPlugin.bpmMultiplier)),
                          activeColor: Colors.white,
                          onChanged: (value) {
                            BeatScratchPlugin.bpmMultiplier = value;
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          })),
                  Container(
                      width: 25,
                      child: MyRaisedButton(
                          padding: EdgeInsets.all(0),
                          child:
                              RotatedBox(quarterTurns: vertical ? 1 : 0, child: Icon(Icons.keyboard_arrow_up_rounded)),
                          onPressed: BeatScratchPlugin.bpmMultiplier * _tempoIncrementFactor <= maxValue
                              ? () {
                                  var newValue = BeatScratchPlugin.bpmMultiplier;
                                  newValue *= _tempoIncrementFactor;
                                  BeatScratchPlugin.bpmMultiplier = max(minValue, min(maxValue, newValue));
                                  BeatScratchPlugin.onSynthesizerStatusChange();
                                }
                              : null)),
                  SizedBox(width: 5),
                  Container(
                      width: 25,
                      child: MyRaisedButton(
                          padding: EdgeInsets.all(0),
                          child: RotatedBox(
                              quarterTurns: vertical ? 1 : 0,
                              child: Text("x1", maxLines: 1, overflow: TextOverflow.fade)),
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
            Expanded(flex: 1, child: createBeatScratchToolbar(leftHalfOnly: true)),
            Container(
                height: 36,
                child: AnimatedContainer(
                    duration: animationDuration,
                    width: MediaQuery.of(context).size.width / 2,
                    child: createSecondToolbar())),
            Expanded(flex: 1, child: createBeatScratchToolbar(rightHalfOnly: true)),
          ],
        ));
  }

  Widget _toolbarsInColumn(BuildContext context) {
    return Column(children: <Widget>[
      createBeatScratchToolbar(),
      AnimatedContainer(duration: animationDuration, height: _secondToolbarHeight, child: createSecondToolbar())
    ]);
  }

  BeatScratchToolbar createBeatScratchToolbar(
          {bool vertical = false, bool leftHalfOnly = false, bool rightHalfOnly = false}) =>
      BeatScratchToolbar(
        score: score,
        messagesUI: messagesUI,
        currentSection: currentSection,
        scoreManager: _scoreManager,
        currentScoreName: MyPlatform.isWeb ? score.name : _scoreManager.currentScoreName,
        sectionColor: sectionColor,
        viewMode: _viewMode,
        editMode: _editMode,
        toggleViewOptions: _toggleViewOptions,
        interactionMode: interactionMode,
        routeToCurrentScore: (String pastebinCode) {
          router.navigateTo(context, "/s/$pastebinCode");
        },
        vertical: vertical,
        verticalSections: verticalSectionList,
        togglePlaying: () {
          setState(() {
            if (!BeatScratchPlugin.playing) {
              BeatScratchPlugin.play();
            } else {
              BeatScratchPlugin.pause();
            }
          });
        },
        toggleSectionListDisplayMode: () {
          setState(() {
            verticalSectionList = !verticalSectionList;
          });
        },
        renderingMode: renderingMode,
        setRenderingMode: (value) {
          setState(() {
            renderingMode = value;
          });
        },
        showScorePicker: (mode) {
          setState(() {
            scorePickerMode = mode;
            showScorePicker = true;
          });
        },
        showMidiInputSettings: () {
          setState(() {
            _wasKeyboardShowingWhenMidiConfigurationOpened = showKeyboard;
            _wasColorboardShowingWhenMidiConfigurationOpened = showColorboard;
            _wereViewOptionsShowingWhenMidiConfigurationOpened = showViewOptions;
            showMidiConfiguration = true;
            showViewOptions = true;
            if (keyboardPart != null && showKeyboard) {
              _showKeyboardConfiguration = true;
            }
            if (_enableColorboard && colorboardPart != null && showColorboard) {
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
          _scoreManager.loadFromScoreUrl(scoreUrl, currentScoreToSave: this.score, onFail: () {
            setState(() {
              pasteFailed = true;
            });
          }, onSuccess: (scoreName) {
            setState(() {
              scorePickerMode = ScorePickerMode.duplicate;
              showScorePicker = true;
              messagesUI.sendMessage(message: "Pasted ${score.name}!",);
              _viewMode();
            });
          });
        },
        export: () {
          setState(() {
            exportUI.visible = true;
            showScorePicker = false;
          });
        },
        openMelody: selectedMelody,
        openPart: selectedPart,
        prevMelody: _prevSelectedMelody,
        prevPart: _prevSelectedPart,
        isMelodyViewOpen: _melodyViewSizeFactor != 0,
        leftHalfOnly: leftHalfOnly,
        rightHalfOnly: rightHalfOnly,
      );

  SecondToolbar createSecondToolbar({bool vertical = false}) => SecondToolbar(
      vertical: vertical,
      editingMelody: editingMelody,
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
          if (_showTapInBar) {
            showViewOptions = true;
          }
        });
      },
      showTempoConfiguration: _showTapInBar,
      visible: (_secondToolbarHeight != null && _secondToolbarHeight != 0) ||
          (_landscapePhoneSecondToolbarWidth != null && _landscapePhoneSecondToolbarWidth != 0) ||
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
          : null);

  SectionList createSectionList({Axis scrollDirection = Axis.horizontal}) {
    SectionList result = SectionList(
      sectionColor: sectionColor,
      score: score,
      setState: setState,
      scrollDirection: scrollDirection,
      currentSection: currentSection,
      selectSection: _selectSection,
      insertSection: _insertSection,
      showSectionBeatCounts: showBeatCounts,
      toggleShowSectionBeatCounts: () {
        setState(() {
          showBeatCounts = !showBeatCounts;
        });
      },
    );
    _sectionLists.add(result);
    return result;
  }

  saveCurrentScore() {
    Future.microtask(() {
      setState(() {
        _savingScore = true;
      });
      _scoreManager.saveCurrentScore(score);
      Future.delayed(animationDuration * 2, () {
        setState(() {
          _savingScore = false;
        });
      });
    });
  }

  Widget _layersAndMusicView(BuildContext context) {
    var data = MediaQuery.of(context);
    double height = data.size.height -
        data.padding.top -
        kToolbarHeight -
        _secondToolbarHeight -
        _midiSettingsHeight -
        _scorePickerHeight -
        _colorboardHeight -
        _keyboardHeight -
        messagesUI.height(context) -
        horizontalSectionListHeight -
        _tapInBarHeight -
        _statusBarHeight -
        webWarningHeight -
        _bottomNotchPadding -
        exportUI.height -
        downloadLinksHeight +
        8 -
        _topNotchPaddingReal -
        _bottomTapInBarHeight;
    double layersWidth =
        data.size.width - verticalSectionListWidth - _leftNotchPadding - _rightNotchPadding - _landscapeTapInBarWidth;
//    if (musicViewMode == MusicViewMode.score || musicViewMode == MusicViewMode.none) {
//      height += 36;
//    }
    final landscapeLayersWidth =
        (layersWidth - _landscapePhoneSecondToolbarWidth - _landscapePhoneBeatscratchToolbarWidth) *
            (1 - _melodyViewSizeFactor);
    final portraitMelodyHeight = height * _melodyViewSizeFactor;

    Widget layersView(context, width, height, {bool bottomShadow = false, bool rightShadow = false}) {
      return Stack(
        children: [
          _partMelodiesView(context, width, height),
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
                              end: Alignment(0.0, 0.0), // 10% of the width, so there are ten blinds.
                              colors: [const Color(0xff212121), const Color(0x00212121)], // red to yellow
                              tileMode: TileMode.clamp, // repeats the gradient over the canvas
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
                              end: Alignment(0.0, 0.0), // 10% of the width, so there are ten blinds.
                              colors: [const Color(0xff212121), const Color(0x00212121)], // red to yellow
                              tileMode: TileMode.clamp, // repeats the gradient over the canvas
                            ),
                          ),
                          child: SizedBox()),
                    ),
                  ],
                ),
              ],
            ))
        ],
      );
    }

    return Stack(children: [
      (context.isPortrait)
          ? Column(children: [
              Expanded(
                child: layersView(context, layersWidth, height * (1 - _melodyViewSizeFactor), bottomShadow: true),
              ),
              AnimatedContainer(
                curve: Curves.linear,
                duration: slowAnimationDuration,
                padding: EdgeInsets.only(top: (_melodyViewSizeFactor == 1) ? 0 : 5),
                height: portraitMelodyHeight,
                child: _musicView(context, height * _melodyViewSizeFactor),
              )
            ])
          : Row(children: [
              AnimatedContainer(
                curve: Curves.easeInOut,
                duration: slowAnimationDuration,
                width: landscapeLayersWidth,
                child: layersView(context, layersWidth, height, rightShadow: true),
              ),
              Expanded(
                  child: AnimatedContainer(
                      duration: animationDuration,
                      padding: EdgeInsets.only(left: (_melodyViewSizeFactor == 1) ? 0 : 5),
                      child: _musicView(context, height)))
            ])
    ]);
  }

  Widget _partMelodiesView(BuildContext context, double availableWidth, double availableHeight) {
    return LayersView(
      key: ValueKey("main-part-melodies-view"),
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
          editingMelody = !editingMelody;
        });
      },
      toggleMelodyReference: _toggleReferenceDisabled,
      setReferenceVolume: _setReferenceVolume,
      setPartVolume: _setPartVolume,
      setColorboardPart: _setColorboardPart,
      setKeyboardPart: _setKeyboardPart,
      colorboardPart: colorboardPart,
      keyboardPart: keyboardPart,
      editingMelody: editingMelody,
      hideMelodyView: _hideMusicView,
      availableWidth: availableWidth,
      height: availableHeight,
      enableColorboard: enableColorboard,
      showBeatCounts: showBeatCounts,
      showViewOptions: showViewOptions,
      scoreManager: _scoreManager,
    );
  }

  MusicView _musicView(BuildContext context, double height) {
    return MusicView(
      key: ValueKey("main-melody-view"),
      enableColorboard: enableColorboard,
      superSetState: setState,
      melodyViewSizeFactor: _melodyViewSizeFactor,
      musicViewMode: musicViewMode,
      score: score,
      currentSection: currentSection,
      colorboardNotesNotifier: colorboardNotesNotifier,
      keyboardNotesNotifier: keyboardNotesNotifier,
      melody: selectedMelody,
      part: selectedPart,
      sectionColor: sectionColor,
      splitMode: splitMode,
      renderingMode: renderingMode,
      toggleSplitMode: toggleMelodyViewDisplayMode,
      closeMelodyView: _hideMusicView,
      toggleMelodyReference: _toggleReferenceDisabled,
      setReferenceVolume: _setReferenceVolume,
      editingMelody: editingMelody,
      toggleEditingMelody: () {
        setState(() {
          editingMelody = !editingMelody;
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
      deletePart: (part) {
        setState(() {
          if (part == this.selectedPart) {
            int index = this.score.parts.indexOf(part);
            if (index > 0) {
              index = index - 1;
            } else {
              index = index + 1;
            }
            if (index < this.score.parts.length) {
              this.selectedPart = this.score.parts[index];
            } else {
              this.selectedPart = null;
              this.musicViewMode = MusicViewMode.section;
            }
          }
          if (part == this.keyboardPart) {
            this.keyboardPart = null;
          }
          if (part == this.colorboardPart) {
            this.colorboardPart = null;
          }
          score.parts.remove(part);

          BeatScratchPlugin.deletePart(part);
        });
      },
      deleteMelody: (melody) {
        BeatScratchPlugin.deleteMelody(melody);
        setState(() {
          if (melody == this.selectedMelody) {
            Part part = this.score.parts.firstWhere((part) => part.melodies.any((m) => m.id == melody.id));
            int index = part.melodies.indexWhere((m) => m.id == melody.id);
            if (index > 0) {
              index = index - 1;
            } else {
              index = index + 1;
            }
            if (index < part.melodies.length) {
              this.selectedMelody = part.melodies[index];
            } else {
              this.selectedMelody = null;
              this._selectOrDeselectPart(part);
            }
          }
          score.parts.forEach((part) {
            part.melodies.removeWhere((m) => m.id == melody.id);
          });
          score.sections.forEach((section) {
            section.melodies.removeWhere((ref) => ref.melodyId == melody.id);
          });
        });
      },
      deleteSection: (section) {
        setState(() {
          if (section.id == this.currentSection.id) {
            int index = this.score.sections.indexWhere((s) => s.id == section.id);
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
        // if (interactionMode == InteractionMode.view) {
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
      cloneCurrentSection: () {
        if (currentSection.name == null || currentSection.name.trim().isEmpty) {
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
        section.name = "$prefix ${number + 1}";
        section.melodies.clear();
        section.melodies.addAll(currentSection.melodies.map((e) => e.bsCopy()));
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
      createMelody: (part, newMelody) {
        setState(() {
          //final newMelody = defaultMelody(sectionBeats: currentSection.beatCount);
          part.melodies.insert(0, newMelody);
          BeatScratchPlugin.createMelody(part, newMelody);
          final reference = currentSection.referenceTo(newMelody)
            ..playbackType = MelodyReference_PlaybackType.playback_indefinitely;
          BeatScratchPlugin.updateSections(score);
          Future.delayed(slowAnimationDuration, () {
            _selectOrDeselectMelody(newMelody, hideMusicOnDeselect: false);
            Future.delayed(slowAnimationDuration, () {
              setState(() {
                editingMelody = true;
              });
            });
          });
        });
      },
    );
  }

  _insertSection(Section newSection) {
    int currentSectionIndex = score.sections.indexOf(currentSection);
    score.sections.insert(currentSectionIndex + 1, newSection);
    BeatScratchPlugin.updateSections(score);
    _selectSection(newSection);
  }

  Widget _midiSettings(BuildContext context) {
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
                      Transform.translate(offset: Offset(0, 1.5), child: Icon(Icons.settings, color: Colors.white)),
                      SizedBox(width: 3),
                      Text("MIDI Settings",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))),
        AnimatedContainer(
            curve: Curves.easeInOut,
            duration: animationDuration,
            height: visible ? max(0, _midiSettingsHeight - 26) : 0,
            width: MediaQuery.of(context).size.width,
            color: Color(0xFF424242),
            child: MidiSettings(
              sectionColor: sectionColor,
              enableColorboard: enableColorboard,
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
                  showKeyboard &= _wasKeyboardShowingWhenMidiConfigurationOpened;
                  showColorboard &= _wasColorboardShowingWhenMidiConfigurationOpened;
                  showViewOptions &= _wereViewOptionsShowingWhenMidiConfigurationOpened;
                });
              },
              toggleKeyboardConfig: () {
                setState(() {
                  if (!_showKeyboardConfiguration) {
                    _wasKeyboardShowingWhenMidiConfigurationOpened = showKeyboard;
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
                    _wasColorboardShowingWhenMidiConfigurationOpened = showColorboard;
                    showColorboard = true;
                  } else if (!_wasColorboardShowingWhenMidiConfigurationOpened) {
                    showColorboard = false;
                  }
                  _showColorboardConfiguration = !_showColorboardConfiguration;
                });
              },
            )),
      ],
    );
  }

  AnimatedContainer _scorePicker(BuildContext context) {
    return AnimatedContainer(
        padding: (!_scalableUI) ? EdgeInsets.only(top: 5) : EdgeInsets.zero,
        curve: Curves.easeInOut,
        duration: animationDuration,
        height: _scorePickerHeight,
        width: MediaQuery.of(context).size.width,
        color: Color(0xFF424242),
        child: ScorePicker(
            scoreManager: _scoreManager,
            mode: scorePickerMode,
            sectionColor: sectionColor,
            openedScore: score,
            requestKeyboardFocused: (focused) {
              setState(() {
                _isSoftwareKeyboardVisible = focused;
              });
            },
            requestMode: (mode) {
              setState(() {
                scorePickerMode = mode;
              });
            },
            close: () {
              doClose() {
                setState(() {
                  scorePickerMode = ScorePickerMode.none;
                  showScorePicker = false;
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

              doCloseButWaitForSave();
            }));
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
          leftMargin: /*_landscapePhoneBeatscratchToolbarWidth + */ _leftNotchPadding,
          part: keyboardPart,
          height: _keyboardHeight,
          showConfiguration: _showKeyboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: keyboardNotesNotifier,
          distanceFromBottom: _bottomTapInBarHeight + _bottomNotchPadding,
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
          leftMargin: _landscapePhoneBeatscratchToolbarWidth + _leftNotchPadding,
          part: colorboardPart,
          height: _colorboardHeight,
          showConfiguration: _showColorboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: colorboardNotesNotifier,
          distanceFromBottom: _keyboardHeight + _bottomTapInBarHeight + _bottomNotchPadding,
        ));
  }
}
