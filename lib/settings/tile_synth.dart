import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../generated/protos/protos.dart';
import '../ui_models.dart';
import '../widget/my_buttons.dart';
import '../widget/my_platform.dart';
import 'settings_common.dart';

class MidiSynthTile extends StatefulWidget {
  final Axis scrollDirection;
  final MidiSynthesizer midiSynthesizer;

  const MidiSynthTile({Key key, this.scrollDirection, this.midiSynthesizer})
      : super(key: key);

  @override
  _MidiSynthTileState createState() => _MidiSynthTileState();
}

class _MidiSynthTileState extends State<MidiSynthTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isInternal = widget.midiSynthesizer.id == "internal";
    bool isExternal = widget.midiSynthesizer.id != "internal";
    bool isVolcanoApp =
        widget.midiSynthesizer.name == "FluidSynth MIDI Synthesizer" &&
            hasVolcanoFluidSynth;
    Color color = isVolcanoApp
        ? chromaticSteps[10]
        : isExternal
            ? chromaticSteps[3]
            : chromaticSteps[1];
    Widget framework = Column(children: [
      Row(children: [
        Icon(isVolcanoApp ? Icons.apps : Icons.open_in_new,
            color: Colors.white),
        SizedBox(width: 5),
        Text(
            isVolcanoApp
                ? "Synthesizer App"
                : "${isExternal ? "External" : "Built-in"} Synthesizer",
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))
      ]),
      Expanded(
          child: Column(children: [
        Expanded(child: SizedBox()),
        Text(widget.midiSynthesizer.name.sanitized,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        if (isInternal && (MyPlatform.isMacOS || MyPlatform.isIOS))
          Text("AudioKit",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w100)),
        if (isInternal && kIsWeb)
          Text("MIDI.js",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w100)),
        if (isInternal && MyPlatform.isAndroid)
          Text("Bundled FluidSynth",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w100)),
        if (isVolcanoApp && MyPlatform.isAndroid)
          Text("Volcano Labs",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w100)),
        Row(children: [
          if (BeatScratchPlugin.supportsSynthesizerConfig)
            Expanded(
                child: Row(
              children: [
                Expanded(child: SizedBox()),
                Container(
                    height: 24,
                    child: Switch(
                      activeColor: Colors.white,
                      onChanged: (bool value) {
                        widget.midiSynthesizer.enabled = value;
                        BeatScratchPlugin.updateSynthesizerConfig(
                            widget.midiSynthesizer);
                        BeatScratchPlugin.onSynthesizerStatusChange();
                      },
                      value: widget.midiSynthesizer.enabled,
                    )),
                Expanded(child: SizedBox()),
              ],
            )),
          if (isInternal)
            Expanded(
                child: Row(
              children: [
                Expanded(child: SizedBox()),
                Container(
                    height: 24,
                    child: MyRaisedButton(
                      child: Text("Reset"),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        BeatScratchPlugin.resetAudioSystem();
                      },
                    )),
                Expanded(child: SizedBox()),
              ],
            ))
        ]),
        if (widget.midiSynthesizer.id != "internal" && !MyPlatform.isAndroid)
          Text("ID: ${widget.midiSynthesizer.id}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w100)),
        Expanded(child: SizedBox()),
      ]))
    ]);
    bool isVolcanoFluidSynth =
        widget.midiSynthesizer.name == "FluidSynth MIDI Synthesizer";

    if (hasVolcanoFluidSynth && MyPlatform.isAndroid && isVolcanoFluidSynth) {
      framework = MyFlatButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          launchVolcanoFluidSynth(context);
        },
        child: framework,
      );
    }

    return AnimatedContainer(
        duration: animationDuration,
        width: widget.scrollDirection == Axis.horizontal ? 200 : null,
        height: widget.scrollDirection == Axis.vertical ? 150 : null,
        color: widget.midiSynthesizer.enabled ? color : Colors.grey,
        padding: EdgeInsets.all(5),
        child: framework);
  }
}
