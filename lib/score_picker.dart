import 'dart:io';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:path_provider/path_provider.dart';

import 'animations/size_fade_transition.dart';
import 'generated/protos/protobeats_plugin.pb.dart';

class ScorePicker extends StatefulWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final Function(VoidCallback) setState;
  final VoidCallback close;

  const ScorePicker(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState, this.close,})
      : super(key: key);

  @override
  _ScorePickerState createState() => _ScorePickerState();
}

class _ScorePickerState extends State<ScorePicker> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers = BeatScratchPlugin.midiSynthesizers;
  Directory documentsDirectory;
  getLocalPath() async {
    documentsDirectory = await getApplicationDocumentsDirectory();
  }
  @override
  initState() {
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    List<FileSystemEntity> files = documentsDirectory.listSync();
    return (widget.scrollDirection == Axis.horizontal)
        ? Row(children: [
            Expanded(child: Padding(padding: EdgeInsets.all(2), child: getList(context))),
      Container(
        width: 44,
//    height: 32,
        padding: EdgeInsets.zero,
        child: Column(children: [Expanded(child:RaisedButton(
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
    ]);
  }

  Widget getList(BuildContext context) {
    List<dynamic> items = midiSynthesizers.map((e) => e as dynamic)
      .followedBy(midiControllers).toList();
    return ImplicitlyAnimatedList<dynamic>(
      scrollDirection: widget.scrollDirection,
      spawnIsolate: false,
      controller: _scrollController,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      // Called, as needed, to build list item widgets.
      // List items are only built when they're scrolled into view.
      itemBuilder: (context, animation, section, index) {
        final dynamic item = items[index];
        Widget tile = _Score(
          scrollDirection: widget.scrollDirection,
          sectionColor: widget.sectionColor,
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

  const _Score({Key key, this.scrollDirection, this.sectionColor})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: scrollDirection == Axis.horizontal ? 200 : null,
      height: scrollDirection == Axis.vertical ? 150 : null,
      color: Colors.grey,
      padding: EdgeInsets.all(5),
      child: Column(children:[
        Row(children:[
          Icon(Icons.input, color: Colors.white), SizedBox(width:5),
          Expanded(child:
          Text("Controller", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))),
//          if(midiController.id == "keyboard")
//            Image.asset("assets/piano.png", width: 16, height: 16),
//          if(midiController.id == "colorboard")
//            Image.asset("assets/colorboard.png", width: 16, height: 16)
        ]),
        Expanded( child:
          Column(children:[
            Expanded(child:SizedBox()),
            Text('Score name', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
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