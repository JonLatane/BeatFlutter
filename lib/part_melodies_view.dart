import 'dart:math';

import 'package:beatscratch_flutter_redux/expanded_section.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'animations/animations.dart';
import 'ui_models.dart';
import 'util.dart';
import 'music_theory.dart';

class PartMelodiesView extends StatefulWidget {
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
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Function(Part) selectPart;
  final bool editingMelody;

  PartMelodiesView(
      {this.score,
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
      this.setPartVolume, this.editingMelody, this.toggleEditingMelody, this.hideMelodyView});

  @override
  _PartMelodiesViewState createState() {
    return new _PartMelodiesViewState();
  }
}

class _PartMelodiesViewState extends State<PartMelodiesView> {
  final ScrollController controller = ScrollController();

  Widget _buildAddButton() {
    return Container(
      width: 160,
      child: FlatButton(onPressed: () {},
      child: Icon(Icons.add),)
    );
  }

  Widget _buildPart(Part part) {
    return Container(
        key: Key(part.id),
        width: 160,
        child: Column(children: [
          Expanded(
            child: _MelodiesView(
              score: widget.score,
              partPosition: widget.score.parts.indexOf(part),
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
            ),
          )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<Part>(
      scrollDirection: Axis.horizontal,
      // The current items in the list.
      items: widget.score.parts,
      // Called by the DiffUtil to decide whether two object represent the same item.
      // For example, if your items have unique ids, this method should check their id equality.
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, oldIndex, newIndex, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.
        setState(() {
//          if (newIndex > oldIndex) {
//            newIndex -= 1;
//          }
          Part toMove = widget.score.parts.removeAt(oldIndex);
          widget.score.parts.insert(newIndex, toMove);
//          widget.score.parts
//            ..clear()
//            ..addAll(newItems);
        });
      },
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, item, index) {
        // Specifiy a transition to be used by the ImplicitlyAnimatedList.
        // In this case a custom transition.
        return Reorderable(
            // Each item must have an unique key.
            key: Key(item.id),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final tile = _buildPart(item);
//              if (t > 0.0) {
//                return tile;
//              }

              return SizeFadeTransition(
                sizeFraction: 0.7,
                curve: Curves.easeInOut,
                animation: animation,
                child: tile,
              );
            });
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
  final int partPosition;
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
  final Part colorboardPart;
  final Part keyboardPart;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final bool editingMelody;

  Part get part => score.parts[partPosition];

  List<Melody> get _items {
    return score.parts[partPosition].melodies;
  }

  _MelodiesView({
    this.score,
    this.scrollDirection,
    this.partPosition,
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
    this.setPartVolume, this.editingMelody, this.toggleEditingMelody, this.hideMelodyView,
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

  get currentSection => widget.currentSection;

  get selectedMelody => widget.selectedMelody;

  get setReferenceVolume => widget.setReferenceVolume;

  get toggleMelodyReference => widget.toggleMelodyReference;

  get selectMelody => widget.selectMelody;

  get sectionColor => widget.sectionColor;

  get editingMelody => widget.editingMelody;

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
    return ReorderableList(
        onReorder: this._reorderCallback,
        onReorderDone: this._reorderDone,
        child: CustomScrollView(
          // cacheExtent: 3000,
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
              actions: <Widget>[
                AnimatedContainer(
                    duration: animationDuration,
                    width: (keyboardPart == part) ? 24 : 0,
                    height: 24,
                    child: Opacity(opacity: 0.5, child: Image.asset('assets/piano.png'))),
                AnimatedContainer(
                    duration: animationDuration,
                    width: (colorboardPart == part) ? 24 : 0,
                    height: 24,
                    child: Opacity(opacity: 0.5, child: Image.asset('assets/colorboard.png'))),
                PopupMenuButton<String>(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Icon(Icons.menu),
                  ),
                  initialValue: "nothing",
                  onSelected: (String selected) {
                    switch (selected) {
                      case "useOnColorboard":
                        setColorboardPart(part);
                        break;
                      case "useOnKeyboard":
                        setKeyboardPart(part);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    PopupMenuItem<String>(
                        enabled: part.instrument.type != InstrumentType.drum,
                        value: "setInstrument",
                        child: Text('Choose Instrument')),
                    PopupMenuItem<String>(
                        value: "useOnKeyboard",
                        child: Row(children: [
                          Checkbox(value: keyboardPart == part, onChanged: null),
                          Expanded(child: Text('Use on Keyboard')),
                          Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                              child: Image.asset(
                                'assets/piano.png',
                                width: 20,
                                height: 20,
                              ))
                        ])),
                    if (part.instrument.type != InstrumentType.drum)
                      PopupMenuItem<String>(
                          value: "useOnColorboard",
                          child: Row(children: [
                            Checkbox(value: colorboardPart == part, onChanged: null),
                            Expanded(
                                child: Text(
                              'Use on Colorboard',
                            )),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                child: Image.asset(
                                  'assets/colorboard.png',
                                  width: 20,
                                  height: 20,
                                ))
                          ])),
                    const PopupMenuItem<String>(value: "blah", child: Text('Remove Part')),
                  ],
                ),
              ],
              pinned: true,
              expandedHeight: 100.0,
              flexibleSpace: FlexibleSpaceBar(
//                stretchModes: [StretchMode.fadeTitle],
                centerTitle: false,
                titlePadding: EdgeInsets.all(0),
//                titlePadding: EdgeInsets.only(left: 8, bottom: 15),
//                titlePadding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                title: Handle(
                    delay: const Duration(milliseconds: 250),
                    child: FlatButton(
                        onPressed: () {
                          print("hi");
                          selectPart(part);
                        },
                        child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: Text(
                                  part.instrument.name,
                                  style: TextStyle(color: Colors.white, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ))))),
              ),
            ),
            SliverAppBar(
              backgroundColor: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
              floating: true,
              pinned: false,
              expandedHeight: 50.0,
              flexibleSpace: Slider(
                  value: max(0.0, min(1.0, part.instrument.volume)),
                  activeColor: Colors.white,
                  onChanged: (value) {
                    setPartVolume(part, value);
                  }),
            ),
            SliverAppBar(
              backgroundColor: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
              floating: true,
              pinned: false,
              expandedHeight: 50.0,
              flexibleSpace: FlatButton(
                  onPressed: () {
                    setState(() {
                      part.melodies.insert(0, Melody()..id = uuid.v4());
                    });
                  },
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                  )),
            ),
            SliverPadding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                sliver: SliverList(
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
          ],
        ));
  }
}

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
    this.toggleEditingMelody, this.hideMelodyView,
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

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    BoxDecoration decoration;
    var color = widget.melody == widget.selectedMelody ? Colors.white : Color(0xFFDDDDDD);

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

    Widget content = Container(
        decoration: decoration,
        padding: EdgeInsets.only(bottom: 5),
        child: Stack(children: [
          Column(children: [
            Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: TextField(
                  controller: TextEditingController()..text = widget.melody.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    widget.melody.name = value;
                  },
                  onTap: () {
                    if(!context.isTabletOrLandscapey) {
                      widget.hideMelodyView();
                    }
                  },
                  decoration:
                      InputDecoration(border: InputBorder.none, hintText: "Melody ${widget.melody.id.substring(0, 5)}"),
                )),
//              Text("Melody ${melody.id.substring(0, 5)}"),
            ExpandedSection(
              child: Slider(
                  value: reference.volume,
                  activeColor: widget.sectionColor,
                  onChanged: (reference.playbackType == MelodyReference_PlaybackType.disabled)
                      ? null
                      : (value) {
                          widget.setReferenceVolume(reference, value);
                        }),
              axis: Axis.vertical,
              expand: reference.playbackType != MelodyReference_PlaybackType.disabled,
            ),
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
                          onPressed: () {
                            if(widget.editingMelody && widget.melody == widget.selectedMelody) {
                              widget.toggleEditingMelody();
                            } else {
                              if(widget.editingMelody) {
                                widget.toggleEditingMelody();
                              }
                              widget.selectMelody(widget.melody);
                            }
                          },
                          color: (widget.melody == widget.selectedMelody && !widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
                          child: Icon(Icons.remove_red_eye))),
                  AnimatedContainer(
                      duration: animationDuration,
                      width: (reference.playbackType == MelodyReference_PlaybackType.disabled) ? 0 : 40,
                      height: 36,
                      child: RaisedButton(
                          onPressed: () {
                            if(widget.melody != widget.selectedMelody) {
                              widget.selectMelody(widget.melody);
                            }
                            widget.toggleEditingMelody(); },
                          padding: EdgeInsets.all(0),
                          color: (widget.melody == widget.selectedMelody && widget.editingMelody) ? widget.sectionColor : Color(0xFFDDDDDD),
                          child: SvgPicture.asset(
                            'assets/edit.svg',
                            fit: BoxFit.fill,
                          ))),
                  Expanded(child: SizedBox()),
                ]))
          ])
        ]));

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    content = Padding(
        padding: EdgeInsets.all(2),
        child: DelayedReorderableListener(
          child: content,
        ));
    content = AnimatedSize(vsync: this, duration: animationDuration,
    child: content);

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: Key(widget.melody.id), //
        childBuilder: _buildChild);
  }
}
