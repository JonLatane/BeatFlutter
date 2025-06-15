import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart' as frl;
import 'package:animated_list_plus/transitions.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../music_preview/melody_preview.dart';
import '../ui_models.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import '../widget/beats_badge.dart';
import '../widget/my_buttons.dart';
import '../widget/my_platform.dart';

class MelodyReferenceView extends StatefulWidget {
  static const double minColumnWidth = 100;
  static const double maxColumnWidth = 250;
  static const double columnWidthIncrement = 12;
  static const double columnWidthMicroIncrement = 1.4;
  static Melody? lastAddedMelody;
  final Melody melody;
  final bool isFirst;
  final bool isLast;
  final Color sectionColor;
  final Section currentSection;
  final Part part;
  final Melody? selectedMelody;
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
  final bool showMediumDetails;
  final bool showHighDetails;
  final double width;

  MelodyReferenceView({
    required this.melody,
    required this.isFirst,
    required this.isLast,
    required this.sectionColor,
    required this.currentSection,
    required this.selectedMelody,
    required this.selectMelody,
    required this.colorboardPart,
    required this.keyboardPart,
    required this.toggleMelodyReference,
    required this.setReferenceVolume,
    required this.editingMelody,
    required this.toggleEditingMelody,
    required this.hideMelodyView,
    required this.showBeatsBadge,
    required this.requestScrollToTop,
    required this.showMediumDetails,
    required this.showHighDetails,
    required this.part,
    required this.width,
  });

  @override
  _MelodyReferenceViewState createState() => _MelodyReferenceViewState();
}

