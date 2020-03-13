import 'dart:collection';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_view/photo_view.dart';
import 'package:quiver/collection.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'melodybeat.dart';
import 'expanded_section.dart';
import 'melody_view.dart';
import 'section_list.dart';
import 'part_melodies_view.dart';
import 'colorboard.dart';
import 'dart:math';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'util.dart';
import 'ui_models.dart';

void main() => runApp(MyApp());

const Color foo = Color.fromRGBO(0xF9, 0x37, 0x30, .1);

const Map<int, Color> swatch = {
  //createSwatch(0xF9, 0x37, 0x30);
  50: Color.fromRGBO(0xF9, 0x37, 0x30, .1),
  100: Color.fromRGBO(0xF9, 0x37, 0x30, .2),
  200: Color.fromRGBO(0xF9, 0x37, 0x30, .3),
  300: Color.fromRGBO(0xF9, 0x37, 0x30, .4),
  400: Color.fromRGBO(0xF9, 0x37, 0x30, .5),
  500: Color.fromRGBO(0xF9, 0x37, 0x30, .6),
  600: Color.fromRGBO(0xF9, 0x37, 0x30, .7),
  700: Color.fromRGBO(0xF9, 0x37, 0x30, .8),
  800: Color.fromRGBO(0xF9, 0x37, 0x30, .9),
  900: Color.fromRGBO(0xF9, 0x37, 0x30, 1),
};

var section1 = Section()
  ..id = uuid.v4()
  ..name = "Section 1";
var score = Score()
  ..parts.addAll([
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Drums"
        ..volume = 0.5
        ..type = InstrumentType.drum)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Piano"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Bass"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Muted Electric Jazz Guitar 1"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
    Part()
      ..id = uuid.v4()
      ..instrument = (Instrument()
        ..name = "Part 5"
        ..volume = 0.5
        ..type = InstrumentType.harmonic)
      ..melodies.addAll([
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
        Melody()..id = uuid.v4(),
      ]),
  ])
  ..sections.addAll([
    section1,
    Section()
      ..id = uuid.v4()
      ..name = "Section 2",
    Section()
      ..id = uuid.v4()
      ..name = "Section 3",
    Section()
      ..id = uuid.v4()
      ..name = "Section 4",
    Section()
      ..id = uuid.v4()
      ..name = "Section 5"
  ]);

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

