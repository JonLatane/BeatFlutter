import 'dart:io';
import 'dart:math';

import 'package:beatscratch_flutter_redux/music_view/music_action_button.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/rendering.dart';

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'my_buttons.dart';
import 'my_platform.dart';
import '../ui_models.dart';

class IncrementableValue extends StatefulWidget {
  final Function onIncrement;
  final Function onDecrement;
  final String value;
  final TextStyle textStyle;
  final double valueWidth;
  final VoidCallback onValuePressed;
  final Widget child;
  final double incrementDistance;
  final double incrementTimingDifferenceMs;
  final bool collapsing;
  final IconData incrementIcon;
  final IconData decrementIcon;
  final VoidCallback onPointerUpCallback;
  final VoidCallback onPointerDownCallback;
  final bool musicActionButtonStyle;
  final Color musicActionButtonColor;

  const IncrementableValue({
    Key key,
    this.onIncrement,
    this.onDecrement,
    this.value,
    this.textStyle,
    this.valueWidth = 45,
    this.onValuePressed,
    this.child,
    this.incrementDistance = 10,
    this.incrementTimingDifferenceMs = 50,
    this.collapsing = false,
    this.incrementIcon = Icons.keyboard_arrow_up_rounded,
    this.decrementIcon = Icons.keyboard_arrow_down_rounded,
    this.onPointerUpCallback,
    this.onPointerDownCallback,
    this.musicActionButtonStyle = false, this.musicActionButtonColor,
  }) : super(key: key);

  @override
  _IncrementableValueState createState() => _IncrementableValueState();
}

class _IncrementableValueState extends State<IncrementableValue> {
  int lastTouchTimeMs = 0;
  Offset incrementStartPos;
  int incrementStartTimeMs;
  bool hasVibration = false;
  static const _msDelay = 3000;
  static const _delay = Duration(milliseconds: _msDelay);
  bool _disposed = false;

  vibrate() {
    if (hasVibration) {
      Vibration.vibrate(duration: 25);
    }
  }

  @override
  void initState() {
    super.initState();
    _disposed = false;
    if (MyPlatform.isMobile) {
      Vibration.hasVibrator().then((value) => hasVibration = value);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool showButtons = !widget.collapsing || DateTime.now().millisecondsSinceEpoch - lastTouchTimeMs < _msDelay;
    double buttonWidth = showButtons ? 28 : 0;
    Widget bgListener = AnimatedContainer(
        duration: animationDuration,
        width: widget.valueWidth + 2 * buttonWidth,
        height: 48,
        child: Listener(
          child: MyFlatButton(onPressed: () {}, color: Colors.transparent, padding: EdgeInsets.zero, child: SizedBox()),
          onPointerDown: (_) {
            widget.onPointerDownCallback?.call();
          },
          onPointerUp: (_) {
            widget.onPointerUpCallback?.call();
          },
          onPointerMove: (_) {},
        ));
    return Stack(
      children: [
        widget.musicActionButtonStyle
            ? MusicActionButton(
                visible: true,
                color: widget.musicActionButtonColor ?? Colors.black12,
                onPressed: null,
                width: widget.valueWidth + 2 * buttonWidth,
                height: 48,
                child: bgListener)
            : bgListener,
        // Row(children:[Expanded(child:MyFlatButton(onPressed: (){}, color: Colors.black54, child:
        //   Column(children: [Expanded(child: SizedBox())])
        // )),]),
        Listener(
          child: Row(children: [
            AnimatedContainer(
                width: buttonWidth,
                padding: EdgeInsets.only(left: showButtons ? 3 : 0),
                duration: animationDuration,
                child: MyRaisedButton(
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: showButtons ? 1 : 0,
                    child: Icon(widget.decrementIcon),
                  ),
                  onPressed: widget.onDecrement != null ? () {
                    lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
                    widget.onDecrement();
                  } : null,
                  padding: EdgeInsets.all(0),
                )),
            widget.child ??
                Container(
                    width: widget.valueWidth,
                    child: MyRaisedButton(
                        onPressed: widget.onValuePressed,
                        padding: EdgeInsets.all(0),
                        child: Text(
                          widget.value ?? "null",
                          style: widget.textStyle ?? TextStyle(color: Colors.white),
                        ))),
            AnimatedContainer(
                width: buttonWidth,
                padding: EdgeInsets.only(right: showButtons ? 3 : 0),
                duration: animationDuration,
                child: MyRaisedButton(
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: showButtons ? 1 : 0,
                    child: Icon(widget.incrementIcon),
                  ),
                  onPressed: widget.onIncrement != null ? () {
                    lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
                    widget.onIncrement();
                  } : null,
                  padding: EdgeInsets.all(0),
                )),
          ]),
          onPointerDown: (event) {
            widget.onPointerDownCallback?.call();
            incrementStartPos = event.position;
            incrementStartTimeMs = DateTime.now().millisecondsSinceEpoch;
            lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
            vibrate();
            if (widget.collapsing) {
              checkCanCollapse() {
                if (DateTime.now().millisecondsSinceEpoch - lastTouchTimeMs > _msDelay) {
                  if (!_disposed) {
                    setState(() {});
                  }
                } else {
                  Future.delayed(const Duration(seconds: 1), checkCanCollapse);
                }
              }

              setState(() {});
              checkCanCollapse();
            }
          },
          onPointerMove: (event) {
            lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
            Offset difference = event.position - incrementStartPos;
            int eventTime = DateTime.now().millisecondsSinceEpoch;
            if (difference.distanceSquared < widget.incrementDistance ||
                eventTime - incrementStartTimeMs < widget.incrementTimingDifferenceMs) {
              return; // Hasn't moved far enough/had enough time to increment again.
            }
            bool isUp = false;
            bool isDown = false;
            double direction = difference.direction;
            if (direction >= -0.75 * pi && direction < 0.25 * pi) {
              isUp = true;
            } else if (direction >= 0.25 * pi) {
              isDown = true;
            } else if (direction < -0.75 * pi) {
              isDown = true;
            }
//          print("direction=$direction | isUp=$isUp | isDown=$isDown");
            if (isUp && widget.onIncrement != null) {
              vibrate();
              incrementStartPos = event.position;
              incrementStartTimeMs = eventTime;
              // print("increment");
              widget.onIncrement();
            } else if (isDown && widget.onDecrement != null) {
              vibrate();
              incrementStartPos = event.position;
              incrementStartTimeMs = eventTime;
              widget.onDecrement();
            }
          },
          onPointerUp: (event) {
            lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
            incrementStartPos = null;
            widget.onPointerUpCallback?.call();
          },
          onPointerCancel: (event) {
            lastTouchTimeMs = DateTime.now().millisecondsSinceEpoch;
            incrementStartPos = null;
          },
        ),
      ],
    );
  }
}
