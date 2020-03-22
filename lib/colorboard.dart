import 'package:beatscratch_flutter_redux/drawing/color_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'drawing/drawing.dart';
import 'package:sensors/sensors.dart';
import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'dart:async';
import 'dart:math';
import 'ui_models.dart';
import 'util.dart';

class Colorboard extends StatefulWidget {
  final double height;
  final bool showConfiguration;
  final Function() hideConfiguration;
  final Color sectionColor;

  const Colorboard({Key key, this.height, this.showConfiguration, this.hideConfiguration, this.sectionColor})
      : super(key: key);

  @override
  _ColorboardState createState() => _ColorboardState();
}

Rect _visibleRect = Rect.zero;

class _ColorboardState extends State<Colorboard> with SingleTickerProviderStateMixin {
  bool useOrientation = true;
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  ValueNotifier<double> scrollPositionNotifier;
  bool reverseScrolling = false;
  ScrollingMode scrollingMode = ScrollingMode.sideScroll;
  double halfStepWidthInPx = 100;

  @override
  void initState() {
    super.initState();
    scrollPositionNotifier = ValueNotifier(0);
    try {
      _streamSubscriptions.add(AeyriumSensor.sensorEvents.listen((event) {
        if (scrollingMode != ScrollingMode.sideScroll) {
//        print("Sensor event: $event");
          double normalizedPitch;
          var absoluteScrollPosition;
          switch (scrollingMode) {
            case ScrollingMode.pitch:
              absoluteScrollPosition = event.pitch;
              if (absoluteScrollPosition < 0) {
                absoluteScrollPosition = -absoluteScrollPosition;
              }
              normalizedPitch = max(0.0, min(1.0, (1.58 - absoluteScrollPosition * 1.2) / 1.5));
              break;
            case ScrollingMode.roll:
              absoluteScrollPosition = event.roll;
              break;
            case ScrollingMode.sideScroll:
              break;
          }

          double newScrollPositionValue = max(0.0, min(1.0, normalizedPitch.toDouble()));
          if (newScrollPositionValue.isFinite && !newScrollPositionValue.isNaN) {
            scrollPositionNotifier.value = newScrollPositionValue;
          }
        }
      }));
    } catch (MissingPluginException) {
      // It's fine for this to not work on desktop
      scrollingMode = ScrollingMode.sideScroll;
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  double get touchScrollAreaHeight => (scrollingMode == ScrollingMode.sideScroll) ? 20 : 0;

  @override
  Widget build(BuildContext context) {
    double halfStepsOnScreen = MediaQuery.of(context).size.width / halfStepWidthInPx;
    double physicalWidth = 88 * halfStepWidthInPx;
    return Stack(children: [
              CustomScrollView(
                scrollDirection: Axis.horizontal,
                slivers: [
                  CustomSliverToBoxAdapter(
                    setVisibleRect: (rect) {
                      _visibleRect = rect;
                      _visibleRect =
                          Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - touchScrollAreaHeight);
                      double newScrollPositionValue = rect.left / (physicalWidth - rect.width);
                      if (newScrollPositionValue.isFinite && !newScrollPositionValue.isNaN) {
                        scrollPositionNotifier.value = max(0.0, min(1.0, newScrollPositionValue));
                      }
                    },
                    child:
                    Column(children: [
                      AnimatedContainer(duration: animationDuration,
                        height: touchScrollAreaHeight, width: physicalWidth,
                        color:widget.sectionColor, child: SizedBox()),
                      CustomPaint(
                        size: Size(physicalWidth, 150),
                        painter: _ColorboardPainter(
                            scrollPositionNotifier: scrollPositionNotifier,
                            halfStepsOnScreen: halfStepsOnScreen,
                            visibleRect: () => _visibleRect),
                      ),
                    ]),
                  )
                ]
              ),
//      Expanded(child:Column(children: [
//        AnimatedContainer(duration: animationDuration,
//          height: touchScrollAreaHeight, child: SizedBox()),
//        Expanded(child:Container(color: Colors.black12, child:GestureDetector()))
//      ])),
      AnimatedContainer(
          duration: animationDuration,
          height: widget.height,
          color: widget.showConfiguration ? Colors.black26 : Colors.transparent,
          child: widget.showConfiguration
              ? Row(children: [
                  Expanded(
                      flex: 3,
                      child: Column(children: [
                        Expanded(child: SizedBox()),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(),
                            ),
                            Container(
                                width: 25,
                                child: RaisedButton(
                                    onPressed: () {}, padding: EdgeInsets.all(0), child: Icon(Icons.arrow_upward))),
                            Container(
                                width: 45,
                                child: RaisedButton(onPressed: () {}, padding: EdgeInsets.all(0), child: Text("C8"))),
                            Container(
                                width: 25,
                                child: RaisedButton(
                                    onPressed: () {}, padding: EdgeInsets.all(0), child: Icon(Icons.arrow_downward))),
                            Expanded(
                              child: SizedBox(),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(),
                            ),
                            Container(
                                width: 25,
                                child: RaisedButton(
                                    onPressed: () {}, padding: EdgeInsets.all(0), child: Icon(Icons.arrow_upward))),
                            Container(
                                width: 45,
                                child: RaisedButton(onPressed: () {}, padding: EdgeInsets.all(0), child: Text("A#-1"))),
                            Container(
                                width: 25,
                                child: RaisedButton(
                                    onPressed: () {}, padding: EdgeInsets.all(0), child: Icon(Icons.arrow_downward))),
                            Expanded(
                              child: SizedBox(),
                            ),
                          ],
                        ),
                        Expanded(child: SizedBox()),
                      ])),
                  Expanded(
                      flex: context.isTabletOrLandscapey ? 3 : 2,
                      child: RaisedButton(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            setState(() {
                              scrollingMode = ScrollingMode.sideScroll;
                            });
                          },
                          color: (scrollingMode == ScrollingMode.sideScroll) ? widget.sectionColor : null,
                          child: Text("Scroll"))),
                  Expanded(
                      flex: context.isTabletOrLandscapey ? 3 : 2,
                      child: RaisedButton(
                          padding: EdgeInsets.all(0),
                          onPressed: () {
                            setState(() {
                              scrollingMode = ScrollingMode.pitch;
                            });
                          },
                          color: (scrollingMode == ScrollingMode.pitch) ? widget.sectionColor : null,
                          child: Row(children: [
                            Expanded(child: SizedBox()),
                            Text("+"),
                            Text("Pitch"),
                            Expanded(child: SizedBox()),
                          ]))),
                  Expanded(
                      flex: context.isTabletOrLandscapey ? 3 : 1,
                      child: Column(children: [
                        Expanded(child: SizedBox()),
                        Container(
                            width: 36,
                            child: RaisedButton(
                                padding: EdgeInsets.all(0),
                                onPressed: (halfStepWidthInPx < 500)
                                    ? () {
                                        setState(() {
                                          halfStepWidthInPx *= 1.1;
                                        });
                                      }
                                    : null,
                                child: Icon(Icons.zoom_in))),
                        Container(
                            width: 36,
                            child: RaisedButton(
                                padding: EdgeInsets.all(0),
                                onPressed: (halfStepWidthInPx > 10)
                                    ? () {
                                        setState(() {
                                          halfStepWidthInPx /= 1.1;
                                        });
                                      }
                                    : null,
                                child: Icon(Icons.zoom_out))),
                        Expanded(child: SizedBox()),
                      ])),
                ])
              : SizedBox()),
    ]);
  }
}

