import '../drawing/canvas_tone_drawer.dart';
import '../drawing/color_guide.dart';
import 'package:flutter/material.dart';
import '../beatscratch_plugin.dart';
import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'dart:async';
import 'dart:math';
import '../generated/protos/music.pb.dart';
import 'my_buttons.dart';
import 'my_platform.dart';
import '../ui_models.dart';
import '../util/util.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import 'incrementable_value.dart';

class Colorboard extends StatefulWidget {
  final Chord chord = (Chord()
    ..rootNote = (NoteName()..noteLetter = NoteLetter.C)
    ..chroma = 146);
  final double height;
  final bool showConfiguration;
  final Function() hideConfiguration;
  final Color sectionColor;
  final Part part;
  final ValueNotifier<Iterable<int>> pressedNotesNotifier;
  final double distanceFromBottom;
  final double width;
  final double leftMargin;

  Colorboard({
    Key key,
    this.height,
    this.showConfiguration,
    this.hideConfiguration,
    this.sectionColor,
    this.part,
    this.pressedNotesNotifier,
    this.distanceFromBottom,
    this.width,
    this.leftMargin,
  }) : super(key: key);

  @override
  _ColorboardState createState() => _ColorboardState();
}

Rect _visibleRect = Rect.zero;

class _ColorboardState extends State<Colorboard> with TickerProviderStateMixin {
  bool useOrientation = true;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  ValueNotifier<double> scrollPositionNotifier;
  ValueNotifier<Chord> chordNotifier;
  bool reverseScrolling = false;
  ScrollingMode scrollingMode = ScrollingMode.sideScroll;

  List<AnimationController> _scaleAnimationControllers = [];

  AnimationController animationController() =>
      AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _halfStepWidthInPx = 20;

  double get halfStepWidthInPx => _halfStepWidthInPx;

  set halfStepWidthInPx(double value) {
    _halfStepWidthInPx = halfStepWidthInPx;
    _scaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _scaleAnimationControllers.clear();
    AnimationController scaleAnimationController = animationController();
    _scaleAnimationControllers.add(scaleAnimationController);
    Animation animation;
    animation = Tween<double>(begin: _halfStepWidthInPx, end: value)
        .animate(scaleAnimationController)
          ..addListener(() {
            setState(() {
              _halfStepWidthInPx = animation.value;
            });
          });
    scaleAnimationController.forward();
  }

  AnimationController orientationAnimationController;
  Animation orientationAnimation;
  int highestPitch = CanvasToneDrawer.TOP;
  int lowestPitch = CanvasToneDrawer.BOTTOM;
  bool showScrollHint = true;

  double get touchScrollAreaHeight =>
      (scrollingMode == ScrollingMode.sideScroll) ? 30 : 0;

  int get keysOnScreen => highestPitch - lowestPitch + 1;

