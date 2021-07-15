import 'package:beatscratch_flutter_redux/widget/color_filtered_image_asset.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import '../ui_models.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import '../widget/my_buttons.dart';

class MelodyToolbar extends StatefulWidget {
  final MusicViewMode musicViewMode;
  final bool editingMelody;
  final Melody melody;
  final Section currentSection;
  final Color sectionColor;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(MelodyReference, double) setReferenceVolume;
  final VoidCallback toggleRecording, backToPart;
  final Function(Melody, String) setMelodyName;
  final Function(Melody) deleteMelody;

  const MelodyToolbar(
      {Key key,
      this.melody,
      this.currentSection,
      this.toggleMelodyReference,
      this.setReferenceVolume,
      this.editingMelody,
      this.sectionColor,
      this.toggleRecording,
      this.backToPart,
      this.setMelodyName,
      this.musicViewMode,
      this.deleteMelody})
      : super(key: key);

  @override
  MelodyToolbarState createState() => MelodyToolbarState();
}

class MelodyToolbarState extends State<MelodyToolbar> {
  bool _showVolume;
  TextEditingController nameController;

  MelodyReference get melodyReference =>
      widget.currentSection.referenceTo(widget.melody);
  bool get melodySelected => widget.melody != null;
  bool get melodyEnabled =>
      melodySelected && (melodyReference?.isEnabled ?? false);
  Melody confirmingDeleteFor;
  bool get isConfirmingDelete =>
      confirmingDeleteFor != null && confirmingDeleteFor == widget.melody;
  bool get showVolume =>
      (melodyReference?.isEnabled == true) &&
      (/*context.isTablet ||*/ _showVolume);

  @override
  initState() {
    super.initState();
    _showVolume = false;
    nameController = TextEditingController();
  }

  @override
  dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    _showVolume &= melodyReference != null &&
        (melodyReference?.isEnabled == true) &&
        !isConfirmingDelete;

    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.melody) {
      confirmingDeleteFor = null;
    }
    nameController.value =
        nameController.value.copyWith(text: widget.melody?.name ?? "");

    return Container(
//        color: Colors.white,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.musicViewMode == MusicViewMode.melody)
                  ? TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (melodySelected)
                          ? (value) {
                              widget.melody.name = value;
                              widget.setMelodyName(
                                  widget.melody, widget.melody.name);
//                        BeatScratchPlugin.updateMelody(widget.melody);
                            }
                          : null,
//                      onEditingComplete: () {
//                        widget.setMelodyName(widget.melody, widget.melody.name);
//                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: (melodySelected) ? widget.melody.idName : "",
                      ))
                  : Text(""))),
      AnimatedContainer(
          duration: animationDuration,
          width: (melodyEnabled && !isConfirmingDelete) ? 40 : 0,
          height: 36,
          padding: EdgeInsets.only(right: showVolume ? 0 : 5),
          child: MyRaisedButton(
            color: (widget.editingMelody)
                ? widget.sectionColor == chromaticSteps[7]
                    ? Colors.white
                    : widget.sectionColor
                : null,
            onPressed: (melodyEnabled)
                ? () {
                    widget.toggleRecording();
                  }
                : null,
            padding: EdgeInsets.all(0),
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity: (melodyEnabled && !isConfirmingDelete) ? 1 : 0,
                child:
                    /*Stack(children: [
                  Align(
                      alignment: Alignment.bottomRight,
                      child: */
                    Icon(Icons.fiber_manual_record,
                        color: chromaticSteps[
                            7])), /*,
                  Align(
                      alignment: Alignment.topLeft,
                      child: Icon(
                        Icons.edit,
                      ))
                ])),*/
          )),
      AnimatedOpacity(
        opacity: (showVolume) ? 1 : 0,
        duration: animationDuration,
        child: AnimatedContainer(
          duration: animationDuration,
          width: (showVolume)
              ? context.isTablet
                  ? 160
                  : 120
              : 0,
          height: 36,
          padding: EdgeInsets.zero,
          child: MySlider(
              value: melodyReference?.volume ?? 0,
              activeColor:
                  (melodyReference != null) ? widget.sectionColor : Colors.grey,
              onChanged: (melodyReference?.isEnabled != true)
                  ? null
                  : (value) {
                      widget.setReferenceVolume(melodyReference, value);
                    }),
        ),
      ),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 40,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: melodySelected
                  ? () {
                      widget.toggleMelodyReference(melodyReference);
                    }
                  : null,
              onLongPress: (melodyReference?.isEnabled == true)
                  ? () {
                      setState(() {
                        _showVolume = !_showVolume;
                      });
                    }
                  : null,
              padding: EdgeInsets.all(0),
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: (melodySelected && !isConfirmingDelete) ? 1 : 0,
                  child: Icon(melodySelected
                      ? (melodyEnabled ? Icons.volume_up : Icons.not_interested)
                      : Icons.not_interested)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 128 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: Align(
              alignment: Alignment.center,
              child: Text("Really delete?",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  widget.deleteMelody(confirmingDeleteFor);
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text(
                "Yes",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  if (widget.melody.name?.isEmpty != false &&
                      (widget.melody.midiData.data.isEmpty ||
                          widget.melody.midiData.data.values
                              .where((mc) => mc.data.length != 0)
                              .isEmpty)) {
                    widget.deleteMelody(widget.melody);
                  } else {
                    confirmingDeleteFor = widget.melody;
                  }
                });
              },
              padding: EdgeInsets.zero,
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: ColorFilteredImageAsset(
                    imageSource: "assets/trash.png",
                    imageColor: Colors.white,
                  )))),
    ]));
  }
}

