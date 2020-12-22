import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../music_preview/melody_preview.dart';
import '../layers_view/layers_view.dart';
import '../storage/score_manager.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../util/bs_notifiers.dart';
import '../widget/my_popup_menu.dart';
import '../widget/my_popup_menu.dart' as myPopup;
import '../widget/beats_badge.dart';

class MelodyMenuBrowser extends StatefulWidget {
  final Part part;
  final Section currentSection;
  final Function(Melody) onMelodySelected;
  final Color textColor;
  final Widget child;

  const MelodyMenuBrowser({Key key, this.child, this.part, this.currentSection, this.onMelodySelected, this.textColor = Colors.white}) : super(key: key);

  @override
  _MelodyMenuBrowserState createState() => _MelodyMenuBrowserState();

  static loadScoreData() async {
    if (kIsWeb) return;
    final futures = _manager.scoreFiles.map((it) async {
      final score = await ScoreManager.loadScore(it as File);
      score.name = it.scoreName;
      return score;
    });
    final data = await Future.wait(futures);
    _scoreDataCache.clear();
    _scoreDataCache.addAll(data.where((s) => s.name != _manager.currentScoreName));
  }
}

final List<Score> _scoreDataCache = [];
final Map<String, List<Melody>> _sampleMelodies = {
  "Classical": [ odeToJoyA(), odeToJoyB() ]
};
final Map<String, List<Melody>> _sampleDrumMelodies = {
  "Bass/Snare": [ boom(), chick(), boomChick() ],
  "Hat (8th/16th)": [ tssst(), tsstTsst(), ],
  "Hat (32nd)": [ fiveOutOfThirtyTwo(), thirteenOutOfThirtyTwo(), twentyOneOutOfThirtyTwo(), twentyNineOutOfThirtyTwo() ],
  "Hat (8th/16th Swing)": [ tssstSwing(), tsstTsstSwing() ],
};
final _manager = ScoreManager();

class _MelodyMenuBrowserState extends State<MelodyMenuBrowser> {
  Score selectedScore;
  Part selectedPart;
  BSNotifier updatedMenu;
  String selectedSamples;
  Iterable<String> get sampleLists => (widget.part.isDrum ? _sampleDrumMelodies : _sampleMelodies)
    .keys;
  List<Melody> get samples =>
    (widget.part.isDrum ? _sampleDrumMelodies[selectedSamples] : _sampleMelodies[selectedSamples])
      ?? [];

  List<Melody> findDuplicatedMelodies(List<Melody> input) =>
    input.where((it) => widget.part.melodies.any((m) => m.name == it.name)).toList();

  List<myPopup.PopupMenuEntry<String>> menuEntriesByDuplicateStatus(List<Melody> input, {bool isSample = false}) {
    if (input.isEmpty) {
      return [ noneFoundHeader("Melodies") ];
    }
    List<Melody> duplicates = findDuplicatedMelodies(input);
    List<Melody> nonDuplicates = List.from(input)..removeWhere((it) => duplicates.contains(it));

    List<myPopup.PopupMenuEntry<String>> result = List();
    result.addAll(nonDuplicates.map((m) => melodyMenuItem(m, isSample: isSample)));
    result.addAll(duplicates.map((m) => melodyMenuItem(m, isSample: isSample, isDuplicate: true)));
    return result;
  }


