import 'dart:math';

import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/rendering.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'animations/animations.dart';

class PartMelodiesView extends StatefulWidget {
  final Score score;
  final Axis axis;
  final Function(VoidCallback) setState;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;
  final Function(Melody) selectMelody;

  PartMelodiesView({this.score, this.setState, this.axis = Axis.horizontal, this.sectionColor, this.currentSection, this.selectedMelody, this.selectMelody});

  @override
  _PartMelodiesViewState createState() {
    return new _PartMelodiesViewState();
  }
}

class _PartMelodiesViewState extends State<PartMelodiesView> {
  final ScrollController controller = ScrollController();

  Widget _buildPart(Part part) {
    if (widget.axis == Axis.horizontal) {
      return Container(
          key: Key(part.id),
          width: 160,
          child: Column(children: [
//            SizedBox(
//                width: 160,
////                  child: DelayedReorderableListener(
//                child: Handle(
//                    delay: const Duration(milliseconds: 250),
//                    child: FlatButton(
//                      color: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
//                      padding: EdgeInsets.all(0),
//                      child: Text(part.instrument.name, style: TextStyle(color: Colors.white)),
//                      onPressed: () => {},
//                    ))),
////              ),
            Expanded(
              child: _MelodiesView(
                score: widget.score,
                scrollDirection: (widget.axis == Axis.horizontal) ? Axis.vertical : Axis.horizontal,
                partPosition: widget.score.parts.indexOf(part),
                sectionColor: widget.sectionColor,
                setState: setState,
                selectMelody: widget.selectMelody,
                currentSection: widget.currentSection,
                selectedMelody: widget.selectedMelody,
              ),
//              child: _MelodiesView2(
//                score: widget.score,
//                scrollDirection: (widget.axis == Axis.horizontal) ? Axis.vertical : Axis.horizontal,
//                part: part,
//                setState: setState,
//              ),
            )
          ]));
    } else {
      return Row(key: Key(part.id), children: [
        FlatButton(
          key: Key(part.id),
          color: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.black,
          child: Text(part.instrument.name, style: TextStyle(color: Colors.white)),
          onPressed: () => {},
        )
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<Part>(
      scrollDirection: widget.axis,
      // The current items in the list.
      items: widget.score.parts,
      // Called by the DiffUtil to decide whether two object represent the same item.
      // For example, if your items have unique ids, this method should check their id equality.
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, oldIndex, newIndex, newItems) {
        // Remember to update the underlying data when the list has been
        // reordered.
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
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
            builder: (context, dragAnimation, inDrag) => SizeFadeTransition(
                  sizeFraction: 0.7,
                  curve: Curves.easeInOut,
                  animation: animation,
                  child: _buildPart(item),
                ));
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

class _MelodiesView extends StatelessWidget {
  final Score score;
  final int partPosition;
  final Axis scrollDirection;
  final Function(Melody) selectMelody;
  final Function(VoidCallback) setState;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;

  Part get part => score.parts[partPosition];

  List<Melody> get _items {
    return score.parts[partPosition].melodies;
  }

  _MelodiesView({
    this.score,
    this.setState,
    this.scrollDirection,
    this.partPosition, this.sectionColor, this.currentSection, this.selectedMelody, this.selectMelody,
  });

  int _indexOfKey(Key key) {
    return _items.indexWhere((Melody melody) => Key(melody.id) == key);
  }

  bool _reorderCallback(Key item, Key newPosition) {
    int draggingIndex = _indexOfKey(item);
    int newPositionIndex = _indexOfKey(newPosition);

    // Uncomment to allow only even target reorder possition
    // if (newPositionIndex % 2 == 1)
    //   return false;

    final draggedItem = _items[draggingIndex];
    setState(() {
      debugPrint("Reordering $item -> $newPosition");
      _items.removeAt(draggingIndex);
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
                PopupMenuButton<String>(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Icon(Icons.menu),
                  ),
                  initialValue: "nothing",
                  onSelected: (String mode) {
                    setState(() {
                      //_draggingMode = mode;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(value: "setInstrument", child: Text('Choose Instrument')),
                    PopupMenuItem<String>(value: "blah", child:
                    Row(children:[
                      Text('Use on Colorboard'),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                        child:Image.asset('assets/colorboard.png', width: 20, height: 20,)
                      )
                    ])),
                    PopupMenuItem<String>(value: "blah", child:
                    Row(children:[
                      Text('Use on Keyboard'),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                        child:Image.asset('assets/piano.png', width: 20, height: 20,)
                      )
                    ])),
                    const PopupMenuItem<String>(value: "blah", child: Text('Remove Part')),
                  ],
                ),
              ],
              pinned: true,
              expandedHeight: 100.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Handle(delay: const Duration(milliseconds: 250), child: Text(part.instrument.name)),
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
                onChanged: (value) => { setState(() => part.instrument.volume = value) }
              ),
            ),
            SliverAppBar(
              backgroundColor: part.instrument.type == InstrumentType.drum ? Colors.brown : Colors.grey,
              floating: true,
              pinned: false,
              expandedHeight: 50.0,
              flexibleSpace: FlatButton(onPressed: () {  },
              child:Icon(Icons.add, color: Colors.white,)),
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
                        // first and last attributes affect border drawn during dragging
                        isFirst: index == 0,
                        isLast: index == _items.length - 1,
                      );
                    },
                    childCount: _items.length,
                  ),
                )),
          ],
        ));
  }
}

class _MelodyReference extends StatelessWidget {
  _MelodyReference({
    this.melody,
    this.isFirst,
    this.isLast, this.sectionColor, this.currentSection, this.selectedMelody, this.selectMelody,
  });

  final Melody melody;
  final bool isFirst;
  final bool isLast;
  final Color sectionColor;
  final Section currentSection;
  final Melody selectedMelody;
  final Function(Melody) selectMelody;

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    BoxDecoration decoration;

    if (state == ReorderableItemState.dragProxy || state == ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = BoxDecoration(color: Color(0xD0FFFFFF));
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: isFirst && !placeholder
                  ? Divider.createBorderSide(context) //
                  : BorderSide.none,
              bottom: isLast && placeholder
                  ? BorderSide.none //
                  : Divider.createBorderSide(context)),
          color: placeholder ? null : Colors.white);
    }

    Widget content = Container(
        decoration: decoration,
        child: FlatButton(
          onPressed: () {
//            print("Hi");
            selectMelody(melody);
          },
          color: melody == selectedMelody ? Colors.white : Color(0xFFDDDDDD),
          child: Stack(children: [
            Column(children: [
              Text("Melody ${melody.id.substring(0, 5)}"),
              Slider(value: 0.5, activeColor: sectionColor, onChanged: (value) => {}),
            ])
          ]))
//      child: SafeArea(
//          top: false,
//          bottom: false,
//          child: Opacity(
//            // hide content for placeholder
//            opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
//            child: IntrinsicHeight(
//              child: Row(
//                crossAxisAlignment: CrossAxisAlignment.stretch,
//                children: <Widget>[
//                  Expanded(
//                      child: Padding(
//                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
//                    child: Text("Melody ${melody.id}", style: TextStyle(color: Colors.black)),
//                  )),
//                ],
//              ),
//            ),
//          )),
        );

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    content = Padding(
        padding: EdgeInsets.all(2),
        child: DelayedReorderableListener(
          child: content,
        ));

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(
        key: Key(melody.id), //
        childBuilder: _buildChild);
  }
}
