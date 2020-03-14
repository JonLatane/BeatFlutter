import 'dart:collection';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'melodybeat.dart';
import 'expanded_section.dart';
import 'part_melodies_view.dart';
import 'dart:math';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:uuid/uuid.dart';
import 'ui_models.dart';
import 'util.dart';
import 'music_theory.dart';

class MelodyView extends StatefulWidget {
  final double melodyViewSizeFactor;
  final MelodyViewMode melodyViewMode;
  final MelodyViewDisplayMode melodyViewDisplayMode;
  final Score score;
  final Section currentSection;
  final Melody melody;
  final Part part;
  final Color sectionColor;
  final VoidCallback toggleMelodyViewDisplayMode;
  final VoidCallback closeMelodyView;

  MelodyView(
      {this.melodyViewSizeFactor,
      this.melodyViewMode,
      this.score,
      this.currentSection,
      this.melody,
      this.part,
      this.sectionColor,
      this.melodyViewDisplayMode,
      this.toggleMelodyViewDisplayMode,
      this.closeMelodyView});

  @override
  _MelodyViewState createState() => _MelodyViewState();
}

class _MelodyViewState extends State<MelodyView> {
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  double _horizontalScale = 1.0;
  double _verticalScale = 1.0;

  @override
  Widget build(context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: animationDuration,
          color: (widget.melodyViewMode == MelodyViewMode.section) ? widget.sectionColor :
          (widget.melodyViewMode == MelodyViewMode.melody) ? Colors.white :
          (widget.melodyViewMode == MelodyViewMode.part)
            ? ((widget.part.instrument.type == InstrumentType.drum) ? Colors.brown : Colors.grey)
          : Colors.black,
          child: Row(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: AnimatedContainer(
                    duration: animationDuration,
                    width: 36,
                    height: (widget.melodyViewMode != MelodyViewMode.score) ? 36 : 0,
                    child: RaisedButton(
                        onPressed: widget.toggleMelodyViewDisplayMode,
                        padding: EdgeInsets.all(0),
                        child: Icon((widget.melodyViewDisplayMode == MelodyViewDisplayMode.half)
                            ? Icons.aspect_ratio
                            : context.isPortrait ? Icons.border_horizontal : Icons.border_vertical))),
              ),
              Expanded(
                  child: Column(children: [
                AnimatedContainer(
                    duration: animationDuration,
                    height: (widget.melodyViewMode == MelodyViewMode.section) ? 48 : 0,
                    child: _SectionToolbar(
                        currentSection: widget.currentSection,
                        sectionColor: widget.sectionColor,
                        melodyViewMode: widget.melodyViewMode)),
                AnimatedContainer(
                  duration: animationDuration,
                  height: (widget.melodyViewMode == MelodyViewMode.part) ? 48 : 0,
                  child: _PartToolbar(
                    part: widget.part)),
                AnimatedContainer(
                    duration: animationDuration,
                    height: (widget.melodyViewMode == MelodyViewMode.melody) ? 48 : 0,
                    child: _MelodyToolbar(
                      melody: widget.melody,
                      currentSection: widget.currentSection,
                    )),
              ])),
              Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: AnimatedContainer(
                      duration: animationDuration,
                      width: 36,
                      height: (widget.melodyViewMode != MelodyViewMode.score) ? 36 : 0,
                      child: RaisedButton(
                          onPressed: widget.closeMelodyView, padding: EdgeInsets.all(0), child: Icon(Icons.close))))
            ],
          ),
        ),
        Expanded(child: _mainMelody(context))
      ],
    );
  }

  Widget _mainMelody(BuildContext context) {
    return Container(
        color: Colors.white,
        child: GestureDetector(
          onScaleStart: (details) => setState(() {
            _startHorizontalScale = _horizontalScale;
          }),
          onScaleUpdate: (ScaleUpdateDetails details) {
            setState(() {
              if (details.horizontalScale > 0) {
                _horizontalScale = max(0.1, min(16, _startHorizontalScale * details.horizontalScale));
              }
            });
          },
          onScaleEnd: (ScaleEndDetails details) {
            //_horizontalScale = max(0.1, min(16, _horizontalScale.ceil().toDouble()));
          },
          child: GridView.builder(
            gridDelegate:
                new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: max(1, (16 / _horizontalScale).floor())),
            itemCount: 20 * 8,
            itemBuilder: (BuildContext context, int index) {
              return GridTile(
                  child: Transform.scale(
                      scale: 1 - 0.2 * ((16 / _horizontalScale).floor() - (16 / _horizontalScale)).abs(),
                      child: SvgPicture.asset('assets/notehead_half.svg')));
            },
//                padding: const EdgeInsets.all(4.0),
          ),
        ));
  }
}

class _MelodyToolbar extends StatelessWidget {
  final Melody melody;
  final Section currentSection;

  MelodyReference get melodyReference => currentSection.referenceTo(melody);

  const _MelodyToolbar({Key key, this.melody, this.currentSection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    return Container(
//        color: Colors.white,
        child: Row(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: TextField(
                    controller: (melody != null) ? (TextEditingController()..text = melody.name) : TextEditingController(),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (melody != null)
                        ? (value) {
                            melody.name = value;
                          }
                        : null,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: (melody != null) ? "Melody ${melody.id.substring(0, 5)}" : ""),
                  ))),
          RaisedButton(
            onPressed: () {},
            child: Icon(Icons.edit),
          )
        ]));
  }
}

class _PartToolbar extends StatelessWidget {
  final Part part;

  const _PartToolbar({Key key, this.part}) : super(key: key);

  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    return Container(
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text( (part != null) ? part.instrument.name : "",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600))))
      ]));
  }

}

class _SectionToolbar extends StatelessWidget {
  // This widget is the root of your application.
  final Section currentSection;
  final Color sectionColor;
  final MelodyViewMode melodyViewMode;

  const _SectionToolbar({Key key, this.currentSection, this.sectionColor, this.melodyViewMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey) {
      width = width / 2;
    }
    return Container(
//        color: sectionColor,
        child: Row(children: [
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: TextField(
                    style: TextStyle(fontWeight: FontWeight.w100),
                    controller: (melodyViewMode == MelodyViewMode.section)
                        ? (TextEditingController()..text = currentSection.name)
                        : TextEditingController(),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (melodyViewMode == MelodyViewMode.section)
                        ? (value) {
                            currentSection.name = value;
                          }
                        : null,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: (melodyViewMode == MelodyViewMode.section)
                            ? "Section ${currentSection.id.substring(0, 5)}"
                            : ""),
                  ))),
//        RaisedButton(onPressed: () {  },
//          child: Icon(Icons.edit),)
        ]));
  }
}
