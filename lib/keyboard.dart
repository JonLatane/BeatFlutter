import 'dart:async';
import 'dart:math';

import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:beatscratch_flutter_redux/drawing/canvas_tone_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'beatscratch_plugin.dart';
import 'colors.dart';
import 'drawing/drawing.dart';
import 'generated/protos/music.pb.dart';
import 'music_notation_theory.dart';
import 'music_theory.dart';
import 'my_buttons.dart';
import 'my_platform.dart';
import 'ui_models.dart';
import 'util.dart';

class Keyboard extends StatefulWidget {
  final double height;
  final bool showConfiguration;
  final Function() hideConfiguration;
  final Color sectionColor;
  final Part part;
  final ValueNotifier<Iterable<int>> pressedNotesNotifier;
  final double width;
  final double leftMargin;

  const Keyboard({Key key,
    this.height,
    this.showConfiguration,
    this.hideConfiguration,
    this.sectionColor,
    this.part,
    this.pressedNotesNotifier,
    this.width,
    this.leftMargin})
    : super(key: key);

  @override
  KeyboardState createState() => KeyboardState();
}

Rect _visibleRect = Rect.zero;

class KeyboardState extends State<Keyboard> with TickerProviderStateMixin {
  static const double _minHalfStepWidthInPx = 5;
  static const double maxHalfStepWidthInPx = 500;
  double get minHalfStepWidthInPx => max(_minHalfStepWidthInPx, _minHalfStepWidthBasedOnScreenSize);
  bool useOrientation = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];
  ValueNotifier<double> scrollPositionNotifier;
  bool reverseScrolling = false;
  ScrollingMode scrollingMode = ScrollingMode.sideScroll;

  List<AnimationController> _scaleAnimationControllers = [];
  AnimationController animationController() => AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _halfStepWidthInPx = 35;
  double get halfStepWidthInPx => _halfStepWidthInPx;
  set halfStepWidthInPx(double value) {
    _halfStepWidthInPx = halfStepWidthInPx;
    _scaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _scaleAnimationControllers.clear();
    AnimationController scaleAnimationController = animationController();
    _scaleAnimationControllers.add(scaleAnimationController);
    Animation animation;
    animation = Tween<double>(begin: _halfStepWidthInPx, end: value)
      .animate(scaleAnimationController)
      ..addListener(() {
        setState(() { _halfStepWidthInPx = animation.value; });
      });
    scaleAnimationController.forward();
  }

  double get diatonicStepWidthInPx => halfStepWidthInPx * 12 / 7;
  AnimationController orientationAnimationController;
  Animation orientationAnimation;
  int highestPitch = CanvasToneDrawer.TOP;
  int lowestPitch = CanvasToneDrawer.BOTTOM;

  int get keysOnScreen => highestPitch - lowestPitch + 1;

  double get touchScrollAreaHeight => (scrollingMode == ScrollingMode.sideScroll) ? 30 : 0;
  bool showScrollHint = false;
  ScrollingMode previousScrollingMode;

  @override
  void initState() {
    super.initState();
    orientationAnimationController = AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    scrollPositionNotifier = ValueNotifier(0);
    if(MyPlatform.isMobile) {
      try {
        _streamSubscriptions.add(AeyriumSensor.sensorEvents.listen((event) {
          if (scrollingMode != ScrollingMode.sideScroll) {
            print("Sensor event: $event");
            double normalizedPitch;
            switch (scrollingMode) {
              case ScrollingMode.pitch:
                var absoluteScrollPosition = event.pitch;
                if (absoluteScrollPosition < 0) {
                  absoluteScrollPosition = -absoluteScrollPosition;
                }
                normalizedPitch = max(0.0, min(1.0, (1.58 - absoluteScrollPosition * 1.2) / 1.5));
                break;
              case ScrollingMode.roll:
//              var maxRoll = -1.45; // All the way to the right
//              var minRoll = 1.45; // All the way to the left
                normalizedPitch = (1.45 - event.roll) / 2.9;
                break;
              case ScrollingMode.sideScroll:
                break;
            }

            double newScrollPositionValue = max(0.0, min(1.0, normalizedPitch));
            if (newScrollPositionValue.isFinite && !newScrollPositionValue.isNaN) {
              Animation animation;
              animation = Tween<double>(begin: scrollPositionNotifier.value, end: newScrollPositionValue)
                .animate(orientationAnimationController)
                ..addListener(() {
                  scrollPositionNotifier.value = animation.value;
//                setState(() {});
                });
              orientationAnimationController.forward(from: scrollPositionNotifier.value);
//            scrollPositionNotifier.value = newScrollPositionValue;
            }
          }
        }));
      } catch (MissingPluginException) {
        // It's fine for this to not work on desktop
        scrollingMode = ScrollingMode.sideScroll;
      }
    }
  }

  @override
  void dispose() {
    _scaleAnimationControllers.forEach((controller) { controller.dispose(); });
    _scaleAnimationControllers.clear();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Map<int, int> _pointerIdsToTones = Map();
  double _startHalfStepWidthInPx;
  double _minHalfStepWidthBasedOnScreenSize;

  @override
  Widget build(BuildContext context) {
    _minHalfStepWidthBasedOnScreenSize = widget.width / keysOnScreen;
    double halfStepsOnScreen = widget.width / halfStepWidthInPx;
    double physicalWidth = 88 * halfStepWidthInPx;
//    print("physicalWidth=$physicalWidth");
    double minNewValue = widget.width / keysOnScreen;
    if(halfStepWidthInPx < minNewValue) {
      halfStepWidthInPx = max(minNewValue, halfStepWidthInPx);
    }
    if (previousScrollingMode != ScrollingMode.sideScroll && scrollingMode == ScrollingMode.sideScroll) {
      showScrollHint = true;
      Future.delayed(Duration(seconds: 5), () {
        showScrollHint = false;
      });
    } else if (previousScrollingMode == ScrollingMode.sideScroll && scrollingMode != ScrollingMode.sideScroll) {
      showScrollHint = false;
    }
    previousScrollingMode = scrollingMode;
    return Stack(children: [
      CustomScrollView(key: Key("colorboard-$physicalWidth"), scrollDirection: Axis.horizontal, slivers: [
        CustomSliverToBoxAdapter(
          setVisibleRect: (rect) {
            _visibleRect = rect;
            _visibleRect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - touchScrollAreaHeight);
            double newScrollPositionValue = rect.left / (physicalWidth - rect.width);
            if (newScrollPositionValue.isFinite && !newScrollPositionValue.isNaN) {
              scrollPositionNotifier.value = max(0.0, min(1.0, newScrollPositionValue));
//                        print("scrolled to ${scrollPositionNotifier.value} (really $newScrollPositionValue)");
            }
          },
          child: Column(children: [

    GestureDetector(
    onScaleStart: (details) => setState(() {
      _startHalfStepWidthInPx = halfStepWidthInPx;
    }),
    onScaleUpdate: (ScaleUpdateDetails details) => setState(() {
      if (details.scale > 0) {
        halfStepWidthInPx = max(minHalfStepWidthInPx, min(maxHalfStepWidthInPx,
          _startHalfStepWidthInPx * details.scale));
      }
    }),
    child:AnimatedContainer(
                duration: animationDuration,
                height: touchScrollAreaHeight,
                width: physicalWidth,
                color: widget.sectionColor,
                child: Align(
                    alignment: Alignment.center,
                    child: Container(height: 5, width: physicalWidth, color: Colors.black54)))),
            CustomPaint(
              size: Size(physicalWidth.floor().toDouble(), widget.height - touchScrollAreaHeight),
              isComplex: true,
              willChange: true,
              painter: _KeyboardPainter(
                  highestPitch: highestPitch,
                  lowestPitch: lowestPitch,
                  pressedNotesNotifier: widget.pressedNotesNotifier,
                  scrollPositionNotifier: scrollPositionNotifier,
                  halfStepsOnScreen: halfStepsOnScreen,
                  visibleRect: () => _visibleRect),
            ),
          ]),
        )
      ]),
//      Touch-handling area with the GestureDetector
      Column(children: [
        AnimatedContainer(
          duration: animationDuration,
          height: touchScrollAreaHeight,
          child: AnimatedContainer(
            width: showScrollHint ? touchScrollAreaHeight * 3.4 : 0,
            duration: animationDuration,
            padding: EdgeInsets.symmetric(horizontal: 5),
            color: widget.sectionColor,
            child: AnimatedOpacity(
              opacity: showScrollHint ? 1 : 0,
              duration: animationDuration,
              child: MyFlatButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    showScrollHint = false;
                  });
                },
                child: Row(children: [
                  Icon(Icons.arrow_left),
                  Expanded(child: Text("Scroll", style: TextStyle(fontSize: 16))),
                  Icon(Icons.arrow_right),
                ]))))),
        Expanded(
            child: Listener(
                onPointerDown: (event) {
                  double left = scrollPositionNotifier.value * (physicalWidth - _visibleRect.width) + event.position.dx;
                  left -= widget.leftMargin;
                  double dy = MediaQuery.of(context).size.height - event.position.dy;
                  double maxDy = widget.height - touchScrollAreaHeight;
                  int tone;
                  if (dy > maxDy / 2) {
                    // Black key area press
                    tone = (left / halfStepWidthInPx).floor() + lowestPitch;
                  } else {
                    // White key area press
                    tone = diatonicTone(left);
                  }
                  try {
                    BeatScratchPlugin.playNote(tone, 127, widget.part);
                  } catch (t) {}
                  _pointerIdsToTones[event.pointer] = tone;
                  print("pressed tone $tone");
                  widget.pressedNotesNotifier.value = _pointerIdsToTones.values;
                },
                onPointerMove: (event) {
                  double left = _visibleRect.left + event.position.dx;
                  left -= widget.leftMargin;
                  double dy = MediaQuery.of(context).size.height - event.position.dy;
                  double maxDy = widget.height - touchScrollAreaHeight;
                  int oldTone = _pointerIdsToTones[event.pointer];
                  int tone;
                  if (dy > maxDy / 2) {
                    // Black key area press
                    tone = (left / halfStepWidthInPx).floor() + lowestPitch;
                  } else {
                    // White key area press
                    tone = diatonicTone(left);
                  }
                  if (tone != oldTone) {
                    print("moving tone $oldTone to $tone");
                    try {
                      BeatScratchPlugin.stopNote(oldTone, 127, widget.part);
                      _pointerIdsToTones[event.pointer] = tone;
                      widget.pressedNotesNotifier.value = _pointerIdsToTones.values.toSet();
                      BeatScratchPlugin.playNote(tone, 127, widget.part);
                    } catch (t) {
                      print(t);
                    }
                  }
                },
                onPointerUp: (event) {
                  int tone = _pointerIdsToTones.remove(event.pointer);
                  widget.pressedNotesNotifier.value = _pointerIdsToTones.values.toSet();
                  try {
                    BeatScratchPlugin.stopNote(tone, 127, widget.part);
                  } catch (t) {}
                },
                onPointerCancel: (event) {
                  int tone = _pointerIdsToTones.remove(event.pointer);
                  widget.pressedNotesNotifier.value = _pointerIdsToTones.values.toSet();
                  try {
                    BeatScratchPlugin.stopNote(tone, 127, widget.part);
                  } catch (t) {}
                },
                child: Container(color: Colors.black12)))
      ]),
