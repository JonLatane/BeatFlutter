import 'dart:io';
import 'dart:math';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/expanded_section.dart';
import 'package:beatscratch_flutter_redux/midi_theory.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter/material.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:unification/unification.dart';
import 'animations/animations.dart';
import 'ui_models.dart';
import 'package:recase/recase.dart';

import 'util.dart';
import 'music_theory.dart';

class PartConfiguration extends StatefulWidget {
  final Part part;
  final Function(VoidCallback) superSetState;

  const PartConfiguration({Key key, this.part, this.superSetState}) : super(key: key);

  @override
  _PartConfigurationState createState() => _PartConfigurationState();
}

class _PartConfigurationState extends State<PartConfiguration> {
  int get midiChannel => widget.part?.instrument?.midiChannel;

  int get midiInstrument => widget.part?.instrument?.midiInstrument;

  int get midiMsb => widget.part?.instrument?.midiGm2Msb;

  int get midiLsb => widget.part?.instrument?.midiGm2Lsb;

  set midiChannel(int value) {
    widget.part?.instrument?.midiChannel = value;
  }
  set midiInstrument(int value) {
    var part = widget.part;
    if (part != null) {
      part.instrument.midiInstrument = value;
    }
  }

  bool get isHarmonic => widget?.part?.isHarmonic ?? false;
  bool get isDrum => widget?.part?.isDrum ?? false;
  String searchText = "";



  Widget _buildMidiInstrumentDisplay(BuildContext context, Animation<double> animation, item, int i) {
    String displayedChannel = "";
    String text = "Drums";
    bool isSelected = false;
    if(isDrum) {
      text = "Drums";
      isSelected = true;
    }
    if(item >= 0) {
      text = midiInstruments[item].titleCase.replaceAll("F X", "FX");
      isSelected = midiInstrument == item;
      displayedChannel = (item + 1).toString();
    }

    Widget tile = AnimatedContainer(duration: animationDuration,
      color: isSelected ? Colors.white : Colors.transparent,
      child: Column(children:[
        Text(displayedChannel,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isSelected ? Colors.black :
          BeatScratchPlugin.isSynthesizerAvailable ? Colors.white : Colors.white.withAlpha(127)),),
        Expanded(child:RotatedBox(
        quarterTurns: 3,
        child: FlatButton(
          onPressed: isHarmonic && BeatScratchPlugin.isSynthesizerAvailable ? () {
            widget.superSetState(() {
              setState(() {
                midiInstrument = item;
              });
            });
            BeatScratchPlugin.pushPart(widget.part, includeMelodies: false);
          } : null,
          padding: EdgeInsets.symmetric(vertical: 7, horizontal: 5),
          child: Align(alignment: Alignment.centerLeft, child:Text(text,
            style: TextStyle(fontSize: 12, color: isSelected ? Colors.black :
            BeatScratchPlugin.isSynthesizerAvailable ? Colors.white : Colors.white.withAlpha(127))))),
      ))]));
    return SizeFadeTransition(
      key: Key("midi-instrument-display-$item"),
      sizeFraction: 0.0,
      curve: Curves.easeInOut,
      axis: Axis.vertical,
      animation: animation,
      child: tile);
  }

  @override
  Widget build(BuildContext context) {
    List<int> items = widget.part == null ? []
      : isHarmonic ? range(0, 128).toList()
      : [-1];
    if(searchText.trim().isNotEmpty && isHarmonic) {
      items = items.where((i) => i == midiInstrument ||
        midiInstruments[i].toLowerCase().contains(searchText.toLowerCase())).toList();
    }
    int maxMidiChannel = 15;
    if(Platform.isIOS) {
      maxMidiChannel = 4;
    }
    return Column(children: [
      Row(children: [
        Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text("Volume:", style: TextStyle(fontSize: 16, color: Colors.white))),
        SizedBox(width: 50,),
        Expanded(child:
        Slider(
          value: max(0.0, min(1.0, widget.part == null ? 0 : widget.part.instrument.volume)),
          activeColor: Colors.white,
          onChanged: (value) {
            widget.superSetState(() {
              setState(() {
                widget.part?.instrument?.volume = value;
                BeatScratchPlugin.pushPart(widget.part, includeMelodies: false);
              });
            });
          }))
      ]),
      Row(children: [
        Expanded(
            child: Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text("MIDI Channel:", style: TextStyle(fontSize: 16, color: Colors.white)))),
        IncrementableValue(
          onDecrement: (isHarmonic && midiChannel >= 0)
              ? () {
              widget.superSetState(() {
                  setState(() {
                    midiChannel -= 1;
                    if (midiChannel == 9) {
                      midiChannel -= 1;
                    }
                  });
              });
              BeatScratchPlugin.pushPart(widget.part, includeMelodies: false);
                }
              : null,
          onIncrement: (isHarmonic && midiChannel < maxMidiChannel)
              ? () {
                  widget.superSetState(() {
                  setState(() {
                    midiChannel += 1;
                    if (midiChannel == 9) {
                      midiChannel += 1;
                    }
                  });
                  });
                  BeatScratchPlugin.pushPart(widget.part, includeMelodies: false);
                }
              : null,
          valueWidth: 100,
          value: "Channel ${(midiChannel ?? -2) + 1}",
        ),
        SizedBox(width:5)
      ]),
      Row(children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text("MIDI Instrument:", style: TextStyle(fontSize: 16, color: Colors.white)))),
        Icon(Icons.search, color: Colors.white),
        Container(width: 120, child:
        TextField(
          style: TextStyle(fontSize: 14, color: Colors.white),
          controller: TextEditingController()..text = searchText,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) { searchText = value; },
//          onTap: () {
//            if (!context.isTabletOrLandscapey) {
//              widget.hideMelodyView();
//            }
//          },
          decoration: InputDecoration(
            border: InputBorder.none, hintText: "Search"),
        ))
      ]),
      Expanded(
          child: ImplicitlyAnimatedList<int>(
        scrollDirection: Axis.horizontal,
        areItemsTheSame: (oldItem, newItem) => oldItem != newItem,
        items: items,
        itemBuilder: _buildMidiInstrumentDisplay,
      ))
    ]);
  }
}
