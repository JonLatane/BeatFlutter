import 'dart:math';

import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:unification/unification.dart';

import 'animations/animations.dart';
import 'beatscratch_plugin.dart';
import 'dummydata.dart';
import 'midi_theory.dart';
import 'music_theory.dart';
import 'my_buttons.dart';
import 'ui_models.dart';
import 'util.dart';

class PartMelodiesView extends StatefulWidget {
  final MelodyViewMode melodyViewMode;
  final bool enableColorboard;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;
  final Function(Melody) selectMelody;
  final VoidCallback toggleEditingMelody;
  final VoidCallback hideMelodyView;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Function(Part, double) setPartVolume;
  final Part colorboardPart;
  final Part keyboardPart;
  final Part selectedPart;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Function(Part) selectPart;
  final bool editingMelody;
  final double availableWidth;
  final double height;
  final Function(VoidCallback) superSetState;
  final bool showBeatCounts;

  PartMelodiesView(
      {this.melodyViewMode,
      this.superSetState,
      this.score,
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
      this.availableWidth,
      this.selectedPart,
      this.enableColorboard,
      this.showBeatCounts,
      this.height});

  @override
  _PartMelodiesViewState createState() {
    return new _PartMelodiesViewState();
  }
}

class _PartMelodiesViewState extends State<PartMelodiesView> {
  final ScrollController controller = ScrollController();