class _MelodyReferenceViewState extends State<MelodyReferenceView>
    with TickerProviderStateMixin {
  MelodyReference get reference =>
      widget.currentSection.referenceTo(widget.melody)!;

  bool get isSelectedMelody => widget.melody.id == widget.selectedMelody?.id;
  late AnimationController animationController;
  TextEditingController nameController = TextEditingController();
  bool get allowEditName => widget.showMediumDetails;
  bool get showVolume =>
      widget.showMediumDetails &&
      reference.playbackType != MelodyReference_PlaybackType.disabled;

  @override
  initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  dispose() {
    animationController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return frl.ReorderableItem(
        key: Key("${widget.melody.id}"), //
        childBuilder: _buildChild);
  }

  Widget _buildChild(BuildContext context, frl.ReorderableItemState state) {
    BoxDecoration decoration;
    Gradient gradient;
    Color bgColor = melodyColor;
    var baseGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment(1.0, 0.0),
      colors: [bgColor, bgColor],
      tileMode: TileMode.repeated, // repeats the gradient over the canvas
    );
    final baseSelectedColor = Color.alphaBlend(
        widget.sectionColor.withOpacity(0.5), musicBackgroundColor);
    final baseSelectedGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment(1.0, 0.0),
      colors: [baseSelectedColor, baseSelectedColor],
      tileMode: TileMode.repeated,
    );
    if (widget.showMediumDetails) {
      gradient = isSelectedMelody ? baseSelectedGradient : baseGradient;
    } else {
      gradient = MelodyPreview.generateVolumeDecoration(
          reference, widget.currentSection,
          isSelectedMelody: isSelectedMelody,
          bgColor: bgColor,
          sectionColor: widget.sectionColor);
    }

    if (state == frl.ReorderableItemState.dragProxy ||
        state == frl.ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = BoxDecoration(gradient: gradient);
    } else {
      bool placeholder = state == frl.ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: widget.isFirst && !placeholder
                  ? Divider.createBorderSide(context) //
                  : BorderSide.none,
              bottom: widget.isLast && placeholder
                  ? BorderSide.none //
                  : Divider.createBorderSide(context)),
          // borderRadius: BorderRadius.circular(5),
          gradient: gradient);
    }
    nameController.value =
        nameController.value.copyWith(text: widget.melody.name);

    Widget content = AnimatedContainer(
        duration: animationDuration,
        decoration: decoration,
        padding: EdgeInsets.zero,
        child: Stack(children: [
          MyFlatButton(
            padding: EdgeInsets.only(bottom: 18),
            onPressed: () {
              if (!isSelectedMelody) {
                widget.requestScrollToTop();
              }
              widget.selectMelody(widget.melody);
            },
            onLongPress: widget.showMediumDetails
                ? null
                : () => widget.toggleMelodyReference(reference),
            child: AnimatedContainer(
              duration: animationDuration,
              // color: widget.showMediumDetails ? Colors.transparent : widget.sectionColor,
              child: Column(children: [
                SizedBox(height: 51.1),
                AnimatedOpacity(
                  duration: animationDuration,
                  opacity: widget.showHighDetails
                      ? reference.isEnabled
                          ? 1
                          : 0.5
                      : 0,
                  child: AnimatedContainer(
                    duration: animationDuration,
                    width: 190,
                    height: widget.showHighDetails ? 80 : 0,
                    child: Column(
                      children: [
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(child: SizedBox()),
                            MelodyPreview(
                                section: widget.currentSection,
                                part: widget.part,
                                melody: widget.melody,
                                height: 65,
                                width: 190,
                                scale: 0.12),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
//              Text("Melody ${melody.id.substring(0, 5)}"),
                AnimatedOpacity(
                    duration: animationDuration,
                    opacity: showVolume ? 1 : 0,
                    child: AnimatedContainer(
                      duration: animationDuration,
                      height: showVolume ? 40 : 0,
                      width: widget.width - 10,
                      child: MySlider(
                          value: reference.volume,
                          activeColor: widget.sectionColor,
                          onChanged: (showVolume)
                              ? (value) {
                                  widget.setReferenceVolume(reference, value);
                                }
                              : null),
                    )),
                Align(
                    alignment: Alignment.centerRight,
                    child: Row(children: [
                      Expanded(child: SizedBox()),
                      AnimatedOpacity(
                        duration: animationDuration,
                        opacity: widget.showMediumDetails ? 1 : 0,
                        child: AnimatedContainer(
                          duration: animationDuration,
                          decoration: BoxDecoration(
                              color: (reference.playbackType ==
                                      MelodyReference_PlaybackType.disabled)
                                  ? Color(0x88DDDDDD)
                                  : widget.sectionColor,
                              borderRadius: BorderRadius.circular(15)),
                          width: 60,
                          height: widget.showMediumDetails ? 36 : 0,
                          child: MyFlatButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              widget.toggleMelodyReference(reference);
                            },
                            child: Align(
                                alignment: Alignment.center,
                                child: Icon(
                                    (reference.playbackType ==
                                            MelodyReference_PlaybackType
                                                .disabled)
                                        ? Icons.not_interested
                                        : Icons.volume_up,
                                    color: widget.sectionColor.textColor())),
                          ),
                        ),
                      ),
                      Expanded(child: SizedBox()),
                    ])),
              ]),
            ),
          ),
          Container(
            padding: EdgeInsets.only(top: 5),
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Row(children: [
                  BeatsBadge(
                      beats: widget.melody.length ~/
                          widget.melody.subdivisionsPerBeat,
                      show: widget.showBeatsBadge),
                  SizedBox(width: 3),
                  Expanded(
                      child: IgnorePointer(
                    ignoring: !widget.showMediumDetails,
                    child: TextField(
                      enabled: widget.showMediumDetails,
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        widget.melody.name = value;
                        //                          BeatScratchPlugin.updateMelody(widget.melody);
                        BeatScratchPlugin.onSynthesizerStatusChange();
                      },
                      style: TextStyle(
                          color: melodyColor.textColor().withOpacity(
                              reference.isEnabled == true ? 1 : 0.5)),
                      onTap: () {
                        if (!context.isTabletOrLandscapey) {
                          widget.hideMelodyView();
                        }
                        if (!MyPlatform.isMacOS) {
                          widget.requestScrollToTop();
                        }
                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: widget.melody.idName),
                    ),
                  )),
                  frl.ReorderableListener(
                      child: Container(
                          width: 24,
                          height: 24,
//                          padding: EdgeInsets.only(right:0),
                          child: Icon(Icons.reorder,
                              color: melodyColor.textColor().withOpacity(
                                  reference.isEnabled == true ? 1 : 0.5))))
                ])),
          ),
          Row(
            children: [
              Expanded(child: SizedBox()),
              Column(
                children: [
                  AnimatedContainer(
                      duration: animationDuration,
                      height: widget.showMediumDetails ? 40 : 0,
                      child: SizedBox()),
                  AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.showHighDetails
                        ? 0
                        : reference.isEnabled
                            ? 0.5
                            : 0.25,
                    child: MelodyPreview(
                        section: widget.currentSection,
                        part: widget.part,
                        melody: widget.melody,
                        height: 65,
                        width: MelodyReferenceView.minColumnWidth - 4,
                        scale: 0.11),
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
            ],
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
    if (MelodyReferenceView.lastAddedMelody == widget.melody) {
      MelodyReferenceView.lastAddedMelody = null;
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