enum MelodyViewDisplayMode { half, full }

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Score _score = score;
  InteractionMode _interactionMode = InteractionMode.view;
  Section _currentSection = section1;
  int _counter = 20;
  bool _showViewOptions = false;
  bool _showKeyboard = false;
  bool _showColorboard = false;
  Part _keyboardPart = null;
  Part _colorboardPart = null;

  get showMelodyView => _melodyViewSizeFactor > 0;
  double _melodyViewSizeFactor = 1.0;
  MelodyViewDisplayMode _melodyViewDisplayMode = MelodyViewDisplayMode.half;
  MelodyViewMode _melodyViewMode = MelodyViewMode.score;

  get melodyViewDisplayMode => _melodyViewDisplayMode;

  set melodyViewDisplayMode(value) {
    _melodyViewDisplayMode = value;
    if (_melodyViewSizeFactor > 0) {
      if (value == MelodyViewDisplayMode.half) {
        _melodyViewSizeFactor = 0.5;
      } else {
        _melodyViewSizeFactor = 1;
      }
    }
  }

  toggleMelodyViewDisplayMode(value) {
    setState(() {
      if (melodyViewDisplayMode == MelodyViewDisplayMode.half) {
        melodyViewDisplayMode = MelodyViewDisplayMode.full;
      } else {
        melodyViewDisplayMode = MelodyViewDisplayMode.half;
      }
    });
  }

  _showMelodyView() {
    if (melodyViewDisplayMode == MelodyViewDisplayMode.half) {
      _melodyViewSizeFactor = 0.5;
    } else {
      _melodyViewSizeFactor = 1;
    }
  }

  _hideMelodyView() {
    _melodyViewSizeFactor = 0;
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

  Melody _selectedMelody;
  get selectedMelody => _selectedMelody;
  set selectedMelody(Melody melody) {
    _selectedMelody = melody;
    if (_interactionMode == InteractionMode.edit) {
      if (melody == null) {
        _melodyViewMode = MelodyViewMode.section;
        _melodyViewSizeFactor = 0;
      } else {
        _melodyViewMode = MelodyViewMode.melody;
        _melodyViewSizeFactor = 0.5;
      }
    }
  }

  Part _selectedPart;
  get selectedPart => _selectedPart;
  set selectedPart(Part part) {
    _selectedPart = part;
    if (_interactionMode == InteractionMode.edit) {
      if (part == null) {
        _melodyViewSizeFactor = 0;
      } else {
        _melodyViewSizeFactor = 0.5;
      }
    }
  }

  Color get sectionColor => sectionColors[_score.sections.indexOf(currentSection) % sectionColors.length];

  _selectOrDeselectMelody(Melody melody) {
    setState(() {
      if (selectedMelody != melody) {
        selectedMelody = melody;
      } else {
        selectedMelody = null;
      }
    });
  }

  _selectOrDeselectPart(Part part) {
    setState(() {
//      if (selectedMelody != melody) {
//        selectedMelody = melody;
//      } else {
//        selectedMelody = null;
//      }
    });
  }

  _doNothing() {}

  _viewMode() {
    setState(() {
      _interactionMode = InteractionMode.view;
      if (MediaQuery.of(context).size.width < 500) {
        _showViewOptions = false;
      }
      _melodyViewMode = MelodyViewMode.score;
      melodyViewDisplayMode = MelodyViewDisplayMode.full;
      _melodyViewSizeFactor = 1;
      selectedMelody = null;
    });
  }

  _editMode() {
    setState(() {
      _interactionMode = InteractionMode.edit;
      _melodyViewMode = MelodyViewMode.section;
      _melodyViewSizeFactor = 0.0;
    });
  }

  _toggleViewOptions() {
    setState(() {
      _showViewOptions = !_showViewOptions;
    });
  }

  _toggleKeyboard() {
    setState(() {
      _showKeyboard = !_showKeyboard;
    });
  }

  _toggleColorboard() {
    setState(() {
      _showColorboard = !_showColorboard;
    });
  }

  _selectSection(Section section) {
    setState(() {
      currentSection = section;
    });
  }

  bool get _combineSecondAndMainToolbar => context.isTabletOrLandscape;

  double get _secondToolbarHeight =>
      (_combineSecondAndMainToolbar) ? 0 : _interactionMode == InteractionMode.edit || _showViewOptions ? 36 : 0;

  double get _colorboardHeight => _showColorboard ? 150 : 0;

  double get _keyboardHeight => _showKeyboard ? 150 : 0;

  PhotoViewScaleStateController scaleStateController;

  @override
  void initState() {
    super.initState();
    scaleStateController = PhotoViewScaleStateController();
    _keyboardPart = _score.parts.firstWhere((part) => true);
    _colorboardPart = _score.parts.firstWhere((part) => part.instrument.type == InstrumentType.harmonic);
  }

  @override
  void dispose() {
    scaleStateController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (selectedMelody != null) {
      setState(() {
        selectedMelody = null;
      });
      return false;
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: sectionColor,
    ));
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
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
                              Expanded(
                                  child: BeatScratchToolbar(
                                      sectionColor: sectionColor,
                                      viewMode: _viewMode,
                                      editMode: _editMode,
                                      toggleViewOptions: _toggleViewOptions,
                                      interactionMode: _interactionMode)),
                              Container(
                                  height: 36,
                                  child: AnimatedContainer(
                                      duration: animationDuration,
                                      width: context.isTabletOrLandscape ||
                                              _interactionMode == InteractionMode.edit ||
                                              _showViewOptions
                                          ? MediaQuery.of(context).size.width / 2
                                          : 0,
                                      child: SecondToolbar(
                                        toggleKeyboard: _toggleKeyboard,
                                        toggleColorboard: _toggleColorboard,
                                        showKeyboard: _showKeyboard,
                                        showColorboard: _showColorboard,
                                        interactionMode: _interactionMode,
                                        showViewOptions: _showViewOptions,
                                      )))
                            ],
                          ))
                      : Column(children: <Widget>[
                          BeatScratchToolbar(
                              sectionColor: sectionColor,
                              viewMode: _viewMode,
                              editMode: _editMode,
                              toggleViewOptions: _toggleViewOptions,
                              interactionMode: _interactionMode),
                          AnimatedContainer(
                              duration: animationDuration,
                              height: _secondToolbarHeight,
                              child: SecondToolbar(
                                toggleKeyboard: _toggleKeyboard,
                                toggleColorboard: _toggleColorboard,
                                showKeyboard: _showKeyboard,
                                showColorboard: _showColorboard,
                                interactionMode: _interactionMode,
                                showViewOptions: _showViewOptions,
                              ))
                        ]),
                  SectionList(
                    sectionColor: sectionColor,
                    score: _score,
                    setState: setState,
                    scrollDirection: Axis.horizontal,
                    visible: _interactionMode == InteractionMode.edit,
                    currentSection: currentSection,
                    selectSection: _selectSection,
                  ),
                  Expanded(child: _partsAndMelodiesAndMelodyView(context)),
                  AnimatedContainer(
                      duration: animationDuration,
                      height: _colorboardHeight,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.white,
                      child: Colorboard()
//                      Image.asset(
//                        'assets/colorboard.png',
//                        fit: BoxFit.fill,
//                      )
                      ),
                  AnimatedContainer(
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

  Widget _partsAndMelodiesAndMelodyView(BuildContext context) {
    var data = MediaQuery.of(context);
    double height = data.size.height -
        data.padding.top -
        kToolbarHeight -
        _secondToolbarHeight -
        _colorboardHeight -
        _keyboardHeight +
        8;
    _handleStatusBar(context);

    return Stack(children: [
      (MediaQuery.of(context).size.width <= MediaQuery.of(context).size.height)
          ? Column(children: [
              Expanded(
                  child: PartMelodiesView(
                currentSection: currentSection,
                score: _score,
                sectionColor: sectionColor,
                setState: setState,
                selectMelody: _selectOrDeselectMelody,
                selectPart: _selectOrDeselectPart,
                selectedMelody: selectedMelody,
                setColorboardPart: _setColorboardPart,
                setKeyboardPart: _setKeyboardPart,
                colorboardPart: _colorboardPart,
                keyboardPart: _keyboardPart,
              )),
              AnimatedContainer(
                  duration: animationDuration,
                  height: height * _melodyViewSizeFactor,
                  child: _melodyView(context))
            ])
          : Row(children: [
              AnimatedContainer(
                  duration: animationDuration,
                  width: MediaQuery.of(context).size.width * (1 - _melodyViewSizeFactor),
                  child: PartMelodiesView(
                    score: _score,
                    currentSection: currentSection,
                    sectionColor: sectionColor,
                    setState: setState,
                    selectMelody: _selectOrDeselectMelody,
                    selectPart: _selectOrDeselectPart,
                    selectedMelody: selectedMelody,
                    setColorboardPart: _setColorboardPart,
                    setKeyboardPart: _setKeyboardPart,
                    colorboardPart: _colorboardPart,
                    keyboardPart: _keyboardPart,
                  )),
              Expanded(child: _melodyView(context))
            ])
    ]);
  }
  Widget _melodyView(BuildContext context) {
    return MelodyView(
      melodyViewSizeFactor: _melodyViewSizeFactor,
      melodyViewMode: _melodyViewMode,
      score: _score,
      currentSection: currentSection,
      melody: selectedMelody,
      part: selectedPart,);
  }

  _handleStatusBar(BuildContext context) {
//    var size = MediaQuery.of(context).size;
//    if(size.width > size.height && size.height < 600) {
//      SystemChrome.setEnabledSystemUIOverlays([]);
//    }
  }
}


