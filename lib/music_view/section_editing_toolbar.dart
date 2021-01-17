import 'package:beatscratch_flutter_redux/cache_management.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../ui_models.dart';
import '../widget/beats_badge.dart';
import '../util/music_theory.dart';
import '../widget/incrementable_value.dart';
import '../colors.dart';

class SectionEditingToolbar extends StatefulWidget {
  final Score score;
  final Color sectionColor;
  final Section currentSection;

  const SectionEditingToolbar(
      {Key key, this.sectionColor, this.score, this.currentSection})
      : super(key: key);

  @override
  _SectionEditingToolbarState createState() => _SectionEditingToolbarState();
}

class _SectionEditingToolbarState extends State<SectionEditingToolbar>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Color recordingAnimationColor;
  Animation<Color> recordingAnimation;

  static final List<NoteName> keys = [
    NoteName()
      ..noteLetter = NoteLetter.C
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.C
      ..noteSign = NoteSign.natural,
    NoteName()
      ..noteLetter = NoteLetter.C
      ..noteSign = NoteSign.sharp,
    NoteName()
      ..noteLetter = NoteLetter.D
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.D
      ..noteSign = NoteSign.natural,
    NoteName()
      ..noteLetter = NoteLetter.D
      ..noteSign = NoteSign.sharp,
    NoteName()
      ..noteLetter = NoteLetter.E
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.E
      ..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.E..noteSign = NoteSign.sharp,
//    NoteName()..noteLetter = NoteLetter.F..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.F
      ..noteSign = NoteSign.natural,
    NoteName()
      ..noteLetter = NoteLetter.F
      ..noteSign = NoteSign.sharp,
    NoteName()
      ..noteLetter = NoteLetter.G
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.G
      ..noteSign = NoteSign.natural,
    NoteName()
      ..noteLetter = NoteLetter.G
      ..noteSign = NoteSign.sharp,
    NoteName()
      ..noteLetter = NoteLetter.A
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.A
      ..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.A..noteSign = NoteSign.sharp,
    NoteName()
      ..noteLetter = NoteLetter.B
      ..noteSign = NoteSign.flat,
    NoteName()
      ..noteLetter = NoteLetter.B
      ..noteSign = NoteSign.natural,
//    NoteName()..noteLetter = NoteLetter.B..noteSign = NoteSign.sharp,
  ];

  @override
  void initState() {
    super.initState();
//    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    super.dispose();
//    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
//    recordingAnimation = ColorTween(
//      begin: Colors.grey,
//      end: chromaticSteps[7],
//    ).animate(animationController)
//      ..addListener(() {
//        setState(() {
//          recordingAnimationColor = recordingAnimation.value;
//        });
//      });
//    animationController.repeat(reverse: true);
//    Color recordingColor;
//    if(widget.melody != null && BeatScratchPlugin.playing) {
//      recordingColor = recordingAnimationColor;
//    } else {
//      recordingColor = Colors.grey;
//    }
    NoteName key = widget.currentSection.harmony.data[0].rootNote;
    int keyIndex = keys.indexOf(key);
    return Row(children: [
      SizedBox(width: 1),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.currentSection.beatCount > 1)
            ? () {
                if (widget.currentSection.beatCount > 1) {
                  widget.currentSection.harmony.length -=
                      widget.currentSection.harmony.subdivisionsPerBeat;
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  BeatScratchPlugin.updateSections(widget.score);
                }

//          BeatScratchPlugin.updateMelody(widget.currentSection.harmony);
              }
            : null,
        onIncrement: (widget.currentSection.beatCount <= 999)
            ? () {
                if (widget.currentSection.beatCount <= 999) {
                  widget.currentSection.harmony.length +=
                      widget.currentSection.harmony.subdivisionsPerBeat;
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  BeatScratchPlugin.updateSections(widget.score);
                }
//          BeatScratchPlugin.updateMelody(widget.melody);
              }
            : null,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
            child: BeatsBadge(beats: widget.currentSection.beatCount)),
      ),
      SizedBox(width: 2),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.currentSection.tempo.bpm > 21)
            ? () {
                widget.currentSection.tempo.bpm--;
                BeatScratchPlugin.updateSections(widget.score);
                BeatScratchPlugin.unmultipliedBpm =
                    widget.currentSection.tempo.bpm;
                BeatScratchPlugin.onSynthesizerStatusChange();
              }
            : null,
        onIncrement: (widget.currentSection.tempo.bpm < 499)
            ? () {
                widget.currentSection.tempo.bpm++;
                BeatScratchPlugin.updateSections(widget.score);
                BeatScratchPlugin.unmultipliedBpm =
                    widget.currentSection.tempo.bpm;
                BeatScratchPlugin.onSynthesizerStatusChange();
              }
            : null,
        child: Container(
            width: 36,
            padding: EdgeInsets.only(top: 0, bottom: 5),
            child: Stack(children: [
              Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                    opacity: 0.4,
                    duration: animationDuration,
                    child: Transform.scale(
                        scale: 0.8,
                        child: Image.asset('assets/metronome.png'))),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                    offset: Offset(0, -7),
                    child: Text(
                        widget.currentSection.tempo.bpm.toStringAsFixed(0),
                        style: TextStyle(
                            color: widget.sectionColor.textColor(),
                            fontWeight: FontWeight.w700))),
              )
            ])),
      ),
      SizedBox(width: 2),
      IncrementableValue(
        collapsing: true,
        onDecrement: () {
          int valueIndex = widget.currentSection.color.value - 1;
          if (valueIndex < 0) {
            valueIndex += IntervalColor.values.length;
          }
          widget.currentSection.color = IntervalColor.values[valueIndex];
          BeatScratchPlugin.onSynthesizerStatusChange();
        },
        onIncrement: () {
          int valueIndex = widget.currentSection.color.value + 1;
          if (valueIndex == IntervalColor.values.length) {
            valueIndex = 0;
          }
          widget.currentSection.color = IntervalColor.values[valueIndex];
          BeatScratchPlugin.onSynthesizerStatusChange();
        },
        child: Container(
            child: Container(
                width: 32,
                height: 32,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.sectionColor.textColor(),
                    ),
                    color: widget.sectionColor),
                child: Icon(
                  Icons.palette,
                  color: widget.sectionColor.textColor(),
                ))),
      ),
      Expanded(
        child: SizedBox(width: 2),
      ),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.currentSection.meter.defaultBeatsPerMeasure > 1)
            ? () {
                if (widget.currentSection.meter.defaultBeatsPerMeasure > 1) {
                  widget.currentSection.meter.defaultBeatsPerMeasure -= 1;
                  MelodyTheory.tonesInMeasureCache.clear();
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  BeatScratchPlugin.updateSections(widget.score);
                }
              }
            : null,
        onIncrement: (widget.currentSection.meter.defaultBeatsPerMeasure < 99)
            ? () {
                if (widget.currentSection.meter.defaultBeatsPerMeasure < 99) {
                  widget.currentSection.meter.defaultBeatsPerMeasure += 1;
                  MelodyTheory.tonesInMeasureCache.clear();
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  BeatScratchPlugin.updateSections(widget.score);
                }
              }
            : null,
        child: Container(
            width: 30,
            height: 32,
            padding: EdgeInsets.only(left: 5),
            child: Stack(children: [
              Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                      offset: Offset(-1.5, -9),
                      child: Text(
                          widget.currentSection.meter.defaultBeatsPerMeasure
                              .toString(),
                          style: TextStyle(
                              color: widget.sectionColor.textColor(),
                              fontSize: 15,
                              fontWeight: FontWeight.w900)))),
              Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                      offset: Offset(-1.5, 6),
                      child: Text(
                        "4",
                        style: TextStyle(
                            color: widget.sectionColor.textColor(),
                            fontSize: 15,
                            fontWeight: FontWeight.w900),
                      )))
            ])),
      ),
      SizedBox(width: 2),
      IncrementableValue(
        collapsing: true,
        onDecrement: () {
          int newKeyIndex = keyIndex - 1;
          if (newKeyIndex < 0) {
            newKeyIndex += keys.length;
          }
          widget.currentSection.harmony.data[0].rootNote = keys[newKeyIndex];
          MelodyTheory.tonesInMeasureCache.clear();
          BeatScratchPlugin.onSynthesizerStatusChange();
          BeatScratchPlugin.updateSections(widget.score);
          clearMutableCaches();

//          BeatScratchPlugin.updateMelody(widget.currentSection.harmony);
        },
        onIncrement: () {
          int newKeyIndex = keyIndex + 1;
          if (newKeyIndex >= keys.length) {
            newKeyIndex -= keys.length;
          }
          widget.currentSection.harmony.data[0].rootNote = keys[newKeyIndex];
          MelodyTheory.tonesInMeasureCache.clear();
          BeatScratchPlugin.onSynthesizerStatusChange();
          BeatScratchPlugin.updateSections(widget.score);
          clearMutableCaches();
        },
        child: Container(
            width: 30,
            height: 32,
            padding: EdgeInsets.only(left: 5),
            child: Align(
                alignment: Alignment.center,
                child: Transform.translate(
                    offset: Offset(-1.5, -2),
                    child: Text(key.simpleString,
                        style: TextStyle(
                            color: widget.sectionColor.textColor(),
                            fontSize: 16,
                            fontWeight: FontWeight.w200))))),
      ),
//      IncrementableValue(
//        onDecrement: null,
//        onIncrement: null,
//        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
//          child:BeatsBadge(beats: widget.currentSection.harmony.subdivisionsPerBeat, isPerBeat: true,)),
//      ),
      SizedBox(width: 1),
    ]);
  }
}
