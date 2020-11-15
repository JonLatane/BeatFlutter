import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/ui_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

import 'animations/size_fade_transition.dart';
import 'generated/protos/protobeats_plugin.pb.dart';
import 'my_buttons.dart';
import 'my_platform.dart';

class MidiSettings extends StatefulWidget {
  final Axis scrollDirection;
  final Color sectionColor;
  final Function(VoidCallback) setState;
  final VoidCallback close;
  final bool enableColorboard;
  final Function(bool) setColorboardEnabled;
  final VoidCallback toggleKeyboardConfig;
  final VoidCallback toggleColorboardConfig;

  const MidiSettings(
      {Key key,
      this.scrollDirection = Axis.horizontal,
      this.sectionColor,
      this.setState, this.close, this.enableColorboard, this.setColorboardEnabled, this.toggleKeyboardConfig, this.toggleColorboardConfig})
      : super(key: key);

  @override
  _MidiSettingsState createState() => _MidiSettingsState();
}


const Map<String, String> supportedAndroidSynthApps = {
  "FluidSynth MIDI Synthesizer": "net.volcanomobile.fluidsynthmidi"
};
const Map<String, String> supportedAndroidControllerApps = {
  "MIDI BLE Connect": "com.mobileer.example.midibtlepairing"
};

extension Sanitize on String {
  String get sanitized => replaceFirst("Roland Roland", "Roland");
}

_launchAndroidApp(BuildContext context, String packageName) async {
  AppAvailability.launchApp(packageName).then((_) {
    print("App $packageName launched!");
  }).catchError((err) {
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text("App $packageName not found!")
    ));
    print(err);
  });
}
_launchVolcanoFluidSynth(BuildContext context) => _launchAndroidApp(context,"net.volcanomobile.fluidsynthmidi");

_launchMobileerMidiBTLEPairing(BuildContext context) => _launchAndroidApp(context,"com.mobileer.example.midibtlepairing");
bool hasVolcanoFluidSynth = false; // net.volcanomobile.fluidsynthmidi
bool hasMobileerMidiBTLEPairing = false; // com.mobileer.example.midibtlepairing


Future<void> getApps() async {

  if (MyPlatform.isAndroid) {


    print(await AppAvailability.checkAvailability("net.volcanomobile.fluidsynthmidi"));
    hasVolcanoFluidSynth = await AppAvailability.isAppEnabled("net.volcanomobile.fluidsynthmidi");
    hasMobileerMidiBTLEPairing = await AppAvailability.isAppEnabled("com.mobileer.example.midibtlepairing");

    // Returns: true

  }
  // else if (Platform.isIOS) {
  //   // iOS doesn't allow to get installed apps.
  //   _installedApps = iOSApps;
  //
  //   print(await AppAvailability.checkAvailability("calshow://"));
  //   // Returns: Map<String, String>{app_name: , package_name: calshow://, versionCode: , version_name: }
  //
  // }

  BeatScratchPlugin.onSynthesizerStatusChange();

}

