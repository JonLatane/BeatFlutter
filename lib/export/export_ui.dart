import 'dart:io';
import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../messages/messages_ui.dart';
import '../util/dummydata.dart';
import 'package:share/share.dart';

import '../util/util.dart';

import '../widget/my_platform.dart';
import 'package:flutter/cupertino.dart';

import '../widget/my_buttons.dart';

import '../colors.dart';
import '../ui_models.dart';
import '../util/music_theory.dart';
import 'export_manager.dart';
import 'export_models.dart';
import 'package:flutter/material.dart';

class ExportUI {
  static final exportDelay = Duration(seconds: 2);
  static final double _baseHeight = 220;
  static final double _progressHeight = 30;

  static Widget exportIcon({double size = 24, Color color}) =>
      Transform.translate(
        offset: Offset(size * 2 / 24, 0),
        child: Icon(MyPlatform.isAppleOS ? CupertinoIcons.share : Icons.share,
            size: MyPlatform.isAppleOS ? size * 1.2 : size, color: color),
      );

  bool visible = false;
  bool exporting = false;
  final BSExport export = BSExport(score: defaultScore());
  ExportManager exportManager = ExportManager();
  MessagesUI messagesUI;

  double get baseHeight => visible ? _baseHeight : 0.0;

  double get progressHeight => exporting ? _progressHeight : 0.0;

  double get height => baseHeight + progressHeight;

