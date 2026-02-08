import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../generated/protos/protos.dart';
import '../ui_models.dart';
import '../widget/my_buttons.dart';
import 'app_settings.dart';
import 'settings_common.dart';

class MidiControllerTile extends StatelessWidget {
  final AppSettings appSettings;
  final Axis scrollDirection;
  final MidiController midiController;
  final bool enableColorboard;
  final Function(bool) setColorboardEnabled;
  final Color sectionColor;
  final VoidCallback toggleKeyboardConfig;
  final VoidCallback toggleColorboardConfig;

  const MidiControllerTile(
      {Key? key,
      required this.appSettings,
      required this.enableColorboard,
      required this.setColorboardEnabled,
      required this.scrollDirection,
      required this.midiController,
      required this.sectionColor,
      required this.toggleKeyboardConfig,
      required this.toggleColorboardConfig})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    bool isKeyboard = midiController.id == "keyboard";
    bool isColorboard = midiController.id == "colorboard";
    bool isMobileerApp =
        midiController.id == "com.mobileer.example.midibtlepairing";
    bool isExternal = !isKeyboard && !isColorboard && !isMobileerApp;
    Color color = isMobileerApp
        ? chromaticSteps[10]
        : isExternal
            ? chromaticSteps[11]
            : (isColorboard && !enableColorboard)
                ? Colors.grey
                : chromaticSteps[9];
    bool hasArrowInFromRight = false;
    if (isKeyboard) {
      hasArrowInFromRight = BeatScratchPlugin.midiControllers.any((element) =>
          element.id != "keyboard" &&
          element.id != "colorboard" &&
          element.id != "com.mobileer.example.midibtlepairing");
    } else if (isExternal) {
      hasArrowInFromRight = BeatScratchPlugin.midiControllers
              .indexWhere((element) => element.id == midiController.id) <
          BeatScratchPlugin.midiControllers.length - 2;
    }
    // print("${midiController.name} hasConnectedExternalController=$hasArrowInFromRight}");
    Widget wrapWithButton(widget) => isMobileerApp
        ? MyFlatButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              launchMobileerMidiBTLEPairing(context);
            },
            child: widget,
          )
        : widget;
    return Stack(
      children: [
        Transform.translate(
            offset: Offset(-17, 55),
            child: Transform.scale(
                scale: 5,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: isExternal ? 1 : 0,
                    child: Icon(Icons.arrow_left, color: chromaticSteps[11])))),
        AnimatedContainer(
            duration: animationDuration,
            width: scrollDirection == Axis.horizontal ? 200 : null,
            height: scrollDirection == Axis.vertical ? 150 : null,
            color: color,
            padding: EdgeInsets.all(5),
            child: wrapWithButton(Column(children: [
              Row(children: [
                if (isExternal)
                  Transform.rotate(
                      angle: isExternal ? pi : 0,
                      child: Icon(Icons.input, color: Colors.white)),
                if (isKeyboard || isColorboard)
                  Icon(Icons.touch_app, color: Colors.white),
                if (isMobileerApp) Icon(Icons.apps, color: Colors.white),
                SizedBox(width: 5),
                Expanded(
                    child: Text(
                        isMobileerApp
                            ? "Controller App"
                            : "${isExternal ? "External" : "On-Screen"} Controller",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w100))),
                if (isKeyboard || isExternal)
                  Image.asset("assets/piano.png", width: 16, height: 16),
                if (isColorboard)
                  Image.asset("assets/colorboard.png", width: 16, height: 16)
              ]),
              Expanded(
                  child: Column(children: [
                Expanded(child: SizedBox()),
                Text(midiController.name.sanitized,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                if (isKeyboard && !kIsWeb)
                  Text(
                      "MIDI controllers connected to your device route to the Keyboard Part.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w100)),
                if (isColorboard)
                  Text(
                      "[BETA] Just a harp on a C7, for now. Has a Colorboard Part.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w100)),
                if (isColorboard)
                  Row(children: [
                    Expanded(
                      child: Row(children: [
                        Expanded(child: SizedBox()),
                        Container(
                          height: 40,
                          child: Switch(
                            activeColor: Colors.white,
                            value: enableColorboard,
                            onChanged: setColorboardEnabled,
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                          ),
                        ),
                        Expanded(child: SizedBox()),
                      ]),
                    ),
                    Expanded(
                        child: Row(children: [
                      Expanded(child: SizedBox()),
                      MyFlatButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              enableColorboard ? toggleColorboardConfig : null,
                          child: Icon(Icons.settings,
                              color: enableColorboard
                                  ? Colors.white
                                  : Colors.black26)),
                      Expanded(child: SizedBox()),
                    ]))
                  ]),
                if (isExternal && midiController.name != midiController.id)
                  Text("ID: ${midiController.id}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w100)),
                // if (isExternal)
                //   Text("Routed to the Keyboard Part.",
                //       textAlign: TextAlign.center,
                //       style: TextStyle(
                //           color: Colors.white,
                //           fontSize: 10,
                //           fontWeight: FontWeight.w100)),
                if (isExternal)
                  MyFlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (!appSettings.controllersReplacingKeyboard
                            .contains(midiController.nameOrId)) {
                          appSettings.controllersReplacingKeyboard =
                              appSettings.controllersReplacingKeyboard +
                                  [midiController.nameOrId];
                        } else {
                          appSettings.controllersReplacingKeyboard = appSettings
                              .controllersReplacingKeyboard
                            ..remove(midiController.nameOrId);
                        }
                        BeatScratchPlugin.onSynthesizerStatusChange();
                      },
                      child: Row(children: [
                        Checkbox(
                          mouseCursor: SystemMouseCursors.basic,
                          activeColor: sectionColor,
                          checkColor: sectionColor.textColor(),
                          value: appSettings.controllersReplacingKeyboard
                              .contains(midiController.nameOrId),
                          onChanged: (v) {
                            if (v == true) {
                              appSettings.controllersReplacingKeyboard =
                                  appSettings.controllersReplacingKeyboard +
                                      [midiController.nameOrId];
                            } else {
                              appSettings.controllersReplacingKeyboard =
                                  appSettings.controllersReplacingKeyboard
                                    ..remove(midiController.nameOrId);
                            }
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          },
                        ),
                        Expanded(
                          child: Text(
                              "Deprioritize the On-Screen Keyboard when connected.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w100)),
                        ),
                        SizedBox(width: 5),
                      ])),
                if (isMobileerApp)
                  Text("Mobileer Inc",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w100)),
                if (isKeyboard)
                  MyFlatButton(
                      onPressed: toggleKeyboardConfig,
                      child: Icon(Icons.settings, color: Colors.white)),
                Expanded(child: SizedBox()),
              ]))
            ]))),
        IgnorePointer(
            child: Transform.translate(
                offset: Offset(193, 55),
                child: Transform.scale(
                    scale: 5,
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: hasArrowInFromRight ? 1 : 0,
                        child: Icon(Icons.arrow_left,
                            color: chromaticSteps[11]))))),
      ],
    );
  }
}
