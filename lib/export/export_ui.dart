import 'dart:io';
import 'dart:typed_data';
import 'package:beatscratch_flutter_redux/messages/messages_ui.dart';
import 'package:share/share.dart';

import 'package:beatscratch_flutter_redux/util/util.dart';

import '../widget/my_platform.dart';
import 'package:flutter/cupertino.dart';

import '../widget/my_buttons.dart';

import '../colors.dart';
import '../ui_models.dart';
import 'export_manager.dart';
import 'export_models.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker_cross/file_picker_cross.dart';

class ExportUI {
  static final double _baseHeight = 200;
  static final double _progressHeight = 30;

  static Widget exportIcon({double size = 24, Color color}) =>
    Transform.translate(offset: Offset(size * 2 / 24, 0),
      child: Icon(MyPlatform.isAppleOS ? CupertinoIcons.share : Icons.share,
        size : MyPlatform.isAppleOS ? size * 1.2 : size, color: color),
    );

  bool visible = false;
  bool exporting = false;
  BSExport export = BSExport();
  FilePickerCross midiFile = FilePickerCross(Uint8List(0), fileExtension: 'midi');
  ExportManager exportManager = ExportManager();
  MessagesUI messagesUI;

  double get baseHeight => visible ? _baseHeight : 0.0;

  double get progressHeight => exporting ? _progressHeight : 0.0;

  double get height => baseHeight + progressHeight;

