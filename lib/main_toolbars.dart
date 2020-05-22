import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:file_picker_cross/file_picker_cross.dart';
import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'beatscratch_plugin.dart';
import 'clearCaches.dart';
import 'colors.dart';
import 'ui_models.dart';
import 'util.dart';

class BeatScratchToolbar extends StatefulWidget {
  final VoidCallback viewMode;
  final VoidCallback editMode;
  final VoidCallback toggleViewOptions;
  final VoidCallback togglePlaying;
  final VoidCallback toggleSectionListDisplayMode;
  final InteractionMode interactionMode;
  final Color sectionColor;
  final RenderingMode renderingMode;
  final Function(RenderingMode) setRenderingMode;
  final VoidCallback showMidiInputSettings;
  final bool focusPartsAndMelodies;
  final VoidCallback toggleFocusPartsAndMelodies;
  final bool showBeatCounts;
  final VoidCallback toggleShowBeatCounts;

  const BeatScratchToolbar(
      {Key key,
      this.interactionMode,
      this.viewMode,
      this.editMode,
      this.toggleViewOptions,
      this.sectionColor,
      this.togglePlaying,
      this.toggleSectionListDisplayMode,
      this.setRenderingMode,
      this.renderingMode,
      this.showMidiInputSettings,
      this.focusPartsAndMelodies,
      this.toggleFocusPartsAndMelodies, this.showBeatCounts, this.toggleShowBeatCounts})
      : super(key: key);

  @override
  _BeatScratchToolbarState createState() => _BeatScratchToolbarState();
}

