import 'dart:ui';

import 'package:flutter/material.dart';

import '../ui_models.dart';
import '../widget/my_buttons.dart';

class MusicActionButton extends StatelessWidget {
  final bool visible;
  final double width, height;
  final Widget child;
  final VoidCallback onPressed;

  MusicActionButton(
    {Key key, this.visible = true, this.width = 48, this.height = 48, @required this.child, @required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = this.width, height = this.height;
    if (!visible && width != null && height != null && width != 0 && height != 0) {
      width = 0;
      height = 0;
    }
    return AnimatedOpacity(
      duration: animationDuration,
      opacity: visible ? 1 : 0,
      child: Stack(children: [
        AnimatedContainer(
          duration: animationDuration, height: height, width: width, child: SizedBox()),
        Positioned(
          top: .1,
          left: 0,
          width: width,
          height: height,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: IgnorePointer(
              ignoring: !visible,
              child: AnimatedContainer(
                duration: animationDuration,
                color: Colors.black12,
                height: height,
                width: width,
                child: SizedBox())))),
        AnimatedContainer(
          duration: animationDuration,
          color: Colors.black12,
          height: height,
          width: width,
          child: onPressed == null ? child : MyFlatButton(onPressed: onPressed, padding: EdgeInsets.zero, child: child))
      ]));
  }
}
