import 'dart:ui';

import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../ui_models.dart';
import '../widget/my_buttons.dart';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../ui_models.dart';
import '../widget/my_buttons.dart';
import '../colors.dart';

class BluetoothDeviceTile extends StatefulWidget {
  static final MIDI_SERVICE_UUID_STRING =
      '03B80E5A-EDE8-4B33-A751-6CE34EC4C700';
  static final MIDI_SERVICE_UUID = Uuid.parse(MIDI_SERVICE_UUID_STRING);
  final DiscoveredDevice device;
  final VoidCallback onConnect, onDisconnect;
  final Color sectionColor;
  final FlutterReactiveBle flutterReactiveBle;

  const BluetoothDeviceTile({
    Key key,
    @required this.device,
    @required this.sectionColor,
    @required this.onConnect,
    @required this.onDisconnect,
    @required this.flutterReactiveBle,
  }) : super(key: key);

  @override
  _BluetoothDeviceTileState createState() => _BluetoothDeviceTileState();
}

class _BluetoothDeviceTileState extends State<BluetoothDeviceTile> {
  DeviceConnectionState connectionState = DeviceConnectionState.disconnected;
  bool get isConnected => connectionState == DeviceConnectionState.connected;
  bool get isConnecting => connectionState == DeviceConnectionState.connecting;
  Color get backgroundColor => isConnected ? widget.sectionColor : Colors.grey;
  Color get foregroundColor => backgroundColor.textColor();
  DiscoveredDevice get device => widget.device;
  Stream<ConnectionStateUpdate> connection;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget framework = Column(children: [
      Row(children: [
        Icon(Icons.bluetooth_audio, color: foregroundColor),
        SizedBox(width: 5),
        Text("Bluetooth MIDI Device",
            style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w100))
      ]),
      Expanded(
          child: Column(children: [
        Expanded(child: SizedBox()),
        Text(device.name,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: foregroundColor,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Expanded(child: SizedBox()),
        Row(children: [
          Expanded(child: SizedBox()),
          MyRaisedButton(
            child: Text(isConnected ? "Disconnect" : "Connect"),
            padding: EdgeInsets.symmetric(horizontal: 10),
            onPressed: isConnecting
                ? null
                : () async {
                    if (isConnected) {
                      _disconnect();
                    } else {
                      _connect();
                    }
                  },
          ),
          Expanded(child: SizedBox()),
        ]),
        Expanded(child: SizedBox()),
      ]))
    ]);

    return AnimatedContainer(
        duration: animationDuration,
        width: 200,
        color: backgroundColor,
        padding: EdgeInsets.all(5),
        child: framework);
  }

  _connect() {
    connection = widget.flutterReactiveBle.connectToAdvertisingDevice(
        id: device.id,
        withServices: [
          BluetoothDeviceTile.MIDI_SERVICE_UUID
        ],
        servicesWithCharacteristicsToDiscover: {
          BluetoothDeviceTile.MIDI_SERVICE_UUID: []
        });
    // await device.connect();
    try {
      _deviceConnected();
    } catch (e) {
      print("Error setting up connection to device");
    }
    widget.onConnect();
  }

  _disconnect() {
    // await device.disconnect();
    widget.onDisconnect();
  }

  _deviceConnected() async {
    // List<BluetoothService> services = await device.discoverServices();
    // final service = services.firstWhere((s) =>
    //     s.uuid.toString().toUpperCase() ==
    //     BluetoothDeviceTile.MIDI_SERVICE_UUID_STRING);
    // BluetoothCharacteristic characteristic = service.characteristics.first;
    // await characteristic.setNotifyValue(true);
    // characteristic.value.listen((event) {
    //   BeatScratchPlugin.sendMIDI(event);
    // });
  }
}