class _BeatScratchToolbarState extends State<BeatScratchToolbar> {
  FilePickerCross filePicker = FilePickerCross(type: FileTypeCross.custom, fileExtension: "beatscratch");
//  FilePicker asdf = FilePicker();

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 48,
        child: Row(children: [
          Expanded(
              child: PopupMenuButton(
//                        onPressed: _doNothing,
                  offset: Offset(0, MediaQuery.of(context).size.height),
                  onSelected: (value) {
                    switch (value) {
                      case "import":
                        print("Showing file picker");
                        filePicker.pick().then((value) {
//                          filePicker.
                        });
                        break;
//                      case "duplicate":
//                        if(Platform.isMacOS) {
//                          print("Showing save panel");
//                          showSavePanel(
//                            allowedFileTypes: [FileTypeFilterGroup(label: "BeatScratch Score", fileExtensions: ["beatscratch"])]
//                          );
////                          FileChooserChannelController.instance.
//                        } else {
//                          print("This shouldn't be happening");
//                        }
//                        break;
                      case "chooseBeatscratchFolder":
                        break;
                      case "notationUi":
                        widget.setRenderingMode(RenderingMode.notation);
                        break;
                      case "colorblockUi":
                        widget.setRenderingMode(RenderingMode.colorblock);
                        break;
                      case "midiSettings":
                        widget.showMidiInputSettings();
                        break;
                      case "about":
                        showAbout(context);
                        break;
                      case "focusPartsAndMelodies":
                        widget.toggleFocusPartsAndMelodies();
                        break;
                      case "showBeatCounts":
                        widget.toggleShowBeatCounts();
                        break;
                      case "clearMutableCaches":
                        clearMutableCaches();
                        break;
                    }
                    //setState(() {});
                  },
                  itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: null,
                          child: Column(children: [
                            Text('This is pre-release software.', style: TextStyle(fontWeight: FontWeight.w900)),
                            Container(height: 5),
                            Text('Sign-in and file storage features are coming. Have fun fiddling around for now.',
                                style: TextStyle(fontWeight: FontWeight.w100, fontSize: 12)),
                          ]),
                          enabled: false,
                        ),
                        const PopupMenuItem(
                          value: null,
                          child: Text('New Score'),
                          enabled: false,
                        ),
                        const PopupMenuItem(
                          value: "open",
                          child: Text('Open Score...'),
                          enabled: true,
                        ),
                        const PopupMenuItem(
                          value: "duplicate",
                          child: Text('Duplicate Score...'),
                          enabled: kDebugMode,
                        ),
                        const PopupMenuItem(
                          value: null,
                          child: Text('Save Score'),
                          enabled: false,
                        ),
                        const PopupMenuItem(
                          value: null,
                          child: Text('Copy Score'),
                          enabled: false,
                        ),
                        if(widget.interactionMode == InteractionMode.edit) PopupMenuItem(
                          value: "focusPartsAndMelodies",
                          child: Row(children: [
                            Checkbox(value: widget.focusPartsAndMelodies, onChanged: null),
                            Expanded(child: Text('Focus Parts/Melodies'))
                          ]),
                        ),
//                    if(interactionMode == InteractionMode.edit) PopupMenuItem(
//                          value: "showBeatCounts",
//                          child: Row(children: [
//                            Checkbox(value: showBeatCounts, onChanged: null),
//                            Expanded(child: Text('Show Section Beat Counts'))
//                          ]),
//                        ),
                        if (kDebugMode) const PopupMenuItem(
                          value: "clearMutableCaches",
                          child: Text('Debug: Clear Dart Caches'),
                        ),
                        const PopupMenuItem(
                          value: "midiSettings",
                          child: Text('MIDI Settings'),
                        ),
                        PopupMenuItem(
                          value: "notationUi",
                          child: Row(children: [
                            Radio(
                              value: RenderingMode.notation,
                              onChanged: null,
                              groupValue: widget.renderingMode,
                            ),
                            Expanded(child: Text('Notation UI')),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                child: Image.asset(
                                  'assets/notehead_filled.png',
                                  width: 20,
                                  height: 20,
                                ))
                          ]),
                        ),
                        PopupMenuItem(
                          value: "colorblockUi",
                          child: Row(children: [
                            Radio(
                              value: RenderingMode.colorblock,
                              onChanged: null,
                              groupValue: widget.renderingMode,
                            ),
                            Expanded(child: Text('Colorblock UI')),
                            Padding(
                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                                child: Image.asset(
                                  'assets/colorboard_vertical.png',
                                  width: 20,
                                  height: 20,
                                ))
                          ]),
                        ),
//              const PopupMenuItem(
//                value: "about",
//                child: Text('About BeatScratch'),
//              ),
                      ],
                  padding: EdgeInsets.only(bottom: 10.0),
                  icon: Image.asset('assets/logo.png'))),
          Expanded(
              child: FlatButton(
                  onPressed: (widget.interactionMode == InteractionMode.view)
                      ? (BeatScratchPlugin.supportsPlayback
                          ? () {
                              widget.togglePlaying();
                            }
                          : null)
                      : () {
                          widget.toggleSectionListDisplayMode();
                        },
                  padding: EdgeInsets.all(0.0),
                  child: Icon(
                      (widget.interactionMode == InteractionMode.view)
                          ? (BeatScratchPlugin.playing ? Icons.pause : Icons.play_arrow)
                          : Icons.menu,
                      color: (widget.interactionMode == InteractionMode.view && !BeatScratchPlugin.supportsPlayback) ? Colors.grey : widget.sectionColor))),
          Expanded(
              child: AnimatedContainer(
                  duration: animationDuration,
                  color: (widget.interactionMode == InteractionMode.view) ? widget.sectionColor : Colors.transparent,
                  child: FlatButton(
                      onPressed: (widget.interactionMode == InteractionMode.view) ? widget.toggleViewOptions : widget.viewMode,
                      padding: EdgeInsets.all(0.0),
                      child: Icon(Icons.remove_red_eye,
                          color: (widget.interactionMode == InteractionMode.view) ? Colors.white : widget.sectionColor)))),
          Expanded(
              child: AnimatedContainer(
                  duration: animationDuration,
                  color: (widget.interactionMode == InteractionMode.edit) ? widget.sectionColor : Colors.transparent,
                  child: FlatButton(
                      onPressed: widget.editMode,
                      padding: EdgeInsets.all(0.0),
                      child: Icon(Icons.edit,
                          color: (widget.interactionMode == InteractionMode.edit) ? Colors.white : widget.sectionColor))))
        ]));
  }

  showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About BeatScratch'),
        content: Column(children: [
          Padding(padding: EdgeInsets.only(bottom: 5), child: Text("Icons provided by:")),
          Row(children: [
            Image.asset(
              "assets/piano.png",
              width: 24,
              height: 24,
            ),
            Text("Piano by André Luiz Gollo from the Noun Project")
          ]),
        ]),
        actions: <Widget>[
          FlatButton(
            color: widget.sectionColor,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class SecondToolbar extends StatelessWidget {
  final VoidCallback toggleKeyboard;
  final VoidCallback toggleColorboard;
  final VoidCallback toggleKeyboardConfiguration;
  final VoidCallback toggleColorboardConfiguration;
  final bool editingMelody;
  final bool showKeyboard;
  final bool showKeyboardConfiguration;
  final bool showColorboard;
  final bool showColorboardConfiguration;
  final InteractionMode interactionMode;
  final bool showViewOptions;
  final Color sectionColor;
  final bool enableColorboard;

  const SecondToolbar({
    Key key,
    this.toggleKeyboard,
    this.toggleColorboard,
    this.showKeyboard,
    this.showColorboard,
    this.interactionMode,
    this.showViewOptions,
    this.showKeyboardConfiguration,
    this.showColorboardConfiguration,
    this.toggleKeyboardConfiguration,
    this.toggleColorboardConfiguration,
    this.sectionColor,
    this.enableColorboard, this.editingMelody,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    bool editMode = interactionMode == InteractionMode.edit;
    int numberOfButtons = editMode ? 4 : 2;
    if (enableColorboard) {
      numberOfButtons += 1;
    }
    return Row(children: [
      AnimatedContainer(
          width: editMode ? width / numberOfButtons : 0,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                  padding: EdgeInsets.zero,
                  child: Stack(children:[
                    AnimatedOpacity(opacity: editMode && !BeatScratchPlugin.playing && !editingMelody ? 1 : 0,
                      duration: animationDuration, child:
                      Icon(Icons.play_arrow,)),
                    AnimatedOpacity(opacity: editMode && BeatScratchPlugin.playing ? 1 : 0,
                      duration: animationDuration, child:
                      Icon(Icons.pause,)),
                    AnimatedOpacity(opacity: editMode && !BeatScratchPlugin.playing && editingMelody ? 1 : 0,
                      duration: animationDuration, child:
                      Icon(Icons.fiber_manual_record, color: chromaticSteps[7])),
                ]),
                  onPressed: BeatScratchPlugin.supportsPlayback
                      ? () {
                    if(BeatScratchPlugin.playing) {
                      BeatScratchPlugin.pause();
                    } else {
                      BeatScratchPlugin.play();
                    }
                        }
                      : null))),
      AnimatedContainer(
          width: editMode ? width / numberOfButtons : 0,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                  child:
                      AnimatedOpacity(opacity: editMode ? 1 : 0, duration: animationDuration, child: Icon(Icons.skip_previous)),
                  onPressed: BeatScratchPlugin.supportsPlayback
                      ? () {
                    BeatScratchPlugin.setBeat(0);
//                          BeatScratchPlugin.stop();
                        }
                      : null))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                  padding: EdgeInsets.only(top: 7, bottom: 5),
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.center,
                      child: Image.asset('assets/metronome.png'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(padding: EdgeInsets.only(right: 3.5), child: Text('123')),
                    )
                  ]),
                  onPressed: null //() => {},
                  ))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                child: Image.asset('assets/piano.png', width: 28, height: 28),
                onPressed: toggleKeyboard,
                onLongPress: toggleKeyboardConfiguration,
                color: (showKeyboardConfiguration) ? sectionColor : (showKeyboard) ? Colors.white : Colors.grey,
              ))),
      AnimatedContainer(
          width: (enableColorboard) ? width / numberOfButtons : 0,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: RaisedButton(
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: toggleColorboard != null ? 1 : 0.25,
                    child: Image.asset('assets/colorboard.png')),
                onPressed: toggleColorboard,
                onLongPress: toggleColorboardConfiguration,
                color: (showColorboardConfiguration) ? sectionColor : (showColorboard) ? Colors.white : Colors.grey,
              )))
    ]);
  }
}
