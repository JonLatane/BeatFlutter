import 'package:beatscratch_flutter_redux/cache_management.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
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
  final bool editingMelody;
  final ValueNotifier<int> highlightedBeat;
  Melody get melody => score.parts.expand((p) => p.melodies).firstWhere((m) => m.id == melodyId, orElse: () => null);

  const MelodyEditingToolbar({Key key, this.melodyId, this.sectionColor, this.score, this.currentSection, this.editingMelody, this.highlightedBeat}) : super(key: key);

  @override
  _MelodyEditingToolbarState createState() => _MelodyEditingToolbarState();
}

class _MelodyEditingToolbarState extends State<MelodyEditingToolbar> with TickerProviderStateMixin {
  AnimationController animationController;
  Color recordingAnimationColor;
  Animation<Color> recordingAnimation;
  bool showHoldToClear = false;
  bool showDataCleared = false;
  bool animationStarted = false;
  int get firstBeatOfSection => widget.score.firstBeatOfSection(widget.currentSection);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
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
    if (!animationStarted && widget.editingMelody && BeatScratchPlugin.playing) {
      animationController.repeat(reverse: true);
      animationStarted = true;
    } else if (widget.editingMelody || !BeatScratchPlugin.playing) {
      animationController.stop(canceled: false);
      animationStarted = false;
    }
    Color recordingColor;
    if(widget.editingMelody && BeatScratchPlugin.playing) {
      recordingColor = recordingAnimationColor;
    } else {
      recordingColor = Colors.grey;
    }
    int beats;
    if(widget.melody != null) {
      beats = widget.melody.length ~/ widget.melody.subdivisionsPerBeat;
    }
    bool hasHighlightedBeat = widget.highlightedBeat.value != null && BeatScratchPlugin.playing && widget.editingMelody;
    return Row(children: [
      SizedBox(width: 5),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.melody != null && widget.melody.beatCount > 1)
          ? () {
          if(widget.melody != null && widget.melody.beatCount > 1) {
            widget.melody.length -= widget.melody.subdivisionsPerBeat;
            BeatScratchPlugin.onSynthesizerStatusChange();
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
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
        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5), child:BeatsBadge(beats: beats)),
//        valueWidth: 100,
//        value: "$beats beat${beats == 1 ? "" : "s"}",
      ),
      SizedBox(width: 5),
      IncrementableValue(
        collapsing: true,
        onDecrement: (widget.melody?.subdivisionsPerBeat ?? -1) > 1 ? () {
          if((widget.melody?.subdivisionsPerBeat ?? -1) > 1) {
            widget.melody?.subdivisionsPerBeat -= 1;
            widget.melody.length = beats * widget.melody.subdivisionsPerBeat;
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.onSynthesizerStatusChange();
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
        onIncrement: (widget.melody?.subdivisionsPerBeat ?? -1) < 24 ? () {
          if ((widget.melody?.subdivisionsPerBeat ?? -1) < 24) {
            widget.melody?.subdivisionsPerBeat += 1;
            widget.melody.length = beats * widget.melody.subdivisionsPerBeat;
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.onSynthesizerStatusChange();
            clearMutableCachesForMelody(widget.melody.id);
            BeatScratchPlugin.updateMelody(widget.melody);
          }
        } : null,
        child: Padding(padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
          child:BeatsBadge(beats: widget.melody?.subdivisionsPerBeat, isPerBeat: true,)),
      ),
      SizedBox(width: 5),
      Expanded(child: SizedBox(width: 5),),
      AnimatedContainer(
        duration: animationDuration,
        width: showHoldToClear ? 35 : 0,
        height: 36,
        padding: EdgeInsets.only(left: 5),
        child:  AnimatedOpacity(duration: animationDuration, opacity: widget.melody != null && showHoldToClear ? 1 : 0,
          child: Stack(children:[
            Transform.translate(offset: Offset(0, -7), child: Align(alignment: Alignment.center, child:
            Text("Hold", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            Transform.translate(offset: Offset(0,  0), child:Align(alignment: Alignment.center, child:
            Text("to", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            Transform.translate(offset: Offset(0, 7), child: Align(alignment: Alignment.center, child:
            Text("clear", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
          ]))),
      AnimatedContainer(
        duration: animationDuration,
        width: showDataCleared ? 45 : 0,
        height: 36,
        padding: EdgeInsets.only(left: 5),
        child:  AnimatedOpacity(duration: animationDuration, opacity: widget.melody != null && showDataCleared ? 1 : 0,
          child: Stack(children:[
            // Transform.translate(offset: Offset(0, -7), child: Align(alignment: Alignment.center, child:
            // Text("Data", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))),
            // Transform.translate(offset: Offset(0, 7), child:
            Align(alignment: Alignment.center, child:
            Text("Cleared", maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 10)))
            // ),
          ]))),
      AnimatedContainer(
        duration: animationDuration,
        width: 44,
        height: 36,
        padding: EdgeInsets.only(left: 8),
        child:  MyRaisedButton(
          color: Color(0x424242).withOpacity(1),
          padding: EdgeInsets.zero,
          onLongPress: widget.melody != null ? () {
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
          } : null,
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
          child: AnimatedOpacity(duration: animationDuration, opacity: widget.editingMelody ? 1 : 0,
            child: Stack(
              children: [
                Align(alignment: Alignment.center, child: Icon(Icons.delete_sweep, color: Colors.white)),
                Align(alignment: Alignment.bottomRight, child: Padding(
                  padding: const EdgeInsets.only(right: 1, bottom: 0),
                  child: Transform.translate(offset: Offset(0,2), child: Text("All",
                    style: TextStyle(fontSize:10, color: Colors.white),),)
                ))
              ],
            )))),
      AnimatedContainer(
        duration: animationDuration,
        width: 44,
        height: 36,
        padding: EdgeInsets.only(left: 8),
        child:  MyRaisedButton(
          color: Color(0x424242).withOpacity(1),
          padding: EdgeInsets.zero,
          onLongPress: widget.melody != null ? () {
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
          } : null,
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
          child: AnimatedOpacity(duration: animationDuration, opacity: widget.editingMelody ? 1 : 0,
            child: Stack(
              children: [
                Align(alignment: Alignment.center, child: Icon(Icons.delete_sweep,
                  color: hasHighlightedBeat ? widget.sectionColor : Colors.white)),
                Align(alignment: Alignment.bottomRight, child: Padding(
                  padding: const EdgeInsets.only(right: 1, bottom: 0),
                  child: Transform.translate(offset: Offset(0,2), child: Text("Beat",
                    style: TextStyle(fontSize:10,
                      color: hasHighlightedBeat ? widget.sectionColor : Colors.white, fontWeight: FontWeight.w400),)),
                ))
              ],
            )))),
      SizedBox(width: 7),
      Column(children: [
        SizedBox(height: 1),
        Transform.translate(offset: Offset(0, 5), child:
        Icon(Icons.fiber_manual_record, color: recordingColor)),
        Text('Recording',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w100, fontSize: 10, color: recordingColor)),
      ]),
      SizedBox(width: 7),
    ]);
  }
}
