
import 'package:flutter/cupertino.dart';

import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/dummydata.dart';
import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:beatscratch_flutter_redux/my_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:unification/unification.dart';

import 'animations/animations.dart';
import 'beatscratch_plugin.dart';
import 'dummydata.dart';
import 'midi_theory.dart';
import 'music_theory.dart';
import 'my_buttons.dart';
import 'ui_models.dart';
import 'util.dart';

class ScalableView extends StatelessWidget {
  final VoidCallback onScaleDown;
  final VoidCallback onScaleUp;
  final Widget child;
  final String zoomLevelDescription; // e.g. 79%, 1x, 2x. Your choice.

  const ScalableView({Key key, this.onScaleDown, this.onScaleUp, this.child, this.zoomLevelDescription}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: [
        child,
        Column(children:[
          Expanded(child: SizedBox()),
          Row(children: [
            Expanded(child:SizedBox()),
            Container(color: Colors.black12, padding:EdgeInsets.all(3),
              child:
              IncrementableValue(child:
              Container(
                width: 48,
                height: 48,
                child:
                Align(
                  alignment: Alignment.center,
                  child: Stack(children: [
                    AnimatedOpacity(opacity: 0.5, duration: animationDuration, child: Transform.translate(
                      offset: Offset(-5, 5),
                      child: Transform.scale(scale: 1, child: Icon(Icons.zoom_out)))),
                    AnimatedOpacity(
                      opacity: 0.5,
                      duration: animationDuration,
                      child: Transform.translate(
                        offset: Offset(5, -5),
                        child: Transform.scale(scale: 1, child: Icon(Icons.zoom_in)))),AnimatedOpacity(
                      opacity: 0.8,
                      duration: animationDuration,
                      child: Transform.translate(offset:Offset(2,20),
                        child: Text(zoomLevelDescription,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      )),

                  ])),
              ),
                collapsing: true,
                incrementIcon: Icons.zoom_in,
                decrementIcon: Icons.zoom_out,
                onIncrement: onScaleUp,
                onDecrement: onScaleDown)
            )])
        ])

      ],
    );
  }
}