class PartToolbar extends StatefulWidget {
  final Color sectionColor;
  final Part part;
  final Function(Part) setKeyboardPart;
  final Function(Part) setColorboardPart;
  final Part colorboardPart;
  final Part keyboardPart;
  final Function(Part) deletePart;
  final bool configuringPart;
  final bool browsingPartMelodies;
  final VoidCallback toggleConfiguringPart, toggleBrowsingPartMelodies;
  final bool enableColorboard;

  const PartToolbar(
      {Key key,
      this.part,
      this.setKeyboardPart,
      this.setColorboardPart,
      this.colorboardPart,
      this.keyboardPart,
      this.deletePart,
      this.configuringPart,
      this.browsingPartMelodies,
      this.toggleConfiguringPart,
      this.sectionColor,
      this.enableColorboard,
      this.toggleBrowsingPartMelodies})
      : super(key: key);

  @override
  PartToolbarState createState() => PartToolbarState();
}

class PartToolbarState extends State<PartToolbar> {
  Part confirmingDeleteFor;

  bool get isConfirmingDelete =>
      confirmingDeleteFor != null && confirmingDeleteFor == widget.part;

  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    if (confirmingDeleteFor != null && confirmingDeleteFor != widget.part) {
      confirmingDeleteFor = null;
    }
    return Container(
      key: Key("part-toolbar-${widget.part?.id}"),
      child: Row(children: [
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(left: 5),
            child: MyRaisedButton(
                onPressed: widget.toggleConfiguringPart,
                padding: EdgeInsets.zero,
                color: widget.configuringPart ? Colors.white : null,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.part == null || isConfirmingDelete ? 0 : 1,
                    child: Icon(Icons.settings,
                        color: widget.configuringPart
                            ? Colors.black
                            : Colors.white)))),
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text((widget.part != null) ? widget.part.midiName : "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600)))),
//        AnimatedContainer(
//            duration: animationDuration,
//            width: isConfirmingDelete ? 0 : 41,
//            height: 36,
//            padding: EdgeInsets.only(right: 5),
//            child: MyRaisedButton(
//                onPressed: widget.part != null
//                    ? () {
//                        widget.setKeyboardPart(widget.part);
//                      }
//                    : null,
//                padding: EdgeInsets.zero,
//                child: AnimatedOpacity(
//                    duration: animationDuration,
//                    opacity: widget.part == null || isConfirmingDelete ? 0 : 1,
//                    child: Stack(children: [
//                      Align(
//                          alignment: Alignment.bottomRight,
//                          child: Padding(
//                              padding: EdgeInsets.all(2),
//                              child: Image.asset("assets/piano.png", width: 22, height: 22))),
//                      Align(
//                          alignment: Alignment.topLeft,
//                          child: Container(
//                              width: 26,
//                              height: 26,
//                              child: Checkbox(value: widget.keyboardPart == widget.part, onChanged: null)))
//                    ])))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete || !widget.enableColorboard ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: (widget.part != null &&
                        widget.part.instrument.type != InstrumentType.drum)
                    ? () {
                        widget.setColorboardPart(widget.part);
                      }
                    : null,
                padding: EdgeInsets.zero,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.part == null ||
                            isConfirmingDelete ||
                            !widget.enableColorboard
                        ? 0
                        : 1,
                    child: Stack(children: [
                      Align(
                          alignment: Alignment.bottomRight,
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: (widget.part != null &&
                                      widget.part.instrument.type !=
                                          InstrumentType.drum)
                                  ? 1
                                  : 0.25,
                              child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Image.asset("assets/colorboard.png",
                                      width: 24, height: 24)))),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                              width: 26,
                              height: 26,
                              child: Checkbox(
                                  value: widget.colorboardPart == widget.part,
                                  onChanged: null)))
                    ])))),
        AnimatedContainer(
            duration: animationDuration,
            width: (/*melodyEnabled && */ !isConfirmingDelete) ? 0 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
              color: (widget.browsingPartMelodies)
                  ? widget.sectionColor == chromaticSteps[7]
                      ? Colors.white
                      : widget.sectionColor
                  : null,
              onPressed: () {
                widget.toggleBrowsingPartMelodies();
              },
              padding: EdgeInsets.all(0),
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: (widget.part != null && !isConfirmingDelete) ? 0 : 0,
                  child: Stack(children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: Icon(Icons.fiber_manual_record,
                            color: chromaticSteps[7])),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.list,
                        ))
                  ])),
            )),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 128 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: Align(
                alignment: Alignment.center,
                child: Text("Really delete?",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white)))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 48 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    widget.deletePart(widget.part);
                    confirmingDeleteFor = null;
                  });
                },
                padding: EdgeInsets.zero,
                child: Text(
                  "Yes",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 48 : 0,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    confirmingDeleteFor = null;
                  });
                },
                padding: EdgeInsets.zero,
                child:
                    Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
        AnimatedContainer(
            duration: animationDuration,
            width: isConfirmingDelete ? 0 : 41,
            height: 36,
            padding: EdgeInsets.only(right: 5),
            child: MyRaisedButton(
                onPressed: () {
                  setState(() {
                    confirmingDeleteFor = widget.part;
                  });
                },
                padding: EdgeInsets.zero,
                child: Padding(
                    padding: EdgeInsets.all(5),
                    child: ColorFilteredImageAsset(
                        imageSource: "assets/trash.png",
                        imageColor: Colors.white)))),
      ]),
    );
  }
}

