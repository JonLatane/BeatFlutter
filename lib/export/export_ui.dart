import 'dart:typed_data';

import '../widget/my_buttons.dart';

import '../colors.dart';
import '../ui_models.dart';
import 'export_models.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker_cross/file_picker_cross.dart';

class ExportUI {
  static double _baseHeight = 200;
  static double _progressHeight = 24;

  bool visible = false;
  bool exporting = false;
  BSExport export = BSExport();
  FilePickerCross midiFile = FilePickerCross(Uint8List(0), fileExtension: 'midi');

  double get baseHeight => visible ? _baseHeight : 0.0;

  double get progressHeight => exporting ? _progressHeight : 0.0;

  double get height => baseHeight + progressHeight;

  Widget build({@required BuildContext context, @required Function(VoidCallback) setState}) {
    return AnimatedContainer(
      duration: animationDuration,
      height: height,
      child: Column(
        children: [
          AnimatedContainer(
              duration: animationDuration,
              height: baseHeight,
              child: Column(children: [
                Row(
                  children: [
                    Transform.translate(offset: Offset(1, 1.5), child: Icon(Icons.outbox, size: 30, color: Colors.white)),
                    SizedBox(width: 5),
                    Text("Export", style: TextStyle(fontSize: 20, color: Colors.white)),
                    SizedBox(width: 5),
                    Expanded(child:Center(child: Text(export?.score?.name ?? "null", style: TextStyle(fontSize: 12, color: Colors.white))))
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
                            Future.delayed(Duration(seconds: 5), () {
                              setState(() {
                                exporting = false;
                              });
                            });
                          }),
                        ))
                      ]))
                ]))
//
              ])),
          AnimatedContainer(
            duration: animationDuration,
            height: progressHeight,
            color: chromaticSteps[5],
            child: Row(children: [Icon(Icons.outbox), Text("Exporting MIDI data...")]),
          ),
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
    double sectionWidth = 100;
    double partsWidth = 200;
    double scrollContentsWidth = exportTypeWidth + sectionWidth + partsWidth;
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
      exportOption("Export Type", "MIDI", exportTypeWidth, chromaticSteps[3]),
      exportOption("Section", "Entire Score", sectionWidth, chromaticSteps[6]),
      exportOption("Parts", "All", partsWidth, chromaticSteps[9]),
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