//    Configuration layer
      Column(children: [
        AnimatedContainer(duration: animationDuration, height: touchScrollAreaHeight, child: SizedBox()),
        AnimatedContainer(
            duration: animationDuration,
            height: max(0,widget.height - touchScrollAreaHeight),
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
                                  child: MyRaisedButton(
                                      onPressed: false ? () {
                                        setState(() {
                                          highestPitch++;
                                        });
                                      } : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_upward))),
                              Container(
                                  width: 45,
                                  child: MyRaisedButton(
                                      onPressed: null,
                                      padding: EdgeInsets.all(0),
                                      child: Text(highestPitch.naturalOrSharpNote.uiString,
                                          style: TextStyle(color: Colors.white)))),
                              Container(
                                  width: 25,
                                  child: MyRaisedButton(
                                      onPressed: false ? () {
                                        setState(() {
                                          highestPitch--;
                                        });
                                      } : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_downward))),
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
                                  child: MyRaisedButton(
                                      onPressed: false ? () {
                                        setState(() {
                                          lowestPitch++;
                                        });
                                      } : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_upward))),
                              Container(
                                  width: 45,
                                  child: MyRaisedButton(
                                      onPressed: null,
                                      padding: EdgeInsets.all(0),
                                      child: Text(lowestPitch.naturalOrSharpNote.uiString,
                                          style: TextStyle(color: Colors.white)))),
                              Container(
                                  width: 25,
                                  child: MyRaisedButton(
                                      onPressed: false ? () {
                                        setState(() {
                                          lowestPitch--;
                                        });
                                      } : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_downward))),
                              Expanded(
                                child: SizedBox(),
                              ),
                            ],
                          ),
                          Expanded(child: SizedBox()),
                        ])),
                    Expanded(
                        flex: context.isTabletOrLandscapey ? 3 : 2,
                        child: MyRaisedButton(
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
                        child: MyRaisedButton(
                            padding: EdgeInsets.all(0),
                            onPressed: (MyPlatform.isAndroid || MyPlatform.isIOS || kDebugMode)
                                ? () {
                                    setState(() {
                                      switch (scrollingMode) {
                                        case ScrollingMode.sideScroll:
                                          scrollingMode = ScrollingMode.roll;
                                          break;
                                        case ScrollingMode.pitch:
                                          scrollingMode = ScrollingMode.roll;
                                          break;
                                        case ScrollingMode.roll:
//                                  scrollingMode = ScrollingMode.pitch;
                                          break;
                                      }
                                    });
                                  }
                                : null,
                            color: (scrollingMode == ScrollingMode.sideScroll) ? null : widget.sectionColor,
                            child: Row(children: [
                              Expanded(child: SizedBox()),
//                            Text("+"),
                              Text((scrollingMode == ScrollingMode.pitch)
                                  ? "Tilt"
                                  : (scrollingMode == ScrollingMode.roll)
                                      ? "Roll"
                                      : (scrollingMode == ScrollingMode.sideScroll) ? "Roll" : "Wat"),
                              Expanded(child: SizedBox()),
                            ]))),
                    Expanded(
                        flex: context.isTabletOrLandscapey ? 3 : 1,
                        child: Column(children: [
                          Expanded(child: SizedBox()),
                          Container(
                              width: 36,
                              child: MyRaisedButton(
                                  padding: EdgeInsets.all(0),
                                  onPressed: (halfStepWidthInPx < maxHalfStepWidthInPx)
                                      ? () {
                                          setState(() {
                                            halfStepWidthInPx *= 1.62;
                                          });
                                        }
                                      : null,
                                  child: Icon(Icons.zoom_in))),
                          Container(
                              width: 36,
                              child: MyRaisedButton(
                                  padding: EdgeInsets.all(0),
                                  onPressed: (halfStepWidthInPx > minHalfStepWidthInPx)
                                      ? () {
                                          setState(() {
                                            double minNewValue = widget.width / keysOnScreen;
                                            double newValue = halfStepWidthInPx / 1.62;
                                            newValue = max(minNewValue, newValue);
                                            halfStepWidthInPx  = newValue;
                                          });
                                        }
                                      : null,
                                  child: Icon(Icons.zoom_out))),
                          Expanded(child: SizedBox()),
                        ])),
                  ])
                : SizedBox())
      ]),
    ]);
  }

  static final Map<ArgumentList, int> diatonicToneCache = Map();
  int diatonicTone(double left) {
    final key = ArgumentList([left, lowestPitch, halfStepWidthInPx]);
    return diatonicToneCache.putIfAbsent(key, () => _diatonicTone(left));
  }
  int _diatonicTone(double left) {
    left += (lowestPitch - CanvasToneDrawer.BOTTOM) * halfStepWidthInPx;
    int diatonicTone = ((left + 0.245 * diatonicStepWidthInPx) / diatonicStepWidthInPx).floor() - 23;
    int octave = (diatonicTone + 28) ~/ 7;
    int toneOffset;
    switch (diatonicTone.mod7) {
      case 0:
        toneOffset = 0;
        break;
      case 1:
        toneOffset = 2;
        break;
      case 2:
        toneOffset = 4;
        break;
      case 3:
        toneOffset = 5;
        break;
      case 4:
        toneOffset = 7;
        break;
      case 5:
        toneOffset = 9;
        break;
      case 6:
        toneOffset = 11;
        break;
    }
    int tone = 12 * (octave - 4) + toneOffset;
//    print("diatonic tone: $diatonicTone octave: $octave toneoffset: $toneOffset tone: $tone");
    return tone;
  }
}

