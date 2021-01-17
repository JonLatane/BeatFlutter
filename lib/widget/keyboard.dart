import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:aeyrium_sensor/aeyrium_sensor.dart';
import 'package:beatscratch_flutter_redux/drawing/canvas_tone_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../drawing/drawing.dart';
import '../generated/protos/music.pb.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import 'incrementable_value.dart';
import 'my_buttons.dart';
import 'my_platform.dart';
import '../ui_models.dart';
import '../util/util.dart';

class Keyboard extends StatefulWidget {
  final double height;
  final bool showConfiguration;
  final Function() hideConfiguration;
  final Color sectionColor;
  final Part part;
  final ValueNotifier<Iterable<int>> pressedNotesNotifier;
  final double width;
  final double leftMargin;
  final double distanceFromBottom;
  final VoidCallback closeKeyboard;

  const Keyboard(
      {Key key,
      this.height,
      this.showConfiguration,
      this.hideConfiguration,
      this.sectionColor,
      this.part,
      this.pressedNotesNotifier,
      this.width,
      this.leftMargin,
      this.distanceFromBottom,
      this.closeKeyboard})
      : super(key: key);

  @override
  KeyboardState createState() => KeyboardState();
}

Rect _visibleRect = Rect.zero;

class KeyboardState extends State<Keyboard> with TickerProviderStateMixin {
  static const double _minHalfStepWidthInPx = 5;
  static const double _maxHalfStepWidthInPx = 500;

  double get _minHalfStepWidthBasedOnScreenSize => widget.width / keysOnScreen;

  double get _maxHalfStepWidthBasedOnScreenSize => widget.width / 5;

  double get minHalfStepWidthInPx =>
      max(_minHalfStepWidthInPx, _minHalfStepWidthBasedOnScreenSize);

  double get maxHalfStepWidthInPx =>
      min(_maxHalfStepWidthInPx, _maxHalfStepWidthBasedOnScreenSize);

  bool useOrientation = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  ValueNotifier<double> scrollPositionNotifier;
  bool reverseScrolling = false;
  ScrollingMode scrollingMode = ScrollingMode.sideScroll;
  ScrollingMode previousScrollingMode;
  bool showScrollHint = false;

  List<AnimationController> _scaleAnimationControllers = [];

  AnimationController animationController() =>
      AnimationController(vsync: this, duration: Duration(milliseconds: 250));
  double _halfStepWidthInPx = 35;
  bool usePressure = true;

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

  double get diatonicStepWidthInPx => halfStepWidthInPx * 12 / 7;
  AnimationController orientationAnimationController;
  Animation orientationAnimation;
  AnimationController blurAnimationController;
  Animation blurAnimation;
  int highestPitch = CanvasToneDrawer.TOP;
  int lowestPitch = CanvasToneDrawer.BOTTOM;

  int get keysOnScreen => highestPitch - lowestPitch + 1;

  double get touchScrollAreaHeight =>
      (scrollingMode == ScrollingMode.sideScroll) ? 30 : 0;

  Map<int, int> _pointerIdsToTones = Map();
  double _startHalfStepWidthInPx;

