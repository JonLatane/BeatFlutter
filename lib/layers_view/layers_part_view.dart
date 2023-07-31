import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart' as frl;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_list_plus/animated_list_plus.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../util/proto_utils.dart';
import '../util/util.dart';
import '../widget/beats_badge.dart';
import '../widget/my_buttons.dart';
import 'melody_menu_browser.dart';
import 'melody_reference_view.dart';

class LayersPartView extends StatefulWidget {
  static const double minColumnWidth = MelodyReferenceView.minColumnWidth;
  static const double maxColumnWidth = MelodyReferenceView.maxColumnWidth;
  static const double columnWidthIncrement =
      MelodyReferenceView.columnWidthIncrement;
  static const double columnWidthMicroIncrement =
      MelodyReferenceView.columnWidthMicroIncrement;

  final Score score;
  final Axis scrollDirection;
  final Function(Melody) selectMelody;
  final VoidCallback toggleEditingMelody;
  final VoidCallback hideMelodyView;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Function(Part, double) setPartVolume;
  final Function(Part) selectPart;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;
  final Part selectedPart;
  final Part colorboardPart;
  final Part keyboardPart;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Function(Part) removePart;
  final bool editingMelody;
  final Part part;
  final bool enableColorboard;
  final bool showBeatCounts;
  final double width, height;
  final bool showMediumDetails;
  final bool showHighDetails;
  final bool autoScroll;

  List<Melody> get _items {
    return part.melodies;
  }

  LayersPartView({
    this.score,
    this.scrollDirection,
    this.part,
    this.sectionColor,
    this.currentSection,
    this.selectedMelody,
    this.selectMelody,
    this.colorboardPart,
    this.keyboardPart,
    this.setKeyboardPart,
    this.setColorboardPart,
    this.selectPart,
    this.toggleMelodyReference,
    this.setReferenceVolume,
    this.setPartVolume,
    this.editingMelody,
    this.toggleEditingMelody,
    this.hideMelodyView,
    this.removePart,
    this.selectedPart,
    this.enableColorboard,
    this.showBeatCounts,
    this.height,
    this.showMediumDetails,
    this.autoScroll,
    this.showHighDetails,
    this.width,
  });

  @override
  _LayersPartViewState createState() {
    return new _LayersPartViewState();
  }
}

MelodyInterpretationType _interpretationType(InstrumentType instrumentType) {
  if (instrumentType == InstrumentType.drum) {
    return MelodyInterpretationType.fixed_nonadaptive;
  } else {
    return MelodyInterpretationType.fixed;
  }
}

class _LayersPartViewState extends State<LayersPartView> {
  get _items => widget._items;

  Part get part => widget.part;

  get setColorboardPart => widget.setColorboardPart;

  get setKeyboardPart => widget.setKeyboardPart;

  get colorboardPart => widget.colorboardPart;

  get keyboardPart => widget.keyboardPart;

  get selectPart => widget.selectPart;

  get setPartVolume => widget.setPartVolume;

  Section get currentSection => widget.currentSection;

  Melody get selectedMelody => widget.selectedMelody;

  get setReferenceVolume => widget.setReferenceVolume;

  get toggleMelodyReference => widget.toggleMelodyReference;

  get selectMelody => widget.selectMelody;

  get sectionColor => widget.sectionColor;

  get editingMelody => widget.editingMelody;

  set editingMelody(value) {
    if (editingMelody != value) {
      toggleEditingMelody();
    }
  }

  get toggleEditingMelody => widget.toggleEditingMelody;

  get hideMelodyView => widget.hideMelodyView;
  ScrollController scrollController;

  int _indexOfKey(Key key) {
    return widget._items.indexWhere((Melody melody) => Key(melody.id) == key);
  }

  bool _reorderCallback(Key item, Key newPosition) {
    int draggingIndex = _indexOfKey(item);
    int newPositionIndex = _indexOfKey(newPosition);

    // Uncomment to allow only even target reorder possition
    // if (newPositionIndex % 2 == 1)
    //   return false;

    final draggedItem = widget._items[draggingIndex];
    setState(() {
      debugPrint("Reordering $item -> $newPosition");
      widget._items.removeAt(draggingIndex);
      _items.insert(newPositionIndex, draggedItem);
    });
    return true;
  }

