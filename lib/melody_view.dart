import 'dart:collection';

import 'package:beatscratch_flutter_redux/generated/protos/music.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'melodybeat.dart';
import 'expanded_section.dart';
import 'part_melodies_view.dart';
import 'dart:math';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:uuid/uuid.dart';


class MelodyView extends StatefulWidget {
  final int counter;

  MelodyView({this.counter});

  @override
  _MelodyViewState createState() => _MelodyViewState().._counter = counter;
}

class _MelodyViewState extends State<MelodyView> {
  int _counter = 0;
  double _startHorizontalScale = 1.0;
  double _startVerticalScale = 1.0;
  double _horizontalScale = 1.0;
  double _verticalScale = 1.0;

  Widget build(context) {
    return Container(
            color: Colors.white,
            child: GestureDetector(
              onScaleStart: (details) => setState(() {
                _startHorizontalScale = _horizontalScale;
              }),
              onScaleUpdate: (ScaleUpdateDetails details) {
                setState(() {
                  if (details.horizontalScale > 0) {
                    _horizontalScale = max(0.1, min(16, _startHorizontalScale * details.horizontalScale));
                  }
                });
              },
              onScaleEnd: (ScaleEndDetails details) {
                //_horizontalScale = max(0.1, min(16, _horizontalScale.ceil().toDouble()));
              },
              child: GridView.builder(
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: max(1, (16 / _horizontalScale).floor())),
                itemCount: _counter * 8,
                itemBuilder: (BuildContext context, int index) {
                  return GridTile(
                      child: Transform.scale(
                          scale: 1 - 0.2 * ((16 / _horizontalScale).floor() - (16 / _horizontalScale)).abs(),
                          child: SvgPicture.asset('assets/notehead_half.svg')));
                },
//                padding: const EdgeInsets.all(4.0),
              ),
            ));
  }
}