class _ColorboardPainter extends CustomPainter {
  final ValueNotifier<double> scrollPositionNotifier;
  final double halfStepsOnScreen;
  final Rect Function() visibleRect;

  _ColorboardPainter({this.scrollPositionNotifier, this.halfStepsOnScreen, this.visibleRect})
      : super(repaint: scrollPositionNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    var bounds = Offset.zero & size;
//    canvas.drawRect(visibleRect(), Paint());
//    canvas.drawRect(bounds, Paint());
//    canvas.clipRect(bounds);
    final ColorGuide colorGuide = ColorGuide()
      ..renderVertically = false
      ..alphaDrawerPaint = Paint()
      ..halfStepsOnScreen = halfStepsOnScreen
      ..bounds = visibleRect()
      ..drawnColorGuideAlpha = 255
      ..drawPadding = 0
      ..nonRootPadding = 10
      ..normalizedDevicePitch = scrollPositionNotifier.value;
    colorGuide.drawColorGuide(canvas);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      // Annotate a rectangle containing the picture of the sun
      // with the label "Sun". When text to speech feature is enabled on the
      // device, a user will be able to locate the sun on this picture by
      // touch.
      var rect = Offset.zero & size;
      var width = size.shortestSide * 0.4;
      rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
      return [
        CustomPainterSemantics(
          rect: rect,
          properties: SemanticsProperties(
            label: 'Sun',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

// Since this Sky painter has no fields, it always paints
// the same thing and semantics information is the same.
// Therefore we return false here. If we had fields (set
// from the constructor) then we would return true if any
// of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(_ColorboardPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(_ColorboardPainter oldDelegate) => false;
}
