import 'dart:io';
import 'dart:ui';
import 'package:beatscratch_flutter_redux/ui_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:path_provider/path_provider.dart';
import 'no_stupid_hands.dart';
import 'score_manager.dart';

import 'animations/size_fade_transition.dart';
import 'generated/protos/music.pb.dart';
import 'generated/protos/protobeats_plugin.pb.dart';

enum ScorePickerMode {
  create, open, duplicate,
}

class ScorePicker extends StatefulWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final Function(VoidCallback) setState;
  final VoidCallback close;
  final ScorePickerMode mode;

  const ScorePicker(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState, this.close, this.mode = ScorePickerMode.create,})
      : super(key: key);

  @override
  _ScorePickerState createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers = BeatScratchPlugin.midiSynthesizers;
  TextEditingController nameController = TextEditingController();
  ScoreManager scoreManager = ScoreManager();

  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          height: widget.mode == ScorePickerMode.open ? 0 : 32,
          duration: animationDuration,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  enabled: widget.mode != ScorePickerMode.open,
                  decoration: InputDecoration(
//                border: InputBorder.none,
                    hintText: "Score Name"),
                ),
                FlatButton(
                  onPressed: () {  },
                  child: Text(
                    widget.mode == ScorePickerMode.create ? "Create" :
                    widget.mode == ScorePickerMode.duplicate ? "Duplicate" : ""
                  )
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: (widget.scrollDirection == Axis.horizontal)
              ? Row(children: [
                  Expanded(child: Padding(padding: EdgeInsets.all(2), child: getList(context))),
            Container(
              width: 44,
//    height: 32,
              padding: EdgeInsets.zero,
              child: Column(children: [Expanded(child:MyRaisedButton(
                color: ChordColor.tonic.color,
                child: Column(children:[
                  Expanded(child: SizedBox()),
                  Icon(Icons.check, color: Colors.white),
                  Text("DONE", style: TextStyle(color: Colors.white, fontSize: 10)),
                  Expanded(child: SizedBox()),
                ]),
                padding: EdgeInsets.all(2),
                onPressed: widget.close,
              ))]))
          ])
            : Column(children: [
            Expanded(child: getList(context)),
          ]),
        ),
      ],
    );
  }

  Widget getList(BuildContext context) {
    return ImplicitlyAnimatedList<FileSystemEntity>(
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: scoreManager.files,
      areItemsTheSame: (a, b) => a.path == b.path,
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        Widget tile = _Score(
          scrollDirection: widget.scrollDirection,
          sectionColor: widget.sectionColor,
          file: scoreManager.files[index],
        );
        tile = Padding(padding: EdgeInsets.all(5), child: tile);
        return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            axis: widget.scrollDirection,
            animation: animation,
            child: tile);
      },
    );
  }
}

class _Score extends StatelessWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final FileSystemEntity file;

  const _Score({Key key, this.scrollDirection, this.sectionColor, this.file})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    String filename = file.path.split("/").last;
    return Container(
      width: scrollDirection == Axis.horizontal ? 200 : null,
      height: scrollDirection == Axis.vertical ? 150 : null,
      color: Colors.grey,
      padding: EdgeInsets.all(5),
      child: Column(children:[
        Row(children:[
//          Icon(Icons.input, color: Colors.white), SizedBox(width:5),
          Expanded(child:
          Text(filename, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))),
//          if(midiController.id == "keyboard")
//            Image.asset("assets/piano.png", width: 16, height: 16),
//          if(midiController.id == "colorboard")
//            Image.asset("assets/colorboard.png", width: 16, height: 16)
          Icon(Icons.delete, color: Colors.white), SizedBox(width:5),
        ]),
        Expanded( child:
          Column(children:[
            Expanded(child:SizedBox()),
            Text(filename, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
//            if(midiController.id == "keyboard" && !kIsWeb)
//              Text("MIDI controllers connected to your device route to the Keyboard Part.", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
//            if(midiController.id == "colorboard")
//              Switch(
//                activeColor: sectionColor,
//                value: enableColorboard,
//                onChanged: setColorboardEnabled,
////                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
//              ),

            Expanded(child:SizedBox()),
      ]))
      ])
    );
  }
}