class _KeyboardPainter extends CustomPainter {
  final ValueNotifier<double> scrollPositionNotifier;
  final ValueNotifier<Iterable<int>> pressedNotesNotifier;
  final double halfStepsOnScreen;
  final Rect Function() visibleRect;
  final int highestPitch, lowestPitch;

  _KeyboardPainter(
      {this.highestPitch,
      this.lowestPitch,
      this.pressedNotesNotifier,
      this.scrollPositionNotifier,
      this.halfStepsOnScreen,
      this.visibleRect})
      : super(repaint: Listenable.merge([scrollPositionNotifier, pressedNotesNotifier, BeatScratchPlugin.pressedMidiControllerNotes]));

  @override
  void paint(Canvas canvas, Size size) {
    var bounds = Offset.zero & size;
//    canvas.drawRect(visibleRect(), Paint());
//    canvas.drawRect(bounds, Paint());
//    canvas.clipRect(bounds);
    KeyboardRenderer()
      ..highestPitch = highestPitch
      ..lowestPitch = lowestPitch
      ..pressedNotes = pressedNotesNotifier.value.followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value)
      ..renderVertically = false
      ..alphaDrawerPaint = Paint()
      ..halfStepsOnScreen = halfStepsOnScreen
      ..bounds = visibleRect()
      ..normalizedDevicePitch = scrollPositionNotifier.value
      ..draw(canvas);
  }

