import 'dart:math';

import 'package:beatscratch_flutter_redux/settings/settings.dart';
import 'package:beatscratch_flutter_redux/widget/color_filtered_image_asset.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import '../colors.dart';
import 'beats_badge.dart';
import 'my_buttons.dart';

class SectionList extends StatefulWidget {
  final Axis scrollDirection;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Function(Section) selectSection;
  final Function(Section) insertSection;
  final Function(VoidCallback) setState;
  final bool showSectionBeatCounts;
  final VoidCallback toggleShowSectionBeatCounts;
  final bool allowReordering;
  final AppSettings appSettings;
  final double width, height;

  const SectionList(
      {Key key,
      this.scrollDirection,
      this.score,
      this.currentSection,
      this.selectSection,
      this.insertSection,
      this.sectionColor,
      this.setState,
      this.showSectionBeatCounts,
      this.toggleShowSectionBeatCounts,
      this.allowReordering,
      this.appSettings,
      this.width,
      this.height})
      : super(key: key);

  @override
  _SectionListState createState() => _SectionListState();
}

class _SectionListState extends State<SectionList> {
  ScrollController _scrollController = ScrollController();

  Color get buttonBackgroundColor =>
      widget.appSettings.darkMode ? musicBackgroundColor : Colors.grey.shade500;
  @override
  Widget build(BuildContext context) {
    _animateToNewlySelectedSection();
    int beatCount = widget.score.beatCount;

    return (widget.scrollDirection == Axis.horizontal)
        ? Row(children: [
            Expanded(
                child:
                    Padding(padding: EdgeInsets.zero, child: getList(context))),
            AnimatedContainer(
                duration: animationDuration,
                width: beatsBadgeWidth(beatCount) + 5,
                height: 32,
                padding: EdgeInsets.zero,
                child: MyFlatButton(
                    padding: EdgeInsets.zero,
                    onPressed: widget.toggleShowSectionBeatCounts,
                    child: BeatsBadge(
                      beats: beatCount,
                      opacity: widget.showSectionBeatCounts ? 1 : 0.5,
                    ))),
            AnimatedContainer(
                duration: animationDuration,
                width: widget.allowReordering ? 37 : 0,
                height: 32,
                padding: EdgeInsets.only(right: 5),
                child: MyRaisedButton(
                  color: buttonBackgroundColor,
                  child: ColorFilteredImageAsset(
                    imageSource: "assets/add.png",
                    imageColor: Colors.white,
                  ),
                  padding: EdgeInsets.all(2),
                  onPressed: widget.score.sections.length < 100
                      ? () {
                          print("inserting section");
                          widget.insertSection(defaultSection()
                            ..tempo = (Tempo()
                              ..bpm = widget.currentSection.tempo.bpm));
                        }
                      : null,
                ))
          ])
        : Column(children: [
            Expanded(child: getList(context)),
            Row(children: [
              Expanded(
                  child: AnimatedOpacity(
                      duration: animationDuration,
                      opacity: widget.showSectionBeatCounts ? 1 : 0.5,
                      child: AnimatedContainer(
                        duration: animationDuration,
//            width: widget.showSectionBeatCounts ? beatsBadgeWidth(beatCount) : 0,
                        height: 36,
                        child: MyFlatButton(
                            padding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 5),
                            onPressed: widget.toggleShowSectionBeatCounts,
                            child: Row(children: [
                              Expanded(child: SizedBox()),
                              Column(children: [
                                Expanded(child: SizedBox()),
                                Text(
                                  "$beatCount",
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900, height: 0.9),
                                ),
                                SizedBox(height: 1),
                                Text(
                                  "beat${beatCount == 1 ? "" : "s"}",
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w100,
                                      fontSize: 8,
                                      height: 0.9),
                                ),
                                Expanded(child: SizedBox()),
                              ]),
                              Expanded(child: SizedBox()),
                            ])),
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.black,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(5))),
                      ))), // ]),
//      ]),
              // Row(children: [
              AnimatedContainer(
                  duration: animationDuration,
                  height: 36,
                  width: widget.allowReordering ? 82.5 : 0,
                  padding: EdgeInsets.all(1),
                  child: MyRaisedButton(
                    color: buttonBackgroundColor,
                    child: ColorFilteredImageAsset(
                      imageSource: "assets/add.png",
                      imageColor: Colors.white,
                    ),
                    onPressed: widget.score.sections.length < 100
                        ? () {
                            print("inserting section");
                            widget.insertSection(defaultSection()
                              ..tempo = (Tempo()
                                ..bpm = widget.currentSection.tempo.bpm));
                          }
                        : null,
                  ))
            ])
          ]);
  }

  Section _previousSection;

  _animateToNewlySelectedSection() {
    try {
      if (_previousSection != null &&
          _previousSection.id != widget.currentSection.id) {
        _animateToCurrentSection();
      }
    } catch (any) {}
    _previousSection = widget.currentSection;
  }

  _animateToCurrentSection() {
    int index = widget.score.sections.indexOf(widget.currentSection);
    if (widget.scrollDirection == Axis.horizontal) {
      double margin = max(0.0, widget.width - _Section.width);
      double position = _Section.width * (index) - margin * 0.25;
      position = min(_scrollController.position.maxScrollExtent, position);
      position = max(0, position);
      _scrollController.animateTo(position,
          duration: animationDuration, curve: Curves.easeInOut);
    } else {
      double margin = max(0.0, widget.height - _Section.height);
      double position = _Section.height * (index) - margin * 0.25;
      position = min(_scrollController.position.maxScrollExtent, position);
      position = max(0, position);
      _scrollController.animateTo(position,
          duration: animationDuration, curve: Curves.easeInOut);
    }
  }

  Widget getList(BuildContext context) {
    var items = widget.score?.sections ?? [];
    if (items.isEmpty) {
      items = [defaultSection()];
    }
    return ImplicitlyAnimatedReorderableList<Section>(
      key: ValueKey("SectionList-${widget.scrollDirection}"),
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: items,
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
                showBeatCount: widget.showSectionBeatCounts,
                allowReordering: widget.allowReordering,
              );

              // If the item is in drag, only return the tile as the
              // SizeFadeTransition would clip the shadow.
              if (t > 0.0 || inDrag) {
                return SizeFadeTransition(
                    sizeFraction: 0.7,
                    curve: Curves.easeInOut,
                    axis: widget.scrollDirection == Axis.horizontal
                        ? Axis.vertical
                        : Axis.horizontal,
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
  static const double width = 165.0;
  static const double height = 36.0;
  final Section currentSection;
  final Section section;
  final Color sectionColor;
  final Function(Section) selectSection;
  final Axis scrollDirection;
  final bool showBeatCount;
  final bool allowReordering;

  const _Section(
      {Key key,
      this.section,
      this.selectSection,
      this.currentSection,
      this.sectionColor,
      this.scrollDirection,
      this.showBeatCount,
      this.allowReordering})
      : super(key: key);

  @override
  _SectionState createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  get hasName => widget.section.name.trim().length > 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        width: _Section.width,
        height: _Section.height,
        color: musicBackgroundColor,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: SizedBox()),
                Row(
                  children: [
                    AnimatedContainer(
                        duration: animationDuration,
                        width: widget.currentSection == widget.section ? 0 : 2,
                        height: _Section.height,
                        // color: widget.sectionColor,
                        child: SizedBox()),
                    AnimatedContainer(
                        duration: animationDuration,
                        width: widget.currentSection == widget.section
                            ? _Section.width
                            : 5,
                        height: widget.currentSection == widget.section
                            ? _Section.height
                            : _Section.height - 4,
                        color: widget.section.color.color,
                        child: SizedBox()),
                  ],
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            MyFlatButton(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Stack(children: [
                Row(children: [
                  BeatsBadge(
                      beats: widget.section.harmony.length ~/
                          widget.section.harmony.subdivisionsPerBeat,
                      show: widget.showBeatCount),
                  SizedBox(width: 3),
                  Expanded(
                      child: Align(
                    alignment: widget.scrollDirection == Axis.horizontal
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Text(
                      widget.section.canonicalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w100,
                          color: hasName
                              ? (widget.currentSection == widget.section)
                                  ? widget.sectionColor.textColor()
                                  : musicForegroundColor
                              : Colors.grey),
                    ),
                  )),
                  AnimatedContainer(
                      duration: animationDuration,
                      width: widget.allowReordering ? 24 : 0,
                      child: Handle(
                          key: Key("handle-${widget.section.id}"),
                          delay: const Duration(milliseconds: 0),
                          child: Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: AnimatedOpacity(
                                  duration: animationDuration,
                                  opacity: widget.allowReordering ? 1 : 0,
                                  child: Icon(
                                    Icons.reorder,
                                    color: (widget.currentSection ==
                                            widget.section)
                                        ? widget.sectionColor.textColor()
                                        : musicForegroundColor,
                                    size: 24,
                                  )))))
                ]),
              ]),
              onPressed: () {
                widget.selectSection(widget.section);
              },
            ),
          ],
        ));
  }
}
