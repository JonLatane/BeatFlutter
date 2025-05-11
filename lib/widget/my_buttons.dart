import 'package:flutter/material.dart';

class MyFlatButton extends TextButton {
  MyFlatButton({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    MouseCursor mouseCursor = SystemMouseCursors.basic,
    ButtonTextTheme? textTheme,
    Color? color,
    EdgeInsetsGeometry? padding,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    ButtonStyle? style,
    bool lightHighlight = false,
    required Widget child,
  }) : super(
          key: key,
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: style ??
              ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(color),
                  overlayColor: WidgetStateProperty.all(
                      lightHighlight ? Colors.white10 : null),
                  mouseCursor:
                      WidgetStateProperty.all(SystemMouseCursors.basic),
                  padding: WidgetStateProperty.all(padding)),
          // ElevatedButton.styleFrom(
          //     primary: color,
          //     // onPrimary: color?.textColor(),
          //     padding: padding,
          //     enabledMouseCursor: SystemMouseCursors.basic),

          clipBehavior: clipBehavior,
          focusNode: focusNode,
          autofocus: autofocus,
          child: child,
        );
}

class MyRaisedButton extends ElevatedButton {
  MyRaisedButton({
    Key? key,
    required VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ValueChanged<bool>? onHighlightChanged,
    MouseCursor mouseCursor = SystemMouseCursors.basic,
    ButtonTextTheme? textTheme,
    Color? textColor,
    Color? disabledTextColor,
    Color? color,
    Color? disabledColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? splashColor,
    Brightness? colorBrightness,
    double elevation = 1.0,
    double focusElevation = 1.0,
    double hoverElevation = 1.0,
    double highlightElevation = 1.0,
    double disabledElevation = 1.0,
    EdgeInsetsGeometry? padding,
    VisualDensity? visualDensity,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    Duration? animationDuration,
    Widget? child,
  })  : assert(elevation >= 0.0),
        assert(focusElevation >= 0.0),
        assert(hoverElevation >= 0.0),
        assert(highlightElevation >= 0.0),
        assert(disabledElevation >= 0.0),
        super(
          key: key,
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: padding,
              enabledMouseCursor: SystemMouseCursors.basic,
              disabledMouseCursor: SystemMouseCursors.basic),
          clipBehavior: clipBehavior,
          focusNode: focusNode,
          autofocus: autofocus,
          // materialTapTargetSize: materialTapTargetSize,
          // animationDuration: animationDuration,
          child: child,
        );
}

class MySlider extends Slider {
  const MySlider({
    Key? key,
    required double value,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeStart,
    ValueChanged<double>? onChangeEnd,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    String? label,
    Color? activeColor,
    Color? inactiveColor,
    MouseCursor mouseCursor = SystemMouseCursors.basic,
    SemanticFormatterCallback? semanticFormatterCallback,
    FocusNode? focusNode,
    bool autofocus = false,
  }) : super(
          key: key,
          value: value,
          onChanged: onChanged,
          onChangeStart: onChangeStart,
          onChangeEnd: onChangeEnd,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          mouseCursor: mouseCursor,
          semanticFormatterCallback: semanticFormatterCallback,
          focusNode: focusNode,
          autofocus: autofocus,
        );
}