  Widget _buildAddButton() {
    double width = widget.score.parts.isNotEmpty
        ? 320
        : context.isTablet ? min(600, widget.availableWidth / 2) : widget.availableWidth;
    bool canAddPart = widget.score.parts.length < 5;
    bool canAddDrumPart =
        canAddPart && !(widget.score.parts.any((element) => element.instrument.type == InstrumentType.drum));
    return Column(children: [
      Expanded(
          child: AnimatedContainer(
              duration: animationDuration,
              width: width,
              child: MyFlatButton(
                color: Colors.brown,
                onPressed: canAddDrumPart
                    ? () {
                        widget.superSetState(() {
                          setState(() {
                            Part part = newDrumPart();
                            widget.score.parts.add(part);
                            BeatScratchPlugin.createPart(part);
//                          BeatScratchPlugin.pushPart(part);
                            if (widget.keyboardPart == null) {
                              widget.setKeyboardPart(part);
                            }
                          });
                        });
                      }
                    : null,
                child: Column(children: [
                  Expanded(child: SizedBox()),
                  Icon(
                    Icons.add,
                    color: canAddDrumPart ? Colors.white : Colors.black26,
                  ),
                  Text(
                    "Add Drum Part",
                    style: TextStyle(color: canAddDrumPart ? Colors.white : Colors.black26),
                  ),
                  Container(
                      width: 270,
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        "Kits, whistles, gunshots, zips, zaps, crickets, screams, and more.   Drum Parts written using "
                        "MIDI pitch values. Standards include: Kick = B1, Snare = D2, Hat = F#2.",
                        style: TextStyle(
                            color: canAddDrumPart ? Colors.white : Colors.black26,
                            fontSize: 10,
                            fontWeight: FontWeight.w100),
                      )),
                  Expanded(child: SizedBox()),
                ]),
              ))),
      Expanded(
          child: AnimatedContainer(
        duration: animationDuration,
        width: width,
        child: MyFlatButton(
            color: Colors.grey,
            onPressed: canAddPart
                ? () {
                    widget.superSetState(() {
                      setState(() {
                        Part part = newPartFor(widget.score);
                        if (widget.score.parts.isNotEmpty && widget.score.parts.last.isDrum /*&& !kIsWeb*/) {
                          widget.score.parts.insert(widget.score.parts.length - 1, part);
                        } else {
                          widget.score.parts.add(part);
                        }
                        BeatScratchPlugin.createPart(part);
                        if (widget.keyboardPart == null) {
                          widget.setKeyboardPart(part);
                        }
                        if (widget.colorboardPart == null) {
                          widget.setColorboardPart(part);
                        }
                      });
                    });
                  }
                : null,
            child: Column(children: [
              Expanded(child: SizedBox()),
              Icon(
                Icons.add,
                color: canAddPart ? Colors.white : Colors.black26,
              ),
              Text(
                "Add Harmonic Part",
                style: TextStyle(color: canAddPart ? Colors.white : Colors.black26),
              ),
              Container(
                  width: 270,
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    "Pianos, guitars, voice, and all other instruments that play notes. Melodies in Harmonic Parts "
                    "can be transformed to fit Harmonies. ",
                    style: TextStyle(
                        color: canAddPart ? Colors.white : Colors.black26, fontSize: 10, fontWeight: FontWeight.w100),
                  )),
              Expanded(child: SizedBox()),
            ])),
      )),
    ]);
  }

  Widget _buildPart(Part part) {
    return Container(
        key: Key("part-container-${part.id}"),
        width: 200,
        child: Column(children: [
          Expanded(
            child: _MelodiesView(
              score: widget.score,
              part: part,
              selectedPart: widget.selectedPart,
              sectionColor: widget.sectionColor,
              selectMelody: widget.selectMelody,
              toggleEditingMelody: widget.toggleEditingMelody,
              toggleMelodyReference: widget.toggleMelodyReference,
              setReferenceVolume: widget.setReferenceVolume,
              setPartVolume: widget.setPartVolume,
              currentSection: widget.currentSection,
              selectedMelody: widget.selectedMelody,
              colorboardPart: widget.colorboardPart,
              keyboardPart: widget.keyboardPart,
              setKeyboardPart: widget.setKeyboardPart,
              setColorboardPart: widget.setColorboardPart,
              selectPart: widget.selectPart,
              editingMelody: widget.editingMelody,
              hideMelodyView: widget.hideMelodyView,
              enableColorboard: widget.enableColorboard,
              removePart: (part) {
                widget.superSetState(() {
                  setState(() {
                    widget.score.parts.remove(part);
                  });
                });
              },
              showBeatCounts: widget.showBeatCounts,
              height: widget.height,
            ),
          )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<Part>(
//      key: Key(widget.score.parts.map((e) => e.id).toString()),
      scrollDirection: Axis.horizontal,
      // The current items in the list.
      items: widget.score.parts + [null],
      // Called by the DiffUtil to decide whether two object represent the same item.
      // For example, if your items have unique ids, this method should check their id equality.
      areItemsTheSame: (a, b) => (a ?? Part()).id == (b ?? Part()).id,
      onReorderFinished: (item, oldIndex, newIndex, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.

        widget.superSetState(() {
          setState(() {
//          if (newIndex > oldIndex) {
//            newIndex -= 1;
//          }
            if (oldIndex < widget.score.parts.length) {
              if (newIndex >= widget.score.parts.length) {
                newIndex = widget.score.parts.length - 1;
              }
              Part toMove = widget.score.parts.removeAt(oldIndex);
              widget.score.parts.insert(newIndex, toMove);
            }
//          widget.score.parts
//            ..clear()
//            ..addAll(newItems);
          });
        });
      },
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, Part item, index) {
        // Specifiy a transition to be used by the ImplicitlyAnimatedList.
        // In this case a custom transition.
        return item != null
            ? Reorderable(
                // Each item must have an unique key.
                key: Key("part-reorderable-${item.id}"),
                builder: (context, dragAnimation, inDrag) {
                  final tile = _buildPart(item);
                  return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: tile,
                      axis: (dragAnimation.value > 0 || inDrag) ? Axis.vertical : Axis.horizontal);
                })
            : Reorderable(
                // Each item must have an unique key.
                key: Key("add"),
                builder: (context, dragAnimation, inDrag) => _buildAddButton());
      },

      // An optional builder when an item was removed from the list.
      // If not specified, the List uses the itemBuilder with
      // the animation reversed.
//      removeItemBuilder: (context, animation, oldItem) {
//        return FadeTransition(
//          opacity: animation,
//          child: _buildPart(oldItem),
//        );
//      },
    );
  }
}

class _MelodiesView extends StatefulWidget {
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
  final double height;

  List<Melody> get _items {
    return part.melodies;
  }

  _MelodiesView({
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
  });