  @override
  void initState() {
    super.initState();
    orientationAnimationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
    blurAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    blurAnimation = Tween<double>(
      begin: 0,
      end: 5,
    ).animate(blurAnimationController);
    scrollPositionNotifier = ValueNotifier(0);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      blurAnimation.addListener(() => setState(() {}));
      // blurAnimationController.addListener(() => setState((){}));
    });
  }

  @override
  void dispose() {
    orientationAnimationController.dispose();
    blurAnimationController.dispose();
    _scaleAnimationControllers.forEach((controller) {
      controller.dispose();
    });
    _scaleAnimationControllers.clear();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double halfStepsOnScreen = widget.width / halfStepWidthInPx;
    double physicalWidth = 88 * halfStepWidthInPx;
//    print("physicalWidth=$physicalWidth");
    double minNewValue = widget.width / keysOnScreen;
    if (halfStepWidthInPx < minNewValue) {
      halfStepWidthInPx = max(minNewValue, halfStepWidthInPx);
    }
    if (previousScrollingMode != ScrollingMode.sideScroll &&
        scrollingMode == ScrollingMode.sideScroll) {
      showScrollHint = true;
      Future.delayed(Duration(seconds: 25), () {
        showScrollHint = false;
      });
    } else if (previousScrollingMode == ScrollingMode.sideScroll &&
        scrollingMode != ScrollingMode.sideScroll) {
      showScrollHint = false;
    }
    if (widget.showConfiguration) {
      blurAnimationController.forward();
    } else {
      blurAnimationController.reverse();
    }
    previousScrollingMode = scrollingMode;
    double sensitivity = 7;
    return Stack(children: [
      CustomScrollView(
          key: Key("keyboard-$physicalWidth"),
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
                GestureDetector(
                    onScaleStart: (details) => setState(() {
                          _startHalfStepWidthInPx = halfStepWidthInPx;
                        }),
                    onScaleUpdate: (ScaleUpdateDetails details) => setState(() {
                          if (details.scale > 0) {
                            halfStepWidthInPx = max(
                                minHalfStepWidthInPx,
                                min(maxHalfStepWidthInPx,
                                    _startHalfStepWidthInPx * details.scale));
                          }
                        }),
                    onVerticalDragUpdate: (details) {
                      if (details.delta.dy > sensitivity) {
                        // Down swipe
                        print("Downswipe! details=$details");
                        widget.closeKeyboard();
                      } else if (details.delta.dy < -sensitivity) {
                        // Up swipe
                      }
                    },
                    child: AnimatedContainer(
                        duration: animationDuration,
                        height: touchScrollAreaHeight,
                        width: physicalWidth,
                        color: widget.sectionColor,
                        child: Align(
                            alignment: Alignment.center,
                            child: Container(
                                height: 5,
                                width: physicalWidth,
                                color: Colors.black54)))),
                CustomPaint(
                  size: Size(physicalWidth.floor().toDouble(),
                      widget.height - touchScrollAreaHeight),
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
//      Touch-handling area with the Listener
      Column(children: [
        IgnorePointer(
          child: AnimatedContainer(
              duration: animationDuration,
              height: touchScrollAreaHeight,
              child: AnimatedOpacity(
                opacity: showScrollHint ? 0.7 : 0,
                duration: animationDuration,
                child: AnimatedContainer(
                    height: 16,
                    duration: animationDuration,
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.white,
                    ),
                    width: 210,
                    child: Column(children: [
                      Expanded(child: SizedBox()),
                      Row(children: [
                        Icon(Icons.arrow_left),
                        // Expanded(child: SizedBox()),
                        Expanded(
                            child: Text("Scroll | Swipe ⬇️ to Close",
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11))),
                        // Expanded(child: SizedBox()),
                        Icon(Icons.arrow_right),
                      ]),
                      Expanded(child: SizedBox()),
                    ])),
              )),
        ),
        Expanded(
            child: Listener(
          child: Container(color: Colors.black12),
          onPointerDown: (event) {
            double left = scrollPositionNotifier.value *
                    (physicalWidth - _visibleRect.width) +
                event.position.dx;
            left -= widget.leftMargin;
            double dy = MediaQuery.of(context).size.height -
                event.position.dy -
                widget.distanceFromBottom;
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
              int velocity = usePressure
                  ? 30 +
                      (97 *
                              (event.pressure - event.pressureMin) /
                              (event.pressureMax - event.pressureMin))
                          .round()
                  : 127;
              BeatScratchPlugin.playNote(tone, velocity, widget.part);
            } catch (t) {}
            _pointerIdsToTones[event.pointer] = tone;
            print("pressed tone $tone");
            widget.pressedNotesNotifier.value = _pointerIdsToTones.values;
          },
          onPointerMove: (event) {
            double left = _visibleRect.left + event.position.dx;
            left -= widget.leftMargin;
            double dy = MediaQuery.of(context).size.height -
                event.position.dy -
                widget.distanceFromBottom;
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
                widget.pressedNotesNotifier.value =
                    _pointerIdsToTones.values.toSet();
                BeatScratchPlugin.playNote(tone, 127, widget.part);
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
        ))
      ]),
//    Configuration layer
      Positioned(
          top: touchScrollAreaHeight,
          left: 0.1,
          width: widget.width,
          height: widget.height,
          child: ClipRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: blurAnimation.value, sigmaY: blurAnimation.value),
                child: Column(children: [
                  IgnorePointer(
                    child: AnimatedContainer(
                        duration: animationDuration,
                        height: touchScrollAreaHeight,
                        child: SizedBox(width: widget.width)),
                  ),
                  AnimatedContainer(
                      duration: animationDuration,
                      height: max(0, widget.height - touchScrollAreaHeight),
                      color: Colors.transparent,
                      child: widget.showConfiguration
                          ? Row(children: [
                              Expanded(
                                  flex: 3,
                                  child: Column(
                                      children: [Expanded(child: SizedBox())])),
                            ])
                          : SizedBox())
                ])),
          )),
      Column(children: [
        IgnorePointer(
          child: AnimatedContainer(
              duration: animationDuration,
              height: touchScrollAreaHeight,
              child: SizedBox(width: widget.width)),
        ),
        AnimatedContainer(
            duration: animationDuration,
            height: max(0, widget.height - touchScrollAreaHeight),
            color:
                widget.showConfiguration ? Colors.black26 : Colors.transparent,
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
                                      onPressed: false
                                          ?
                                          //ignore: dead_code
                                          () {
                                              setState(() {
                                                highestPitch++;
                                              });
                                            }
                                          : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_upward))),
                              Container(
                                  width: 45,
                                  child: MyRaisedButton(
                                      onPressed: null,
                                      padding: EdgeInsets.all(0),
                                      child: Text(
                                          highestPitch
                                              .naturalOrSharpNote.uiString,
                                          style:
                                              TextStyle(color: Colors.white)))),
                              Container(
                                  width: 25,
                                  child: MyRaisedButton(
                                      onPressed: false
                                          ?
                                          //ignore: dead_code
                                          () {
                                              setState(() {
                                                highestPitch--;
                                              });
                                            }
                                          : null,
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
                                      onPressed: false
                                          ?
                                          //ignore: dead_code
                                          () {
                                              setState(() {
                                                lowestPitch++;
                                              });
                                            }
                                          : null,
                                      padding: EdgeInsets.all(0),
                                      child: Icon(Icons.arrow_upward))),
                              Container(
                                  width: 45,
                                  child: MyRaisedButton(
                                      onPressed: null,
                                      padding: EdgeInsets.all(0),
                                      child: Text(
                                          lowestPitch
                                              .naturalOrSharpNote.uiString,
                                          style:
                                              TextStyle(color: Colors.white)))),
                              Container(
                                  width: 25,
                                  child: MyRaisedButton(
                                      onPressed: false
                                          ?
                                          //ignore: dead_code
                                          () {
                                              setState(() {
                                                lowestPitch--;
                                              });
                                            }
                                          : null,
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
                        flex: context.isTabletOrLandscapey ? 6 : 4,
                        child: Column(children: [
                          Expanded(child: SizedBox()),
                          Row(children: [
                            Expanded(
                                child: MyRaisedButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed: () {
                                      setState(() {
                                        scrollingMode =
                                            ScrollingMode.sideScroll;
                                      });
                                    },
                                    color: (scrollingMode ==
                                            ScrollingMode.sideScroll)
                                        ? widget.sectionColor
                                        : null,
                                    child: Text("Scroll",
                                        style: TextStyle(
                                            color: widget.sectionColor
                                                .textColor())))),
                            Expanded(
                                child: MyRaisedButton(
                                    padding: EdgeInsets.all(0),
                                    onPressed:
                                        false //(MyPlatform.isAndroid || MyPlatform.isIOS || kDebugMode)
                                            ?
                                            //ignore: dead_code
                                            () {
                                                setState(() {
                                                  switch (scrollingMode) {
                                                    case ScrollingMode
                                                        .sideScroll:
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
                                    color: (scrollingMode ==
                                            ScrollingMode.sideScroll)
                                        ? null
                                        : widget.sectionColor,
                                    child: Row(children: [
                                      Expanded(child: SizedBox()),
//                            Text("+"),
                                      Text((scrollingMode ==
                                              ScrollingMode.pitch)
                                          ? "Tilt"
                                          : (scrollingMode ==
                                                  ScrollingMode.roll)
                                              ? "Roll"
                                              : (scrollingMode ==
                                                      ScrollingMode.sideScroll)
                                                  ? "Roll"
                                                  : "Wat"),
                                      Expanded(child: SizedBox()),
                                    ]))),
                          ]),
                          if (MyPlatform.isIOS || true)
                            Row(
                              children: [
                                Expanded(child: SizedBox()),
                                Container(
                                    height: 20,
                                    child: Switch(
                                      activeColor: Colors.white,
                                      value: usePressure,
                                      onChanged: (v) => setState(() {
                                        usePressure = v;
                                      }),
                                    )),
                                Text("3D Touch",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(
                                            usePressure ? 1 : 0.5))),
                                Expanded(child: SizedBox()),
                              ],
                            ),
                          Expanded(child: SizedBox()),
                        ])),
                    SizedBox(width: 5),
                    Column(children: [
                      Expanded(child: SizedBox()),
                      zoomButton(),
                      Expanded(child: SizedBox()),
                    ]),
                  ])
                : SizedBox())
      ])
    ]);
  }

  Container zoomButton() {
    return Container(
        color: Colors.black12,
        padding: EdgeInsets.zero,
        child: IncrementableValue(
          child: Container(
            // color: Colors.black12,
            width: 48,
            height: 48,
            child: Align(
                alignment: Alignment.center,
                child: Stack(children: [
                  AnimatedOpacity(
                      opacity: 0.5,
                      duration: animationDuration,
                      child: Transform.translate(
                          offset: Offset(-5, 5),
                          child: Transform.scale(
                              scale: 1, child: Icon(Icons.zoom_out)))),
                  AnimatedOpacity(
                      opacity: 0.5,
                      duration: animationDuration,
                      child: Transform.translate(
                          offset: Offset(5, -5),
                          child: Transform.scale(
                              scale: 1, child: Icon(Icons.zoom_in)))),
                  AnimatedOpacity(
                      opacity: 0.8,
                      duration: animationDuration,
                      child: Transform.translate(
                        offset: Offset(2, 20),
                        child: Text(
                            "${(1 + 99 * (halfStepWidthInPx - minHalfStepWidthInPx) / (maxHalfStepWidthInPx - minHalfStepWidthInPx)).toStringAsFixed(0)}%",
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12)),
                      )),
                ])),
          ),
          collapsing: true,
          incrementIcon: Icons.zoom_in,
          decrementIcon: Icons.zoom_out,
          onIncrement: (halfStepWidthInPx < maxHalfStepWidthInPx)
              ? () {
                  setState(() {
                    halfStepWidthInPx =
                        min(maxHalfStepWidthInPx, halfStepWidthInPx * 1.1);
                  });
                }
              : null,
          onDecrement: (halfStepWidthInPx > minHalfStepWidthInPx)
              ? () {
                  setState(() {
                    halfStepWidthInPx =
                        max(minHalfStepWidthInPx, halfStepWidthInPx / 1.1);
                  });
                }
              : null,
        ));
  }

  static final Map<ArgumentList, int> diatonicToneCache = Map();

  int diatonicTone(double left) {
    final key = ArgumentList([left, lowestPitch, halfStepWidthInPx]);
    return diatonicToneCache.putIfAbsent(key, () => _diatonicTone(left));
  }

  int _diatonicTone(double left) {
    left += (lowestPitch - CanvasToneDrawer.BOTTOM) * halfStepWidthInPx;
    int diatonicTone =
        ((left + 0.245 * diatonicStepWidthInPx) / diatonicStepWidthInPx)
                .floor() -
            23;
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
      : super(
            repaint: Listenable.merge([
          scrollPositionNotifier,
          pressedNotesNotifier,
          BeatScratchPlugin.pressedMidiControllerNotes
        ]));

  @override
  void paint(Canvas canvas, Size size) {
    // var bounds = Offset.zero & size;
//    canvas.drawRect(visibleRect(), Paint());
//    canvas.drawRect(bounds, Paint());
//    canvas.clipRect(bounds);
    KeyboardRenderer()
      ..highestPitch = highestPitch
      ..lowestPitch = lowestPitch
      ..pressedNotes = pressedNotesNotifier.value
          .followedBy(BeatScratchPlugin.pressedMidiControllerNotes.value)
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
          alphaDrawerPaint.color =
              chromaticSteps[(tone - chord.rootNote.tone).mod12];
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
        if (renderLettersAndNumbers) {
          String text = NoteLetter.values
              .firstWhere(
                  (letter) => letter.tone.mod12 == visiblePitch.tone.mod12)
              .name;
          TextSpan span = new TextSpan(
              text: text,
              style: TextStyle(
                  fontFamily: "VulfSans",
                  fontWeight: FontWeight.w500,
                  color: Colors.grey));
          TextPainter tp = new TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(
              canvas,
              new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4.5,
                  toneBounds.bottom - 48));
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
              alphaDrawerPaint.color =
                  chromaticSteps[(tone - chord.rootNote.tone).mod12];
            }
            canvas.drawRect(
                Rect.fromLTRB(toneBounds.left, toneBounds.top, toneBounds.right,
                    toneBounds.top + (toneBounds.top + toneBounds.bottom) / 2),
                alphaDrawerPaint);
            break;
        }
        if (renderLettersAndNumbers && tone.mod12 == 0) {
//            alphaDrawerPaint.color = Colors.black;
          TextSpan span = new TextSpan(
              text: (4 + (tone / 12)).toInt().toString(),
              style: TextStyle(
                  fontFamily: "VulfSans",
                  fontWeight: FontWeight.w100,
                  color: Colors.grey));
          TextPainter tp = new TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          tp.layout();
          tp.paint(
              canvas,
              new Offset(toneBounds.left + halfStepPhysicalDistance * 0.5 - 4,
                  toneBounds.bottom - 30));
        }
      });
    });

    //TODO draw lower keys
  }
}
