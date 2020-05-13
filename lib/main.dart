import 'dart:io';
import 'dart:math';

import 'package:beatscratch_flutter_redux/clearCaches.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/generated/protos/protobeats_plugin.pb.dart';
import 'package:beatscratch_flutter_redux/midi_settings.dart';
import 'package:beatscratch_flutter_redux/platform_svg/platform_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'beatscratch_plugin.dart';
import 'keyboard.dart';
import 'melody_view.dart';
import 'section_list.dart';
import 'part_melodies_view.dart';
import 'colorboard.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'util.dart';
import 'ui_models.dart';
import 'package:flutter/foundation.dart';
import 'dummydata.dart';
import 'main_toolbars.dart';
import 'music_theory.dart';

void main() => runApp(MyApp());

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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
//    debugPaintSizeEnabled = true;
    return MaterialApp(
      title: 'BeatFlutter',
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
      home: MyHomePage(title: 'BeatFlutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Score initialScore = defaultScore();
Section initialSection = initialScore.sections[0];

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score _score = initialScore;
  InteractionMode interactionMode = InteractionMode.view;
  SplitMode _splitMode;
  SplitMode get splitMode => _splitMode;
  set splitMode(SplitMode value) {
    _splitMode = value;
    if(_melodyViewSizeFactor != 0) {
      if (value == SplitMode.half && interactionMode == InteractionMode.edit) {
        _melodyViewSizeFactor = 0.5;
      } else {
        _melodyViewSizeFactor = 1;
      }
    }
  }

  MelodyViewMode _melodyViewMode = MelodyViewMode.score;

  MelodyViewMode get melodyViewMode => _melodyViewMode;

  set melodyViewMode(MelodyViewMode value) {
    _melodyViewMode = value;
    if (value != MelodyViewMode.melody) {
      selectedMelody = null;
    }
    if (value != MelodyViewMode.part) {
      selectedPart = null;
    }
  }

  RenderingMode renderingMode = RenderingMode.notation;

  bool _editingMelody = false;

  bool get editingMelody => _editingMelody;

  bool _hadVerticalSectionListBefore;
  bool _hadSplitModeBefore;
  set editingMelody(value) {
    _editingMelody = value;
    if (value) {
      var part = _score.parts.firstWhere((part) => part.melodies.any((it) => it.id == selectedMelody.id));
      _setKeyboardPart(part);
      BeatScratchPlugin.setRecordingMelody(selectedMelody);
      if(_isPhone) {
        _hadVerticalSectionListBefore = verticalSectionList;
        _hadSplitModeBefore = splitMode == SplitMode.half;
        if(_isLandscapePhone) {
          verticalSectionList = true;
          splitMode = SplitMode.full;
        } else {
          verticalSectionList = false;
          splitMode = SplitMode.full;
        }
      }
      _showMelodyView();
    } else {
      BeatScratchPlugin.setRecordingMelody(null);
      if(_isPhone && selectedMelody != null) {
        verticalSectionList = _hadVerticalSectionListBefore ?? verticalSectionList;
        splitMode = (_hadSplitModeBefore == true) ? SplitMode.half : splitMode;
      }
      _hadVerticalSectionListBefore = null;
      _hadSplitModeBefore = null;
    }
  }

  Section _currentSection = initialScore.sections[0];

  Section get currentSection => _currentSection;

  set currentSection(Section section) {
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
  bool showMidiConfiguration = false;
  bool showKeyboard = true;
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

  bool focusPartsAndMelodies = true;
  bool showBeatCounts = false;

  updateScore(Function(Score) updates) {
    setState(() {
      _score = _score.copyWith(updates);
    });
  }

  _showMelodyView() {
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

  _hideMelodyView() {
    setState(() {
      _melodyViewSizeFactor = 0;
      selectedMelody = null;
      editingMelody = false;
      selectedPart = null;
      melodyViewMode = MelodyViewMode.none;
    });
  }

  toggleMelodyViewDisplayMode() {
    setState(() {
      if (splitMode == SplitMode.half) {
        splitMode = SplitMode.full;
      } else {
        splitMode = SplitMode.half;
      }
      _showMelodyView();
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

  Melody selectedMelody;
  Part selectedPart;

  List<SectionList> _sectionLists = [];

  Color get sectionColor => sectionColors[_score.sections.indexOf(currentSection) % sectionColors.length];

  _selectOrDeselectMelody(Melody melody) {
    setState(() {
      if (selectedMelody != melody) {
        selectedMelody = melody;
        if (editingMelody) {
          BeatScratchPlugin.setRecordingMelody(melody);
        }
        melodyViewMode = MelodyViewMode.melody;
        _showMelodyView();
      } else {
        selectedMelody = null;
        editingMelody = false;
        _hideMelodyView();
      }
    });
  }

  _selectOrDeselectPart(Part part) {
    setState(() {
      print("yay");
      if (selectedPart != part) {
        selectedPart = part;
        editingMelody = false;
        melodyViewMode = MelodyViewMode.part;
        _showMelodyView();
      } else {
        _hideMelodyView();
      }
//      if (selectedMelody != melody) {
//        selectedMelody = melody;
//      } else {
//        selectedMelody = null;
//      }
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
    BeatScratchPlugin.updateSections(_score);
  }

  _setReferenceVolume(MelodyReference ref, double volume) {
    setState(() {
      ref.volume = volume;
    });
    BeatScratchPlugin.updateSections(_score);
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
      if (!context.isTabletOrLandscapey) {
        showViewOptions = false;
      }
      melodyViewMode = MelodyViewMode.score;
      selectedMelody = null;
      _showMelodyView();
    });
  }

  _editMode() {
    BeatScratchPlugin.setPlaybackMode(Playback_Mode.section);
    setState(() {
      if (interactionMode == InteractionMode.edit) {
        _selectSection(currentSection);
      } else {
        interactionMode = InteractionMode.edit;
        splitMode = SplitMode.half; //(context.isTablet) ? SplitMode.half : SplitMode.full;
        melodyViewMode = MelodyViewMode.section;
        _showMelodyView();
//        _hideMelodyView();
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
    BeatScratchPlugin.setCurrentSection(section);
    setState(() {
      if (currentSection == section) {
        editingMelody = false;
        if (melodyViewMode != MelodyViewMode.section) {
          melodyViewMode = MelodyViewMode.section;
          _showMelodyView();
        } else {
          if (!melodyViewVisible) {
            _showMelodyView();
          } else {
            _hideMelodyView();
          }
        }
      } else {
        currentSection = section;
      }
    });
  }

  bool get _combineSecondAndMainToolbar => context.isTabletOrLandscapey;

  double get _secondToolbarHeight =>
      (_combineSecondAndMainToolbar) ? 0 : interactionMode == InteractionMode.edit || showViewOptions ? 36 : 0;

  double get _midiSettingsHeight => showMidiConfiguration ? 150 : 0;

  bool _isPhone = false;
  bool _isLandscapePhone = false;
  double get _colorboardHeight => showColorboard ? _isLandscapePhone ? 115 : 150 : 0;

  double get _keyboardHeight => showKeyboard ? _isLandscapePhone ? 115 : 150 : 0;

  double get _statusBarHeight => BeatScratchPlugin.isSynthesizerAvailable ? 0 : _isLandscapePhone ? 25 : 30;

  double get _tapInBarHeight =>
      interactionMode == InteractionMode.edit || showViewOptions || _forceShowTapInBar
        ? (_isLandscapePhone && (showKeyboard || showColorboard)) ? 38 : 44
        : 0;
  bool _forceShowTapInBar = false;

  bool verticalSectionList = false;

  double get verticalSectionListWidth => interactionMode == InteractionMode.edit && verticalSectionList ? 165 : 0;

  double get horizontalSectionListHeight => interactionMode == InteractionMode.edit && !verticalSectionList ? 36 : 0;

  AnimationController loadingAnimationController;

  @override
  void initState() {
    super.initState();
    BeatScratchPlugin.createScore(_score);
    BeatScratchPlugin.onSectionSelected = (sectionId) {
      setState(() {
        currentSection = _score.sections.firstWhere((section) => section.id == sectionId);
      });
    };
    BeatScratchPlugin.onSynthesizerStatusChange = () {
      setState(() {});
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
        final part = _score.parts.firstWhere((p) => p.melodies.any((m) => m.id == melody.id));
        final index = part.melodies.indexWhere((m) => m.id == melody.id);
//        print("Replacing ${part.melodies[index]} with $melody");
        part.melodies[index] = melody;
        clearMutableCaches();
//        _score.parts.expand((s) => s.melodies).firstWhere((m) => m.id == melody.id).midiData = melody.midiData;
      });
    };
    keyboardPart = _score.parts.firstWhere((part) => true, orElse: () => null);
    colorboardPart =
        _score.parts.firstWhere((part) => part.instrument.type == InstrumentType.harmonic, orElse: () => null);

    colorboardNotesNotifier = ValueNotifier(Set());
    keyboardNotesNotifier = ValueNotifier(Set());

    loadingAnimationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    loadingAnimationController.dispose();
    colorboardNotesNotifier.dispose();
    keyboardNotesNotifier.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_goBack()) {
      return (await showDialog(
            context: context,
            builder: (context) => new AlertDialog(
              title: new Text('Are you sure?'),
              content: new Text('Do you want to exit BeatFlutter?'),
              actions: <Widget>[
                new FlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: new Text('No'),
                ),
                new FlatButton(
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
        _hideMelodyView();
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

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

//  final GoogleSignIn _googleSignIn = GoogleSignIn();
//  final FirebaseAuth _auth = FirebaseAuth.instance;
//  Future<FirebaseUser> _handleSignIn() async {
//    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
//    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//    final AuthCredential credential = GoogleAuthProvider.getCredential(
//      accessToken: googleAuth.accessToken,
//      idToken: googleAuth.idToken,
//    );
//
//    final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;
//    print("signed in " + user.displayName);
//    return user;
//  }

  @override
  Widget build(BuildContext context) {
    if (splitMode == null) {
      splitMode = SplitMode.half; //(context.isTablet) ? SplitMode.half : SplitMode.full;
      verticalSectionList = context.isTablet;
    }
    _isPhone = context.isPhone;
    _isLandscapePhone = context.isLandscapePhone;
    if(editingMelody && _isPhone) {
      verticalSectionList = context.isLandscape;
    }
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
//    var top = MediaQuery.of(context).size.height - _colorboardHeight - _keyboardHeight;
//    var bottom = MediaQuery.of(context).size.height;
//    var right = MediaQuery.of(context).size.width;
//    var left = 0.0;
//    SystemChannels.platform.invokeMethod("SystemGestures.setSystemGestureExclusionRects", <Map<String, int>>[
//      {"left": left.toInt(), "top": top.toInt(), "right": 10, "bottom": bottom.toInt()},
//      {"left": (right - 10).toInt(), "top": top.toInt(), "right": right.toInt(), "bottom": bottom.toInt()},
//    ]);
    Map<LogicalKeySet, Intent> shortcuts = {LogicalKeySet(LogicalKeyboardKey.escape): Intent.doNothing};
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
            body: new GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: Stack(children: [
                Column(children: [
                  _webBanner(context),
                  _downloadBanner(context),
                  if (_combineSecondAndMainToolbar) _toolbars(context),
                  _horizontalSectionList(),
                  Expanded(
                      child: Row(children: [
                    _verticalSectionList(),
                    Expanded(child: _partsAndMelodiesAndMelodyView(context))
                  ])),
                  if (!_combineSecondAndMainToolbar) _toolbars(context),
                  _midiSettings(context),
                  _tapInBar(context),
                  _audioSystemWorkingBar(context),
                  _colorboard(context),
                  _keyboard(context),
                ]),
                Column(children:[
                  Expanded(child: SizedBox()),
                  // Listener overlay to block accidental input to keyboard/tempo bar
                  // if software keyboard is open in landscape/fullscreen (Android)
                  if(MediaQuery.of(context).viewInsets.bottom > 0)
                    Container(color: Colors.black54, width: MediaQuery.of(context).size.width, height:100,
                      child: Listener(
                        onPointerDown: (event) {
                          print("got input");
                        },
                        onPointerMove: (event) {
                          print("got input");},
                        onPointerUp: (event) {
                          print("got input");},
                        onPointerCancel: (event) {
                          print("got input");},
                      ))
                ])
                //]),
              ]),
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

  Widget _webBanner(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: webWarningHeight,
        color: Color(0xFF212121),
        child: Row(children: [
          Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
              child: Column(children: [
                Align(
                    child: Text("BeatScratch",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                Align(
                    child: Row(children: [
                  Text("Web", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text("Preview", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w100)),
                ])),
              ])),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                        child: Text(
                            "is pre-release software.\nBugs and missing features abound.\nmacOS/iOS/Android apps have playback, recording, and better performance.",
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))),
//        Expanded(child:SizedBox()),
                    AnimatedContainer(
                        duration: animationDuration,
                        width: max(0, MediaQuery.of(context).size.width - 865 - (showDownloadLinks ? 0 : 180)),
                        child: SizedBox()),
                    Padding(
                        padding: EdgeInsets.only(right: 5, left: 5),
                        child: RaisedButton(
                            onPressed: () {
                              _launchURL("https://beatscratch.io/privacy.html");
                            },
                            child: Text("Privacy"))),
                    Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: RaisedButton(
                            onPressed: () {
                              _launchURL("https://beatscratch.io/usage.html");
                            },
                            child: Text("Docs"))),
                    AnimatedContainer(
                        duration: animationDuration,
                        width: showDownloadLinks || !showWebWarning ? 0 : 180,
                        child: Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: RaisedButton(
                                onPressed: showDownloadLinks
                                    ? null
                                    : () {
                                        setState(() {
                                          showDownloadLinks = true;
                                        });
                                      },
                                child: Text("Download App")))),
                  ]))),
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: RaisedButton(
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
                  FlatButton(
                      onPressed: () {
                        _launchURL("https://play.google.com/store/apps/details?id=com.jonlatane.beatpad");
                      },
                      padding: EdgeInsets.all(0),
                      child: Image.asset("assets/play_en_badge_web_generic.png")),
                  Transform.translate(offset: Offset(-15,0), child:
                  FlatButton(
                      onPressed: () {
                        _launchURL("https://testflight.apple.com/join/dXJr9JJs");
                      },
                      padding: EdgeInsets.all(0),
                      child: Image.asset("assets/testflight-badge.png"))),
                  Container(
                      width: 120,
                      height: 40,
                      padding: EdgeInsets.only(right: 5),
                      child: FlatButton(
                          color: Colors.white,
                          onPressed: () {
                            _launchURL("https://www.dropbox.com/s/71jclv5a5tgd1c7/BeatFlutter.tar.bz2?dl=1");
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
                      child: RaisedButton(
                          onPressed: () {
                            _launchURL("https://beatscratch.io/platforms.html");
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
          Icon(Icons.warning, size: 18, color: chromaticSteps[5]),
          SizedBox(width: 5),
          Text("BeatScratch Synthesizer is loading...",
              style: TextStyle(
                color: Colors.white,
              ))
        ]));
  }

  Widget _tapInBar(BuildContext context) {
    bool playing = BeatScratchPlugin.playing;
    int tapInBeat = _tapInBeat;
    return AnimatedContainer(
        duration: animationDuration,
        height: _tapInBarHeight,
        color: Color(0xFF424242),
        child: Row(children: [
          AnimatedContainer(
              duration: Duration(milliseconds: 35),
              padding: EdgeInsets.only(left: 5),
              width: !playing && tapInBeat == null ? 42 : 0,
              child: RaisedButton(
                child: Text(!playing && tapInBeat == null ? "3" : "", style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: tapInBeat == null
                    ? () {
                        BeatScratchPlugin.countIn(-2);
                        setState(() {
                          _tapInBeat = -2;
                        });
                        Future.delayed(Duration(seconds: 3), () {
                          setState(() {
                            _tapInBeat = null;
                          });
                        });
                      }
                    : null,
                padding: EdgeInsets.zero,
              )),
          AnimatedContainer(
              duration: Duration(milliseconds: 120),
              padding: EdgeInsets.only(left: 5),
              width: !BeatScratchPlugin.playing && (_tapInBeat == null || _tapInBeat <= -2) ? 42 : 0,
              child: RaisedButton(
                child: Text("4", style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: _tapInBeat == -2
                    ? () {
                        BeatScratchPlugin.countIn(-1);
                        setState(() {
                          _tapInBeat = null;
                        });
//              Future.delayed(Duration(seconds: 3), () {
//                setState(() {
//                  _tapInBeat = null;
//                });
//              });
                      }
                    : null,
                padding: EdgeInsets.zero,
              )),
          AnimatedContainer(
              duration: animationDuration,
              padding: EdgeInsets.only(left: 5),
              width: BeatScratchPlugin.playing && !(context.isPortrait && context.isPhone) ? 69 : 0,
              child: RaisedButton(
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: BeatScratchPlugin.playing && !(context.isPortrait && context.isPhone) ? 1 : 0,
                    child: Icon(Icons.pause)),
                onPressed: BeatScratchPlugin.playing
                    ? () {
                        setState(() {
                          BeatScratchPlugin.pause();
                          _tapInBeat = null;
                        });
                      }
                    : null,
                padding: EdgeInsets.zero,
              )),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: Stack(children: [
                    AnimatedOpacity(
                        duration: animationDuration,
                        opacity: !BeatScratchPlugin.playing ? 1 : 0,
                        child: Row(children: [
                          Icon(editingMelody ? Icons.fiber_manual_record : Icons.play_arrow, color: Colors.grey),
                          SizedBox(width: 5),
                          Text("Tap in to ${editingMelody ? "record" : "play"}",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100))
                        ])),
                    AnimatedOpacity(
                        duration: animationDuration,
                        opacity: BeatScratchPlugin.playing ? 1 : 0,
                        child: Row(children: [
                          Icon(editingMelody ? Icons.fiber_manual_record : Icons.play_arrow,
                              color: editingMelody ? chromaticSteps[7] : chromaticSteps[0]),
                          SizedBox(width: 5),
                          Text(
                              editingMelody && BeatScratchPlugin.supportsRecording
                                  ? "Recording"
                                  : !editingMelody && BeatScratchPlugin.supportsPlayback
                                      ? "Playing"
                                      : "${editingMelody ? "Recording" : "Playback"} doesn't actually work yet...",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100))
                        ]))
                  ]))),
          Container(
              width: 42,
              padding: EdgeInsets.only(right: 5),
              child: RaisedButton(
                padding: EdgeInsets.all(5),
                color: BeatScratchPlugin.metronomeEnabled ? sectionColor : Colors.grey,
                child: Image.asset('assets/metronome.png'),
                onPressed: () {
                  setState(() {
                    BeatScratchPlugin.metronomeEnabled = !BeatScratchPlugin.metronomeEnabled;
                  });
                },
              ))
//        Container(padding: EdgeInsets.only(left: 5), width: 69,
//          child: RaisedButton(child: Text("Done", style: TextStyle(color: Colors.white),),
//            color: chromaticSteps[0],
//            onPressed: _tapInBeat != null ? () {
//              setState(() {
//                _tapInBeat = null;
//              });
//            } : null, padding: EdgeInsets.zero,)),
        ]));
  }

  Widget _toolbars(BuildContext context) {
    return _combineSecondAndMainToolbar
        ? Container(
            height: 48,
            child: Row(
              children: <Widget>[
                Expanded(child: createBeatScratchToolbar()),
                Container(
                    height: 36,
                    child: AnimatedContainer(
                        duration: animationDuration,
                        width:
                            context.isTabletOrLandscapey || interactionMode == InteractionMode.edit || showViewOptions
                                ? MediaQuery.of(context).size.width / 2
                                : 0,
                        child: createSecondToolbar()))
              ],
            ))
        : Column(children: <Widget>[
            createBeatScratchToolbar(),
            AnimatedContainer(duration: animationDuration, height: _secondToolbarHeight, child: createSecondToolbar())
          ]);
  }

  BeatScratchToolbar createBeatScratchToolbar() => BeatScratchToolbar(
        sectionColor: sectionColor,
        viewMode: _viewMode,
        editMode: _editMode,
        toggleViewOptions: _toggleViewOptions,
        interactionMode: interactionMode,
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
        showMidiInputSettings: () {
          setState(() {
            _wasKeyboardShowingWhenMidiConfigurationOpened = showKeyboard;
            _wasColorboardShowingWhenMidiConfigurationOpened = showColorboard;
            _wereViewOptionsShowingWhenMidiConfigurationOpened = showViewOptions;
            showMidiConfiguration = true;
            showViewOptions = true;
            if (keyboardPart != null) {
              showKeyboard = true;
              _showKeyboardConfiguration = true;
            }
            if (_enableColorboard && colorboardPart != null) {
              showColorboard = true;
              _showColorboardConfiguration = true;
            }
          });
        },
    focusPartsAndMelodies: focusPartsAndMelodies,
    toggleFocusPartsAndMelodies: () {
      setState(() {
        focusPartsAndMelodies = !focusPartsAndMelodies;
      });
    },
    showBeatCounts: showBeatCounts,
    toggleShowBeatCounts: () {
      setState(() {
        showBeatCounts = !showBeatCounts;
      });
    },
      );

  SecondToolbar createSecondToolbar() => SecondToolbar(
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
      );

  SectionList createSectionList({Axis scrollDirection = Axis.horizontal}) {
    SectionList result = SectionList(
      sectionColor: sectionColor,
      score: _score,
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

  Widget _partsAndMelodiesAndMelodyView(BuildContext context) {
    var data = MediaQuery.of(context);
    double height = data.size.height -
        data.padding.top -
        kToolbarHeight -
        _secondToolbarHeight -
        _midiSettingsHeight -
        _colorboardHeight -
        _keyboardHeight -
        horizontalSectionListHeight -
        _tapInBarHeight -
        _statusBarHeight -
        webWarningHeight -
        downloadLinksHeight +
        8;
    double width = data.size.width - verticalSectionListWidth;
//    if (melodyViewMode == MelodyViewMode.score || melodyViewMode == MelodyViewMode.none) {
//      height += 36;
//    }
    return Stack(children: [
      (context.isPortrait)
          ? Column(children: [
              Expanded(child: _partMelodiesView(context, width, height * (1 - _melodyViewSizeFactor))),
              AnimatedContainer(
                  curve: Curves.easeInOut,
                  duration: slowAnimationDuration,
                  padding: EdgeInsets.only(top: (_melodyViewSizeFactor == 1) ? 0 : 5),
                  height: height * _melodyViewSizeFactor,
                  child: _melodyView(context, height * _melodyViewSizeFactor))
            ])
          : Row(children: [
              AnimatedContainer(
                  curve: Curves.easeInOut,
                  duration: slowAnimationDuration,
                  width: width * (1 - _melodyViewSizeFactor),
                  child: _partMelodiesView(context, width, height)),
              Expanded(
                  child: AnimatedContainer(
                      duration: animationDuration,
                      padding: EdgeInsets.only(left: (_melodyViewSizeFactor == 1) ? 0 : 5),
                      child: _melodyView(context, height)))
            ])
    ]);
  }

  Widget _partMelodiesView(BuildContext context, double availableWidth, double availableHeight) {
    return PartMelodiesView(
      melodyViewMode: melodyViewMode,
      superSetState: setState,
      currentSection: currentSection,
      score: _score,
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
      hideMelodyView: _hideMelodyView,
      availableWidth: availableWidth,
      height: availableHeight,
      enableColorboard: enableColorboard,
      showBeatCounts: showBeatCounts,
    );
  }

  MelodyView _melodyView(BuildContext context, double height) {
    return MelodyView(
      enableColorboard: enableColorboard,
      superSetState: setState,
      focusPartsAndMelodies: focusPartsAndMelodies,
      melodyViewSizeFactor: _melodyViewSizeFactor,
      melodyViewMode: melodyViewMode,
      score: _score,
      currentSection: currentSection,
      colorboardNotesNotifier: colorboardNotesNotifier,
      keyboardNotesNotifier: keyboardNotesNotifier,
      melody: selectedMelody,
      part: selectedPart,
      sectionColor: sectionColor,
      splitMode: splitMode,
      renderingMode: renderingMode,
      toggleSplitMode: toggleMelodyViewDisplayMode,
      closeMelodyView: _hideMelodyView,
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
            int index = this._score.parts.indexOf(part);
            if (index > 0) {
              index = index - 1;
            } else {
              index = index + 1;
            }
            if (index < this._score.parts.length) {
              this.selectedPart = this._score.parts[index];
            } else {
              this.selectedPart = null;
              this.melodyViewMode = MelodyViewMode.section;
            }
          }
          if (part == this.keyboardPart) {
            this.keyboardPart = null;
          }
          if (part == this.colorboardPart) {
            this.colorboardPart = null;
          }
          _score.parts.remove(part);

          BeatScratchPlugin.deletePart(part);
        });
      },
      deleteMelody: (melody) {
        BeatScratchPlugin.deleteMelody(melody);
        setState(() {
          if (melody == this.selectedMelody) {
            Part part = this._score.parts.firstWhere((part) => part.melodies.any((m) => m.id == melody.id));
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
          _score.parts.forEach((part) {
            part.melodies.removeWhere((m) => m.id == melody.id);
          });
          _score.sections.forEach((section) {
            section.melodies.removeWhere((ref) => ref.melodyId == melody.id);
          });
        });
      },
      deleteSection: (section) {
        setState(() {
          if (section.id == this.currentSection.id) {
            int index = this._score.sections.indexWhere((s) => s.id == section.id);
            if (index > 0) {
              index = index - 1;
            } else {
              index = index + 1;
            }
            this.currentSection = this._score.sections[index];
          }
          _score.sections.removeWhere((s) => s.id == section.id);
        });
        BeatScratchPlugin.updateSections(_score);
      },
      selectBeat: (beat) {
        if (interactionMode == InteractionMode.view) {
          int seekingBeat = 0;
          int sectionIndex = 0;
          Section section = _score.sections[sectionIndex++];
          while (beat - seekingBeat >= section.beatCount) {
            seekingBeat += section.beatCount;
            section = _score.sections[sectionIndex++];
          }
          print("Setting section to $section and beat to ${beat - seekingBeat}");
          setState(() {
            currentSection = section;
          });
          BeatScratchPlugin.setCurrentSection(section);
          BeatScratchPlugin.setBeat(beat - seekingBeat);
        } else {
          BeatScratchPlugin.setBeat(beat);
        }
      },
      cloneCurrentSection: () {
        if (currentSection.name == null || currentSection.name.trim().isEmpty) {
          String prefix = "Section";
          while (_score.sections.any((s) => s.name.startsWith("$prefix "))) {
            prefix = "$prefix'";
          }
          currentSection.name = "$prefix 1";
        }
        Section section = currentSection.clone();
        section.id = uuid.v4();
        final match = RegExp(
          r"^(.*?)(\d*)$",
        ).allMatches(section.name).first;
        String prefix = match.group(1);
        prefix = prefix.trim();
        int number = int.tryParse(match.group(2)) ?? 1;
        section.name = "$prefix ${number + 1}";
        section.melodies.clear();
        section.melodies.addAll(currentSection.melodies.map((e) => e.clone()));
        _insertSection(section);
      },
    );
  }

  _insertSection(Section newSection) {
    int currentSectionIndex = _score.sections.indexOf(currentSection);
    _score.sections.insert(currentSectionIndex + 1, newSection);
    BeatScratchPlugin.updateSections(_score);
    _selectSection(newSection);
  }

  AnimatedContainer _midiSettings(BuildContext context) {
    return AnimatedContainer(
        curve: Curves.easeInOut,
        duration: animationDuration,
        height: _midiSettingsHeight,
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
          part: keyboardPart,
          height: _keyboardHeight,
          showConfiguration: _showKeyboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: keyboardNotesNotifier,
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
          part: colorboardPart,
          height: _colorboardHeight,
          showConfiguration: _showColorboardConfiguration,
          sectionColor: sectionColor,
          pressedNotesNotifier: colorboardNotesNotifier,
          distanceFromBottom: _keyboardHeight,
        ));
  }
}