  @override
  _MelodiesViewState createState() {
    return new _MelodiesViewState();
  }
}

MelodyInterpretationType _interpretationType(InstrumentType instrumentType) {
  if (instrumentType == InstrumentType.drum) {
    return MelodyInterpretationType.fixed_nonadaptive;
  } else {
    return MelodyInterpretationType.fixed;
  }
}

class _MelodiesViewState extends State<_MelodiesView> {
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
  ScrollController scrollController = ScrollController();

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

  requestScrollToTop(int melodyIndex) {
    if (melodyIndex < 0) {
      scrollController.animateTo(0, duration: Duration(milliseconds: 1000), curve: Curves.ease);
      return;
    }
    int activeMelodyRefsBeforeIndex = 0; //currentSection.referenceTo(melody)
    range(0, melodyIndex).forEach((i) {
      final checkMelody = part.melodies[i];
      if (currentSection.referenceTo(checkMelody).playbackType != MelodyReference_PlaybackType.disabled) {
        activeMelodyRefsBeforeIndex += 1;
      }
    });
    int inactiveMelodyRefsBeforeIndex = melodyIndex - activeMelodyRefsBeforeIndex;
    scrollController.animateTo(190.0 + (137.0 * activeMelodyRefsBeforeIndex) + (97.0 * inactiveMelodyRefsBeforeIndex),
        duration: Duration(milliseconds: 1000), curve: Curves.ease);
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

  @override
  Widget build(BuildContext context) {
    String partName;
    if (part.instrument.type == InstrumentType.drum) {
      partName = "Drums";
    } else {
      partName = midiInstruments[part.instrument.midiInstrument];
    }
    bool isSelectedPart = widget.selectedPart == part;
    Color backgroundColor, textColor;
    if (part.instrument.type == InstrumentType.drum) {
      backgroundColor = isSelectedPart ? Colors.white : Colors.brown;
      textColor = isSelectedPart ? Colors.brown : Colors.white;
    } else {
      backgroundColor = isSelectedPart ? Colors.white : Colors.grey;
      textColor = isSelectedPart ? Colors.grey : Colors.white;
    }
    if (lastSelectedMelodyId != null && selectedMelody != null && lastSelectedMelodyId != selectedMelody.id) {
      int indexOfMelody = part.melodies.indexWhere((m) => m.id == selectedMelody?.id);
      if (indexOfMelody >= 0) {
        requestScrollToTop(indexOfMelody);
      }
    }
    lastSelectedMelodyId = selectedMelody?.id;
    return ReorderableList(
        onReorder: this._reorderCallback,
        onReorderDone: this._reorderDone,
        child: CustomScrollView(
          // cacheExtent: 3000,
//          key: Key("MelodyScroller"),
          controller: scrollController,
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: backgroundColor,
              actions: <Widget>[
                AnimatedContainer(
                    duration: animationDuration,
                    width: (keyboardPart == part) ? 24 : 0,
                    height: 24,
                    child: Opacity(
                        opacity: 0.5,
                        child: Padding(padding: EdgeInsets.all(2), child: Image.asset('assets/piano.png')))),
                AnimatedContainer(
                    duration: animationDuration,
                    width: (widget.enableColorboard && colorboardPart == part) ? 24 : 0,
                    height: 24,
                    child: Opacity(opacity: 0.5, child: Image.asset('assets/colorboard.png'))),
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
                        requestScrollToTop(-1);
                      },
                      child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                              padding: EdgeInsets.only(bottom: 0, top: 30),
                              child: Text(
                                partName,
                                style: TextStyle(color: textColor, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ))))),
            ),
            SliverAppBar(
              backgroundColor: backgroundColor,
              floating: true,
              pinned: false,
              expandedHeight: 50.0,
              flexibleSpace: MySlider(
                  value: max(0.0, min(1.0, part.instrument.volume)),
                  activeColor: textColor,
                  onChanged: (value) {
                    setPartVolume(part, value);
                  }),
            ),
            buildAddAndRecordButton(
                backgroundColor,
                textColor),
//            newMelodyBeatCountPicker(backgroundColor, textColor),
//            buildAddMelodyButton(backgroundColor, textColor,
//              defaultMelody(sectionBeats: currentSection.beatCount)
//                ..length = defaultMelodySubdivisionsPerBeat
//                ..instrumentType = part.instrument.type
//                ..interpretationType = _interpretationType(part.instrument.type),
//              forceShowBeatCount: true
//            ),
//            buildAddMelodyButton(backgroundColor, textColor,
//              defaultMelody(sectionBeats: currentSection.beatCount)
//                ..length = 2 * defaultMelodySubdivisionsPerBeat
//                ..instrumentType = part.instrument.type
//                ..interpretationType = _interpretationType(part.instrument.type),
//              forceShowBeatCount: true
//            ),
//            buildAddMelodyButton(backgroundColor, textColor,
//              defaultMelody(sectionBeats: currentSection.beatCount)
//                ..length = defaultMelodySubdivisionsPerBeat * currentSection.meter.defaultBeatsPerMeasure
//                ..instrumentType = part.instrument.type
//                ..interpretationType = _interpretationType(part.instrument.type),
//              forceShowBeatCount: true
//            ),
//            buildAddMelodyButton(backgroundColor, textColor,
//              defaultMelody(sectionBeats: currentSection.beatCount)
//                ..length = 2 * defaultMelodySubdivisionsPerBeat * currentSection.meter.defaultBeatsPerMeasure
//                ..instrumentType = part.instrument.type
//                ..interpretationType = _interpretationType(part.instrument.type),
//              forceShowBeatCount: true
//            ),
            SliverPadding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                sliver:
//                ImplicitlyAnimatedReorderableList<Melody>(
//                  scrollDirection: Axis.vertical,
//                  // The current items in the list.
//                  items: widget.part.melodies,
//                  // Called by the DiffUtil to decide whether two object represent the same item.
//                  // For example, if your items have unique ids, this method should check their id equality.
//                  areItemsTheSame: (Melody a, b) => a.id == b.id,
//                  onReorderFinished: (item, oldIndex, newIndex, newItems) {
//                    // Remember to update the underlying data when the list has been
//                    // reordered.
//                    setState(() {
//                      if (oldIndex < widget.part.melodies.length) {
//                        if (newIndex >= widget.part.melodies.length) {
//                          newIndex = widget.part.melodies.length - 1;
//                        }
//                        Melody toMove = widget.part.melodies.removeAt(oldIndex);
//                        widget.part.melodies.insert(newIndex, toMove);
//                      }
//                    });
//                  },
//                  // Called, as needed, to build list item widgets.
//                  // List items are only built when they're scrolled into view.
//                  itemBuilder: (context, animation, Melody item, index) {
//                    // Specifiy a transition to be used by the ImplicitlyAnimatedList.
//                    // In this case a custom transition.
//                    return item != null
//                        ? Reorderable(
//                            // Each item must have an unique key.
//                            key: Key(item.id),
//                            builder: (context, dragAnimation, inDrag) {
//                              final t = dragAnimation.value;
//                              final tile = _MelodyReference(
//                                melody: _items[index],
//                                sectionColor: sectionColor,
//                                currentSection: currentSection,
//                                selectedMelody: selectedMelody,
//                                selectMelody: selectMelody,
//                                toggleEditingMelody: toggleEditingMelody,
//                                toggleMelodyReference: toggleMelodyReference,
//                                setReferenceVolume: setReferenceVolume,
//                                // first and last attributes affect border drawn during dragging
//                                isFirst: index == 0,
//                                isLast: index == _items.length - 1,
//                                colorboardPart: colorboardPart,
//                                keyboardPart: keyboardPart,
//                                editingMelody: editingMelody,
//                                hideMelodyView: hideMelodyView,
//                              );
//
//                              return SizeFadeTransition(
//                                  sizeFraction: 0.7,
//                                  curve: Curves.easeInOut,
//                                  animation: animation,
//                                  child: tile,
//                                  axis: (t > 0 || inDrag) ? Axis.vertical : Axis.horizontal);
//                            })
//                        : Reorderable(
//                            // Each item must have an unique key.
//                            key: Key("add"),
//                            builder: (context, dragAnimation, inDrag) => _MelodyReference(
//                                  melody: _items[index],
//                                  sectionColor: sectionColor,
//                                  currentSection: currentSection,
//                                  selectedMelody: selectedMelody,
//                                  selectMelody: selectMelody,
//                                  toggleEditingMelody: toggleEditingMelody,
//                                  toggleMelodyReference: toggleMelodyReference,
//                                  setReferenceVolume: setReferenceVolume,
//                                  // first and last attributes affect border drawn during dragging
//                                  isFirst: index == 0,
//                                  isLast: index == _items.length - 1,
//                                  colorboardPart: colorboardPart,
//                                  keyboardPart: keyboardPart,
//                                  editingMelody: editingMelody,
//                                  hideMelodyView: hideMelodyView,
//                                ));
//                  },
//                )),
                    SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return _MelodyReference(
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
                        requestScrollToTop: () {
                          requestScrollToTop(index);
                        },
                      );
                    },
                    childCount: _items.length,
                  ),
                )),
            if (part.instrument.type == selectedMelody?.instrumentType)
              buildAddFromTemplateButton(backgroundColor, textColor, selectedMelody.clone(),
              icon: Icons.control_point_duplicate),
            if (part.instrument.type == InstrumentType.harmonic)
              buildAddFromTemplateButton(backgroundColor, textColor, odeToJoyA()),
            if (part.instrument.type == InstrumentType.harmonic)
              buildAddFromTemplateButton(backgroundColor, textColor, odeToJoyB()),
            if (part.instrument.type == InstrumentType.drum) buildAddFromTemplateButton(backgroundColor, textColor, boom()),
            if (part.instrument.type == InstrumentType.drum) buildAddFromTemplateButton(backgroundColor, textColor, chick()),
            if (part.instrument.type == InstrumentType.drum) buildAddFromTemplateButton(backgroundColor, textColor, tssst()),
            if (part.instrument.type == InstrumentType.drum)
              buildAddFromTemplateButton(backgroundColor, textColor, tsstTsst()),
            if (part.instrument.type == InstrumentType.drum)
              buildAddFromTemplateButton(backgroundColor, textColor, tssstSwing()),
            if (part.instrument.type == InstrumentType.drum)
              buildAddFromTemplateButton(backgroundColor, textColor, tsstTsstSwing()),
            // Blank space at bottom
            SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                pinned: false,
                expandedHeight: max(5, widget.height - 150),
                flexibleSpace: SizedBox()),