class BeatScratchToolbar extends StatelessWidget {
  final VoidCallback viewMode;
  final VoidCallback editMode;
  final VoidCallback toggleViewOptions;
  final InteractionMode interactionMode;
  final Color sectionColor;

  const BeatScratchToolbar(
      {Key key, this.interactionMode, this.viewMode, this.editMode, this.toggleViewOptions, this.sectionColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 48,
        child: Row(children: [
          Expanded(
              child: PopupMenuButton(
//                        onPressed: _doNothing,
                  offset: Offset(0, MediaQuery.of(context).size.height),
                  onSelected: (result) {
                    //setState(() {});
                  },
                  itemBuilder: (BuildContext context) => [
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
                        Expanded(child:Text('Notation UI')),
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
                            Expanded(child:Text('Colorblock UI')),
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
                  onPressed: () => {},
                  padding: EdgeInsets.all(0.0),
                  child: Icon((interactionMode == InteractionMode.view) ? Icons.play_arrow : Icons.menu,
                      color: sectionColor))),
          Expanded(
              child: (interactionMode == InteractionMode.view)
                  ? RaisedButton(
                      color: sectionColor,
                      onPressed: toggleViewOptions,
                      padding: EdgeInsets.all(0.0),
                      child: Icon(Icons.remove_red_eye, color: Colors.white))
                  : FlatButton(
                      onPressed: viewMode,
                      padding: EdgeInsets.all(0.0),
                      child: Icon(Icons.remove_red_eye, color: sectionColor))),
          Expanded(
              child: (interactionMode == InteractionMode.edit)
                  ? RaisedButton(
                      color: sectionColor,
                      onPressed: editMode,
                      padding: EdgeInsets.all(0.0),
                      child: Icon(Icons.edit, color: Colors.white))
                  : FlatButton(
                      onPressed: editMode, padding: EdgeInsets.all(0.0), child: Icon(Icons.edit, color: sectionColor)))
        ]));
  }
}

class SecondToolbar extends StatelessWidget {
  final VoidCallback toggleKeyboard;
  final VoidCallback toggleColorboard;
  final bool showKeyboard;
  final bool showColorboard;
  final InteractionMode interactionMode;
  final bool showViewOptions;

  const SecondToolbar(
      {Key key,
      this.toggleKeyboard,
      this.toggleColorboard,
      this.showKeyboard,
      this.showColorboard,
      this.interactionMode,
      this.showViewOptions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscape) {
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
                color: (showKeyboard) ? Colors.white : Colors.grey,
              ))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                child: Image.asset('assets/colorboard.png'),
                onPressed: toggleColorboard,
                color: (showColorboard) ? Colors.white : Colors.grey,
              )))
    ]);
  }
}