class SectionToolbar extends StatefulWidget {
  // This widget is the root of your application.
  final bool canDeleteSection;
  final Section currentSection;
  final Color sectionColor;
  final MusicViewMode musicViewMode;
  final Function(Section, String) setSectionName;
  final Function(Section) deleteSection;
  final Function cloneCurrentSection;
  final bool editingSection;
  final Function(bool) setEditingSection;

  const SectionToolbar(
      {Key key,
      this.currentSection,
      this.sectionColor,
      this.musicViewMode,
      this.setSectionName,
      this.deleteSection,
      this.canDeleteSection,
      this.editingSection,
      this.cloneCurrentSection,
      this.setEditingSection})
      : super(key: key);

  @override
  SectionToolbarState createState() => SectionToolbarState();
}

class SectionToolbarState extends State<SectionToolbar> {
  Section confirmingDeleteFor;

  bool get isConfirmingDelete =>
      confirmingDeleteFor != null &&
      confirmingDeleteFor == widget.currentSection;

  TextEditingController nameController = TextEditingController();
  @override
  dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    if (confirmingDeleteFor != null &&
        confirmingDeleteFor != widget.currentSection) {
      confirmingDeleteFor = null;
    }
    nameController.value =
        nameController.value.copyWith(text: widget.currentSection.name ?? "");
    return Container(
//        color: sectionColor,
        child: Row(children: [
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(left: 5),
              child: (widget.musicViewMode == MusicViewMode.section)
                  ? TextField(
                      cursorColor: widget.sectionColor.textColor(),
                      style: TextStyle(
                          fontWeight: FontWeight.w100,
                          color: widget.sectionColor.textColor()),
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (widget.musicViewMode == MusicViewMode.section)
                          ? (value) {
                              widget.currentSection.name = value;
                              widget.setSectionName(widget.currentSection,
                                  widget.currentSection.name);
                            }
                          : null,
//                      onEditingComplete: () {
//                        widget.setSectionName(widget.currentSection, widget.currentSection.name);
//                      },
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              (widget.musicViewMode == MusicViewMode.section)
                                  ? widget.currentSection.idName
                                  : ""),
                    )
                  : Text(""))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
            padding: EdgeInsets.zero,
            color: widget.editingSection ? Colors.white : null,
            child: AnimatedOpacity(
                duration: animationDuration,
                opacity: widget.musicViewMode != MusicViewMode.section ||
                        isConfirmingDelete
                    ? 0
                    : 0,
                child: Icon(Icons.edit)),
            onPressed: () {
              widget.setEditingSection(!widget.editingSection);
            },
          )),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: widget.cloneCurrentSection,
              padding: EdgeInsets.zero,
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: widget.musicViewMode != MusicViewMode.section ||
                          isConfirmingDelete
                      ? 0
                      : 1,
                  child: Icon(FontAwesomeIcons.codeBranch)))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 128 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: Align(
              alignment: Alignment.center,
              child: Text("Really delete?",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.sectionColor.textColor())))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  widget.deleteSection(confirmingDeleteFor);
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text(
                "Yes",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 48 : 0,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: () {
                setState(() {
                  confirmingDeleteFor = null;
                });
              },
              padding: EdgeInsets.zero,
              child: Text("No", maxLines: 1, overflow: TextOverflow.ellipsis))),
      AnimatedContainer(
          duration: animationDuration,
          width: isConfirmingDelete ? 0 : 41,
          height: 36,
          padding: EdgeInsets.only(right: 5),
          child: MyRaisedButton(
              onPressed: widget.canDeleteSection
                  ? () {
                      setState(() {
                        confirmingDeleteFor = widget.currentSection;
                      });
                    }
                  : null,
              padding: EdgeInsets.zero,
              child: Padding(
                  padding: EdgeInsets.all(5),
                  child: ColorFilteredImageAsset(
                      imageSource: "assets/trash.png",
                      imageColor: widget.canDeleteSection
                          ? Colors.white
                          : Colors.black)))),
    ]));
  }
}
