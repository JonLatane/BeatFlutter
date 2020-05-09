import 'dart:math';

import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:beatscratch_flutter_redux/expanded_section.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/platform_svg/platform_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:unification/unification.dart';

import 'animations/animations.dart';
import 'beatscratch_plugin.dart';
import 'instrument_picker.dart';
import 'midi_theory.dart';
import 'music_theory.dart';
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
  final Function(VoidCallback) superSetState;

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
      this.enableColorboard});

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
              child: FlatButton(
                color: Colors.brown,
                onPressed: canAddDrumPart
                    ? () {
                        widget.superSetState(() {
                          setState(() {
                            Part part = newDrumPart();
                            widget.score.parts.add(part);
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
                        "MIDI pitch values. Standards include: Kick = B1, Snare = D2, Hat = F#2."
                        "\n\nMay only be used on the Keyboard.",
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
        child: FlatButton(
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
                    "can be transformed to fit Harmonies. "
                    "\n\nMay be used on the Keyboard${widget.enableColorboard ? " or the Colorboard" : ""}.",
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
                }),
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
  });

  @override
  _MelodiesViewState createState() {
    return new _MelodiesViewState();
  }
}

class _MelodiesViewState extends State<_MelodiesView> {
  get _items => widget._items;

  get part => widget.part;

  get setColorboardPart => widget.setColorboardPart;

  get setKeyboardPart => widget.setKeyboardPart;

  get colorboardPart => widget.colorboardPart;

  get keyboardPart => widget.keyboardPart;

  get selectPart => widget.selectPart;

  get setPartVolume => widget.setPartVolume;

  Section get currentSection => widget.currentSection;

  get selectedMelody => widget.selectedMelody;

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

  void _reorderDone(Key item) {
    final draggedItem = _items[_indexOfKey(item)];
    debugPrint("Reordering finished for ${draggedItem.id}}");
  }

  // This widget is the root of your application.
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
    return ReorderableList(
        onReorder: this._reorderCallback,
        onReorderDone: this._reorderDone,
        child: CustomScrollView(
          // cacheExtent: 3000,
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
                  title: FlatButton(
                      onPressed: () {
                        selectPart(part);
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
              flexibleSpace: Slider(
                  value: max(0.0, min(1.0, part.instrument.volume)),
                  activeColor: textColor,
                  onChanged: (value) {
                    setPartVolume(part, value);
                  }),
            ),
            buildAddMelodyButton(backgroundColor, textColor, defaultMelody()..instrumentType = part.instrument.type),
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
                      );
                    },
                    childCount: _items.length,
                  ),
                )),
            if (part.instrument.type == InstrumentType.harmonic)
              buildAddMelodyButton(backgroundColor, textColor, odeToJoyA()),
            if (part.instrument.type == InstrumentType.harmonic)
              buildAddMelodyButton(backgroundColor, textColor, odeToJoyB()),
            if (part.instrument.type == InstrumentType.drum) buildAddMelodyButton(backgroundColor, textColor, boom()),
            if (part.instrument.type == InstrumentType.drum) buildAddMelodyButton(backgroundColor, textColor, chick()),
            if (part.instrument.type == InstrumentType.drum) buildAddMelodyButton(backgroundColor, textColor, tssst()),
            if (part.instrument.type == InstrumentType.drum)
              buildAddMelodyButton(backgroundColor, textColor, tsstTsst()),
          ].where((it) => it != null).toList(),
        ));
  }

  Widget buildAddMelodyButton(Color backgroundColor, Color textColor, Melody newMelody) {
    bool melodyExists = newMelody.name.isNotEmpty && part.melodies.any((it) => it.name == newMelody.name);
    if (melodyExists) {
      return null;
    }
    return SliverAppBar(
      backgroundColor: backgroundColor,
      floating: true,
      pinned: false,
      expandedHeight: 50.0,
      flexibleSpace: FlatButton(
          onPressed: () {
            _lastAddedMelody = newMelody;
            setState(() {
              int index = newMelody.name.isEmpty ? 0 : part.melodies.length;
              part.melodies.insert(index, newMelody);
              BeatScratchPlugin.createMelody(part, newMelody);
              toggleMelodyReference(currentSection.referenceTo(newMelody));
              selectMelody(newMelody);
              // Go directly to recording mode if not a template.
              if (newMelody.name.isEmpty) {
                editingMelody = true;
                setKeyboardPart(part);
              }
            });
          },
          child: Stack(children: [
          Align(alignment: Alignment.center, child: Row(children: [
              if (newMelody.name.isEmpty) Expanded(child: SizedBox()),
              Icon(
                Icons.add,
                color: textColor,
              ),
              if (newMelody.name.isEmpty) Expanded(child: SizedBox()),
              if (newMelody.name.isNotEmpty)
                Expanded(
                  child: Transform.translate(offset: Offset(0, -1), child:Text(
                  newMelody.name,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w300),
                )),),
            ])),
            Align(alignment: Alignment.centerRight, child: Transform.translate(offset: Offset(10, 0), child:
            BeatsBadge(beats: newMelody.length ~/ newMelody.subdivisionsPerBeat),))
          ])),
    );
  }
}

