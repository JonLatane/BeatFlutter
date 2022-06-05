import '../cache_management.dart';
import '../colors.dart';
import '../generated/protos/music.pb.dart';
import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../ui_models.dart';
import '../widget/beats_badge.dart';
import '../util/music_theory.dart';
import '../util/music_utils.dart';
import '../widget/incrementable_value.dart';
import '../widget/my_buttons.dart';

class MelodyEditingToolbar extends StatefulWidget {
  final String melodyId;
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final bool recordingMelody;
  final bool visible;
  final ValueNotifier<int> highlightedBeat;
  final Function(MelodyReference, double) setReferenceVolume;
  final VoidCallback toggleRecording;

  Melody get melody => score.parts
      .expand((p) => p.melodies)
      .firstWhere((m) => m.id == melodyId, orElse: () => null);

  const MelodyEditingToolbar(
      {Key key,
      @required this.melodyId,
      @required this.sectionColor,
      @required this.score,
      @required this.currentSection,
      @required this.highlightedBeat,
      @required this.setReferenceVolume,
      @required this.recordingMelody,
      @required this.visible,
      @required this.toggleRecording})
      : super(key: key);

  @override
  _MelodyEditingToolbarState createState() => _MelodyEditingToolbarState();
}

class _MelodyEditingToolbarState extends State<MelodyEditingToolbar>
    with TickerProviderStateMixin {
  AnimationController animationController;
  Color recordingAnimationColor;
  Animation<Color> recordingAnimation;
  bool showHoldToClear = false;
  bool showDataCleared = false;
  bool animationStarted = false;

  int get firstBeatOfSection =>
      widget.score.firstBeatOfSection(widget.currentSection);

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    recordingAnimation = ColorTween(
      begin: Colors.grey,
      end: chromaticSteps[7],
    ).animate(animationController)
      ..addListener(() {
        setState(() {
          recordingAnimationColor = recordingAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!animationStarted &&
        widget.recordingMelody &&
        BeatScratchPlugin.playing) {
      animationController.repeat(reverse: true);
      animationStarted = true;
    } else if (widget.recordingMelody || !BeatScratchPlugin.playing) {
      animationController.stop(canceled: false);
      animationStarted = false;
    }
    Color recordingColor;
    if (widget.recordingMelody && BeatScratchPlugin.playing) {
      recordingColor = recordingAnimationColor;
    } else {
      recordingColor = Colors.grey;
    }
    int beats;
    if (widget.melody != null) {
      beats = widget.melody.length ~/ widget.melody.subdivisionsPerBeat;
    }
    bool hasHighlightedBeat = widget.highlightedBeat.value != null &&
        BeatScratchPlugin.playing &&
        widget.recordingMelody;
    final melodyReference = widget.currentSection.referenceTo(widget.melody);
    bool playingOrCountingIn =
        BeatScratchPlugin.playing || BeatScratchPlugin.countInInitiated;
    bool showGo = widget.recordingMelody &&
        !playingOrCountingIn &&
        BeatScratchPlugin.supportsPlayback;
    return Row(children: [
      SizedBox(width: 5),
      Container(
        width: 48,
        child: MyFlatButton(
            padding: EdgeInsets.zero,
            onPressed: widget.toggleRecording,
            child: Stack(children: [
              Center(
                  child: Transform.translate(
                      offset: Offset(0, -5),
                      child: Icon(Icons.fiber_manual_record,
                          color: recordingColor))),
              Center(
                  child: Transform.translate(
                      offset: Offset(0, 10),
                      child: Text(
                          widget.recordingMelody
                              ? BeatScratchPlugin.playing
                                  ? 'Recording\n'
                                  : 'Recording\nOn'
                              : 'Recording\nOff',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              height: 0.9,
                              fontWeight: FontWeight.w100,
                              fontSize: 8,
                              color: recordingColor)))),
            ])),
      ),

      /// child: Column(children: [
      ///   Expanded(child: SizedBox()),
      ///   Transform.translate(
      ///       offset: Offset(0, 0),
      ///       child: Icon(Icons.fiber_manual_record, color: recordingColor)),
      ///   Text(
      ///       widget.recordingMelody
      ///           ? BeatScratchPlugin.playing
      ///               ? 'Recording\n'
      ///               : 'Recording\nOn'
      ///           : 'Recording\nOff',
      ///       overflow: TextOverflow.ellipsis,
      ///       textAlign: TextAlign.center,
      ///       style: TextStyle(
      ///           height: 0.9,
      ///           fontWeight: FontWeight.w100,
      ///           fontSize: 8,
      ///           color: recordingColor)),
      ///   Expanded(child: SizedBox()),
      /// ])),
      AnimatedOpacity(
          duration: animationDuration,
          opacity: showGo ? 1 : 0,
          child: AnimatedContainer(
              duration: animationDuration,
              width: showGo ? 30 : 0,
              child: MyFlatButton(
                  padding: EdgeInsets.zero,
                  onPressed: showGo
                      ? () {
                          if (BeatScratchPlugin.playing) {
                            BeatScratchPlugin.pause();
                          } else {
                            BeatScratchPlugin.play();
                          }
                        }
                      : null,
                  child: Stack(
                    children: [
                      Center(
                        child: Transform.translate(
                            offset: Offset(0, -5),
                            child: Icon(Icons.double_arrow,
                                color:
                                    !showGo ? Colors.grey : chromaticSteps[0])),
                      ),
                      Center(
                          child: Transform.translate(
                              offset: Offset(0, 15),
                              child: Text('Go!\n',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w100,
                                      fontSize: 8,
                                      color: !showGo
                                          ? Colors.grey
                                          : chromaticSteps[7]))))
                    ],
                  )))),
      // Column(children: [
      //   Expanded(child: SizedBox()),
      //   Transform.translate(
      //       offset: Offset(0, 5),
      //       child: Icon(Icons.double_arrow,
      //           color: !showGo ? Colors.grey : chromaticSteps[0])),
      //   Text('Go!\n',
      //       overflow: TextOverflow.ellipsis,
      //       textAlign: TextAlign.center,
      //       style: TextStyle(
      //           fontWeight: FontWeight.w100,
      //           fontSize: 8,
      //           color: !showGo ? Colors.grey : chromaticSteps[7])),
      //   Expanded(child: SizedBox()),
      // ])))),
      SizedBox(width: 7),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.melody != null && widget.melody.beatCount > 1)
            ? () {
                if (widget.melody != null && widget.melody.beatCount > 1) {
                  widget.melody.length -= widget.melody.subdivisionsPerBeat;
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.updateMelody(widget.melody);
                }
              }
            : null,
        onIncrement: (widget.melody != null && widget.melody.beatCount <= 999)
            ? () {
                if (widget.melody != null && widget.melody.beatCount <= 999) {
                  widget.melody.length += widget.melody.subdivisionsPerBeat;
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.updateMelody(widget.melody);
                }
              }
            : null,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
            child: BeatsBadge(beats: beats)),
//        valueWidth: 100,
//        value: "$beats beat${beats == 1 ? "" : "s"}",
      ),
      SizedBox(width: 5),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.melody?.subdivisionsPerBeat ?? -1) > 1
            ? () {
                if ((widget.melody?.subdivisionsPerBeat ?? -1) > 1) {
                  widget.melody?.subdivisionsPerBeat -= 1;
                  widget.melody.length =
                      beats * widget.melody.subdivisionsPerBeat;
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.updateMelody(widget.melody);
                }
              }
            : null,
        onIncrement: (widget.melody?.subdivisionsPerBeat ?? -1) < 24
            ? () {
                if ((widget.melody?.subdivisionsPerBeat ?? -1) < 24) {
                  widget.melody?.subdivisionsPerBeat += 1;
                  widget.melody.length =
                      beats * widget.melody.subdivisionsPerBeat;
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.onSynthesizerStatusChange();
                  clearMutableCachesForMelody(widget.melody.id);
                  BeatScratchPlugin.updateMelody(widget.melody);
                }
              }
            : null,
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
            child: BeatsBadge(
              beats: widget.melody?.subdivisionsPerBeat,
              isPerBeat: true,
            )),
      ),
      SizedBox(width: 5),
      Expanded(
          child: AnimatedOpacity(
        duration: animationDuration,
        opacity: widget.melody != null && widget.visible ? 1 : 0,
        child: MySlider(
            value: melodyReference?.volume ?? 0,
            activeColor: melodyReference?.playbackType ==
                    MelodyReference_PlaybackType.playback_indefinitely
                ? widget.sectionColor
                : widget.sectionColor.withOpacity(0.5),
            onChanged: (widget.melody != null && widget.visible)
                ? (value) {
                    widget.setReferenceVolume(melodyReference, value);
                  }
                : null),
      )),
      AnimatedContainer(
          duration: animationDuration,
          width: showHoldToClear ? 35 : 0,
          height: 36,
          padding: EdgeInsets.only(left: 5),
          child: AnimatedOpacity(
              duration: animationDuration,
              opacity: widget.melody != null && showHoldToClear ? 1 : 0,
              child: Stack(children: [
                Transform.translate(
                    offset: Offset(0, -7),
                    child: Align(
                        alignment: Alignment.center,
                        child: Text("Hold",
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 10)))),
                Transform.translate(
                    offset: Offset(0, 0),
                    child: Align(
                        alignment: Alignment.center,
                        child: Text("to",
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 10)))),
                Transform.translate(
                    offset: Offset(0, 7),
                    child: Align(
                        alignment: Alignment.center,
                        child: Text("clear",
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 10)))),
              ]))),
      AnimatedContainer(
          duration: animationDuration,
          width: showDataCleared ? 45 : 0,
          height: 36,
          padding: EdgeInsets.only(left: 5),
          child: AnimatedOpacity(
              duration: animationDuration,
              opacity: widget.melody != null && showDataCleared ? 1 : 0,
              child: Stack(children: [
                // Transform.translate(offset: Offset(0, -7), child: Align(alignment: Alignment.center, child:
                // Text("Data", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
                // Transform.translate(offset: Offset(0, 7), child:
                Align(
                    alignment: Alignment.center,
                    child: Text("Cleared",
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: TextStyle(fontSize: 10)))
                // ),
              ]))),
      AnimatedContainer(
          duration: animationDuration,
          width: 44,
          height: 36,
          padding: EdgeInsets.only(left: 8),
          child: MyRaisedButton(
              color: Color(0x424242).withOpacity(1),
              padding: EdgeInsets.zero,
              onLongPress: widget.melody != null
                  ? () {
                      print("clearing");
                      widget.melody.midiData.data.clear();
                      clearMutableCachesForMelody(widget.melody.id);
                      BeatScratchPlugin.onSynthesizerStatusChange();
                      BeatScratchPlugin.updateMelody(widget.melody);
                      setState(() {
                        showDataCleared = true;
                        showHoldToClear = false;
                      });
                      Future.delayed(Duration(seconds: 3), () {
                        setState(() {
                          showDataCleared = false;
                        });
                      });
                    }
                  : null,
              onPressed: () {
                setState(() {
                  showHoldToClear = true;
                  showDataCleared = false;
                });
                Future.delayed(Duration(seconds: 3), () {
                  setState(() {
                    showHoldToClear = false;
                  });
                });
              },
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: widget.visible ? 1 : 0,
                  child: Stack(
                    children: [
                      Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.delete_sweep, color: Colors.white)),
                      Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 1, bottom: 0),
                              child: Transform.translate(
                                offset: Offset(0, 2),
                                child: Text(
                                  "All",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white),
                                ),
                              )))
                    ],
                  )))),
      AnimatedContainer(
          duration: animationDuration,
          width: 44,
          height: 36,
          padding: EdgeInsets.only(left: 8),
          child: MyRaisedButton(
              color: Color(0x424242).withOpacity(1),
              padding: EdgeInsets.zero,
              onLongPress: widget.melody != null
                  ? () {
                      print("clearing single beat");
                      int beatToDelete = widget.highlightedBeat.value;
                      if (beatToDelete == null) {
                        beatToDelete = BeatScratchPlugin.currentBeat.value;
                      } else {
                        beatToDelete -= firstBeatOfSection;
                      }
                      widget.melody.deleteBeat(beatToDelete);
                      clearMutableCachesForMelody(widget.melody.id);
                      BeatScratchPlugin.onSynthesizerStatusChange();
                      BeatScratchPlugin.updateMelody(widget.melody);
                      setState(() {
                        showDataCleared = true;
                        showHoldToClear = false;
                      });
                      Future.delayed(Duration(seconds: 3), () {
                        setState(() {
                          showDataCleared = false;
                        });
                      });
                    }
                  : null,
              onPressed: () {
                setState(() {
                  showHoldToClear = true;
                  showDataCleared = false;
                });
                Future.delayed(Duration(seconds: 3), () {
                  setState(() {
                    showHoldToClear = false;
                  });
                });
              },
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: widget.visible ? 1 : 0,
                  child: Stack(
                    children: [
                      Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.delete_sweep,
                              color: hasHighlightedBeat
                                  ? widget.sectionColor
                                  : Colors.white)),
                      Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 1, bottom: 0),
                            child: Transform.translate(
                                offset: Offset(0, 2),
                                child: Text(
                                  "Beat",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: hasHighlightedBeat
                                          ? widget.sectionColor
                                          : Colors.white,
                                      fontWeight: FontWeight.w400),
                                )),
                          ))
                    ],
                  )))),
      SizedBox(width: 7),
    ]);
  }
}
