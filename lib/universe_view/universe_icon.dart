import 'package:beatscratch_flutter_redux/ui_models.dart';
import 'package:beatscratch_flutter_redux/util/bs_methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

import '../colors.dart';

class UniverseIcon extends StatefulWidget {
  final Color sectionColor;
  final InteractionMode interactionMode;
  final BSMethod animateIcon;

  const UniverseIcon(
      {Key key,
      @required this.sectionColor,
      @required this.interactionMode,
      this.animateIcon})
      : super(key: key);

  @override
  _UniverseIconState createState() => _UniverseIconState();
}

class _UniverseIconState extends State<UniverseIcon>
    with TickerProviderStateMixin {
  AnimationController orbitRotationController;
  Animation<double> orbitRotation;
  AnimationController atomRotationController;
  Animation<double> atomRotation;
  @override
  initState() {
    super.initState();

    orbitRotationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    orbitRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(orbitRotationController);

    atomRotationController = AnimationController(
      duration: slowAnimationDuration,
      vsync: this,
    );
    atomRotation = Tween<double>(
      begin: 0,
      end: -2 * pi,
    ).animate(atomRotationController);

    widget.animateIcon?.addListener(() {
      if (widget.interactionMode != InteractionMode.universe) {
        orbitRotationController.forward().then(
            (_) => (!disposed) ? orbitRotationController.reverse() : null);
        atomRotationController
            .forward()
            .then((_) => (!disposed) ? atomRotationController.reverse() : null);
      } else {
        orbitRotationController.reverse().then(
            (_) => (!disposed) ? orbitRotationController.forward() : null);
        atomRotationController
            .reverse()
            .then((_) => (!disposed) ? atomRotationController.forward() : null);
      }
    });
  }

  bool disposed = false;
  @override
  dispose() {
    orbitRotationController.dispose();
    atomRotationController.dispose();
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.interactionMode.isUniverse) {
      orbitRotationController.forward();
      atomRotationController.forward();
    } else {
      orbitRotationController.reverse();
      atomRotationController.reverse();
    }
    return Transform.translate(
        offset: Offset(0, 0),
        child: Stack(children: [
          AnimatedBuilder(
              animation: orbitRotationController,
              builder: (_, child) => Transform(
                  transform: Matrix4.rotationZ(orbitRotation.value),
                  alignment: Alignment.center,
                  child: Transform.scale(
                      scale: 1.4,
                      child: Icon(MaterialCommunityIcons.orbit,
                          color: ((widget.interactionMode ==
                                      InteractionMode.universe)
                                  ? widget.sectionColor
                                  : subBackgroundColor)
                              .textColor()
                              .withOpacity(widget.interactionMode ==
                                      InteractionMode.universe
                                  ? 0.8
                                  : 0.6))))),
          AnimatedBuilder(
              animation: atomRotationController,
              builder: (_, child) => Transform(
                  transform: Matrix4.rotationZ(atomRotation.value),
                  alignment: Alignment.center,
                  child: Transform.scale(
                      scale: 1,
                      child: Icon(
                        FontAwesomeIcons.atom,
                        color: ((widget.interactionMode !=
                                    InteractionMode.universe)
                                ? widget.sectionColor
                                : widget.sectionColor.textColor())
                            .withOpacity(widget.interactionMode ==
                                    InteractionMode.universe
                                ? 1
                                : 1),
                      )))),
          // Icon(MaterialCommunityIcons.weather_hurricane,
          //     color: chromaticSteps[10].withOpacity(0.8)),
        ]));
  }
}
