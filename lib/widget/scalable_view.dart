
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'incrementable_value.dart';
import 'my_buttons.dart';
import '../ui_models.dart';

class ScalableView extends StatefulWidget {
  final VoidCallback onMicroScaleDown;
  final VoidCallback onMicroScaleUp;
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

  const ScalableView({Key key, this.onScaleDown, this.onScaleUp, this.child, this.zoomLevelDescription, this.autoScroll, this.toggleAutoScroll, this.scrollToCurrent, this.visible = true, this.primaryColor = Colors.white, this.showViewOptions = true, this.onMicroScaleDown, this.onMicroScaleUp}) : super(key: key);

  @override
  _ScalableViewState createState() => _ScalableViewState();
}

class _ScalableViewState extends State<ScalableView> {
  double lastUpdatedScale;
  int directionUpOrDown;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Stack(
        children: [
          widget.child,
          Row(children:[
            Expanded(child: SizedBox()),
            if (widget.autoScroll != null && widget.toggleAutoScroll != null)Column(children: [
              Expanded(child: SizedBox()),
              AnimatedOpacity(
                duration: animationDuration,
                opacity: widget.visible && widget.showViewOptions ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !widget.visible,
                  child: Container(
                    color: Colors.black12,
                    height: 48,
                    width: 48,
                    child: MyFlatButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.toggleAutoScroll,
                      child: Stack(children: [
                        Transform.translate(
                          offset: Offset(0, -6),
                          child: Text("Auto",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontSize: 10, color: widget.autoScroll ? widget.primaryColor : Colors.grey))),
                        Transform.translate(
                          offset: Offset(0, 6),
                          child: AnimatedOpacity(
                            duration: animationDuration,
                            opacity: !widget.autoScroll ? 1 : 0,
                            child: Icon(Icons.location_disabled, color: Colors.grey),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, 6),
                          child: AnimatedOpacity(
                            duration: animationDuration,
                            opacity: widget.autoScroll ? 1 : 0,
                            child: Icon(Icons.my_location, color: widget.primaryColor),
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
                          child: Text(widget.zoomLevelDescription,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        )),

                    ])),
                ),
                  collapsing: true,
                  incrementIcon: Icons.zoom_in,
                  decrementIcon: Icons.zoom_out,
                  onIncrement: widget.onScaleUp,
                  onDecrement: widget.onScaleDown)
              ),
              SizedBox(height: 2),
            ]),
            SizedBox(width: 2),
          ])

        ],
      ),
      onScaleStart: (details) {
        lastUpdatedScale = 1;
      },
      onScaleUpdate: (details) {
        final scale = details.scale;
        // print("scale: $scale");
        if (widget.onMicroScaleUp != null && scale - lastUpdatedScale >= .01) {
          widget.onMicroScaleUp();
        } else if (widget.onMicroScaleDown != null && scale - lastUpdatedScale <= -.01) {
          widget.onMicroScaleDown();
        } else if (widget.onScaleUp != null && scale - lastUpdatedScale >= .09) {
          widget.onScaleUp();
        } else if (widget.onScaleDown != null && scale - lastUpdatedScale <= -.09) {
          widget.onScaleDown();
        }
      },
      onScaleEnd: (details) {
        lastUpdatedScale = null;
      },
    );
  }
}