//            Container(height: max(5, widget.height - 60))
          ].where((it) => it != null).toList(),
        ));
  }

  Widget buildAddAndRecordButton(Color backgroundColor, Color textColor) {
    Melody newMelody = defaultMelody(sectionBeats: currentSection.beatCount)
      ..length = newMelodyBeatCounts[newMelodyBeatCountIndex] * defaultMelodySubdivisionsPerBeat
      ..instrumentType = part.instrument.type
      ..interpretationType = _interpretationType(part.instrument.type);
    return SliverAppBar(
      backgroundColor: backgroundColor,
      floating: false,
      pinned: false,
      forceElevated: false,
      expandedHeight: 80.0,
      flexibleSpace: MyFlatButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _lastAddedMelody = newMelody;
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
              requestScrollToTop(0);
//            } else {
//              requestScrollToTop(part.melodies.length - 1);
//            }
          });
        },
        child:
        Column(
          children: [
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Stack(children: [
                Align(alignment: Alignment.center, child: Row(children: [
                  Expanded(child: SizedBox()),
                  Icon(
                    Icons.add,
                    color: textColor,
                  ),
                  Expanded(child: SizedBox()),
                ])),
//                Align(alignment: Alignment.centerRight, child: Transform.translate(offset: Offset(10, 0), child:
//                BeatsBadge(beats: newMelody.length ~/ newMelody.subdivisionsPerBeat, show: widget.showBeatCounts,),)),
                if (newMelody.name.isEmpty) Align(alignment: Alignment.centerLeft, child: Transform.translate(offset: Offset(-10, 0), child:
                Icon(Icons.fiber_manual_record, color: chromaticSteps[7].withAlpha(127)),))
              ]),
            ),
            Container(height: 30, child: newMelodyBeatCountPickerRow(backgroundColor, textColor))
          ],
        )),
    );
  }

  Widget buildAddFromTemplateButton(Color backgroundColor, Color textColor, Melody newMelody,
      {bool forceShowBeatCount = false, IconData icon = Icons.add}) {
    bool melodyExists = newMelody.name.isNotEmpty && part.melodies.any((it) => it.name == newMelody.name);
    if(icon == Icons.control_point_duplicate) {
      newMelody.id = uuid.v4();
    }
    if (melodyExists && icon == Icons.add) {
      return null;
    } else if (melodyExists && newMelody.name.isNotEmpty && icon == Icons.control_point_duplicate) {
      final match = RegExp(
        r"^(.*?)(\d*)\s*$",
      )
        .allMatches(newMelody.name)
        .first;
      String prefix = match.group(1);
      prefix = prefix.trim();
      int number = int.tryParse(match.group(2)) ?? 1;
      int newNumber = number + 1;
      newMelody.name = "$prefix $newNumber";
      while (part.melodies.any((it) => it.name == newMelody.name)) {
        newNumber += 1;
        newMelody.name = "$prefix $newNumber";
      }
    }
    return SliverAppBar(
      backgroundColor: backgroundColor,
      floating: true,
      pinned: false,
      expandedHeight: 50.0,
      flexibleSpace: MyFlatButton(
          onPressed: () {
            _lastAddedMelody = newMelody;
            setState(() {
              int index = part.melodies.length;
              part.melodies.insert(index, newMelody);
              BeatScratchPlugin.createMelody(part, newMelody);
              final reference = currentSection.referenceTo(newMelody);
              toggleMelodyReference(reference);
              requestScrollToTop(part.melodies.length - 1);

            });
          },
          child: Stack(children: [
            if (icon != Icons.add)
            Align(alignment: Alignment.center, child: Row(children: [
              Expanded(child: SizedBox()),
              Text(
                newMelody.name?.isNotEmpty ?? false ? newMelody.name : "Melody ${newMelody.id.substring(0, 5)}",
                style: TextStyle(color: newMelody.name?.isNotEmpty ?? false ? textColor : textColor.withOpacity(0.5), fontWeight: FontWeight.w300),
              ),
              Expanded(child: SizedBox()),
            ])),
          Align(alignment: Alignment.center, child: Row(children: [
              Icon(
                icon,
                color: textColor,
              ),

            if (icon == Icons.add) Expanded(
                  child: Transform.translate(offset: Offset(0, -1), child:Text(
                  newMelody.name?.isNotEmpty ?? false ? newMelody.name : "Melody ${newMelody.id.substring(0, 5)}",
                  style: TextStyle(color: newMelody.name?.isNotEmpty ?? false ? textColor : textColor.withOpacity(0.5), fontWeight: FontWeight.w300),
                )),),
            ])),
            Align(alignment: Alignment.centerRight, child: Transform.translate(offset: Offset(10, 0), child:
            BeatsBadge(beats: newMelody.length ~/ newMelody.subdivisionsPerBeat, show: widget.showBeatCounts,),)),
          ])),
    );
  }

  Widget newMelodyBeatCountPickerRow(Color backgroundColor, Color textColor) {
    return Row(
      children: <Widget>[SizedBox(width:5)].followedBy(newMelodyBeatCounts.asMap().entries.map((entry) {
        return Expanded(
          child: MyFlatButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                newMelodyBeatCountIndex = entry.key;
              });
            },
            child: BeatsBadge(
              opacity: newMelodyBeatCountIndex == entry.key ? 1 : 0.3,
              beats: entry.value,
              show: true,
            )));
      })).toList());
  }
}