  @override
  void initState() {
    super.initState();
    orientationAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    scrollPositionNotifier = ValueNotifier(0);
    chordNotifier = ValueNotifier(widget.chord);
    if (MyPlatform.isMobile) {
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
                normalizedPitch = max(
                    0.0, min(1.0, (1.58 - absoluteScrollPosition * 1.2) / 1.5));
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
            if (newScrollPositionValue.isFinite &&
                !newScrollPositionValue.isNaN) {
              Animation animation;
              animation = Tween<double>(
                      begin: scrollPositionNotifier.value,
                      end: newScrollPositionValue)
                  .animate(orientationAnimationController)
                    ..addListener(() {
                      scrollPositionNotifier.value = animation.value;
//                setState(() {});
                    });
              orientationAnimationController.forward(
                  from: scrollPositionNotifier.value);
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
    _scaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _scaleAnimationControllers.clear();
    scrollPositionNotifier.dispose();
    chordNotifier.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Map<int, int> _pointerIdsToTones = Map();

  @override
  Widget build(BuildContext context) {
    double halfStepsOnScreen = widget.width / halfStepWidthInPx;
    double physicalWidth = keysOnScreen * halfStepWidthInPx;
    chordNotifier.value = widget.chord;

    double minNewValue = widget.width / keysOnScreen;
    if (halfStepWidthInPx < minNewValue) {
      halfStepWidthInPx = max(minNewValue, halfStepWidthInPx);
    }
//    print("physicalWidth=$physicalWidth");
    return Stack(children: [
      CustomScrollView(
          key: Key("colorboard-$physicalWidth"),
          scrollDirection: Axis.horizontal,
          slivers: [
            CustomSliverToBoxAdapter(
              setVisibleRect: (rect) {
                _visibleRect = rect;
                _visibleRect = Rect.fromLTRB(rect.left, rect.top, rect.right,
                    rect.bottom - touchScrollAreaHeight);
                double newScrollPositionValue =
                    rect.left / (physicalWidth - rect.width);
                if (newScrollPositionValue.isFinite &&
                    !newScrollPositionValue.isNaN) {
                  scrollPositionNotifier.value =
                      max(0.0, min(1.0, newScrollPositionValue));
//                        print("scrolled to ${scrollPositionNotifier.value} (really $newScrollPositionValue)");
                }
              },
              child: Column(children: [
                AnimatedContainer(
                    duration: animationDuration,
                    height: touchScrollAreaHeight,
                    width: physicalWidth,
                    color: widget.sectionColor,
                    child: Align(
                        alignment: Alignment.center,
                        child: AnimatedContainer(
                            duration: animationDuration,
                            height: min(5, touchScrollAreaHeight),
                            width: physicalWidth,
                            color: Colors.black54))),
                CustomPaint(
                  size: Size(physicalWidth.floor().toDouble(),
                      widget.height - touchScrollAreaHeight),
                  isComplex: true,
                  willChange: true,
                  painter: _ColorboardPainter(
                      chordNotifier: chordNotifier,
                      pressedNotesNotifier: widget.pressedNotesNotifier,
                      scrollPositionNotifier: scrollPositionNotifier,
                      highestPitch: highestPitch,
                      lowestPitch: lowestPitch,
                      halfStepsOnScreen: halfStepsOnScreen,
                      visibleRect: () => _visibleRect),
                ),
              ]),
            )
          ]),
//      Touch-handling area with the GestureDetector
      Column(children: [
        AnimatedContainer(
            // Touch hint area
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
                          Expanded(
                              child: Text("Scroll",
                                  style: TextStyle(fontSize: 16))),
                          Icon(Icons.arrow_right),
                        ]))))),
        Expanded(
            child: Listener(
                onPointerDown: (event) {
                  double left = _visibleRect.left + event.position.dx;
                  left -= widget.leftMargin;
//              double left = scrollPositionNotifier.value * (physicalWidth - _visibleRect.width) + event.position.dx;
                  int tone = (left / halfStepWidthInPx).floor() + lowestPitch;
                  tone = widget.chord.closestTone(tone);
                  double dy = MediaQuery.of(context).size.height -
                      event.position.dy -
                      widget.distanceFromBottom;
                  double maxDy = widget.height - touchScrollAreaHeight;
                  double velocityRatio = min(dy, maxDy) / maxDy;
//              print("dy=$dy; maxDy=$maxDy; velocity ratio=$velocityRatio");
                  int velocity =
                      min(127, max(0, (velocityRatio * 127).toInt()));
                  _pointerIdsToTones[event.pointer] = tone;
//              print("pressed tone $tone");
                  try {
                    BeatScratchPlugin.playNote(tone, velocity, widget.part);
                  } catch (t) {}
                  widget.pressedNotesNotifier.value = _pointerIdsToTones.values;
                },
                onPointerMove: (event) {
                  double left = _visibleRect.left + event.position.dx;
                  left -= widget.leftMargin;
                  int tone = (left / halfStepWidthInPx).floor() + lowestPitch;
                  tone = widget.chord.closestTone(tone);
                  double dy = MediaQuery.of(context).size.height -
                      event.position.dy -
                      widget.distanceFromBottom;
                  double maxDy = widget.height - touchScrollAreaHeight;
                  double velocityRatio = min(dy, maxDy) / maxDy;
//              print("dy=$dy; maxDy=$maxDy; velocity ratio=$velocityRatio");
                  int velocity =
                      min(127, max(0, (velocityRatio * 127).toInt()));
                  int oldTone = _pointerIdsToTones[event.pointer];
                  if (tone != oldTone) {
                    print("moving tone $oldTone to $tone");
                    try {
                      BeatScratchPlugin.stopNote(oldTone, 127, widget.part);
                      _pointerIdsToTones[event.pointer] = tone;
                      widget.pressedNotesNotifier.value =
                          _pointerIdsToTones.values.toSet();
                      BeatScratchPlugin.playNote(tone, velocity, widget.part);
                    } catch (t) {
                      print(t);
                    }
                  }
                },
                onPointerUp: (event) {
                  int tone = _pointerIdsToTones.remove(event.pointer);
                  widget.pressedNotesNotifier.value =
                      _pointerIdsToTones.values.toSet();
                  try {
                    BeatScratchPlugin.stopNote(tone, 127, widget.part);
                  } catch (t) {}
                },
                onPointerCancel: (event) {
                  int tone = _pointerIdsToTones.remove(event.pointer);
                  widget.pressedNotesNotifier.value =
                      _pointerIdsToTones.values.toSet();
                  try {
                    BeatScratchPlugin.stopNote(tone, 127, widget.part);
                  } catch (t) {}
                },
                child: Container(color: Colors.black12)))
      ]),
//    Configuration layer
      Column(children: [
        AnimatedContainer(
            duration: animationDuration,
            height: touchScrollAreaHeight,
            child: SizedBox()),
        AnimatedContainer(
            duration: animationDuration,
            height: max(0, widget.height - touchScrollAreaHeight),
            color:
                widget.showConfiguration ? Colors.black26 : Colors.transparent,
            child: widget.showConfiguration
                ? Row(children: [
                    Expanded(
                        flex: 3,
                        child: Row(children: [
                          Expanded(child: SizedBox()),
                          Column(children: [
                            Expanded(child: SizedBox()),
                            IncrementableValue(
                              onIncrement: highestPitch <= 67
                                  ? () {
                                      setState(() {
                                        highestPitch++;
                                      });
                                    }
                                  : null,
                              onDecrement: highestPitch > lowestPitch + 1
                                  ? () {
                                      setState(() {
                                        highestPitch--;
                                      });
                                    }
                                  : null,
                              value: highestPitch.naturalOrSharpNote.uiString,
                            ),
                            IncrementableValue(
                              onIncrement: highestPitch > lowestPitch + 1
                                  ? () {
                                      setState(() {
                                        lowestPitch++;
                                      });
                                    }
                                  : null,
                              onDecrement: lowestPitch >= -60
                                  ? () {
                                      setState(() {
                                        lowestPitch--;
                                      });
                                    }
                                  : null,
                              value: lowestPitch.naturalOrSharpNote.uiString,
                            ),
                            Expanded(child: SizedBox()),
                          ]),
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
                            color: (scrollingMode == ScrollingMode.sideScroll)
                                ? widget.sectionColor
                                : null,
                            child: Text("Scroll"))),
                    Expanded(
                        flex: context.isTabletOrLandscapey ? 3 : 2,
                        child: MyRaisedButton(
                            padding: EdgeInsets.all(0),
                            onPressed:
                                false // (MyPlatform.isMobile || MyPlatform.isDebug)
                                    ?
                                    //ignore: dead_code
                                    () {
                                        setState(() {
                                          switch (scrollingMode) {
                                            case ScrollingMode.sideScroll:
                                              scrollingMode =
                                                  ScrollingMode.roll;
                                              break;
                                            case ScrollingMode.pitch:
                                              scrollingMode =
                                                  ScrollingMode.roll;
                                              break;
                                            case ScrollingMode.roll:
//                                  scrollingMode = ScrollingMode.pitch;
                                              break;
                                          }
                                        });
                                      }
                                    : null,
                            color: (scrollingMode == ScrollingMode.sideScroll)
                                ? null
                                : widget.sectionColor,
                            child: Row(children: [
                              Expanded(child: SizedBox()),
//                            Text("+"),
                              Text((scrollingMode == ScrollingMode.pitch)
                                  ? "Tilt"
                                  : (scrollingMode == ScrollingMode.roll)
                                      ? "Roll"
                                      : (scrollingMode ==
                                              ScrollingMode.sideScroll)
                                          ? "Roll"
                                          : "Wat"),
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
                                  onPressed: (halfStepWidthInPx < 500)
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
                                  onPressed: (halfStepWidthInPx > 10)
                                      ? () {
                                          setState(() {
                                            double minNewValue =
                                                widget.width / keysOnScreen;
                                            double newValue =
                                                halfStepWidthInPx / 1.62;
                                            newValue =
                                                max(minNewValue, newValue);
                                            halfStepWidthInPx = newValue;
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
}

class _ColorboardPainter extends CustomPainter {
  final ValueNotifier<double> scrollPositionNotifier;
  final ValueNotifier<Iterable<int>> pressedNotesNotifier;
  final int lowestPitch;
  final int highestPitch;
  final double halfStepsOnScreen;
  final Rect Function() visibleRect;
  final ValueNotifier<Chord> chordNotifier;

  _ColorboardPainter(
      {this.chordNotifier,
      this.lowestPitch,
      this.highestPitch,
      this.pressedNotesNotifier,
      this.scrollPositionNotifier,
      this.halfStepsOnScreen,
      this.visibleRect})
      : super(
            repaint: Listenable.merge(
                [scrollPositionNotifier, pressedNotesNotifier, chordNotifier]));

  @override
  void paint(Canvas canvas, Size size) {
//    canvas.drawRect(visibleRect(), Paint());
//    canvas.drawRect(bounds, Paint());
//    canvas.clipRect(bounds);
    final ColorGuide colorGuide = ColorGuide()
      ..chord = chordNotifier.value
      ..renderVertically = false
      ..alphaDrawerPaint = Paint()
      ..halfStepsOnScreen = halfStepsOnScreen
      ..bounds = visibleRect()
      ..lowestPitch = lowestPitch
      ..highestPitch = highestPitch
      ..drawnColorGuideAlpha = 255
      ..drawPadding = 0
      ..nonRootPadding = 10
      ..pressedNotes = pressedNotesNotifier.value
      ..normalizedDevicePitch = scrollPositionNotifier.value;
    colorGuide.drawColorGuide(canvas);
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
  bool shouldRepaint(_ColorboardPainter oldDelegate) => true;

//  @override
//  bool shouldRebuildSemantics(_ColorboardPainter oldDelegate) => false;
}
