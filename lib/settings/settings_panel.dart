import 'dart:async';

import 'package:dart_midi/dart_midi.dart';
import 'package:dart_midi/src/byte_writer.dart';

import '../messages/messages_ui.dart';
import 'tile_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/protos.dart';
import '../music_preview/melody_preview.dart';
import 'app_settings.dart';
import '../storage/universe_manager.dart';
import '../ui_models.dart';
import '../universe_view/universe_icon.dart';
import '../util/dummydata.dart';
import '../util/midi_theory.dart';
import '../util/util.dart';
import '../widget/my_buttons.dart';
import '../widget/my_platform.dart';
import 'settings_common.dart';
import 'tile.dart';
import 'tile_controller.dart';
import 'tile_synth.dart';

class SettingsPanel extends StatefulWidget {
  final AppSettings appSettings;
  final UniverseManager universeManager;
  final MessagesUI messagesUI;
  final Color sectionColor;
  final VoidCallback close;
  final bool enableColorboard;
  final Function(bool) setColorboardEnabled;
  final VoidCallback toggleKeyboardConfig;
  final VoidCallback toggleColorboardConfig;
  final BSMethod bluetoothScan;
  final bool visible;
  final ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;
  final Part keyboardPart;

  const SettingsPanel(
      {Key key,
      @required this.appSettings,
      @required this.universeManager,
      @required this.sectionColor,
      @required this.close,
      @required this.enableColorboard,
      @required this.setColorboardEnabled,
      @required this.toggleKeyboardConfig,
      @required this.toggleColorboardConfig,
      @required this.bluetoothScan,
      @required this.visible,
      @required this.messagesUI,
      @required this.bluetoothControllerPressedNotes,
      @required this.keyboardPart})
      : super(key: key);

  @override
  _SettingsPanelState createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  ScrollController _scrollController = ScrollController();
  Iterable<MidiController> get midiControllers =>
      BeatScratchPlugin.midiControllers;
  Iterable<MidiSynthesizer> get midiSynthesizers =>
      BeatScratchPlugin.midiSynthesizers;
  List<MidiDevice> observedDevices;
  List<String> connectedDeviceIds;
  StreamSubscription<MidiPacket> midiCommandSubscription;

  _startBluetoothScanLoop() async {
    MidiCommand().devices.then((results) {
      observedDevices = results.where((r) => r.type == "BLE").toList();
      connectedDeviceIds
          .removeWhere((id) => !observedDevices.any((d) => d.id == id));
      Future.delayed(
          Duration(seconds: widget.visible ? 5 : 15), _startBluetoothScanLoop);
    });
  }

  @override
  initState() {
    super.initState();
    observedDevices = [];
    connectedDeviceIds = [];
    if (MyPlatform.isNative) {
      MidiCommand().startScanningForBluetoothDevices();
      _startBluetoothScanLoop();
      midiCommandSubscription =
          MidiCommand().onMidiDataReceived?.listen((event) {
        widget.bluetoothControllerPressedNotes.value
            .putIfAbsent(event.device.id, () => []);
        Iterable<MidiEvent> midiEvents = event.midiEvents;
        ByteWriter writer = ByteWriter();
        midiEvents.forEach((e) {
          if (e is NoteOnEvent) {
            e.channel = widget.keyboardPart.instrument.midiChannel;
            e.writeEvent(writer);
            widget.bluetoothControllerPressedNotes.value[event.device.id]
                .add(e.noteNumber - 60);
            widget.bluetoothControllerPressedNotes.notifyListeners();
          } else if (e is NoteOffEvent) {
            e.channel = widget.keyboardPart.instrument.midiChannel;
            e.writeEvent(writer);
            widget.bluetoothControllerPressedNotes.value[event.device.id]
                .remove(e.noteNumber - 60);
            widget.bluetoothControllerPressedNotes.notifyListeners();
          }
        });
        BeatScratchPlugin.sendMIDI(writer.buffer);
      });
    }
  }