  _reorderDone(Key item) {
    final draggedItem = _items[_indexOfKey(item)];
    debugPrint("Reordering finished for ${draggedItem.id}}");
  }

  bool get scrollControllerIsNearTop =>
      scrollController.hasClients &&
      scrollController.offset < (widget.showMediumDetails ? 150 : 165);
  DateTime _lastScrollTime;
  setScrollToTopTimeout() {
    final v = DateTime.now();
    Future.delayed(Duration(seconds: 3), () {
      if (_lastScrollTime == v && scrollControllerIsNearTop) {
        scrollToTop();
      }
    });
    _lastScrollTime = v;
  }

  /// Animates scrolling to the offset at which [melodyIndex] is at the top of the view
  requestScrollToTop(int melodyIndex) {
    if (melodyIndex < 0) {
      scrollController.animateTo(0,
          duration: Duration(milliseconds: 1000), curve: Curves.ease);
      return;
    }
    int activeMelodyRefsBeforeIndex = 0; //currentSection.referenceTo(melody)
    range(0, melodyIndex).forEach((i) {
      final checkMelody = part.melodies[i];
      if (currentSection.referenceTo(checkMelody).playbackType !=
          MelodyReference_PlaybackType.disabled) {
        activeMelodyRefsBeforeIndex += 1;
      }
    });
    int inactiveMelodyRefsBeforeIndex =
        melodyIndex - activeMelodyRefsBeforeIndex;

    final double baseHeight = 73.23;
    final double enabledToggleHeight = 34.77;
    final double volumeSliderHeight = 41.0;
    double melodyStartPoint = 80;
    double activeMelodyRefHeight = baseHeight,
        inactiveMelodyRefHeight = baseHeight;
    if (widget.showMediumDetails) {
      activeMelodyRefHeight += enabledToggleHeight + volumeSliderHeight;
      inactiveMelodyRefHeight += enabledToggleHeight;
      melodyStartPoint = 163;
      if (widget.showHighDetails) {
        activeMelodyRefHeight += 80;
        inactiveMelodyRefHeight += 80;
      }
    }

    scrollController.animateTo(
        melodyStartPoint +
            (activeMelodyRefHeight * activeMelodyRefsBeforeIndex) +
            (inactiveMelodyRefHeight * inactiveMelodyRefsBeforeIndex),
        duration: Duration(milliseconds: 1000),
        curve: Curves.ease);
  }

  scrollToTop() {
    if (widget.part.melodies.isEmpty) {
      requestScrollToTop(-1);
    } else {
      requestScrollToTop(0);
    }
  }

  tryScrollToTop() {
    if (scrollController.hasClients) {
      scrollToTop();
    } else {
      Future.delayed(animationDuration, () => tryScrollToTop());
    }
  }

