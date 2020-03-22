import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'melody_view.dart';
import 'section_list.dart';
import 'part_melodies_view.dart';
import 'colorboard.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'util.dart';
import 'ui_models.dart';
import 'dummydata.dart';

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score _score = score;
  InteractionMode _interactionMode = InteractionMode.view;
  MelodyViewDisplayMode melodyViewDisplayMode = null;
  MelodyViewMode _melodyViewMode = MelodyViewMode.score;
  bool _editingMelody = false;

  bool get editingMelody => _editingMelody;

  set editingMelody(value) {
    _editingMelody = value;
    if (value) _showMelodyView();
  }

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

  Section _currentSection = section1;
  bool _showViewOptions = false;
  bool _showKeyboard = false;
  bool _showKeyboardConfiguration = false;
  bool _showColorboard = false;
  bool _showColorboardConfiguration = false;
  Part _keyboardPart;
  Part _colorboardPart;
  bool _playing = false;

  bool get melodyViewVisible => _melodyViewSizeFactor > 0;

  double _melodyViewSizeFactor = 1.0;

  _showMelodyView() {
    if (_interactionMode == InteractionMode.edit) {
      if (melodyViewDisplayMode == MelodyViewDisplayMode.half) {
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
      selectedPart = null;
      melodyViewMode = MelodyViewMode.none;
    });
  }

  toggleMelodyViewDisplayMode() {
    setState(() {
      if (melodyViewDisplayMode == MelodyViewDisplayMode.half) {
        melodyViewDisplayMode = MelodyViewDisplayMode.full;
      } else {
        melodyViewDisplayMode = MelodyViewDisplayMode.half;
      }
      _showMelodyView();
    });
  }

  _setKeyboardPart(Part part) {
    setState(() {
      _keyboardPart = part;
    });
  }

  _setColorboardPart(Part part) {
    setState(() {
      _colorboardPart = part;
    });
  }

  get currentSection => _currentSection;

  set currentSection(Section section) {
    _currentSection = section;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
  }

  Melody selectedMelody;
  Part selectedPart;

  List<SectionList> _sectionLists = [];

  Color get sectionColor => sectionColors[_score.sections.indexOf(currentSection) % sectionColors.length];

  _selectOrDeselectMelody(Melody melody) {
    setState(() {
      if (selectedMelody != melody) {
        selectedMelody = melody;
        melodyViewMode = MelodyViewMode.melody;
        _showMelodyView();
      } else {
        selectedMelody = null;
        _hideMelodyView();
      }
    });
  }

  _selectOrDeselectPart(Part part) {
    setState(() {
      print("yay");
      if (selectedPart != part) {
        selectedPart = part;
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
        if(selectedMelody != null && ref != null && ref.melodyId == selectedMelody.id) {
          editingMelody = false;
        }
      });
    }
  }

  _setReferenceVolume(MelodyReference ref, double volume) {
    setState(() {
      ref.volume = volume;
    });
  }

  _setPartVolume(Part part, double volume) {
    setState(() {
      part.instrument.volume = volume;
    });
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
    setState(() {
      _interactionMode = InteractionMode.view;
      if (!context.isTabletOrLandscapey) {
        _showViewOptions = false;
      }
      melodyViewMode = MelodyViewMode.score;
      selectedMelody = null;
      _showMelodyView();
    });
  }

  _editMode() {
    setState(() {
      if (_interactionMode == InteractionMode.edit) {
        _selectSection(currentSection);
      } else {
        _interactionMode = InteractionMode.edit;
        _hideMelodyView();
      }
    });
  }

  _toggleViewOptions() {
    setState(() {
      _showViewOptions = !_showViewOptions;
    });
  }

  _toggleKeyboard() {
    setState(() {
      if(_showKeyboardConfiguration) {
        _showKeyboardConfiguration = false;
      } else {
        _showKeyboard = !_showKeyboard;
        if (!_showKeyboard) {
          _showKeyboardConfiguration = false;
        }
      }
    });
  }

  _toggleColorboard() {
    setState(() {
      if(_showColorboardConfiguration) {
        _showColorboardConfiguration = false;
      } else {
        _showColorboard = !_showColorboard;
        if(!_showColorboard) {
          _showColorboardConfiguration = false;
        }
      }
    });
  }

  _selectSection(Section section) {
    setState(() {
      if (currentSection == section) {
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
    (_combineSecondAndMainToolbar) ? 0 : _interactionMode == InteractionMode.edit || _showViewOptions ? 36 : 0;

  double get _colorboardHeight => _showColorboard ? 150 : 0;

  double get _keyboardHeight => _showKeyboard ? 150 : 0;

  PhotoViewScaleStateController scaleStateController;

  @override
  void initState() {
    super.initState();
    scaleStateController = PhotoViewScaleStateController();
    _keyboardPart = _score.parts.firstWhere((part) => true, orElse: () => null);
    _colorboardPart = _score.parts.firstWhere((part) => part.instrument.type == InstrumentType.harmonic, orElse: () => null);
  }

  @override
  void dispose() {
    scaleStateController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_interactionMode == InteractionMode.edit && _melodyViewSizeFactor > 0) {
      setState(() {
        _hideMelodyView();
      });
      return false;
    } else if(_showKeyboardConfiguration || _showColorboardConfiguration) {
      setState(() {
        _showKeyboardConfiguration = false;
        _showColorboardConfiguration = false;
      });
    } else if(_showKeyboard || _showColorboard) {
      setState(() {
        _showKeyboard = false;
        _showColorboard = false;
      });
    } else {
      return (await showDialog(
        context: context,
        builder: (context) =>
        new AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    if(melodyViewDisplayMode == null) {
      melodyViewDisplayMode = (context.isTablet) ? MelodyViewDisplayMode.half : MelodyViewDisplayMode.full;
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
    var top = MediaQuery.of(context).size.height - _colorboardHeight - _keyboardHeight;
    var bottom = MediaQuery.of(context).size.height;
    var right = MediaQuery.of(context).size.width;
    var left = 0.0;
    SystemChannels.platform.invokeMethod("SystemGestures.setSystemGestureExclusionRects", <Map<String, int>>[
      {"left":left.toInt(),  "top":top.toInt(), "right":10, "bottom":bottom.toInt()},
      {"left":(right - 10).toInt(),  "top":top.toInt(), "right":right.toInt(), "bottom":bottom.toInt()},
    ]);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
//            resizeToAvoidBottomPadding: false,
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
            //Column(children: [
            Flex(direction: Axis.vertical, children: <Widget>[
              _combineSecondAndMainToolbar
                ? Container(
                height: 48,
                child: Row(
                  children: <Widget>[
                    Expanded(child: createBeatScratchToolbar()),
                    Container(
                      height: 36,
                      child: AnimatedContainer(
                        duration: animationDuration,
                        width: context.isTabletOrLandscapey ||
                          _interactionMode == InteractionMode.edit ||
                          _showViewOptions
                          ? MediaQuery
                          .of(context)
                          .size
                          .width / 2
                          : 0,
                        child: createSecondToolbar()))
                  ],
                ))
                : Column(children: <Widget>[
                createBeatScratchToolbar(),
                AnimatedContainer(
                  duration: animationDuration, height: _secondToolbarHeight, child: createSecondToolbar())
              ]),
              createSectionList(),
              Expanded(child: _partsAndMelodiesAndMelodyView(context)),
              AnimatedContainer(
                curve: Curves.easeInOut,
                duration: animationDuration,
                height: _colorboardHeight,
                width: MediaQuery
                  .of(context)
                  .size
                  .width,
                color: Colors.white,
                child: Colorboard(
                  height: _colorboardHeight,
                  showConfiguration: _showColorboardConfiguration,
                  sectionColor: sectionColor,
                )
//                      Image.asset(
//                        'assets/colorboard.png',
//                        fit: BoxFit.fill,
//                      )
              ),
              AnimatedContainer(
                curve: Curves.easeInOut,
                duration: animationDuration,
                height: _keyboardHeight,
                width: MediaQuery
                  .of(context)
                  .size
                  .width,
                color: Colors.white,
                child: Image.asset(
                  'assets/piano.png',
                  fit: BoxFit.fill,
                )),
            ])
            //]),
          ]),
        )));
  }

  BeatScratchToolbar createBeatScratchToolbar() =>
    BeatScratchToolbar(
      sectionColor: sectionColor,
      viewMode: _viewMode,
      editMode: _editMode,
      toggleViewOptions: _toggleViewOptions,
      interactionMode: _interactionMode,
      playing: _playing,
      togglePlaying: () {
        setState(() {
          _playing = !_playing;
        });
      },
      toggleSectionListDisplayMode: () {},
    );

  SecondToolbar createSecondToolbar() =>
    SecondToolbar(
      toggleKeyboard: _toggleKeyboard,
      toggleKeyboardConfiguration: () {
        setState(() {
          _showKeyboard = true;
          _showKeyboardConfiguration = !_showKeyboardConfiguration;
        });
      },
      toggleColorboard: _toggleColorboard,
      toggleColorboardConfiguration: () {
        setState(() {
          _showColorboard = true;
          _showColorboardConfiguration = !_showColorboardConfiguration;
        });
      },
      showKeyboard: _showKeyboard,
      showColorboard: _showColorboard,
      interactionMode: _interactionMode,
      showViewOptions: _showViewOptions,
      showColorboardConfiguration: _showColorboardConfiguration,
      showKeyboardConfiguration: _showKeyboardConfiguration,
      sectionColor: sectionColor,
    );

  SectionList createSectionList() {
    SectionList result = SectionList(
      sectionColor: sectionColor,
      score: _score,
      setState: setState,
      scrollDirection: Axis.horizontal,
      visible: _interactionMode == InteractionMode.edit,
      currentSection: currentSection,
      selectSection: _selectSection,
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
      _colorboardHeight -
      _keyboardHeight +
      8 -
      36;
    if (melodyViewMode == MelodyViewMode.score || melodyViewMode == MelodyViewMode.none) {
      height += 36;
    }
    _handleStatusBar(context);

    return Stack(children: [
      (context.isPortrait)
        ? Column(children: [
        Expanded(child: _partMelodiesView(context)),
        AnimatedContainer(
          curve: Curves.easeInOut,
          duration: slowAnimationDuration,
          padding: EdgeInsets.only(top: (_melodyViewSizeFactor == 1) ? 0 : 5),
          height: height * _melodyViewSizeFactor,
          child: _melodyView(context))
      ])
        : Row(children: [
        AnimatedContainer(
          curve: Curves.easeInOut,
          duration: slowAnimationDuration,
          width: MediaQuery
            .of(context)
            .size
            .width * (1 - _melodyViewSizeFactor),
          child: _partMelodiesView(context)),
        Expanded(
          child: AnimatedContainer(
            duration: animationDuration,
            padding: EdgeInsets.only(left: (_melodyViewSizeFactor == 1) ? 0 : 5),
            child: _melodyView(context)))
      ])
    ]);
  }

  Widget _partMelodiesView(BuildContext context) {
    return PartMelodiesView(
      currentSection: currentSection,
      score: _score,
      sectionColor: sectionColor,
      selectMelody: _selectOrDeselectMelody,
      selectPart: _selectOrDeselectPart,
      selectedMelody: selectedMelody,
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
      colorboardPart: _colorboardPart,
      keyboardPart: _keyboardPart,
      editingMelody: editingMelody,
      hideMelodyView: _hideMelodyView,
    );
  }

  Widget _melodyView(BuildContext context) {
    return MelodyView(
      melodyViewSizeFactor: _melodyViewSizeFactor,
      melodyViewMode: melodyViewMode,
      score: _score,
      currentSection: currentSection,
      melody: selectedMelody,
      part: selectedPart,
      sectionColor: sectionColor,
      melodyViewDisplayMode: melodyViewDisplayMode,
      toggleMelodyViewDisplayMode: toggleMelodyViewDisplayMode,
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
    );
  }

  _handleStatusBar(BuildContext context) {
//    var size = MediaQuery.of(context).size;
//    if(size.height < 600) {
//      SystemChrome.setEnabledSystemUIOverlays([]);
//    } else {
//      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
//    }
  }
}

class BeatScratchToolbar extends StatelessWidget {
  final VoidCallback viewMode;
  final VoidCallback editMode;
  final VoidCallback toggleViewOptions;
  final bool playing;
  final VoidCallback togglePlaying;
  final VoidCallback toggleSectionListDisplayMode;
  final InteractionMode interactionMode;
  final Color sectionColor;

  const BeatScratchToolbar({Key key,
    this.interactionMode,
    this.viewMode,
    this.editMode,
    this.toggleViewOptions,
    this.sectionColor,
    this.playing,
    this.togglePlaying,
    this.toggleSectionListDisplayMode})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      child: Row(children: [
        Expanded(
          child: PopupMenuButton(
//                        onPressed: _doNothing,
            offset: Offset(0, MediaQuery
              .of(context)
              .size
              .height),
            onSelected: (result) {
              //setState(() {});
            },
            itemBuilder: (BuildContext context) =>
            [
              const PopupMenuItem(
                value: null,
                child: Text('score name'),
                enabled: false,
              ),
              const PopupMenuItem(
                value: null,
                child: Text('New Score'),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('Open Score...'),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('Duplicate Score...'),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('Save Score'),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('Copy Score'),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('MIDI Output Settings'),
              ),
              PopupMenuItem(
                value: null,
                child: Row(children: [
                  Checkbox(value: true, onChanged: null),
                  Expanded(child: Text('Notation UI')),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    child: SvgPicture.asset(
                      'assets/notehead_filled.svg',
                      width: 20,
                      height: 20,
                    ))
                ]),
              ),
              PopupMenuItem(
                value: null,
                child: Row(children: [
                  Checkbox(value: false, onChanged: null),
                  Expanded(child: Text('Colorblock UI')),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    child: Image.asset(
                      'assets/colorboard_vertical.png',
                      width: 20,
                      height: 20,
                    ))
                ]),
              ),
              const PopupMenuItem(
                value: null,
                child: Text('Quit BeatScratch'),
              ),
            ],
            padding: EdgeInsets.only(bottom: 10.0),
            icon: SvgPicture.asset('assets/logo.svg'))),
        Expanded(
          child: FlatButton(
            onPressed: () {
              if (interactionMode == InteractionMode.view) {
                togglePlaying();
              } else {
                toggleSectionListDisplayMode();
              }
            },
            padding: EdgeInsets.all(0.0),
            child: Icon(
              (interactionMode == InteractionMode.view)
                ? (playing ? Icons.stop : Icons.play_arrow)
                : Icons.menu,
              color: sectionColor))),
        Expanded(
          child: AnimatedContainer(
            duration: animationDuration,
            color: (interactionMode == InteractionMode.view) ? sectionColor : Colors.transparent,
            child: FlatButton(
              onPressed: (interactionMode == InteractionMode.view) ? toggleViewOptions : viewMode,
              padding: EdgeInsets.all(0.0),
              child: Icon(Icons.remove_red_eye,
                color: (interactionMode == InteractionMode.view) ? Colors.white : sectionColor)))),
        Expanded(
          child: AnimatedContainer(
            duration: animationDuration,
            color: (interactionMode == InteractionMode.edit) ? sectionColor : Colors.transparent,
            child: FlatButton(
              onPressed: editMode,
              padding: EdgeInsets.all(0.0),
              child: Icon(Icons.edit,
                color: (interactionMode == InteractionMode.edit) ? Colors.white : sectionColor))))
      ]));
  }
}

