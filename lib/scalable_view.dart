
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'incrementable_value.dart';
import 'ui_models.dart';

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
        Row(children:[
          Expanded(child: SizedBox()),
          Column(children: [
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
            ),
            SizedBox(height: 2),
          ]),
          SizedBox(width: 2),
        ])

      ],
    );
  }
}