  @override
  initState() {
    super.initState();
    updatedMenu = new BSNotifier();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedScore == null) {

    }
    return new MyPopupMenuButton(
      // color: widget.instrumentType.isDrum ? Colors.brown : Colors.grey,
      padding: EdgeInsets.zero,
      child: widget.child ?? Column(children: [Expanded(
        child: Row(children: [
          SizedBox(width: 15),
          Icon(Icons.folder_open, color: widget.textColor),
          SizedBox(width: 5),
          Expanded(child: Text("Import", maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w200))),
        ]),
      )
      ]),
      updatedMenu: updatedMenu,
      itemBuilder: (ctx) {
        if (selectedScore == null && selectedSamples == null) {
          List<myPopup.PopupMenuEntry<String>> result = [ mainHeader(), samplesSectionHeader()];
          result.addAll(sampleLists.map((listName) => sampleListMenuItem(listName)));
          // result.addAll(samples.map((m) => melodyMenuItem(m, isSample: true)));
          if (BeatScratchPlugin.supportsStorage) {
            result.add(scoreSectionHeader());
            result.addAll(_scoreDataCache.map(scoreMenuItem));
          }
          return result;
        } else if (selectedSamples != null) {
          List<myPopup.PopupMenuEntry<String>> result = [ backMenuItem(), sampleListHeader()];
          result.addAll(menuEntriesByDuplicateStatus(samples, isSample: true));
          // result.addAll(samples.map((m) => melodyMenuItem(m, isSample: true)));
          return result;
        } else if (selectedPart == null) {
          return [backMenuItem(), partListHeader()] + selectedScore.parts
            .map(partMenuItem).toList();
        } else {
          List<myPopup.PopupMenuEntry<String>> result = [ backMenuItem(), melodyListHeader(selectedPart)];
          result.addAll(menuEntriesByDuplicateStatus(selectedPart.melodies));
          return result;
        }
      },
      onSelected: (value) {
        switch (value) {
          case "back":
            if (selectedPart != null) {
              if (selectedPart.isDrum) {
                selectedScore = null;
              }
              selectedPart = null;
            } else if (selectedScore != null) {
              selectedScore = null;
            } else if (selectedSamples != null) {
              selectedSamples = null;
            }
            updatedMenu();
            break;
          default:
            if (selectedScore == null && selectedSamples == null) {
              if (value.startsWith("samples-")) {
                selectedSamples = value.replaceAll("samples-", "");
              } else {
                selectedScore = _scoreDataCache.firstWhere((s) => s.id == value);
                if (widget.part.isDrum) {
                  selectedPart = selectedScore.parts.firstWhere((p) => p.isDrum, orElse: null);
                }
              }
              updatedMenu();
            } else if (selectedSamples != null) {
              if (value.startsWith("sample-")) {
                final melody = samples.firstWhere((m) => "sample-${m.id}" == value);
                widget.onMelodySelected(melody);
              } // else - ???
            } else if (selectedPart == null) {
              selectedPart = selectedScore.parts.firstWhere((p) => p.id == value);
              updatedMenu();
            } else {
              final melody = selectedPart.melodies.firstWhere((m) => m.id == value);
              widget.onMelodySelected(melody);
            }
        }

      }
    );
  }

  MyPopupMenuItem<String> backMenuItem() {
    return MyPopupMenuItem(
      value: "back",
      child: Container(child: Row(children: [
        Icon(Icons.chevron_left),
        Expanded(child: Text(selectedSamples != null ? "Import" : selectedPart != null && !selectedPart.isDrum ? "Parts" : "Import"))
      ])),
      enabled: true,
    );
  }

  MyPopupMenuItem<String> scoreMenuItem(Score score) {
    return MyPopupMenuItem(
      value: score.id,
      child: Row(children: [
        Expanded(child: Text(score.name)),
        Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.chevron_right))
      ]),
      enabled: true,
    );
  }

  TextStyle instrumentStyle(Part part, {bool header = false}) {
    return TextStyle(fontWeight: FontWeight.w800,
      color: part.instrument.type == InstrumentType.drum ? Colors.brown.withOpacity(widget.part.isDrum ? 1 : 0.5)
        : widget.part.isDrum || header ? Colors.grey : Colors.black,);
  }

  MyPopupMenuItem<String> partMenuItem(Part part) {
    return MyPopupMenuItem(
      value: part.id,
      child: Row(children: [
        Expanded(child:
        Text(part.midiName, style: instrumentStyle(part))),
        Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.chevron_right))
      ]),
      enabled: part.instrument.type == widget.part.instrument.type,
    );
  }

  MyPopupMenuItem<String> melodyMenuItem(Melody melody, {bool isSample = false, bool isDuplicate = false}) {
    return MyPopupMenuItem(
      value: isSample ? "sample-${melody.id}" : melody.id,
      child: Column(
        children: [
          Row(children: [
            Opacity(opacity: isDuplicate? 0.5 : 1, child: BeatsBadge(beats: melody.beatCount)),
            SizedBox(width: 5),
            Expanded(child: Opacity(opacity: isDuplicate? 0.5 : 1, child: Text(melody.name))),
            SizedBox(width: 5),
            Padding(padding: EdgeInsets.symmetric(vertical: 2), child: Icon(Icons.add)),
            if (!isDuplicate && widget.part.instrument.type == melody.instrumentType) SizedBox(width: 5),
            if (isDuplicate) Transform.scale(
              scale: 0.8,
              child: Container(
                decoration: BoxDecoration(color: Color(0xFF212121), borderRadius: BorderRadius.circular(5)),
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                child: Row(children:[
                  Stack(
                    children: [
                      // Transform.scale(scale: 1.1, child: Icon(Icons.circle, color: Color(0xFF424242))),
                      Transform.translate(offset: Offset(0, -0.5), child: Transform.scale(scale: 0.7, child: Icon(Icons.warning_amber_sharp, color: chromaticSteps[5]))),
                    ],
                  ),
                  Stack(
                    children: [
                      Transform.translate(offset: Offset(0, -5),
                        child: Text("Duplicate", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200))),
                      Transform.translate(offset: Offset(0, 5),
                        child: Text("Name", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200)))
                    ],
                  ),
                  SizedBox(width: 5)
              ])),
            ),
            if (widget.part.instrument.type != melody.instrumentType) Transform.scale(
              scale: 0.8,
              child: Container(
                decoration: BoxDecoration(color: Color(0xFF212121), borderRadius: BorderRadius.circular(5)),
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                child: Row(children:[
                  Stack(
                    children: [
                      // Transform.scale(scale: 1.1, child: Icon(Icons.circle, color: Color(0xFF424242))),
                      Transform.translate(offset: Offset(0, -0.5), child: Transform.scale(scale: 0.8, child: Icon(Icons.warning_amber_sharp, color: chromaticSteps[7]))),
                    ],
                  ),
                  Stack(
                    children: [
                      Transform.translate(offset: Offset(0, -5),
                        child: Text("Wrong", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200))),
                      Transform.translate(offset: Offset(0, 5),
                        child: Text("Part Type", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w200)))
                    ],
                  ),
                  SizedBox(width: 5)
                ])),
            ),
          ]),
              Opacity(opacity: isDuplicate? 0.5 : 1, child: MelodyPreview(section: widget.currentSection, part: widget.part, melody: melody,)),
        ],
      ),
      enabled: melody.instrumentType == widget.part.instrument.type,
    );
  }

  MyPopupMenuItem<String> sampleListMenuItem(String sampleListName) {
    return MyPopupMenuItem(
      value: "samples-$sampleListName",
      child: Column(
        children: [
          Row(children: [
            // Expanded(child: SizedBox()),
            Text(sampleListName),
            Expanded(child: SizedBox()),
            Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.chevron_right))
          ]),
        ],
      ),
      enabled: true,
    );
  }

  MyPopupMenuItem<String> mainHeader() {
    return _splitListHeader(
      Text("Import\nMelody", textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10)/*style: instrumentStyle(part, header: true)*/),
      Text(widget.part.midiName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: instrumentStyle(widget.part, header: true)),
    );
  }

  MyPopupMenuItem<String> samplesSectionHeader() {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text("Bundled Samples", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w200)),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }

  MyPopupMenuItem<String> scoreSectionHeader() {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text("Saved Scores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w200)),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }

  MyPopupMenuItem<String> sampleListHeader() {
    return _splitListHeader(
      Text("Bundled\nSamples", textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10)/*style: instrumentStyle(part, header: true)*/),
      Text(selectedSamples, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle()),
    );
  }

  MyPopupMenuItem<String> partListHeader() {
    return _splitListHeader(
      Text("Saved\nScores", textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10)/*style: instrumentStyle(part, header: true)*/),
      Text(selectedScore.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle()),
    );
  }

  MyPopupMenuItem<String> melodyListHeader(Part part) {
    return _splitListHeader(
      Text(selectedScore.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10)),
      Text(selectedPart.midiName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: instrumentStyle(part, header: true))
    );
  }

  MyPopupMenuItem<String> _splitListHeader(Widget left, Widget right) {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: left
              ),
            ),
            // Expanded(child: SizedBox()),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: right,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(width: 2.0, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }

  MyPopupMenuItem<String> noneFoundHeader(String entityPluralName) {
    return MyPopupMenuItem(
      value: "none-found",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text("No $entityPluralName Here."),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }
}

