import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'dummydata.dart';
import 'ui_models.dart';
import 'util.dart';

import 'animations/size_fade_transition.dart';

class SectionList extends StatefulWidget {
  final Axis scrollDirection;
  final bool visible;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Function(Section) selectSection;
  final Function(VoidCallback) setState;

  const SectionList(
      {Key key,
      this.scrollDirection,
      this.visible,
      this.score,
      this.currentSection,
      this.selectSection,
      this.sectionColor,
      this.setState})
      : super(key: key);

  @override
  _SectionListState createState() => _SectionListState();
}

class _SectionListState extends State<SectionList> {
  ScrollController _scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        height: (widget.scrollDirection == Axis.vertical) ? MediaQuery.of(context).size.height : (widget.visible) ? 36 : 0,
        width: (widget.scrollDirection == Axis.horizontal) ? MediaQuery.of(context).size.width : (widget.visible) ? 36 : 0,
        child: (widget.scrollDirection == Axis.horizontal)
            ? Row(children: [
                Expanded(
                    child: Padding(padding: EdgeInsets.all(2), child: getList(context)
//            ListView.builder(
//              scrollDirection: scrollDirection,
//              itemBuilder: (context, position) {
//                return RaisedButton(
//                  color: (currentSection == score.sections[position]) ? sectionColor : Colors.white,
//                  child: Text(score.sections[position].name, style: TextStyle(fontWeight: FontWeight.w100),),
//                  onPressed: () => {selectSection(score.sections[position])},
//                );
//              },
//              itemCount: score.sections.length,
//            )
                        )),
                Container(
                  width: 41, height: 36,
                  padding: EdgeInsets.only(right: 5),
                  child: RaisedButton(
                    child: Icon(Icons.add),
                    padding: EdgeInsets.all(0),
                    onPressed: widget.score.sections.length < 100 ? () {
                      print("inserting section");
                      insertSection();
                    } : null,
                  )
                )
              ])
            : Column(children: [
                Expanded(
                    child: ListView.builder(
                  scrollDirection: widget.scrollDirection,
                  itemBuilder: (context, position) {
                    return RaisedButton(
                      color: (widget.currentSection == widget.score.sections[position]) ? Colors.white : Colors.grey,
                      child: Text(widget.score.sections[position].name),
                      onPressed: () => {
                        //selectSection(score.sections[position])
                      },
                    );
                  },
                  itemCount: widget.score.sections.length,
                )),
                RaisedButton(
                  child: Icon(Icons.add),
                  onPressed: widget.score.sections.length < 100 ? () {
                    print("inserting section");
                    insertSection();
                  } : null,
                )
              ]));
  }

  insertSection() {
    Section newSection = Section()
      ..id = uuid.v4()
      ..harmony = (
        Harmony()
          ..id = uuid.v4()
          ..meter = (Meter()..defaultBeatsPerMeasure = 4)
          ..subdivisionsPerBeat = 4
          ..length = 64
          ..data.addAll({0: cChromatic})
      );
    int currentSectionIndex = widget.score.sections.indexOf(widget.currentSection);
    widget.setState(() {
      setState(() {
        widget.score.sections.insert(currentSectionIndex + 1, newSection);
        widget.selectSection(newSection);
      });
    });
    _scrollController.animateTo(_scrollController.offset + 150, duration: animationDuration, curve: Curves.easeInOut);
  }

  Widget getList(BuildContext context) {
    return ImplicitlyAnimatedReorderableList<Section>(
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: widget.score.sections,
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, oldIndex, newIndex, newItems) {
        widget.setState(() {
//          if (newIndex > oldIndex) {
//            newIndex -= 1;
//          }
          Section toMove = widget.score.sections.removeAt(oldIndex);
          widget.score.sections.insert(newIndex, toMove);
        });
      },
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        // Specify a transition to be used by the ImplicitlyAnimatedList.
        // In this case a custom transition.
        return Reorderable(
            // Each item must have an unique key.
            key: Key(section.id),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final tile = Handle(
                  key: Key("handle-${section.id}"),
                  delay: const Duration(milliseconds: 250),
                  child: _Section(
                    sectionColor: widget.sectionColor,
                    selectSection: widget.selectSection,
                    currentSection: widget.currentSection,
                    section: section,
                  ));

              // If the item is in drag, only return the tile as the
              // SizeFadeTransition would clip the shadow.
              if (t > 0.0) {
                return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
//                axis: scrollDirection,
                    animation: animation,
                    child: tile);
              }
              return SizeFadeTransition(
                  sizeFraction: 0.7, curve: Curves.easeInOut, axis: widget.scrollDirection, animation: animation, child: tile);
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

class _Section extends StatefulWidget {
  final Section currentSection;
  final Section section;
  final Color sectionColor;
  final Function(Section) selectSection;

  const _Section({Key key, this.section, this.selectSection, this.currentSection, this.sectionColor}) : super(key: key);

  @override
  _SectionState createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  TextEditingController _controller = TextEditingController();

  get hasName => widget.section.name.trim().length > 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        color: (widget.currentSection == widget.section) ? widget.sectionColor : Colors.white,
        child: FlatButton(
          child: Text(hasName ? widget.section.name : "Section ${widget.section.id.substring(0, 5)}",
            style: TextStyle(fontWeight: FontWeight.w100,
            color: hasName ? Colors.black : Colors.grey),
          ),
          onPressed: () {
            widget.selectSection(widget.section);
          },
        ));
  }
}
