
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'incrementable_value.dart';
import 'my_buttons.dart';
import 'ui_models.dart';

class ScalableView extends StatelessWidget {
  final VoidCallback onScaleDown;
  final VoidCallback onScaleUp;
  final Widget child;
  final String zoomLevelDescription; // e.g. 79%, 1x, 2x. Your choice.
  final bool autoScroll;
  final VoidCallback toggleAutoScroll;
  final VoidCallback scrollToCurrent;
  final bool visible;
  final Color primaryColor;
  final bool showViewOptions;

  const ScalableView({Key key, this.onScaleDown, this.onScaleUp, this.child, this.zoomLevelDescription, this.autoScroll, this.toggleAutoScroll, this.scrollToCurrent, this.visible = true, this.primaryColor = Colors.white, this.showViewOptions = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      children: [
        child,
        Row(children:[
          Expanded(child: SizedBox()),
          if (autoScroll != null && toggleAutoScroll != null)Column(children: [
            Expanded(child: SizedBox()),
            AnimatedOpacity(
              duration: animationDuration,
              opacity: visible && showViewOptions ? 1 : 0,
              child: IgnorePointer(
                ignoring: !visible,
                child: Container(
                  color: Colors.black12,
                  height: 48,
                  width: 48,
                  child: MyFlatButton(
                    padding: EdgeInsets.zero,
                    onPressed: toggleAutoScroll,
                    child: Stack(children: [
                      Transform.translate(
                        offset: Offset(0, -6),
                        child: Text("Auto",
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 10, color: autoScroll ? primaryColor : Colors.grey))),
                      Transform.translate(
                        offset: Offset(0, 6),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: !autoScroll ? 1 : 0,
                          child: Icon(Icons.location_disabled, color: Colors.grey),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, 6),
                        child: AnimatedOpacity(
                          duration: animationDuration,
                          opacity: autoScroll ? 1 : 0,
                          child: Icon(Icons.my_location, color: primaryColor),
                        ),
                      ),
                    ]))),
              ),
            ),
            SizedBox(height: 2),
          ]),
          SizedBox(width: 2),
          Column(children: [
            Expanded(child:SizedBox()),
            Container(color: Colors.black12, padding:EdgeInsets.all(0),
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