  @override
  initState() {
    super.initState();
    scrollController = ScrollController()..addListener(setScrollToTopTimeout);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScrollToTop();
    });
  }

  @override
  dispose() {
    scrollController.dispose();
    super.dispose();
  }

  List<int> get newMelodyBeatCounts => [
        currentSection.beatCount,
        2 * currentSection.meter.defaultBeatsPerMeasure,
        currentSection.meter.defaultBeatsPerMeasure,
        2,
        1,
      ];
  int newMelodyBeatCountIndex = 0;

  String lastSelectedMelodyId;
  double prevWidth;

  @override
  Widget build(BuildContext context) {
    String partName;
    if (part.instrument.type == InstrumentType.drum) {
      partName = "Drums";
    } else {
      partName = part.midiName;
    }
    prevWidth = widget.width;
    bool isSelectedPart = widget.selectedPart == part;
    Color backgroundColor, textColor;
    if (part.instrument.type == InstrumentType.drum) {
      backgroundColor = isSelectedPart ? Colors.white : Colors.brown;
      textColor = isSelectedPart ? Colors.brown : Colors.white;
    } else {
      backgroundColor = isSelectedPart ? Colors.white : Colors.grey;
      textColor = isSelectedPart ? Colors.grey : Colors.white;
    }
    if (lastSelectedMelodyId != null &&
        selectedMelody != null &&
        lastSelectedMelodyId != selectedMelody.id &&
        widget.autoScroll) {
      int indexOfMelody =
          part.melodies.indexWhere((m) => m.id == selectedMelody?.id);
      if (indexOfMelody >= 0) {
        requestScrollToTop(indexOfMelody);
      }
    }
    lastSelectedMelodyId = selectedMelody?.id;
    setScrollToTopTimeout();
    return frl.ReorderableList(
        onReorder: this._reorderCallback,
        onReorderDone: this._reorderDone,
        child: CustomScrollView(
          // cacheExtent: 3000,
//          key: Key("MelodyScroller"),
          controller: scrollController,
          slivers: <Widget>[
            MediaQuery.removePadding(
                context: context,
                removeRight: true,
                child: SliverAppBar(
                  titleSpacing: 0,
                  excludeHeaderSemantics: true,
                  leading: Container(),
                  backgroundColor: backgroundColor,
                  actions: <Widget>[
                    IgnorePointer(
                      child: AnimatedContainer(
                          duration: animationDuration,
                          width: (keyboardPart == part) ? 24 : 0,
                          height: 24,
                          child: Opacity(
                              opacity: 0.5,
                              child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Image.asset('assets/piano.png')))),
                    ),
                    IgnorePointer(
                      child: AnimatedContainer(
                          duration: animationDuration,
                          width: (widget.enableColorboard &&
                                  colorboardPart == part)
                              ? 24
                              : 0,
                          height: 24,
                          child: Opacity(
                              opacity: 0.5,
                              child: Image.asset('assets/colorboard.png'))),
                    ),
                    Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Handle(
                            key: Key("handle-part-${part.id}"),
                            delay: Duration.zero,
                            child: Icon(Icons.reorder, color: textColor))),
                  ],
                  pinned: true,
                  expandedHeight: 100.0,
                  flexibleSpace: FlexibleSpaceBar(
//                stretchModes: [StretchMode.fadeTitle],
                      centerTitle: false,
                      titlePadding: EdgeInsets.all(0),
//                titlePadding: EdgeInsets.only(left: 8, bottom: 15),
//                titlePadding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                      title: MyFlatButton(
                          onPressed: () {
                            selectPart(part);
                            if (widget.autoScroll) {
                              scrollToTop();
                            }
                          },
                          child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                  padding: EdgeInsets.only(
                                      bottom: 0, top: 30, left: 7, right: 7),
                                  child: Text(
                                    partName,
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ))))),
                )),

            SliverAppBar(
              leading: Container(),
              backgroundColor: backgroundColor,
              floating: true,
              pinned: false,
              toolbarHeight: widget.showMediumDetails ? 50.0 : 0,
              expandedHeight: widget.showMediumDetails ? 50.0 : 0,
              flexibleSpace: MySlider(
                  value: max(0.0, min(1.0, part.instrument.volume)),
                  activeColor: textColor,
                  onChanged: (value) {
                    setScrollToTopTimeout();
                    setPartVolume(part, value);
                  }),
            ),
            buildAddAndRecordButton(backgroundColor, textColor),
            SliverPadding(
                padding: EdgeInsets.only(bottom: 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return MelodyReferenceView(
                          melody: _items[index],
                          sectionColor: sectionColor,
                          currentSection: currentSection,
                          selectedMelody: selectedMelody,
                          selectMelody: selectMelody,
                          toggleEditingMelody: toggleEditingMelody,
                          toggleMelodyReference: toggleMelodyReference,
                          setReferenceVolume: setReferenceVolume,
                          // first and last attributes affect border drawn during dragging
                          isFirst: index == 0,
                          isLast: index == _items.length - 1,
                          colorboardPart: colorboardPart,
                          keyboardPart: keyboardPart,
                          editingMelody: editingMelody,
                          hideMelodyView: hideMelodyView,
                          showBeatsBadge: widget.showBeatCounts,
                          showMediumDetails: widget.showMediumDetails,
                          showHighDetails: widget.showHighDetails,
                          part: widget.part,
                          requestScrollToTop: () {
                            if (widget.autoScroll) {
                              requestScrollToTop(index);
                            }
                          },
                          width: widget.width);
                    },
                    childCount: _items.length,
                  ),
                )),
            SliverAppBar(
              leading: Container(),
              backgroundColor: backgroundColor,
              floating: true,
              pinned: false,
              expandedHeight: 50.0,
              flexibleSpace: MelodyMenuBrowser(
                part: part,
                currentSection: currentSection,
                textColor: textColor,
                onMelodySelected: (melody) =>
                    createMelody(melody.bsRebuild((it) {
                  it.id = uuid.v4();
                })),
              ),
            ),
            if (part.instrument.type == selectedMelody?.instrumentType)
              buildDuplicateButton(
                backgroundColor,
                textColor,
              ),
            // if (part.instrument.type == InstrumentType.harmonic)
            //   buildAddFromTemplateButton(backgroundColor, textColor, odeToJoyA()),
            // if (part.instrument.type == InstrumentType.harmonic)
            //   buildAddFromTemplateButton(backgroundColor, textColor, odeToJoyB()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, boom()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, chick()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, tssst()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, tsstTsst()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, tssstSwing()),
            // if (part.instrument.type == InstrumentType.drum)
            //   buildAddFromTemplateButton(backgroundColor, textColor, tsstTsstSwing()),
            // Blank space at bottom
            SliverAppBar(
                leading: Container(),
                backgroundColor: Colors.transparent,
                floating: true,
                pinned: false,
                expandedHeight: max(5, 2 * widget.height - 0),
                flexibleSpace: SizedBox()),
            // AnimatedContainer(
            //     duration: animationDuration,
            //     height: max(5, 2 * widget.height - 0))
          ].where((it) => it != null).toList(),
        ));
  }

  Widget buildAddAndRecordButton(Color backgroundColor, Color textColor) {
    Melody newMelody = defaultMelody(sectionBeats: currentSection.beatCount)
      ..length = newMelodyBeatCounts[newMelodyBeatCountIndex] *
          defaultMelodySubdivisionsPerBeat
      ..instrumentType = part.instrument.type
      ..interpretationType = _interpretationType(part.instrument.type);
    return SliverAppBar(
      leading: Container(),
      backgroundColor: backgroundColor,
      floating: false,
      pinned: false,
      forceElevated: false,
      toolbarHeight: widget.showMediumDetails ? 70.0 : 40,
      expandedHeight: widget.showMediumDetails ? 70.0 : 40,
      flexibleSpace: MyFlatButton(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Stack(children: [
                Align(
                    alignment: Alignment.center,
                    child: Row(children: [
                      Expanded(child: SizedBox()),
                      Icon(
                        Icons.add,
                        color: textColor,
                      ),
                      Expanded(child: SizedBox()),
                    ])),
//                Align(alignment: Alignment.centerRight, child: Transform.translate(offset: Offset(10, 0), child:
//                BeatsBadge(beats: newMelody.length ~/ newMelody.subdivisionsPerBeat, show: widget.showBeatCounts,),)),
                if (newMelody.name.isEmpty)
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: Offset(-10, 0),
                        child: Icon(Icons.fiber_manual_record,
                            color: chromaticSteps[7].withAlpha(127)),
                      ))
              ]),
            ),
            if (widget.showMediumDetails)
              Container(
                  height: 30,
                  child:
                      newMelodyBeatCountPickerRow(backgroundColor, textColor))
          ],
        ),
        onPressed: () {
          MelodyReferenceView.lastAddedMelody = newMelody;
          setState(() {
            int index = 0;
            part.melodies.insert(index, newMelody);
            BeatScratchPlugin.createMelody(part, newMelody);
            final reference = currentSection.referenceTo(newMelody);
            toggleMelodyReference(reference);
            // Go directly to recording mode if not a template.
//            if (newMelody.name.isEmpty) {
            selectMelody(newMelody);
            setReferenceVolume(reference, 1.0);
            editingMelody = true;
            setKeyboardPart(part);
            if (widget.autoScroll) {
              requestScrollToTop(0);
            }
//            } else {
//              requestScrollToTop(part.melodies.length - 1);
//            }
          });
        },
      ),
    );
  }

  createMelody(Melody newMelody) {
    newMelody = newMelody.bsRebuild((it) {
      it.id = uuid.v4();
    });
    MelodyReferenceView.lastAddedMelody = newMelody;
    setState(() {
      int index = part.melodies.length;
      part.melodies.insert(index, newMelody);
      BeatScratchPlugin.createMelody(part, newMelody);
      final reference = currentSection.referenceTo(newMelody);
      toggleMelodyReference(reference);
      if (widget.autoScroll) {
        requestScrollToTop(part.melodies.length - 1);
      }
    });
  }

  Widget buildDuplicateButton(
    Color backgroundColor,
    Color textColor,
  ) {
    return SliverAppBar(
      leading: Container(),
      backgroundColor: backgroundColor,
      floating: true,
      pinned: false,
      expandedHeight: 50.0,
      flexibleSpace: MyFlatButton(
          onPressed: () {
            final melody = widget.selectedMelody.bsCopy()..id = uuid.v4();
            bool melodyExists = melody.name.isNotEmpty &&
                part.melodies.any((it) => it.name == melody.name);
            if (melodyExists && melody.name.isNotEmpty) {
              final expr = RegExp(
                r"^(.*?)(\d*)\s*$",
              );
              final match = expr.allMatches(melody.name).first;
              String prefix = match.group(1);
              prefix = prefix.trim();
              int number = int.tryParse(match.group(2)) ?? 1;
              int newNumber = number + 1;
              melody.name = "$prefix $newNumber";
              while (part.melodies.any((it) {
                return it.name == melody.name;
              })) {
                newNumber += 1;
                melody.name = "$prefix $newNumber";
              }
            }
            createMelody(melody);
          },
          child: Stack(children: [
            Align(
                alignment: Alignment.center,
                child: Row(children: [
                  Icon(
                    FontAwesomeIcons.codeBranch,
                    color: textColor,
                  ),
                  if (true)
                    Expanded(
                      child: Transform.translate(
                          offset: Offset(5, -1),
                          child: Text(
                            selectedMelody.canonicalName,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                color: selectedMelody.name?.isNotEmpty ?? false
                                    ? textColor
                                    : textColor.withOpacity(0.5),
                                fontWeight: FontWeight.w300),
                          )),
                    ),
                ])),
            Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: Offset(5, 0),
                  child: BeatsBadge(
                    beats: selectedMelody.beatCount,
                    show: widget.showBeatCounts,
                  ),
                )),
            Align(
                alignment: Alignment.bottomRight,
                child: Transform.translate(
                  offset: Offset(8, -4),
                  child: Text("Duplicate",
                      style: TextStyle(
                          fontSize: 9,
                          color: textColor,
                          fontWeight: FontWeight.w500)),
                )),
          ])),
    );
  }

  Widget newMelodyBeatCountPickerRow(Color backgroundColor, Color textColor) {
    return Row(
        children: <Widget>[SizedBox(width: 5)]
            .followedBy(newMelodyBeatCounts.asMap().entries.map((entry) {
              return Expanded(
                  child: MyFlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          setScrollToTopTimeout();
                          newMelodyBeatCountIndex = entry.key;
                        });
                      },
                      child: BeatsBadge(
                        opacity: newMelodyBeatCountIndex == entry.key ? 1 : 0.3,
                        beats: entry.value,
                        show: true,
                      )));
            }))
            .toList());
  }
}