class _MidiSettingsState extends State<MidiSettings> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> get midiControllers => BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> get midiSynthesizers => BeatScratchPlugin.midiSynthesizers;

  @override
  Widget build(BuildContext context) {
    return (widget.scrollDirection == Axis.horizontal)
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
    ]);
  }

  Widget getList(BuildContext context) {
    final List<MidiController> midiControllers = this.midiControllers.toList();
    if (MyPlatform.isAndroid && hasMobileerMidiBTLEPairing) {
      final controller = MidiController()
        ..id = "com.mobileer.example.midibtlepairing"
        ..name = "MIDI BLE Connect"
        ..enabled = true;
      midiControllers.insert(midiControllers.length - 1, controller);
    }
    List<MidiSynthesizer> midiSynthesizers = BeatScratchPlugin.supportsSynthesizerConfig
     ? this.midiSynthesizers.toList()
     : [ this.midiSynthesizers.toList().first ];
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
        if (index >= items.length) {
          return SizedBox();
        }
        final dynamic item = items[index];
        Widget tile;
        if(item is MidiController) {
          tile = _MidiController(
            scrollDirection: widget.scrollDirection,
            midiController: item,
            enableColorboard: widget.enableColorboard,
            setColorboardEnabled: widget.setColorboardEnabled,
            sectionColor: widget.sectionColor,
            toggleKeyboardConfig: widget.toggleKeyboardConfig,
            toggleColorboardConfig: widget.toggleColorboardConfig,
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
  final VoidCallback toggleKeyboardConfig;
  final VoidCallback toggleColorboardConfig;

  const _MidiController({Key key, this.enableColorboard, this.setColorboardEnabled, this.scrollDirection, this.midiController, this.sectionColor, this.toggleKeyboardConfig, this.toggleColorboardConfig})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    bool isKeyboard = midiController.id == "keyboard";
    bool isColorboard = midiController.id == "colorboard";
    bool isMobileerApp = midiController.id == "com.mobileer.example.midibtlepairing";
    bool isExternal = !isKeyboard && !isColorboard && !isMobileerApp;
    Color color = isMobileerApp ? chromaticSteps[10] : isExternal ? chromaticSteps[11] : (isColorboard && !enableColorboard) ? Colors.grey : chromaticSteps[9];
    bool hasArrowInFromRight = false;
    if (isKeyboard) {
      hasArrowInFromRight = BeatScratchPlugin.midiControllers.any((element) => element.id !="keyboard" && element.id != "colorboard"
        && element.id != "com.mobileer.example.midibtlepairing");
    } else if (isExternal) {
      hasArrowInFromRight = BeatScratchPlugin.midiControllers.indexWhere((element) => element.id == midiController.id)
        < BeatScratchPlugin.midiControllers.length - 2;
    }
    print("${midiController.name} hasConnectedExternalController=$hasArrowInFromRight}");
    Widget wrapWithButton(widget) => isMobileerApp ? MyFlatButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        _launchMobileerMidiBTLEPairing(context);
      },
      child: widget,) : widget;
    return Stack(
      children: [
        Transform.translate(offset: Offset(-17,55), child:
        Transform.scale(scale: 5, child: AnimatedOpacity(duration: animationDuration, opacity: isExternal ? 1 : 0,child: Icon(Icons.arrow_left, color: chromaticSteps[11])))),

    AnimatedContainer(
          duration: animationDuration,
          width: scrollDirection == Axis.horizontal ? 200 : null,
          height: scrollDirection == Axis.vertical ? 150 : null,
          color: color,
          padding: EdgeInsets.all(5),
          child: wrapWithButton(Column(children:[
            Row(children:[
                  if (isExternal) Transform.rotate(angle: isExternal ? pi : 0, child: Icon(Icons.input, color: Colors.white)),
                  if (isKeyboard || isColorboard) Icon(Icons.touch_app, color: Colors.white),
                  if (isMobileerApp) Icon(Icons.apps, color: Colors.white),
        SizedBox(width:5),
              Expanded(child:
              Text(isMobileerApp ? "Controller App" : "${isExternal ? "External" : "On-Screen"} Controller",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))),
              if(isKeyboard || isExternal) Image.asset("assets/piano.png", width: 16, height: 16),
              if(isColorboard) Image.asset("assets/colorboard.png", width: 16, height: 16)
            ]),
            Expanded( child:
              Column(children:[
                Expanded(child:SizedBox()),
                Text(midiController.name.sanitized, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                if(isKeyboard && !kIsWeb)
                  Text("MIDI controllers connected to your device route to the Keyboard Part.", textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
                if(isColorboard)
                  Text("[BETA] Just a harp on a C7, for now. Has a Colorboard Part.", textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
                if(isColorboard)
                  Row(children: [
                    Expanded(
                      child: Row(children: [
                        Expanded(child:SizedBox()),
                        Container(
                          height: 40,
                          child: Switch(
                            activeColor: Colors.white,
                            value: enableColorboard,
                            onChanged: setColorboardEnabled,
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                          ),
                        ),
                        Expanded(child:SizedBox()),
                      ]),
                    ),
                    Expanded(child: Row(children: [
                      Expanded(child:SizedBox()),
                      MyFlatButton(
                        padding: EdgeInsets.zero,
                        onPressed: enableColorboard ? toggleColorboardConfig : null, child: Icon(Icons.settings, color: enableColorboard ? Colors.white : Colors.black26)),
                      Expanded(child:SizedBox()),
                    ]))
                  ]),
                if(isExternal && midiController.name != midiController.id)
                  Text("ID: ${midiController.id}", textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
                if(isExternal)
                  Text("Routed to the Keyboard Part.", textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
                if(isMobileerApp)
                  Text("Mobileer Inc", textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
                if(isKeyboard)
                  MyFlatButton(onPressed: toggleKeyboardConfig, child: Icon(Icons.settings, color: Colors.white)),

                Expanded(child:SizedBox()),
          ]))
          ]
        ))),

        IgnorePointer(child:
        Transform.translate(offset: Offset(193,55), child:
        Transform.scale(scale: 5, child: AnimatedOpacity(duration: animationDuration, opacity: hasArrowInFromRight ? 1 : 0,child: Icon(Icons.arrow_left, color: chromaticSteps[11]))))),
      ],
    );
  }
}

class _MidiSynthesizer extends StatefulWidget {
  final Axis scrollDirection;
  final MidiSynthesizer midiSynthesizer;

  const _MidiSynthesizer({Key key, this.scrollDirection, this.midiSynthesizer})
    : super(key: key);

  @override
  __MidiSynthesizerState createState() => __MidiSynthesizerState();
}

class __MidiSynthesizerState extends State<_MidiSynthesizer> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getApps();
  }
  @override
  Widget build(BuildContext context) {
    bool isInternal = widget.midiSynthesizer.id == "internal";
    bool isExternal = widget.midiSynthesizer.id != "internal";
    bool isVolcanoApp = widget.midiSynthesizer.name == "FluidSynth MIDI Synthesizer" && hasVolcanoFluidSynth;
    Color color = isVolcanoApp ? chromaticSteps[10] : isExternal ? chromaticSteps[3] : chromaticSteps[1];
    Widget framework = Column(children:[
      Row(children:[
        Icon(isVolcanoApp ? Icons.apps : Icons.open_in_new, color: Colors.white), SizedBox(width:5),
        Text(isVolcanoApp ? "Synthesizer App" : "${isExternal ? "External": "Built-in"} Synthesizer",
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w100))
      ]),
      Expanded( child:
      Column(children:[
        Expanded(child:SizedBox()),
        Text(widget.midiSynthesizer.name.sanitized, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        if(isInternal && (MyPlatform.isMacOS || MyPlatform.isIOS))
          Text("AudioKit", textAlign: TextAlign.center ,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
        if(isInternal && kIsWeb)
          Text("MIDI.js", textAlign: TextAlign.center ,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
        if(isInternal && MyPlatform.isAndroid)
          Text("Bundled FluidSynth", textAlign: TextAlign.center ,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
        if(isVolcanoApp && MyPlatform.isAndroid)
          Text("Volcano Labs", textAlign: TextAlign.center ,
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
        Row(children: [
          if(BeatScratchPlugin.supportsSynthesizerConfig)
            Expanded(child: Row(
              children: [
                Expanded(child: SizedBox()),
                Container(height: 24, child:
                Switch(activeColor: Colors.white,
                  onChanged: (bool value) {
                    widget.midiSynthesizer.enabled = value;
                    BeatScratchPlugin.updateSynthesizerConfig(widget.midiSynthesizer);
                    BeatScratchPlugin.onSynthesizerStatusChange();
                  }, value: widget.midiSynthesizer.enabled,)),
                Expanded(child: SizedBox()),
              ],
            )),
          if(isInternal)
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
          Text("ID: ${widget.midiSynthesizer.id}", textAlign: TextAlign.center ,style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w100)),
        Expanded(child:SizedBox()),
      ]))
    ]);
    bool isVolcanoFluidSynth =  widget.midiSynthesizer.name == "FluidSynth MIDI Synthesizer";

    if (hasVolcanoFluidSynth && MyPlatform.isAndroid && isVolcanoFluidSynth) {
      framework = MyFlatButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          _launchVolcanoFluidSynth(context);
        },
        child: framework,);
    }
    
    return AnimatedContainer(
      duration: animationDuration,
      width: widget.scrollDirection == Axis.horizontal ? 200 : null,
      height: widget.scrollDirection == Axis.vertical ? 150 : null,
      color: widget.midiSynthesizer.enabled ? color : Colors.grey,
      padding: EdgeInsets.all(5),
      child: framework
    );
  }

}