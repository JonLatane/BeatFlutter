import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:unification/unification.dart';

import '../animations/animations.dart';
import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../storage/score_manager.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
import 'my_buttons.dart';
import 'my_platform.dart';
import 'scalable_view.dart';

double beatsBadgeWidth(int beats) {
  double width = 30;
  if (beats == null) {
    beats = 9999;
  }
  if (beats > 99) width = 40;
  if (beats > 999) width = 50;
  if (beats > 9999) width = 60;
  if (beats > 99999) width = 70;
  return width;
}

class BeatsBadge extends StatelessWidget {
  final int beats;
  final bool show;
  final double opacity;
  final bool isPerBeat;

  const BeatsBadge({Key key, this.beats, this.show = true, this.opacity = 0.5, this.isPerBeat = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: animationDuration,
      opacity: show ? opacity : 0,
      child: AnimatedContainer(
        duration: animationDuration,
        width: show ? beatsBadgeWidth(beats) : 0,
        height: 25,
        child: Stack(children: [
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, -5),
              child: Text(
                "$beats",
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: TextStyle(fontWeight: FontWeight.w900, color: isPerBeat ? Colors.white : Colors.black),
              ))),
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, 6),
              child: Text(
                isPerBeat ? "/beat" : "beat${beats == 1 ? "" : "s"}",
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  fontWeight: FontWeight.w100, fontSize: 8, color: isPerBeat ? Colors.white : Colors.black),
              ))),
        ]),
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: isPerBeat ? Colors.black : Colors.white,
          border: Border.all(
            color: Colors.black,
          ),
          borderRadius: BorderRadius.all(Radius.circular(5))),
      ));
  }
}