import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../settings/app_settings.dart';
import '../storage/score_manager.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import '../widget/my_buttons.dart';
import '../widget/scalable_view.dart';
import 'layers_part_view.dart';

/**
 * The Layers
 */
class LayersView extends StatefulWidget {
  final AppSettings appSettings;
  final ScoreManager scoreManager;
  final MusicViewMode musicViewMode;
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
  final bool showViewOptions;
  final bool shiftUpZoomControls;

  LayersView(
      {this.musicViewMode,
      this.superSetState,
      this.appSettings,
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
      this.height,
      Key key,
      this.showViewOptions,
      this.scoreManager,
      this.shiftUpZoomControls})
      : super(key: key);

  @override
  _LayersViewState createState() {
    return new _LayersViewState();
  }
}

class _LayersViewState extends State<LayersView> {
  final ScrollController controller = ScrollController();
  static const double minColumnWidth = LayersPartView.minColumnWidth;
  static const double maxColumnWidth = LayersPartView.maxColumnWidth;
  static const double columnWidthIncrement =
      LayersPartView.columnWidthIncrement;
  static const double columnWidthMicroIncrement =
      LayersPartView.columnWidthMicroIncrement;

  double get columnWidth => widget.appSettings.layersColumnWidth;
  set columnWidth(double v) => widget.appSettings.layersColumnWidth =
      max(minColumnWidth, min(maxColumnWidth, v));

  double get columnWidthPercent =>
      0.99 *
          (columnWidth - minColumnWidth) /
          (maxColumnWidth - minColumnWidth) +
      .01;

  bool get autoScroll => widget.appSettings.autoScrollLayers;
  set autoScroll(bool v) => widget.appSettings.autoScrollLayers = v;

  // How "zoom" is achieved
  bool get showMediumDetails =>
      columnWidth > minColumnWidth + 3 * columnWidthIncrement;
  bool get showHighDetails =>
      columnWidth > maxColumnWidth - 3 * columnWidthIncrement;

  @override
  initState() {
    super.initState();
  }

  Widget _buildAddButton() {
    double width = widget.score.parts.isNotEmpty
        ? 320
        : context.isTablet
            ? min(600, widget.availableWidth / 2)
            : widget.availableWidth;
    bool canAddPart = widget.score.parts.length < 5;
    bool canAddDrumPart = canAddPart &&
        !(widget.score.parts
            .any((element) => element.instrument.type == InstrumentType.drum));
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
                            widget.selectPart(part);
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
                    style: TextStyle(
                        color: canAddDrumPart ? Colors.white : Colors.black26),
                  ),
                  if (widget.height > 100)
                    Container(
                        width: 270,
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          "Kits, whistles, gunshots, zips, zaps, crickets, screams, and more.   Drum Parts written using "
                          "MIDI pitch values. Standards include: Kick = B1, Snare = D2, Hat = F#2.",
                          style: TextStyle(
                              color: canAddDrumPart
                                  ? Colors.white
                                  : Colors.black26,
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
                        if (widget.score.parts.isNotEmpty &&
                            widget.score.parts.last.isDrum /*&& !kIsWeb*/) {
                          widget.score.parts
                              .insert(widget.score.parts.length - 1, part);
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
                        widget.selectPart(part);
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
                style: TextStyle(
                    color: canAddPart ? Colors.white : Colors.black26),
              ),
              if (widget.height > 100)
                Container(
                    width: 270,
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      "Pianos, guitars, voice, and all other instruments that play notes. Melodies in Harmonic Parts "
                      "can be transformed to fit Harmonies. ",
                      style: TextStyle(
                          color: canAddPart ? Colors.white : Colors.black26,
                          fontSize: 10,
                          fontWeight: FontWeight.w100),
                    )),
              Expanded(child: SizedBox()),
            ])),
      )),
    ]);
  }

  Widget _buildPart(Part part) {
    return AnimatedContainer(
      duration: animationDuration,
      key: Key("part-container-${part.id}"),
      width: this.columnWidth,
      child: Column(children: [
        Expanded(
          child: LayersPartView(
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
            showMediumDetails: showMediumDetails,
            showHighDetails: showHighDetails,
            width: columnWidth,
            height: widget.height,
            autoScroll: autoScroll,
          ),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScalableView(
        child: ImplicitlyAnimatedReorderableList<Part>(
          key: ValueKey("LayersViewPartList"),
//      key: Key(widget.score.parts.map((e) => e.id).toString()),
          scrollDirection: Axis.horizontal,
          // The current items in the list.
          items: widget.score.parts + [Part()..id = "add-button"],
          // Called by the DiffUtil to decide whether two object represent the same item.
          // For example, if your items have unique ids, this method should check their id equality.
          areItemsTheSame: (a, b) => a.id == b.id,
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
            return item.id != "add-button"
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
                          axis: (dragAnimation.value > 0 || inDrag)
                              ? Axis.vertical
                              : Axis.horizontal);
                    })
                : Reorderable(
                    // Each item must have an unique key.
                    key: Key("add"),
                    builder: (context, dragAnimation, inDrag) =>
                        _buildAddButton());
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
        ),
        zoomButtonColor:
            widget.keyboardPart.isDrum ? Colors.brown : Colors.grey,
        shiftUpZoomControls: widget.shiftUpZoomControls,
        onScaleDown: (columnWidth > minColumnWidth)
            ? () {
                setState(() {
                  columnWidth -= columnWidthIncrement;
                  columnWidth = max(columnWidth, minColumnWidth);
                });
              }
            : null,
        onScaleUp: (columnWidth < maxColumnWidth)
            ? () {
                setState(() {
                  columnWidth += columnWidthIncrement;
                  columnWidth = min(columnWidth, maxColumnWidth);
                });
              }
            : null,
        onMicroScaleDown: (columnWidth > minColumnWidth)
            ? () {
                setState(() {
                  columnWidth -= columnWidthMicroIncrement;
                  columnWidth = max(columnWidth, minColumnWidth);
                });
              }
            : null,
        onMicroScaleUp: (columnWidth < maxColumnWidth)
            ? () {
                setState(() {
                  columnWidth += columnWidthMicroIncrement;
                  columnWidth = min(columnWidth, maxColumnWidth);
                });
              }
            : null,
        zoomLevelDescription:
            "${(columnWidthPercent * 100).toStringAsFixed(0)}%",
        autoScroll: autoScroll,
        toggleAutoScroll: () {
          setState(() {
            autoScroll = !autoScroll;
          });
        },
        showViewOptions: widget.showViewOptions);
  }
}