double beatsBadgeWidth(int beats) {
  double width = 30;
  if (beats == null) {
    beats = 9999;
  }
  if (beats > 99) width = 40;
  if (beats > 999) width = 50;
  if (beats > 9999) width = 60;
  if (beats > 99999) width = 70;
  return width;
}

class BeatsBadge extends StatelessWidget {
  final int beats;
  final bool show;
  final double opacity;
  final bool isPerBeat;

  const BeatsBadge({Key key, this.beats, this.show = true, this.opacity = 0.5, this.isPerBeat = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
        duration: animationDuration,
        opacity: show ? opacity : 0,
        child: AnimatedContainer(
          duration: animationDuration,
          width: show ? beatsBadgeWidth(beats) : 0,
          height: 25,
          child: Stack(children: [
            Align(
                alignment: Alignment.center,
                child: Transform.translate(
                    offset: Offset(0, -5),
                    child: Text(
                      "$beats",
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(fontWeight: FontWeight.w900, color: isPerBeat ? Colors.white : Colors.black),
                    ))),
            Align(
                alignment: Alignment.center,
                child: Transform.translate(
                    offset: Offset(0, 6),
                    child: Text(
                      isPerBeat ? "/beat" : "beat${beats == 1 ? "" : "s"}",
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                          fontWeight: FontWeight.w100, fontSize: 8, color: isPerBeat ? Colors.white : Colors.black),
                    ))),
          ]),
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
              color: isPerBeat ? Colors.black : Colors.white,
              border: Border.all(
                color: Colors.black,
              ),
              borderRadius: BorderRadius.all(Radius.circular(5))),
        ));
  }
}