  Widget build({@required BuildContext context, @required Function(VoidCallback) setState}) {
    return AnimatedContainer(
      duration: animationDuration,
      height: height,
      child: Column(
        children: [
          AnimatedOpacity(
            duration: animationDuration,
            opacity: progressHeight == 0 ? 0 : 1,
            child: AnimatedContainer(
              duration: animationDuration,
              height: progressHeight,
              color: chromaticSteps[5],
              child: Row(children: [
                exportIcon(size: 20),
                Text("Exporting MIDI data...")
              ]),
            ),
          ),
          AnimatedContainer(
              duration: animationDuration,
              height: baseHeight,
              child: Column(children: [
                Row(
                  children: [
                    Transform.translate(
                        offset: Offset(1, 1.5),
                        child: exportIcon(size: 30, color: Colors.white)),
                    SizedBox(width: 5),
          Transform.translate(offset: Offset(0,3),
            child: Text("Export", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700))),
                    SizedBox(width: 5),
                    Expanded(
                        child: Row(
                      children: [
                        Expanded(child: SizedBox()),
                        Transform.translate(offset: Offset(0,3),
                          child: Text(export?.score?.name ?? "null",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                        Expanded(child: SizedBox()),
                      ],
                    ))
                  ],
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Transform.translate(
                        offset: Offset(1, 1.5), child: Icon(Icons.warning, size: 24, color: ChordColor.dominant.color)),
                    SizedBox(width: 5),
                    Text("BETA", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                          "MIDI Exports are currently not playable 😅 If you have a hex viewer handy and the experience to help me fix it, leave feedback!",
                          style: TextStyle(fontSize: 8, color: Colors.white)),
                    ),
                    SizedBox(width: 5),
                  ],
                ),
                SizedBox(height: 3),
                Expanded(
                    child: Row(children: [
                  Expanded(child: exportOptions(context: context, setState: setState)),
                  Container(
                      width: 44,
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        Expanded(
                            child: MyRaisedButton(
                          color: ChordColor.dominant.color,
                          child: Column(children: [
                            Expanded(child: SizedBox()),
                            Icon(Icons.cancel_outlined, color: Colors.white),
                            Text("CANCEL", style: TextStyle(color: Colors.white, fontSize: 10)),
                            Expanded(child: SizedBox()),
                          ]),
                          padding: EdgeInsets.all(2),
                          onPressed: () => setState(() {
                            visible = false;
                          }),
                        ))
                      ])),
                  Container(
                      width: 44,
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        Expanded(
                            child: MyRaisedButton(
                          color: ChordColor.tonic.color,
                          child: Column(children: [
                            Expanded(child: SizedBox()),
                            Icon(Icons.arrow_forward, color: Colors.white),
                            Text("EXPORT", style: TextStyle(color: Colors.white, fontSize: 10)),
                            Expanded(child: SizedBox()),
                          ]),
                          padding: EdgeInsets.all(2),
                          onPressed: () => setState(() {
                            exporting = true;
                            visible = false;
                            Future.microtask(() {
                              File file;
                              try {
                                File file = export(exportManager);
                              } catch (e) {
                                print(e);
                                messagesUI.sendMessage(
                                    message: "MIDI Export failed!", isError: true, setState: setState);
                              }
                              Future.delayed(Duration(seconds: 2), () {
                                setState(() {
                                  exporting = false;
                                });
                                if (MyPlatform.isMacOS) {
                                  messagesUI.sendMessage(
                                      message: "Opening exports directory in Finder...", setState: setState);
                                  Future.delayed(Duration(seconds: 1), () {
                                    launchURL("file://${exportManager.exportsDirectory.path}");
                                    messagesUI.sendMessage(message: "Export complete!", setState: setState);
                                  });
                                } else if (MyPlatform.isMobile) {
                                  messagesUI.sendMessage(message: "Sharing MIDI file...", setState: setState);
                                  Future.delayed(Duration(seconds: 1), () {
                                    Share.shareFiles([file.path], text: export.score.name);
                                    messagesUI.sendMessage(message: "Export complete!", setState: setState);
                                  });
                                }
                              });
                            });
                          }),
                        ))
                      ]))
                ]))
//
              ])),
        ],
      ),
    );
  }

  static const TextStyle labelStyle = TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle = TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding = EdgeInsets.only(left: 5, top: 5, bottom: 5);

  SingleChildScrollView exportOptions({@required BuildContext context, @required Function(VoidCallback) setState}) {
    double width = MediaQuery.of(context).size.width;
    double scrollContainerWidth = width - 88;
    double exportTypeWidth = 100;
    double speedWidth = 100;
    double sectionWidth = 100;
    double partsWidth = 200;
    double scrollContentsWidth = exportTypeWidth + sectionWidth + partsWidth + speedWidth;
    bool usesFlex = scrollContainerWidth > scrollContentsWidth;

    Widget exportOption(String label, String value, double size, Color color) {
      if (usesFlex) {
        return Expanded(
            flex: size.toInt(),
            child: Container(
                color: color,
                child: Column(children: [
                  Text(label, style: labelStyle),
                  Expanded(child: Align(alignment: Alignment.center, child: Text(value, style: valueStyle)))
                ])));
      } else {
        return AnimatedContainer(
            duration: animationDuration,
            width: size,
            padding: itemPadding,
            child: Container(
                color: color,
                child: Column(children: [
                  Text(label, style: labelStyle),
                  Expanded(child: Align(alignment: Alignment.center, child: Text(value, style: valueStyle)))
                ])));
      }
    }

    Widget row = Row(children: [
      exportOption("Export Type", "MIDI", exportTypeWidth, chromaticSteps[1]),
      exportOption("Speed", "1x", speedWidth, chromaticSteps[2]),
      exportOption("Section", "Entire Score", sectionWidth, chromaticSteps[3]),
      exportOption("Parts", "All", partsWidth, chromaticSteps[9]),
      if (!usesFlex) SizedBox(width: 5),
    ]);

    if (usesFlex) {
      row = Container(width: scrollContainerWidth, child: row);
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AnimatedContainer(duration: animationDuration, height: baseHeight, child: row));
  }

  chooseExportFile({@required BuildContext context, @required Function(VoidCallback) setState}) async {
    // String exportPath = await midiFile.exportToStorage();
// show a dialog to open a file
    midiFile = await FilePickerCross.importFromStorage(
        type: FileTypeCross.custom,
        // Available: `any`, `audio`, `image`, `video`, `custom`. Note: not available using FDE
        fileExtension:
            '.midi, .mid' // Only if FileTypeCross.custom . May be any file extension like `.dot`, `.ppt,.pptx,.odp`
        );
  }
// setState(() {
//   filePickerCross = filePicker;
//   filePickerCross.saveToPath(path: filePickerCross.fileName);
//   FilePickerCross.quota().then((value) {
//     setState(() => quota = value);
//   });
//   lastFiles.add(filePickerCross.fileName);
//   try {
//     _fileString = filePickerCross.toString();
//   } catch (e) {
//     _fileString = 'Not a text file. Showing base64.\n\n' +
//       filePickerCross.toBase64();
//   }
// });
}