class SecondToolbar extends StatelessWidget {
  final VoidCallback toggleKeyboard;
  final VoidCallback toggleColorboard;
  final VoidCallback toggleKeyboardConfiguration;
  final VoidCallback toggleColorboardConfiguration;
  final bool showKeyboard;
  final bool showKeyboardConfiguration;
  final bool showColorboard;
  final bool showColorboardConfiguration;
  final InteractionMode interactionMode;
  final bool showViewOptions;
  final Color sectionColor;

  const SecondToolbar({Key key,
    this.toggleKeyboard,
    this.toggleColorboard,
    this.showKeyboard,
    this.showColorboard,
    this.interactionMode,
    this.showViewOptions,
    this.showKeyboardConfiguration,
    this.showColorboardConfiguration, this.toggleKeyboardConfiguration, this.toggleColorboardConfiguration, this.sectionColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery
      .of(context)
      .size
      .width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    return Row(children: [
      AnimatedContainer(
        width: (interactionMode == InteractionMode.edit) ? width / 5 : 0,
        duration: animationDuration,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: RaisedButton(child: Image.asset('assets/play.png'), onPressed: () => {}))),
      AnimatedContainer(
        width: (interactionMode == InteractionMode.edit) ? width / 5 : 0,
        duration: animationDuration,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: RaisedButton(
            child: Image.asset('assets/stop.png'),
            onPressed: () => {},
          ))),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: RaisedButton(
            padding: EdgeInsets.only(top: 7, bottom: 5),
            child: Stack(children: [
              SvgPicture.asset('assets/metronome.svg'),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(padding: EdgeInsets.only(right: 3.5), child: Text('123')),
              )
            ]),
            onPressed: () => {},
          ))),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: RaisedButton(
            child: Image.asset('assets/piano.png'),
            onPressed: toggleKeyboard,
            onLongPress: toggleKeyboardConfiguration,
            color: (showKeyboardConfiguration) ? sectionColor : (showKeyboard) ? Colors.white : Colors.grey,
          ))),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: RaisedButton(
            child: Image.asset('assets/colorboard.png'),
            onPressed: toggleColorboard,
            onLongPress: toggleColorboardConfiguration,
            color: (showColorboardConfiguration) ? sectionColor : (showColorboard) ? Colors.white : Colors.grey,
          )))
    ]);
  }
}