Melody _lastAddedMelody;

class _MelodyReference extends StatefulWidget {
  final Melody melody;
  final bool isFirst;
  final bool isLast;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;
  final Function(Melody) selectMelody;
  final VoidCallback toggleEditingMelody;
  final VoidCallback hideMelodyView;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final Part colorboardPart;
  final Part keyboardPart;
  final bool editingMelody;
  final bool showBeatsBadge;
  final VoidCallback requestScrollToTop;

  _MelodyReference({
    this.melody,
    this.isFirst,
    this.isLast,
    this.sectionColor,
    this.currentSection,
    this.selectedMelody,
    this.selectMelody,
    this.colorboardPart,
    this.keyboardPart,
    this.toggleMelodyReference,
    this.setReferenceVolume,
    this.editingMelody,
    this.toggleEditingMelody,
    this.hideMelodyView,
    this.showBeatsBadge,
    this.requestScrollToTop,
  });

  @override
  __MelodyReferenceState createState() => __MelodyReferenceState();
}

class __MelodyReferenceState extends State<_MelodyReference> with TickerProviderStateMixin {
  MelodyReference get reference => widget.currentSection.referenceTo(widget.melody);

  bool get isSelectedMelody => widget.melody.id == widget.selectedMelody?.id;
  AnimationController animationController;
  TextEditingController nameController = TextEditingController();