class BeatsBadge extends StatelessWidget {
  final int beats;

  const BeatsBadge({Key key, this.beats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: 0.5, child:
    Container(
      width: 30,
      height: 25,
      child: Stack(children: [
        Align(alignment: Alignment.center, child:
          Transform.translate(offset: Offset(0, -5), child:
            Text("$beats", style: TextStyle(fontWeight: FontWeight.w900),))),
      Align(alignment: Alignment.center, child:
        Transform.translate(offset: Offset(0, 6), child:
          Text("beat${beats == 1 ? "" : "s"}", style: TextStyle(fontWeight: FontWeight.w100, fontSize: 8),))),
      ]),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
          border: Border.all(
            color: Colors.black,
          ),
          borderRadius: BorderRadius.all(Radius.circular(5))),
    ));
  }
}

Melody _lastAddedMelody;

class _MelodyReference extends StatefulWidget {
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
  });

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

  @override
  __MelodyReferenceState createState() => __MelodyReferenceState();
}

class __MelodyReferenceState extends State<_MelodyReference> with TickerProviderStateMixin {
  MelodyReference get reference => widget.currentSection.referenceTo(widget.melody);

  bool get isSelectedMelody => widget.melody.id == widget.selectedMelody?.id;
  AnimationController controller;

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

    toggleMelody() {
      if (widget.editingMelody && isSelectedMelody) {
        widget.toggleEditingMelody();
      } else {
        if (widget.editingMelody) {
          widget.toggleEditingMelody();
        }
        widget.selectMelody(widget.melody);
      }
    }

    Widget content = Container(
        decoration: decoration,
        padding: EdgeInsets.only(bottom: 5),
        child: FlatButton(
            onPressed: toggleMelody,
            padding: EdgeInsets.zero,
            child: Stack(children: [
              Column(children: [
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    child: Row(children: [
                      BeatsBadge(beats: widget.melody.length ~/ widget.melody.subdivisionsPerBeat),
                      SizedBox(width:3),
                      Expanded(
                          child: TextField(
                        controller: TextEditingController()..text = widget.melody.name,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          widget.melody.name = value;
                        },
                        onTap: () {
                          if (!context.isTabletOrLandscapey) {
                            widget.hideMelodyView();
                          }
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
//              Text("Melody ${melody.id.substring(0, 5)}"),
                AnimatedOpacity(
                    duration: animationDuration,
                    opacity: reference.playbackType != MelodyReference_PlaybackType.disabled ? 1 : 0,
                    child: AnimatedContainer(
                      duration: animationDuration,
                      height: reference.playbackType != MelodyReference_PlaybackType.disabled ? 40 : 0,
                      child: Slider(
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
                        child: RaisedButton(
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
                      Container(
                          width: 40,
                          height: 36,
                          child: RaisedButton(
                              padding: EdgeInsets.all(0),
                              onPressed: toggleMelody,
                              color:
                                  (isSelectedMelody && !widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
                              child: Icon(Icons.remove_red_eye))),
                      AnimatedContainer(
                          duration: animationDuration,
                          width: (reference.playbackType == MelodyReference_PlaybackType.disabled) ? 0 : 40,
                          height: 36,
                          child: RaisedButton(
                              onPressed: () {
                                if (!isSelectedMelody) {
                                  widget.selectMelody(widget.melody);
                                }
                                widget.toggleEditingMelody();
                              },
                              padding: EdgeInsets.all(0),
                              color:
                                  (isSelectedMelody && widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
                              child: Image.asset(
                                'assets/edit.png',
                                fit: BoxFit.fill,
                              ))),
                      Expanded(child: SizedBox()),
                    ]))
              ]),
            ])));

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
    controller = AnimationController(vsync: this, duration: Duration(seconds: 1));
    if (_lastAddedMelody == widget.melody) {
      _lastAddedMelody = null;
      content = SizeFadeTransition(
//        key: Key("lastAdded"),
          axis: Axis.vertical,
          sizeFraction: 0.0,
          curve: Curves.easeInOut,
          animation: controller,
          child: content);
    }
    controller.forward();

    return content;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: Key(widget.melody.id), //
        childBuilder: _buildChild);
  }
}
