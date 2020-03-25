import 'package:flutter/material.dart';

var sectionColors = [
  ChordColor.major.color,
  ChordColor.minor.color,
  ChordColor.dominant.color,
  ChordColor.augmented.color,
  ChordColor.diminished.color,
];

var chromaticSteps = [
  Color(0xFF4DFA90),
  Color(0xFFA32E6C),
  Color(0xFF80E340),
  Color(0xFF884DF2),
  Color(0xFF59F9FF),
  Color(0xFFCFFA53),
  Color(0xFFF652F9),
  Color(0xFFF93730),
  Color(0xFF4AFBC1),
  Color(0xFF4C9AFF),
  Color(0xFFA03BDB),
  Color(0xFF2EBBB5),
];

enum ChordColor { dominant, major, minor, augmented, diminished, none }

extension ActualColors on ChordColor {
  Color get color {
    switch(this) {
      case ChordColor.major:
        return Color(0xFF59F9FF);
        break;
      case ChordColor.minor:
        return Color(0xFF884DF2);
        break;
      case ChordColor.dominant:
        return Color(0xFFF93730);
        break;
      case ChordColor.augmented:
        return Color(0xFF4AFBC1);
        break;
      case ChordColor.diminished:
        return Color(0xFFF652F9);
        break;
      case ChordColor.none:
        return Colors.white;
        break;
    }
    return Colors.white;
  }
}