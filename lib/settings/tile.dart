
import 'package:flutter/material.dart';

import '../ui_models.dart';
import '../widget/my_buttons.dart';

class SettingsTile extends StatelessWidget {
  final String id;
  final Widget child;
  final Color color;
  final VoidCallback onPressed;

  const SettingsTile({
    Key key,
    this.id,
    this.child,
    this.color,
    this.onPressed,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    Widget wrapWithButton(widget) => onPressed != null
        ? MyFlatButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            child: widget,
          )
        : widget;
    return AnimatedContainer(
        duration: animationDuration,
        width: 200,
        height: 150,
        color: color,
        padding: EdgeInsets.all(5),
        child: wrapWithButton(child));
  }
}

class SeparatorTile extends StatelessWidget {
  final String text;
  final String id;

  const SeparatorTile({
    Key key,
    this.text,
    this.id,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: animationDuration,
        width: 27,
        height: 150,
        decoration: BoxDecoration(
            border: Border(
          left: BorderSide(width: 2.0, color: Colors.grey),
        )),
        padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
        child: RotatedBox(
          child: Center(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w300))),
          quarterTurns: 3,
        ));
  }
}