  @override
  dispose() {
    midiCommandSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Padding(padding: EdgeInsets.all(2), child: getList(context))),
      Container(
          width: 44,
//    height: 32,
          padding: EdgeInsets.zero,
          child: Column(children: [
            Expanded(
                child: MyRaisedButton(
              color: ChordColor.tonic.color,
              child: Column(children: [
                Expanded(child: SizedBox()),
                Icon(Icons.check, color: ChordColor.tonic.color.textColor()),
                Text("DONE",
                    style: TextStyle(
                        color: ChordColor.tonic.color.textColor(),
                        fontSize: 10)),
                Expanded(child: SizedBox()),
              ]),
              padding: EdgeInsets.all(2),
              onPressed: widget.close,
            ))
          ]))
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
    List<MidiSynthesizer> midiSynthesizers =
        BeatScratchPlugin.supportsSynthesizerConfig
            ? this.midiSynthesizers.toList()
            : [this.midiSynthesizers.toList().first];
    List<dynamic> appSettings = [
      SeparatorTile(text: "App Settings", id: "app-settings"),
      SettingsTile(
        id: "pasteeIntegration",
        color: widget.appSettings.integratePastee
            ? widget.sectionColor
            : Colors.grey,
        child: Container(
          child: Column(
            children: [
              Expanded(child: SizedBox()),
              SizedBox(height: 15),
              Text("Paste.ee Integration",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: (widget.appSettings.integratePastee
                              ? widget.sectionColor
                              : Colors.grey)
                          .textColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text(
                  "Use https://paste.ee to shorten\nScore Links when copying them.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: (widget.appSettings.integratePastee
                              ? widget.sectionColor
                              : Colors.grey)
                          .textColor(),
                      fontSize: 10,
                      fontWeight: FontWeight.w100)),
              Switch(
                activeColor: Colors.white,
                value: widget.appSettings.integratePastee,
                onChanged: (v) => setState(() {
                  widget.appSettings.integratePastee = v;
                }),
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
      SettingsTile(
        id: "darkMode",
        color: musicBackgroundColor,
        child: Container(
          child: Column(
            children: [
              Expanded(child: SizedBox()),
              SizedBox(height: 15),
              Text("Dark Mode",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: musicForegroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 9),
              Icon(FontAwesomeIcons.solidMoon, color: musicForegroundColor),
              Switch(
                activeColor: Colors.white,
                value: widget.appSettings.darkMode,
                onChanged: (v) => widget.appSettings.darkMode = v,
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
      SettingsTile(
        id: "systemsToRender",
        color: widget.sectionColor,
        child: Container(
          child: Column(
            children: [
              Text("Systems To Render",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: widget.sectionColor.textColor(),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(children: [
                    Container(
                      height: 25,
                      child: MyFlatButton(
                          onPressed: () {
                            widget.messagesUI.setAppState(() {
                              widget.appSettings.systemsToRender = 0;
                            });
                          },
                          padding: EdgeInsets.zero,
                          color: widget.appSettings.systemsToRender == 0
                              ? widget.sectionColor.textColor()
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                "Unlimited systems",
                                style: TextStyle(
                                  color: widget.appSettings.systemsToRender < 1
                                      ? widget.sectionColor
                                          .textColor()
                                          .textColor()
                                      : widget.sectionColor.textColor(),
                                ),
                                textAlign: TextAlign.center,
                              )),
                            ],
                          )),
                    ),
                    ...range(1, 6).map((systemsToRenderValue) => Container(
                          height: 25,
                          child: MyFlatButton(
                              onPressed: () {
                                widget.messagesUI.setAppState(() {
                                  widget.appSettings.systemsToRender =
                                      systemsToRenderValue;
                                });
                              },
                              padding: EdgeInsets.zero,
                              color: widget.appSettings.systemsToRender ==
                                      systemsToRenderValue
                                  ? widget.sectionColor.textColor()
                                  : null,
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                    "$systemsToRenderValue system${systemsToRenderValue == 1 ? "" : "s"}",
                                    style: TextStyle(
                                      color:
                                          widget.appSettings.systemsToRender ==
                                                  systemsToRenderValue
                                              ? widget.sectionColor
                                                  .textColor()
                                                  .textColor()
                                              : widget.sectionColor.textColor(),
                                    ),
                                    textAlign: TextAlign.center,
                                  )),
                                ],
                              )),
                        )),
                  ]),
                ),
              ),
              Row(children: [
                Expanded(child: SizedBox()),
                Text("Affects performance.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: widget.sectionColor.textColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w100)),
                Expanded(child: SizedBox()),
              ]),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
      SettingsTile(
        id: "colors",
        color: Colors.grey,
        child: Column(
          children: [
            Expanded(child: SizedBox()),
            Icon(Icons.palette, size: 48, color: Colors.grey.textColor()),
            SizedBox(height: 3),
            Text("Color Info...",
                style: TextStyle(color: Colors.grey.textColor())),
            Expanded(child: SizedBox()),
          ],
        ),
        onPressed: () => showColors(context, widget.sectionColor),
      ),
    ];

    List<dynamic> features = [
      SeparatorTile(text: "Beta Features", id: "features"),
      if (MyPlatform.isDebug)
        SettingsTile(
          id: "universeModeWebViewSignIn",
          color: widget.universeManager.useWebViewSignIn
              ? widget.sectionColor
              : Colors.grey,
          child: Container(
            child: Column(
              children: [
                Expanded(child: SizedBox()),
                SizedBox(height: 15),
                Text("WebView Sign-in",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: (widget.universeManager.useWebViewSignIn
                                ? widget.sectionColor
                                : Colors.grey)
                            .textColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 9),
                Row(children: [
                  Expanded(child: SizedBox()),
                  UniverseIcon(
                    interactionMode: InteractionMode.universe,
                    sectionColor: widget.universeManager.useWebViewSignIn
                        ? widget.sectionColor
                        : Colors.grey,
                  ),
                  SizedBox(width: 5),
                  Text("BETA",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (widget.universeManager.useWebViewSignIn
                                  ? widget.sectionColor
                                  : Colors.grey)
                              .textColor(),
                          fontSize: 14,
                          fontWeight: FontWeight.w900)),
                  Expanded(child: SizedBox()),
                ]),
                Switch(
                  activeColor: Colors.white,
                  value: widget.universeManager.useWebViewSignIn,
                  onChanged: (v) => setState(() {
                    widget.universeManager.useWebViewSignIn = v;
                    BeatScratchPlugin.onSynthesizerStatusChange();
                  }),
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 5),
          ),
        ),
      if (MyPlatform.isIOS)
        SettingsTile(
          id: "apolloUniverse",
          color: widget.appSettings.enableApollo
              ? widget.sectionColor
              : Colors.grey,
          child: Container(
            child: Column(
              children: [
                Expanded(child: SizedBox()),
                SizedBox(height: 15),
                Text("iOS: Apollo",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: (widget.appSettings.enableApollo
                                ? widget.sectionColor
                                : Colors.grey)
                            .textColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 9),
                Row(children: [
                  Expanded(child: SizedBox()),
                  Icon(FontAwesomeIcons.reddit,
                      color: (widget.appSettings.enableApollo
                              ? widget.sectionColor
                              : Colors.grey)
                          .textColor()),
                  SizedBox(width: 5),
                  Text("Use Apollo to\nread Reddit comments",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (widget.appSettings.enableApollo
                                  ? widget.sectionColor
                                  : Colors.grey)
                              .textColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.w100)),
                  Expanded(child: SizedBox()),
                ]),
                Switch(
                  activeColor: Colors.white,
                  value: widget.appSettings.enableApollo,
                  onChanged: widget.appSettings.enableUniverse
                      ? (v) => setState(() {
                            widget.appSettings.enableApollo = v;
                            BeatScratchPlugin.onSynthesizerStatusChange();
                          })
                      : null,
//                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                ),
                Expanded(child: SizedBox()),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 5),
          ),
        ),
    ];
    List<dynamic> items = <dynamic>[
      if (observedDevices.isNotEmpty)
        SeparatorTile(text: "Bluetooth Devices", id: "bluetooth-settings"),
      ...observedDevices,
      SeparatorTile(text: "MIDI Devices", id: "midi-settings"),
      ...midiSynthesizers,
      ...midiControllers,
      ...appSettings,
      ...features,
    ];
    return ImplicitlyAnimatedList<dynamic>(
      key: ValueKey("MidiSettingsList"),
      scrollDirection: Axis.horizontal,
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
        if (item is MidiController) {
          tile = MidiControllerTile(
            appSettings: widget.appSettings,
            scrollDirection: Axis.horizontal,
            midiController: item,
            enableColorboard: widget.enableColorboard,
            setColorboardEnabled: widget.setColorboardEnabled,
            sectionColor: widget.sectionColor,
            toggleKeyboardConfig: widget.toggleKeyboardConfig,
            toggleColorboardConfig: widget.toggleColorboardConfig,
          );
        } else if (item is MidiSynthesizer) {
          tile = MidiSynthTile(
            scrollDirection: Axis.horizontal,
            midiSynthesizer: item,
          );
        } else if (item is SettingsTile || item is SeparatorTile) {
          tile = item;
        } else if (item is MidiDevice) {
          tile = BluetoothDeviceTile(
            key: ValueKey("Bluetooth-Device-${item.id}"),
            device: item,
            sectionColor: widget.sectionColor,
            connected: connectedDeviceIds.any((id) => id == item.id),
            onConnect: () {
              connectedDeviceIds.add(item.id.toString());
            },
            onDisconnect: () {
              connectedDeviceIds.remove(item.id.toString());
            },
            bluetoothControllerPressedNotes:
                widget.bluetoothControllerPressedNotes,
          );
        }
        tile = Padding(padding: EdgeInsets.all(5), child: tile);
        return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            axis: Axis.horizontal,
            animation: animation,
            child: tile);
      },
    );
  }
}

showColors(BuildContext context, Color sectionColor) {
  Widget colorRow(Color color, String name, String symbol) => Row(children: [
        Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: SizedBox()),
                Container(
                    width: 60,
                    height: 40,
                    decoration:
                        BoxDecoration(border: Border.all(), color: color),
                    child: Center(
                        child: Text(symbol,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: color.textColor(),
                                fontSize: 10,
                                fontWeight: FontWeight.w600)))),
                Expanded(child: SizedBox()),
              ],
            )),
        // Expanded(child: SizedBox()),
        Expanded(
            flex: 5,
            child: Row(
              children: [
                SizedBox(width: 15),
                Text(name,
                    style: TextStyle(
                        color: musicForegroundColor,
                        fontWeight: FontWeight.w200)),
              ],
            )),
        // Expanded(child: SizedBox()),
        // Container(
        //     width: 36,
        //     height: 36,
        //     decoration: BoxDecoration(
        //       border: Border.all(),
        //     ),
        //     child: Center(
        //         child: Text(symbol,
        //             textAlign: TextAlign.center,
        //             style: TextStyle(
        //                 color: musicForegroundColor,
        //                 fontSize: 10,
        //                 fontWeight: FontWeight.w600)))),
      ]);
  Widget chromaticColumn(int note, Color color) => Container(
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          MelodyPreview(
              width: 36,
              height: 48,
              scale: 0.15,
              section: defaultSection(),
              part: Part()
                ..id = uuid.v4()
                ..instrument = (Instrument()..type = InstrumentType.harmonic),
              melody: baseMelody()
                ..instrumentType = InstrumentType.harmonic
                ..subdivisionsPerBeat = 2
                ..length = 64
                ..setMidiDataFromSimpleMelody(Map.from({
                  0: [note],
                }))),
          SizedBox(height: 5),
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(border: Border.all(), color: color),
              child: SizedBox()),
        ],
      ));
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: musicBackgroundColor,
      title: Row(children: [
        Text("Beat",
            style: TextStyle(
                color: musicForegroundColor, fontWeight: FontWeight.w900)),
        Text("Scratch",
            style: TextStyle(
                color: musicForegroundColor, fontWeight: FontWeight.w100)),
        SizedBox(width: 5),
        Text('Colors',
            style: TextStyle(
              color: musicForegroundColor,
            ))
      ]),
      content: Column(children: [
        Expanded(
            child: SingleChildScrollView(
                child: Column(children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text("Primary Colors",
                  style: TextStyle(
                      color: musicForegroundColor,
                      fontWeight: FontWeight.w700))),
          colorRow(chromaticSteps[0], "Tonic", "I"),
          colorRow(chromaticSteps[7], "Dominant", "V"),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text("Section/Interval Colors",
                  style: TextStyle(
                      color: musicForegroundColor,
                      fontWeight: FontWeight.w700))),
          colorRow(chromaticSteps[4], "Major", "III"),
          colorRow(chromaticSteps[3], "Minor", "♭III"),
          colorRow(chromaticSteps[5], "Perfect/Subdominant", "IV"),
          colorRow(chromaticSteps[8], "Augmented", "♯V/♭VI"),
          colorRow(chromaticSteps[6], "Diminished", "♭V/♯IV"),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text("Other Colors",
                  style: TextStyle(
                      color: musicForegroundColor,
                      fontWeight: FontWeight.w700))),
          colorRow(chromaticSteps[1], "m2/m9", "♭II"),
          colorRow(chromaticSteps[2], "2/9/M2/M9", "II"),
          colorRow(chromaticSteps[9], "6/M6", "VI"),
          colorRow(chromaticSteps[10], "7/m7", "♭VII"),
          colorRow(chromaticSteps[11], "M7", "VII"),
        ]))),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Text("Chromatic Scale",
                style: TextStyle(
                    color: musicForegroundColor, fontWeight: FontWeight.w700))),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chromaticColumn(0, chromaticSteps[0]),
              chromaticColumn(1, chromaticSteps[1]),
              chromaticColumn(2, chromaticSteps[2]),
              chromaticColumn(3, chromaticSteps[3]),
              chromaticColumn(4, chromaticSteps[4]),
              chromaticColumn(5, chromaticSteps[5]),
              chromaticColumn(6, chromaticSteps[6]),
              chromaticColumn(7, chromaticSteps[7]),
              chromaticColumn(8, chromaticSteps[8]),
              chromaticColumn(9, chromaticSteps[9]),
              chromaticColumn(10, chromaticSteps[10]),
              chromaticColumn(11, chromaticSteps[11]),
            ],
          ),
        )
      ]),
      // actions: <Widget>[
      //   MyFlatButton(
      //     color: sectionColor,
      //     onPressed: () => Navigator.of(context).pop(true),
      //     child: Text('OK'),
      //   ),
      // ],
    ),
  );
}
