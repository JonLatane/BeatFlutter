import 'package:flutter/material.dart';

class ExpandedSection extends StatefulWidget {
  final Widget child;
  final bool expand;
  final Axis axis;

  ExpandedSection({this.expand = false, this.axis = Axis.horizontal, this.child});

  @override
  _ExpandedSectionState createState() => _ExpandedSectionState(axis: axis);
}

class _ExpandedSectionState extends State<ExpandedSection> with SingleTickerProviderStateMixin {
  AnimationController expandController;
  Animation<double> animation;
  final Axis axis;

  _ExpandedSectionState({this.axis});

  @override
  void initState() {
    super.initState();
    _prepareAnimations();
    _runExpandCheck();
  }

  @override
  void didUpdateWidget(ExpandedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(axis: axis, axisAlignment: 1.0, sizeFactor: animation, child: widget.child);
  }

  ///Setting up the animation
  void _prepareAnimations() {
    expandController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }
}