  @override
  initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  dispose() {
    animationController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: Key("${widget.melody.id}"), //
        childBuilder: _buildChild);
  }

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    BoxDecoration decoration;
    var color = isSelectedMelody ? Colors.white : Color(0xFFDDDDDD);

    if (state == ReorderableItemState.dragProxy || state == ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = BoxDecoration(color: color);
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: widget.isFirst && !placeholder
                  ? Divider.createBorderSide(context) //
                  : BorderSide.none,
              bottom: widget.isLast && placeholder
                  ? BorderSide.none //
                  : Divider.createBorderSide(context)),
          color: color);
    }
    nameController.value = nameController.value.copyWith(text: widget.melody.name);

    Widget content = Container(
        decoration: decoration,
        padding: EdgeInsets.only(bottom: 5),
        child: Stack(children: [
          MyFlatButton(
            onPressed: () {
              if (!isSelectedMelody) {
                widget.requestScrollToTop();
              }
              widget.selectMelody(widget.melody);

//              if (widget.editingMelody && isSelectedMelody) {
//                widget.toggleEditingMelody();
//              } else {
////        if (widget.editingMelody) {
////          widget.toggleEditingMelody();
////        }
//                widget.selectMelody(widget.melody);
//                widget.requestScrollToTop();
//              }
            },
            padding: EdgeInsets.zero,
            child: Column(children: [
              SizedBox(height: 51.1),
//              Text("Melody ${melody.id.substring(0, 5)}"),
              AnimatedOpacity(
                  duration: animationDuration,
                  opacity: reference.playbackType != MelodyReference_PlaybackType.disabled ? 1 : 0,
                  child: AnimatedContainer(
                    duration: animationDuration,
                    height: reference.playbackType != MelodyReference_PlaybackType.disabled ? 40 : 0,
                    child: MySlider(
                        value: reference.volume,
                        activeColor: widget.sectionColor,
                        onChanged: (reference.playbackType == MelodyReference_PlaybackType.disabled)
                            ? null
                            : (value) {
                                widget.setReferenceVolume(reference, value);
                              }),
                  )),
              Align(
                  alignment: Alignment.centerRight,
                  child: Row(children: [
                    Expanded(child: SizedBox()),
                    Container(
                      width: 40,
                      height: 36,
                      child: MyRaisedButton(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            widget.toggleMelodyReference(reference);
                          },
                          color: (reference.playbackType == MelodyReference_PlaybackType.disabled)
                              ? Color(0xFFDDDDDD)
                              : widget.sectionColor,
                          child: Align(
                              alignment: Alignment.center,
                              child: Icon((reference.playbackType == MelodyReference_PlaybackType.disabled)
                                  ? Icons.not_interested
                                  : Icons.volume_up))),
                    ),
//                      Container(
//                          width: 40,
//                          height: 36,
//                          child: MyRaisedButton(
//                              padding: EdgeInsets.all(0),
//                              onPressed: toggleMelody,
//                              color:
//                                  (isSelectedMelody && !widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
//                              child: Icon(Icons.remove_red_eye))),
//                      AnimatedContainer(
//                          duration: animationDuration,
//                          width: (reference.playbackType == MelodyReference_PlaybackType.disabled) ? 0 : 40,
//                          height: 36,
//                          child: MyRaisedButton(
//                              onPressed: () {
//                                if (!isSelectedMelody) {
//                                  widget.selectMelody(widget.melody);
//                                }
//                                widget.toggleEditingMelody();
//                              },
//                              padding: EdgeInsets.all(0),
//                              color:
//                                  (isSelectedMelody && widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
//                              child: Image.asset(
//                                'assets/edit.png',
//                                fit: BoxFit.fill,
//                              ))),
                    Expanded(child: SizedBox()),
                  ]))
            ]),
          ),
          Container(
            padding: EdgeInsets.only(top: 5),
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Row(children: [
                  BeatsBadge(
                      beats: widget.melody.length ~/ widget.melody.subdivisionsPerBeat, show: widget.showBeatsBadge),
                  SizedBox(width: 3),
                  Expanded(
                      child: TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (value) {
                      widget.melody.name = value;
                      //                          BeatScratchPlugin.updateMelody(widget.melody);
                      BeatScratchPlugin.onSynthesizerStatusChange();
                    },
                    onTap: () {
                      if (!context.isTabletOrLandscapey) {
                        widget.hideMelodyView();
                      }
                      widget.requestScrollToTop();
                    },
                    decoration: InputDecoration(
                        border: InputBorder.none, hintText: "Melody ${widget.melody.id.substring(0, 5)}"),
                  )),
                  ReorderableListener(
                      child: Container(
                          width: 24,
                          height: 24,
//                          padding: EdgeInsets.only(right:0),
                          child: Icon(Icons.reorder)))
                ])),
          ),
        ]));

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
//    content = DelayedReorderableListener(
//        child: content,
//      );

    content = Padding(
      padding: EdgeInsets.all(2),
      child: content,
    );

//    content = AnimatedOpacity(
//      duration: Duration(seconds: 3),
//      opacity: opacityLevel,
//      child: content);
    if (_lastAddedMelody == widget.melody) {
      _lastAddedMelody = null;
      content = SizeFadeTransition(
//        key: Key("lastAdded"),
          axis: Axis.vertical,
          sizeFraction: 0.0,
          curve: Curves.easeInOut,
          animation: animationController,
          child: content);
      animationController.forward();
    }

    return content;
  }
}