  Widget build(
      {@required BuildContext context,
      @required Function(VoidCallback) setState,
      @required Section currentSection}) {
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
              // color: chromaticSteps[5],
              child: Stack(children: [
                Row(children: [
                  AnimatedContainer(
                      duration: exportDelay,
                      width: exporting ? MediaQuery.of(context).size.width : 0,
                      color: chromaticSteps[0]),
                  Expanded(child: Container(color: chromaticSteps[5]))
                ]),
                Row(children: [
                  exportIcon(size: 20),
                  SizedBox(width: 3),
                  Text("Exporting MIDI data...")
                ])
              ]),
            ),
          ),
          AnimatedOpacity(
            duration: animationDuration,
            opacity: baseHeight == 0 ? 0 : 1,
            child: AnimatedContainer(
                duration: animationDuration,
                height: baseHeight,
                child: Column(children: [
                  Row(
                    children: [
                      Transform.translate(
                          offset: Offset(1, 1.5),
                          child: exportIcon(
                              size: MyPlatform.isAndroid ? 24 : 30,
                              color: Colors.white)),
                      SizedBox(width: 5),
                      Transform.translate(
                          offset: Offset(0, MyPlatform.isAndroid ? 0 : 3),
                          child: Text("Export",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700))),
                      SizedBox(width: 5),
                      Expanded(
                          child: Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Transform.translate(
                            offset: Offset(0, 3),
                            child: Text(export?.score?.name ?? "null",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white)),
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
                          offset: Offset(1, 1.5),
                          child: Icon(Icons.info,
                              size: 24, color: ChordColor.tonic.color)),
                      SizedBox(width: 5),
                      // Text("NOTE",
                      //     style: TextStyle(
                      //         fontSize: 16,
                      //         color: Colors.white,
                      //         fontWeight: FontWeight.w500)),
                      // SizedBox(width: 7),
                      Expanded(
                        child: Text(
                            "BeatScratch MIDI Exports use 24-tick-per-beat timecoding. Many MIDI players, including "
                            "Apple QuickTime-based players, cannot play this encoding. Imports into your "
                            "DAW or notation/engraving software should work well, though!",
                            style: TextStyle(fontSize: 9, color: Colors.white)),
                      ),
                      SizedBox(width: 5),
                    ],
                  ),
                  SizedBox(height: 3),
                  Expanded(
                      child: Row(children: [
                    Expanded(
                        child: exportOptions(
                            context: context,
                            setState: setState,
                            currentSection: currentSection)),
                    Container(
                        width: 44,
                        padding: EdgeInsets.zero,
                        child: Column(
                            verticalDirection: VerticalDirection.up,
                            children: [
                              Expanded(
                                  child: MyRaisedButton(
                                color: ChordColor.dominant.color,
                                child: Column(children: [
                                  Expanded(child: SizedBox()),
                                  Icon(Icons.cancel_outlined,
                                      color: ChordColor.dominant.color
                                          .textColor()),
                                  Text("CANCEL",
                                      style: TextStyle(
                                          color: ChordColor.dominant.color
                                              .textColor(),
                                          fontSize: 10)),
                                  Expanded(child: SizedBox()),
                                ]),
                                padding: EdgeInsets.all(2),
                                onPressed: () => setState(() {
                                  visible = false;
                                }),
                              )),
                              Expanded(
                                  child: MyRaisedButton(
                                color: ChordColor.tonic.color,
                                child: Column(children: [
                                  Expanded(child: SizedBox()),
                                  Icon(Icons.arrow_forward,
                                      color:
                                          ChordColor.tonic.color.textColor()),
                                  Text("EXPORT",
                                      style: TextStyle(
                                          color: ChordColor.tonic.color
                                              .textColor(),
                                          fontSize: 10)),
                                  Expanded(child: SizedBox()),
                                ]),
                                padding: EdgeInsets.all(2),
                                onPressed: () => setState(() {
                                  exporting = true;
                                  visible = false;
                                  Future.microtask(() {
                                    File file;
                                    bool success = false;
                                    try {
                                      file = export(exportManager);
                                      success = true;
                                    } catch (e) {
                                      print(e);
                                      if (e is Error) {
                                        print(e.stackTrace);
                                      }

                                      messagesUI.sendMessage(
                                          message: "MIDI Export failed!",
                                          isError: true);
                                    }
                                    Future.delayed(exportDelay, () {
                                      setState(() {
                                        exporting = false;
                                      });
                                      if (success) {
                                        if (MyPlatform.isMacOS) {
                                          messagesUI.sendMessage(
                                              message:
                                                  "Opening exports directory in Finder...");
                                          Future.delayed(Duration(seconds: 1),
                                              () {
                                            launchURL(
                                                "file://${exportManager.exportsDirectory.path}");
                                            messagesUI.sendMessage(
                                                message: "Export complete!");
                                          });
                                        } else if (MyPlatform.isIOS) {
                                          messagesUI.sendMessage(
                                              message:
                                                  "Opening exports directory in Files...");
                                          Future.delayed(Duration(seconds: 1),
                                              () {
                                            launchURL(
                                                "shareddocuments://${exportManager.exportsDirectory.path}");
                                            messagesUI.sendMessage(
                                                message: "Export complete!");
                                          });
                                        } else if (MyPlatform.isMobile) {
                                          messagesUI.sendMessage(
                                              message: "Sharing MIDI file...");
                                          Future.delayed(Duration(seconds: 1),
                                              () {
                                            Share.shareFiles([file.path],
                                                text: export.score.name);
                                            messagesUI.sendMessage(
                                                message: "Export complete!");
                                          });
                                        }
                                      }
                                    });
                                  });
                                }),
                              ))
                            ]))
                  ]))
//
                ])),
          ),
        ],
      ),
    );
  }

  static const TextStyle labelStyle =
      TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static TextStyle valueStyle(Color color) =>
      TextStyle(fontWeight: FontWeight.w600, color: color);
  static const EdgeInsets itemPadding =
      EdgeInsets.only(left: 5, top: 5, bottom: 5);

  SingleChildScrollView exportOptions(
      {@required BuildContext context,
      @required Function(VoidCallback) setState,
      @required Section currentSection}) {
    double width = MediaQuery.of(context).size.width;
    double scrollContainerWidth = width - 44;
    double exportTypeWidth = 100;
    double speedWidth = 100;
    double sectionWidth = 100;
    double partsWidth = 230;
    double scrollContentsWidth =
        exportTypeWidth + sectionWidth + partsWidth + speedWidth;
    bool usesFlex = scrollContainerWidth > scrollContentsWidth;

    Widget exportOption(String label, String value, double size, Color color,
        {List<String> values,
        List<String> disabledValues,
        Widget customValue,
        Function(String) selectValue}) {
      if (disabledValues == null) {
        disabledValues = [];
      }
      if (values == null || values.isEmpty) {
        values = [value];
      }
      if (value != null && !values.contains(value)) {
        values = values + [value];
      }
      values = values.toSet().toList();

      Widget column = Column(children: [
        // if (usesFlex) Expanded(child:SizedBox()),
        ...values.map((v) {
          final clickable = selectValue != null && !disabledValues.contains(v);
          return MyFlatButton(
              color: v == value ? Colors.white : Colors.black12,
              padding: EdgeInsets.all(5),
              onPressed: clickable ? () => selectValue(v) : null,
              child: Text(v,
                  textAlign: TextAlign.center,
                  style: valueStyle(
                    !clickable
                        ? Colors.grey
                        : v == value
                            ? Colors.black
                            : Colors.white,
                  )));
        }).toList(),
        if (customValue != null) customValue,
        // if (usesFlex) Expanded(child:SizedBox())
      ]);
      // if (!usesFlex) {
      column = SingleChildScrollView(child: column);
      // }

      Widget tile = Container(
          color: color,
          child: Column(children: [
            Text(label, style: labelStyle),
            Expanded(child: Align(alignment: Alignment.center, child: column))
          ]));

      if (usesFlex) {
        return Expanded(flex: size.toInt(), child: tile);
      } else {
        return AnimatedContainer(
            duration: animationDuration,
            width: size,
            padding: itemPadding,
            child: tile);
      }
    }

    if (export.score == null ||
        !export.score.sections.any((s) => s.id == export.sectionId)) {
      export.sectionId = null;
    }
    export.partIds.removeWhere(
        (partId) => !export.score.parts.any((p) => partId == p.id));
    if (export.partIds.length == export.score.parts.length) {
      export.partIds.clear();
    }

    Widget row = Row(children: [
      exportOption("Export Type", "MIDI", exportTypeWidth, chromaticSteps[1],
          values: ["MIDI", "MusicXML", "Audio"],
          disabledValues: ["MusicXML", "Audio"],
          selectValue: (v) => setState(() {
                export.exportType = ExportType.midi;
              })),
      exportOption(
          "Speed",
          export.tempoMultiplier == 1.0
              ? "1x"
              : "${export.tempoMultiplier.toStringAsFixed(3).replaceAll("1.000", "1")}x",
          speedWidth,
          chromaticSteps[2],
          values: [
            "1x",
            "${(BeatScratchPlugin.bpmMultiplier ?? 1).toStringAsFixed(3).replaceAll("1.000", "1")}x"
          ],
          selectValue: (v) => setState(() {
                export.tempoMultiplier = double.parse(v.replaceAll("x", ""));
              })),
      exportOption(
          "Section",
          export.sectionId == null
              ? "Entire Score"
              : export.score.sections
                      .firstWhere((s) => s.id == export.sectionId)
                      ?.canonicalName ??
                  "NULL",
          sectionWidth,
          chromaticSteps[3],
          values: ["Entire Score", currentSection.canonicalName],
          selectValue: (v) => setState(() {
                export.sectionId =
                    (v == "Entire Score") ? null : currentSection.id;
              })),
      exportOption("Parts", export.partIds.isEmpty ? "All Parts" : null,
          partsWidth, chromaticSteps[9],
          values: ["All Parts"],
          selectValue: (v) => setState(() {
                if (v == "All Parts") export.partIds.clear();
              }),
          customValue: Container(
              height: 90,
              child: Row(
                  children: export.score.parts
                      .map((p) => Expanded(
                              child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: MyFlatButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    if (!export.partIds.remove(p.id)) {
                                      export.partIds.add(p.id);
                                    }
                                  });
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: animationDuration,
                                        color: (p.isDrum
                                                ? Colors.brown
                                                : Colors.grey)
                                            .withOpacity(
                                                export.partIds.contains(p.id)
                                                    ? 1
                                                    : 0.5),
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Row(
                                            children: [
                                              SizedBox(width: 3),
                                              Expanded(
                                                child: Text(p.midiName,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                              ),
                                              SizedBox(width: 3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                          )))
                      .toList()))),
      if (!usesFlex) SizedBox(width: 5),
    ]);

    if (usesFlex) {
      row = Container(width: scrollContainerWidth, child: row);
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AnimatedContainer(
            duration: animationDuration, height: baseHeight, child: row));
  }
}
