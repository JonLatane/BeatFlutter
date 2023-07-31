import 'package:flutter/material.dart';
import 'package:flutter_appavailability/flutter_appavailability.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/protos.dart';
import '../widget/my_platform.dart';

extension Sanitize on String {
  String get sanitized => replaceFirst("Roland Roland", "Roland");
}

extension ControllerNameOrId on MidiController {
  String get nameOrId => (name?.isNotEmpty == true) ? name : id;
}

const Map<String, String> supportedAndroidSynthApps = {
  "FluidSynth MIDI Synthesizer": "net.volcanomobile.fluidsynthmidi"
};
const Map<String, String> supportedAndroidControllerApps = {
  "MIDI BLE Connect": "com.mobileer.example.midibtlepairing"
};

_launchAndroidApp(BuildContext context, String packageName) async {
  AppAvailability.launchApp(packageName).then((_) {
    print("App $packageName launched!");
  }).catchError((err) {
    ScaffoldMessenger.of(context)
        // ignore: deprecated_member_use
        .showSnackBar(SnackBar(content: Text("App $packageName not found!")));
    print(err);
  });
}

launchVolcanoFluidSynth(BuildContext context) =>
    _launchAndroidApp(context, "net.volcanomobile.fluidsynthmidi");

launchMobileerMidiBTLEPairing(BuildContext context) =>
    _launchAndroidApp(context, "com.mobileer.example.midibtlepairing");

bool hasVolcanoFluidSynth = false; // net.volcanomobile.fluidsynthmidi
bool hasMobileerMidiBTLEPairing = false; // com.mobileer.example.midibtlepairing

Future<void> getApps() async {
  if (MyPlatform.isAndroid) {
    // print(await AppAvailability.checkAvailability(
    //     "net.volcanomobile.fluidsynthmidi"));
    hasVolcanoFluidSynth =
        await AppAvailability.isAppEnabled("net.volcanomobile.fluidsynthmidi");
    hasMobileerMidiBTLEPairing = await AppAvailability.isAppEnabled(
        "com.mobileer.example.midibtlepairing");

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
