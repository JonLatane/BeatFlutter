import 'dart:io';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

import 'animations/size_fade_transition.dart';
import 'generated/protos/protobeats_plugin.pb.dart';

class MidiSettings extends StatefulWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final Function(VoidCallback) setState;
  final VoidCallback close;
  final bool enableColorboard;
  final Function(bool) setColorboardEnabled;

  const MidiSettings(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState, this.close, this.enableColorboard, this.setColorboardEnabled})
      : super(key: key);

  @override
  _MidiSettingsState createState() => _MidiSettingsState();
}

class _MidiSettingsState extends State<MidiSettings> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> midiControllers = BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> midiSynthesizers = BeatScratchPlugin.midiSynthesizers;

  @override
  Widget build(BuildContext context) {
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
        Widget tile;
        if(item is MidiController) {
          tile = _MidiController(
            scrollDirection: widget.scrollDirection,
            midiController: item,
            enableColorboard: widget.enableColorboard,
            setColorboardEnabled: widget.setColorboardEnabled,
            sectionColor: widget.sectionColor,
          );
        } else {
          tile = _MidiSynthesizer(
            scrollDirection: widget.scrollDirection,
            midiSynthesizer: item as MidiSynthesizer,
          );
        }
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

class _MidiController extends StatelessWidget {
  final Axis scrollDirection;
  final MidiController midiController;
  final bool enableColorboard;
  final Function(bool) setColorboardEnabled;
  final Color sectionColor;

  const _MidiController({Key key, this.enableColorboard, this.setColorboardEnabled, this.scrollDirection, this.midiController, this.sectionColor})
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
          if(midiController.id == "keyboard")
            Image.asset("assets/piano.png", width: 16, height: 16),
          if(midiController.id == "colorboard")
            Image.asset("assets/colorboard.png", width: 16, height: 16)
        ]),
        Expanded( child:
          Column(children:[
            Expanded(child:SizedBox()),
            Text(midiController.name, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            if(midiController.id == "keyboard" && !kIsWeb)
              Text("MIDI controllers connected to your device route to the Keyboard Part.", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
            if(midiController.id == "colorboard")
              Switch(
                activeColor: sectionColor,
                value: enableColorboard,
                onChanged: setColorboardEnabled,
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
              ),

            Expanded(child:SizedBox()),
      ]))
      ])
    );
  }
}

class _MidiSynthesizer extends StatelessWidget {
  final Axis scrollDirection;
  final MidiSynthesizer midiSynthesizer;

  const _MidiSynthesizer({Key key, this.scrollDirection, this.midiSynthesizer})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: scrollDirection == Axis.horizontal ? 200 : null,
      height: scrollDirection == Axis.vertical ? 150 : null,
      color: chromaticSteps[1],
      padding: EdgeInsets.all(5),
      child: Column(children:[
        Row(children:[
          Icon(Icons.open_in_new, color: Colors.white), SizedBox(width:5),
          Text("Synthesizer", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))
        ]),
        Expanded( child:
        Column(children:[
          Expanded(child:SizedBox()),
          Text(midiSynthesizer.name, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          if(midiSynthesizer.id == "internal" && (Platform.isMacOS || Platform.isIOS))
            Text("AudioKit", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
          if(midiSynthesizer.id == "internal" && kIsWeb)
            Text("MIDI.js", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
          if(midiSynthesizer.id == "internal" && Platform.isAndroid)
            Text("FluidSynth", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
          if(midiSynthesizer.id == "internal")
            Container(height: 24, padding: EdgeInsets.only(top:3), child:RaisedButton(child: Text("Reset"), padding: EdgeInsets.zero,
              onPressed: () { BeatScratchPlugin.resetAudioSystem(); },
            )),
          Expanded(child:SizedBox()),
        ]))
      ])
    );
  }
}