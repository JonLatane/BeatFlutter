import 'package:flutter/material.dart';

import '../ui_models.dart';
import '../widget/my_buttons.dart';

import 'package:flutter_midi_command/flutter_midi_command.dart';

import '../colors.dart';

class BluetoothDeviceTile extends StatefulWidget {
  static final MIDI_SERVICE_UUID_STRING =
      '03B80E5A-EDE8-4B33-A751-6CE34EC4C700';
  // static final MIDI_SERVICE_UUID = Uuid.parse(MIDI_SERVICE_UUID_STRING);
  final MidiDevice device;
  final VoidCallback onConnect, onDisconnect;
  final Color sectionColor;
  final bool connected;
  final ValueNotifier<Map<String, List<int>>> bluetoothControllerPressedNotes;

  const BluetoothDeviceTile(
      {Key? key,
      required this.connected,
      required this.device,
      required this.sectionColor,
      required this.onConnect,
      required this.onDisconnect,
      required this.bluetoothControllerPressedNotes})
      : super(key: key);

  @override
  _BluetoothDeviceTileState createState() => _BluetoothDeviceTileState();
}

class _BluetoothDeviceTileState extends State<BluetoothDeviceTile> {
  // DeviceConnectionState connectionState = DeviceConnectionState.disconnected;
  bool get isConnected => widget.connected;
  bool isConnecting = false;
  Color get backgroundColor => isConnected ? widget.sectionColor : Colors.grey;
  Color get foregroundColor => backgroundColor.textColor();
  MidiDevice get device => widget.device;
  // Stream<ConnectionStateUpdate> connection;

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
    setState(() {
      isConnecting = true;
    });
    MidiCommand().connectToDevice(device);
    try {
      _deviceConnected();
    } catch (e) {
      print("Error setting up connection to device");
    }
    widget.onConnect();
    setState(() {
      isConnecting = false;
    });
  }

  _disconnect() {
    // await device.disconnect();
    MidiCommand().disconnectDevice(device);
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
