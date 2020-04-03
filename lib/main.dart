import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/platform_svg/platform_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
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

Score score = defaultScore();
Section section1 = score.sections[0];

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score _score = score;
  InteractionMode interactionMode = InteractionMode.view;
  MelodyViewDisplayMode melodyViewDisplayMode;
  
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
  set editingMelody(value) {
    _editingMelody = value;
    if (value) _showMelodyView();
  }


  Section _currentSection = section1;
  bool showViewOptions = false;
  bool showKeyboard = false;
  bool _showKeyboardConfiguration = false;
  bool showColorboard = false;
  bool _showColorboardConfiguration = false;
  Part keyboardPart;
  Part colorboardPart;
  bool playing = false;

  bool get melodyViewVisible => _melodyViewSizeFactor > 0;

  double _melodyViewSizeFactor = 1.0;

  _showMelodyView() {
    if (interactionMode == InteractionMode.edit) {
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
        if (selectedMelody != null && ref != null && ref.melodyId == selectedMelody.id) {
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
      interactionMode = InteractionMode.view;
      if (!context.isTabletOrLandscapey) {
        showViewOptions = false;
      }
      melodyViewMode = MelodyViewMode.score;
      selectedMelody = null;
      _showMelodyView();
    });
  }

  _editMode() {
    setState(() {
      if (interactionMode == InteractionMode.edit) {
        _selectSection(currentSection);
      } else {
        interactionMode = InteractionMode.edit;
        _hideMelodyView();
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
      (_combineSecondAndMainToolbar) ? 0 : interactionMode == InteractionMode.edit || showViewOptions ? 36 : 0;

  double get _colorboardHeight => showColorboard ? 150 : 0;

  double get _keyboardHeight => showKeyboard ? 150 : 0;

  PhotoViewScaleStateController scaleStateController;

  bool verticalSectionList = false;

  double get verticalSectionListWidth => interactionMode == InteractionMode.edit && verticalSectionList ? 150 : 0;

  double get horizontalSectionListHeight => interactionMode == InteractionMode.edit && !verticalSectionList ? 36 : 0;

  @override
  void initState() {
    super.initState();
    scaleStateController = PhotoViewScaleStateController();
    keyboardPart = _score.parts.firstWhere((part) => true, orElse: () => null);
    colorboardPart =
        _score.parts.firstWhere((part) => part.instrument.type == InstrumentType.harmonic, orElse: () => null);
  }

  @override
  void dispose() {
    scaleStateController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (interactionMode == InteractionMode.edit && _melodyViewSizeFactor > 0) {
      setState(() {
        _hideMelodyView();
      });
      return false;
    } else if (_showKeyboardConfiguration || _showColorboardConfiguration) {
      setState(() {
        _showKeyboardConfiguration = false;
        _showColorboardConfiguration = false;
      });
    } else if (showKeyboard || showColorboard) {
      setState(() {
        showKeyboard = false;
        showColorboard = false;
      });
    } else if (interactionMode == InteractionMode.edit) {
      _viewMode();
    } else {
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
  
  _confirmExit() {
    
  }

  bool showWebWarning = kIsWeb;

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
    if (melodyViewDisplayMode == null) {
      melodyViewDisplayMode = (context.isTablet) ? MelodyViewDisplayMode.half : MelodyViewDisplayMode.full;
      verticalSectionList = context.isTablet;
    }
    if (context.isLandscape) {
      SystemChrome.setEnabledSystemUIOverlays([]);
    } else {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
    var top = MediaQuery.of(context).size.height - _colorboardHeight - _keyboardHeight;
    var bottom = MediaQuery.of(context).size.height;
    var right = MediaQuery.of(context).size.width;
    var left = 0.0;
    SystemChannels.platform.invokeMethod("SystemGestures.setSystemGestureExclusionRects", <Map<String, int>>[
      {"left": left.toInt(), "top": top.toInt(), "right": 10, "bottom": bottom.toInt()},
      {"left": (right - 10).toInt(), "top": top.toInt(), "right": right.toInt(), "bottom": bottom.toInt()},
    ]);
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
                  AnimatedContainer(
                      duration: animationDuration,
                      height: showWebWarning ? 60 : 0,
                      color: Color(0xFF212121),
                      child: Row(children: [
                        Padding(
                            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                            child: Column(children: [
                              Align(
                                  child: Text("BeatScratch",
                                      style:
                                          TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
                              Align(
                                  child: Row(children: [
                                Text("Web",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                Text("Preview",
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w100)),
                              ])),
                            ])),
                        Expanded(
                            child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                                child: Text(
                                    "is pre-Alpha software. macOS and iOS ports are coming, and the Android app is on the Play Store.",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100)))),
                        FlatButton(
                            onPressed: () {
                              _launchURL("https://play.google.com/store/apps/details?id=com.jonlatane.beatpad");
                            },
                            padding: EdgeInsets.all(0),
                            child: Image.asset("assets/play_en_badge_web_generic.png")),
                        Container(
                            width: 120,
                            height: 40,
                            padding: EdgeInsets.only(right: 5),
                            child: FlatButton(
                                color: Colors.white,
                                onPressed: () {
                                  _launchURL("https://beatscratch.io/assets/BeatFlutter.zip");
                                },
                                padding: EdgeInsets.all(0),
                                child: Stack(children:[
                                  Align(alignment: Alignment.bottomRight, child:
                                  Padding(padding: EdgeInsets.only(right:5, bottom:2), child:
                                  Text("macOS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)))),
                                  Align(alignment: Alignment.topLeft, child:
                                  Padding(padding: EdgeInsets.only(top:2, left:5), child:
                                  Text("Download For", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400))))
                                ]))),
                        Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: RaisedButton(
                                onPressed: () {
                                  setState(() {
                                    showWebWarning = false;
                                  });
                                },
                                child: Text("OK!"))),
                      ])),
//            Flex(direction: Axis.vertical, children: <Widget>[
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
                                              interactionMode == InteractionMode.edit ||
                                              showViewOptions
                                          ? MediaQuery.of(context).size.width / 2
                                          : 0,
                                      child: createSecondToolbar()))
                            ],
                          ))
                      : Column(children: <Widget>[
                          createBeatScratchToolbar(),
                          AnimatedContainer(
                              duration: animationDuration, height: _secondToolbarHeight, child: createSecondToolbar())
                        ]),
                  AnimatedContainer(
                      duration: animationDuration,
                      curve: Curves.easeInOut,
                      height: horizontalSectionListHeight,
                      child: createSectionList(scrollDirection: Axis.horizontal)),
                  Expanded(
                      child: Row(children: [
                    AnimatedContainer(
                        duration: animationDuration,
                        curve: Curves.easeInOut,
                        width: verticalSectionListWidth,
                        child: createSectionList(scrollDirection: Axis.vertical)),
                    Expanded(child: _partsAndMelodiesAndMelodyView(context))
                  ])),
                  AnimatedContainer(
                      curve: Curves.easeInOut,
                      duration: animationDuration,
                      height: _colorboardHeight,
                      width: MediaQuery.of(context).size.width,
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
                      width: MediaQuery.of(context).size.width,
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

  BeatScratchToolbar createBeatScratchToolbar() => BeatScratchToolbar(
        sectionColor: sectionColor,
        viewMode: _viewMode,
        editMode: _editMode,
        toggleViewOptions: _toggleViewOptions,
        interactionMode: interactionMode,
        playing: playing,
        togglePlaying: () {
          setState(() {
            playing = !playing;
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
            if(keyboardPart != null) {
              showKeyboard = true;
              _showKeyboardConfiguration = true;
            }
            if(colorboardPart != null) {
              showColorboard = true;
              _showColorboardConfiguration = true;
            }
          });
        },
      );

  SecondToolbar createSecondToolbar() => SecondToolbar(
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
        horizontalSectionListHeight;
    double width = data.size.width - verticalSectionListWidth;
//    if (melodyViewMode == MelodyViewMode.score || melodyViewMode == MelodyViewMode.none) {
//      height += 36;
//    }
    _handleStatusBar(context);

    return Stack(children: [
      (context.isPortrait)
          ? Column(children: [
              Expanded(child: _partMelodiesView(context, width)),
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
                  width: width * (1 - _melodyViewSizeFactor),
                  child: _partMelodiesView(context, width)),
              Expanded(
                  child: AnimatedContainer(
                      duration: animationDuration,
                      padding: EdgeInsets.only(left: (_melodyViewSizeFactor == 1) ? 0 : 5),
                      child: _melodyView(context)))
            ])
    ]);
  }

  Widget _partMelodiesView(BuildContext context, double availableWidth) {
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
      colorboardPart: colorboardPart,
      keyboardPart: keyboardPart,
      editingMelody: editingMelody,
      hideMelodyView: _hideMelodyView,
      availableWidth: availableWidth,
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
      renderingMode: renderingMode,
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
      setKeyboardPart: _setKeyboardPart,
      setColorboardPart: _setColorboardPart,
      colorboardPart: colorboardPart,
      keyboardPart: keyboardPart,
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
          score.parts.remove(part);
        });
      },
      deleteMelody: (melody) {
        setState(() {
          if (melody == this.selectedMelody) {
            Part part = this._score.parts.firstWhere((part) => part.melodies.contains(melody));
            int index = part.melodies.indexOf(melody);
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
            part.melodies.remove(melody);
          });
          score.sections.forEach((section) {
            section.melodies.removeWhere((ref) => ref.melodyId == melody.id);
          });
        });
      },
      deleteSection: (section) {
        setState(() {
          if (section == this.currentSection) {
            int index = this._score.sections.indexOf(section);
            if (index > 0) {
              index = index - 1;
            } else {
              index = index + 1;
            }
            this.currentSection = this._score.sections[index];
          }
          score.sections.remove(section);
        });
      },
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