//  @override
//  SemanticsBuilderCallback get semanticsBuilder {
//    return (Size size) {
//      // Annotate a rectangle containing the picture of the sun
//      // with the label "Sun". When text to speech feature is enabled on the
//      // device, a user will be able to locate the sun on this picture by
//      // touch.
//      var rect = Offset.zero & size;
//      var width = size.shortestSide * 0.4;
//      rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
//      return [
//        CustomPainterSemantics(
//          rect: rect,
//          properties: SemanticsProperties(
//            label: 'Sun',
//            textDirection: TextDirection.ltr,
//          ),
//        ),
//      ];
//    };
//  }

// Since this Sky painter has no fields, it always paints
// the same thing and semantics information is the same.
// Therefore we return false here. If we had fields (set
// from the constructor) then we would return true if any
// of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(_KeyboardPainter oldDelegate) => true;

//  @override
//  bool shouldRebuildSemantics(_ColorboardPainter oldDelegate) => false;
}

class KeyboardRenderer extends CanvasToneDrawer {
  Iterable<int> pressedNotes;
  bool renderLettersAndNumbers = true;

  draw(Canvas canvas) {
    canvas.drawColor(Colors.black12, BlendMode.srcATop);
    int alpha = alphaDrawerPaint.color.alpha;
//    print("keyboard alpha=$alpha");
    alphaDrawerPaint.preserveProperties(() {
      var halfStepPhysicalDistance = axisLength / halfStepsOnScreen;
      // Draw white keys
      visibleDiatonicPitches.forEach((visiblePitch) {
        var tone = visiblePitch.tone;
        if (tone.mod12 != 0 &&
            tone.mod12 != 2 &&
            tone.mod12 != 4 &&
            tone.mod12 != 5 &&
            tone.mod12 != 7 &&
            tone.mod12 != 9 &&
            tone.mod12 != 11) return;
        var toneBounds = visiblePitch.bounds;

        if (pressedNotes.contains(tone)) {
          alphaDrawerPaint.color = chromaticSteps[(tone - chord.rootNote.tone).mod12];
          canvas.drawRect(toneBounds, alphaDrawerPaint);
        }
        canvas.drawRect(
            toneBounds,
            Paint()
              ..color = Colors.black.withAlpha(alpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
//        print("drawing white key ${visiblePitch.tone}: ${visiblePitch.tone.naturalOrSharpNote}");
//        NoteSpecification ns = visiblePitch.tone.naturalOrSharpNote;
        if(renderLettersAndNumbers) {
          String text = NoteLetter.values
            .firstWhere((letter) => letter.tone.mod12 == visiblePitch.tone.mod12)
            .name;
          TextSpan span = new TextSpan(
            text: text, style: TextStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w500, color: Colors.grey));
          TextPainter tp = new TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4.5, toneBounds.bottom - 48));
        }
      });

      // Draw black keys
      visiblePitches.forEach((visiblePitch) {
        var tone = visiblePitch.tone;
        var toneBounds = visiblePitch.bounds;
        switch (tone.mod12) {
          case 1:
          case 3:
          case 6:
          case 8:
          case 10:
            alphaDrawerPaint.color = Color(0xFF000000).withAlpha(alpha);

            if (pressedNotes.contains(tone)) {
              alphaDrawerPaint.color = chromaticSteps[(tone - chord.rootNote.tone).mod12];
            }
            canvas.drawRect(
                Rect.fromLTRB(toneBounds.left, toneBounds.top, toneBounds.right,
                    toneBounds.top + (toneBounds.top + toneBounds.bottom) / 2),
                alphaDrawerPaint);
            break;
        }
        if (renderLettersAndNumbers && tone.mod12 == 0) {
//            alphaDrawerPaint.color = Colors.black;
          TextSpan span = new TextSpan(text: (4 + (tone / 12)).toInt().toString(),
            style: TextStyle(fontFamily: "VulfSans", fontWeight: FontWeight.w100, color: Colors.grey));
          TextPainter tp = new TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(canvas, new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4, toneBounds.bottom - 30));
        }
      });
    });

    //TODO draw lower keys
  }
}
