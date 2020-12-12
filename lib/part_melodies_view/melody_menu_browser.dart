
import 'dart:io';

import 'package:beatscratch_flutter_redux/part_melodies_view/part_melodies_view.dart';

import '../util/dummydata.dart';

import '../melody_view/melody_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import '../storage/score_manager.dart';
import '../ui_models.dart';
import '../util/music_theory.dart';
import '../widget/my_popup_menu.dart';

class MelodyMenuBrowser extends StatefulWidget {
  final Part part;
  final Section currentSection;
  final Function(Melody) onMelodySelected;
  InstrumentType get instrumentType => part.instrument.type;

  const MelodyMenuBrowser({Key key, this.part, this.currentSection, this.onMelodySelected }) : super(key: key);
  @override
  _MelodyMenuBrowserState createState() => _MelodyMenuBrowserState();

  static loadScoreData() async {
    final futures = _manager.scoreFiles.map((it) async {
      final score = await _manager.loadScore(it as File);
      score.name = it.scoreName;
      return score;
    });
    final data = await Future.wait(futures);
    _scoreDataCache.clear();
    _scoreDataCache.addAll(data.where((s) => s.name != _manager.currentScoreName));
  }
}

final List<Score> _scoreDataCache = [];
final _manager = ScoreManager();

class _MelodyMenuBrowserState extends State<MelodyMenuBrowser> {
  Score selectedScore;
  Part selectedPart;
  ChangeNotifier updatedMenu;

  @override
  initState() {
    super.initState();
    updatedMenu = new ChangeNotifier();
  }

  @override
  Widget build(BuildContext context) {
    if (selectedScore == null) {

    }
    return new MyPopupMenuButton(
      // color: widget.instrumentType.isDrum ? Colors.brown : Colors.grey,
      padding: EdgeInsets.zero,
      child: Column(children:[Expanded(
        child: Row(children: [
          SizedBox(width:15),
          Icon(Icons.folder_open, color: Colors.white),
          SizedBox(width:5),
          Expanded(child: Text("Import...", maxLines:1, overflow: TextOverflow.fade, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200))),
        ]),
      )]),
      updatedMenu: updatedMenu,
      itemBuilder: (ctx)  {
        if (selectedScore == null) {
          return [scoreListHeader()] + _scoreDataCache.map(scoreMenuItem).toList();
        } else if (selectedPart == null) {
          return [backMenuItem(), partListHeader()] + selectedScore.parts
            .map(partMenuItem).toList();
        } else {
          return [backMenuItem(), melodyListHeader(selectedPart)] + selectedPart.melodies.map(melodyMenuItem).toList();
        }
      },
      onSelected: (value) {
        switch (value) {
          case "back":
            if (selectedPart != null) {
              selectedPart = null;
              updatedMenu.notifyListeners();
            } else if (selectedScore != null) {
              selectedScore = null;
              updatedMenu.notifyListeners();
            }
            break;
          default:
            if (selectedScore == null) {
              selectedScore = _scoreDataCache.firstWhere((s) => s.id == value);
              updatedMenu.notifyListeners();
            } else if (selectedPart == null) {
              selectedPart = selectedScore.parts.firstWhere((p) => p.id == value);
              updatedMenu.notifyListeners();
            } else {
              final melody = selectedPart.melodies.firstWhere((m) => m.id == value);
              widget.onMelodySelected(melody);
            }
        }

      }
    );
  }

  MyPopupMenuItem backMenuItem() {
    return MyPopupMenuItem(
      value: "back",
      child: Container(child:Row(children: [
        Icon(Icons.chevron_left),
        Expanded(child:Text(selectedPart != null ? "Parts" : "Scores"))
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
      color: part.instrument.type == InstrumentType.drum ? Colors.brown
        : widget.instrumentType == InstrumentType.drum || header ? Colors.grey : Colors.black,);
  }

  MyPopupMenuItem<String> partMenuItem(Part part) {
    return MyPopupMenuItem(
      value: part.id,
      child: Row(children: [
        Expanded(child:
        Text(part.midiName, style: instrumentStyle(part))),
        Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.chevron_right))
      ]),
      enabled: part.instrument.type == widget.instrumentType,
    );
  }

  MyPopupMenuItem<String> melodyMenuItem(Melody melody) {
    Score preview = melodyPreview(melody, widget.part, widget.currentSection);
    return MyPopupMenuItem(
      value: melody.id,
      child: Column(
        children: [
          Row(children: [
            BeatsBadge(beats: melody.beatCount),
            SizedBox(width: 5),
            Expanded(child: Text(melody.name)),
            Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
          IgnorePointer(
            child: Container(width: 300, height: 80, child:
            MelodyView(
              initialScale: 0.15,
              previewMode: true,
              isCurrentScore: false,
              enableColorboard: false,
              superSetState: setState,
              melodyViewSizeFactor: 1.0,
              melodyViewMode: MelodyViewMode.none,
              score: preview,
              currentSection: preview?.sections?.first,
              colorboardNotesNotifier: ValueNotifier([]),
              keyboardNotesNotifier: ValueNotifier([]),
              melody: null,
              part: null,
              sectionColor: Colors.grey,
              splitMode: SplitMode.full,
              renderingMode: RenderingMode.notation,
              toggleSplitMode: () {},
              closeMelodyView: () {},
              toggleMelodyReference: (r) {},
              setReferenceVolume: (r, d) {},
              editingMelody: false,
              toggleEditingMelody: () {},
              setPartVolume: (p, v) {},
              setMelodyName: (m, n) {},
              setSectionName: (s, n) {},
              setKeyboardPart: (p) {},
              setColorboardPart: (p) {},
              colorboardPart: null,
              keyboardPart: null,
              height: 100.0,
              deletePart: (part) {},
              deleteMelody: (melody) {},
              deleteSection: (section) {},
              selectBeat: (beat) {},
              cloneCurrentSection: () {},
            )),
          )
        ],
      ),
      enabled: true,
    );
  }
  MyPopupMenuItem<String> scoreListHeader() {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text("Import Melody From Score"),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }
  MyPopupMenuItem<String> partListHeader() {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text(selectedScore.name, maxLines: 2, overflow: TextOverflow.ellipsis,),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }
  MyPopupMenuItem<String> melodyListHeader(Part part) {
    return MyPopupMenuItem(
      value: "header",
      child: Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox()),
            Text(selectedPart.midiName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: instrumentStyle(part, header: true)),
            Expanded(child: SizedBox()),
            // Padding(padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5), child: Icon(Icons.add))
          ]),
        ],
      ),
      enabled: false,
    );
  }


}

