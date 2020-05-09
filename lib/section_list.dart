import 'dart:math';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/part_melodies_view.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'dummydata.dart';
import 'ui_models.dart';
import 'util.dart';

import 'animations/size_fade_transition.dart';

class SectionList extends StatefulWidget {
  final Axis scrollDirection;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Function(Section) selectSection;
  final Function(Section) insertSection;
  final Function(VoidCallback) setState;

  const SectionList(
      {Key key,
      this.scrollDirection,
      this.score,
      this.currentSection,
      this.selectSection,
      this.insertSection,
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
    _animateToNewlySelectedSection();
    return (widget.scrollDirection == Axis.horizontal)
        ? Row(children: [
            Expanded(child: Padding(padding: EdgeInsets.all(2), child: getList(context))),
            Container(
                width: 37,
                height: 32,
                padding: EdgeInsets.only(right: 5),
                child: RaisedButton(
                  child: Image.asset("assets/add.png"),
                  padding: EdgeInsets.all(2),
                  onPressed: widget.score.sections.length < 100
                      ? () {
                          print("inserting section");
                          widget.insertSection(defaultSection());
                        }
                      : null,
                ))
          ])
        : Column(children: [
            Expanded(child: getList(context)),
            Row(children: [
              Expanded(
                  child: Container(
                      height: 36,
                      child: RaisedButton(
                        child: Image.asset("assets/add.png"),
                        onPressed: widget.score.sections.length < 100
                            ? () {
                                print("inserting section");
                                widget.insertSection(defaultSection());
                              }
                            : null,
                      )))
            ])
          ]);
  }

  Section _previousSection;
  _animateToNewlySelectedSection() {
    if(_previousSection != null && _previousSection.id != widget.currentSection.id) {
      int index = widget.score.sections.indexOf(widget.currentSection);
      if (widget.scrollDirection == Axis.horizontal) {
        double position = 150.0 * (index - 1);
        position = min(_scrollController.position.maxScrollExtent + 300, position);
        _scrollController.animateTo(position, duration: animationDuration, curve: Curves.easeInOut);
      } else {
        double position = 36.0 * (index - 1);
        position = min(_scrollController.position.maxScrollExtent + 72, position);
        _scrollController.animateTo(position, duration: animationDuration, curve: Curves.easeInOut);
      }
      _previousSection = widget.currentSection;
    }
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
          BeatScratchPlugin.updateSections(widget.score);
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
              final tile = _Section(
                sectionColor: widget.sectionColor,
                selectSection: widget.selectSection,
                currentSection: widget.currentSection,
                scrollDirection: widget.scrollDirection,
                section: section,
              );

              // If the item is in drag, only return the tile as the
              // SizeFadeTransition would clip the shadow.
              if (t > 0.0 || inDrag) {
                return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    axis: widget.scrollDirection == Axis.horizontal ? Axis.vertical : Axis.horizontal,
                    animation: animation,
                    child: tile);
              }
              return SizeFadeTransition(
                  sizeFraction: 0.7,
                  curve: Curves.easeInOut,
                  axis: widget.scrollDirection,
                  animation: animation,
                  child: tile);
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
  final Axis scrollDirection;

  const _Section(
      {Key key, this.section, this.selectSection, this.currentSection, this.sectionColor, this.scrollDirection})
      : super(key: key);

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
        width: 180,
        height: 36,
        color: (widget.currentSection == widget.section) ? widget.sectionColor : Colors.white,
        child: FlatButton(
          padding: EdgeInsets.only(left: 5, right: 5),
          child: Stack(children:[Row(children: [
            BeatsBadge(beats: widget.section.harmony.length ~/ widget.section.harmony.subdivisionsPerBeat),
            SizedBox(width:3),
            Expanded(
                child: Align(
              alignment: widget.scrollDirection == Axis.horizontal ? Alignment.center : Alignment.centerLeft,
              child: Text(
                hasName ? widget.section.name : "Section ${widget.section.id.substring(0, 5)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w100, color: hasName ? Colors.black : Colors.grey),
              ),
            )),
            Handle(
                key: Key("handle-${widget.section.id}"),
                delay: const Duration(milliseconds: 0),
                child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.reorder,
                      size: 24,
                    )))
          ]),
    ]),
          onPressed: () {
            widget.selectSection(widget.section);
          },
        ));
  }
}
