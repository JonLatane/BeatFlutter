import 'package:flutter/material.dart';
import 'generated/protos/protos.dart';

// var sectionColors = [
//   ChordColor.major.color,
//   ChordColor.minor.color,
//   ChordColor.dominant.color,
//   ChordColor.augmented.color,
//   ChordColor.diminished.color,
// ];

var chromaticSteps = [
  Color(0xFF4DFA90), // "tonic"
  Color(0xFFc64981), // "b2/b9" -
  Color(0xFF52a15a), // "2/9" -
  Color(0xFF884DF2), // "minor"
  Color(0xFF59F9FF), // "major"
  Color(0xFFF9F652), // "subdominant/perfect"
  Color(0xFFF652F9), // "diminished"
  Color(0xFFF93730), // "dominant/5"
  Color(0xFF5296ce), // "augmented (or m6)" -
  Color(0xFF76f014), // "M6" -
  Color(0xFFfd048f), // "b7" -
  Color(0xFFFFB259), // "M7"
];

var subBackgroundColor = Color(0xFF212121);
var musicBackgroundColor = Color(0xFF424242);
var musicForegroundColor = Colors.white;

var melodyColor = Color(0xFFDDDDDD);

enum ChordColor { dominant, major, minor, augmented, diminished, tonic, none }
enum SectionColor { major, minor, perfect, augmented, diminished }

extension ChordColors on ChordColor {
  Color get color {
    switch (this) {
      case ChordColor.major:
        return chromaticSteps[4];
        break;
      case ChordColor.minor:
        return chromaticSteps[3];
        break;
      case ChordColor.dominant:
        return chromaticSteps[7];
        break;
      case ChordColor.augmented:
        return chromaticSteps[8];
        break;
      case ChordColor.diminished:
        return chromaticSteps[6];
        break;
      case ChordColor.tonic:
        return chromaticSteps[0];
        break;
      case ChordColor.none:
        return Colors.white;
        break;
    }
    return Colors.white;
  }
}

extension IntervalColors on IntervalColor {
  Color get color {
    switch (this) {
      case IntervalColor.major:
        return chromaticSteps[4];
        break;
      case IntervalColor.minor:
        return chromaticSteps[3];
        break;
      case IntervalColor.perfect:
        return chromaticSteps[5];
        break;
      case IntervalColor.augmented:
        return chromaticSteps[8];
        break;
      case IntervalColor.diminished:
        return chromaticSteps[6];
        break;
    }
    return Colors.white;
  }
}

extension BSColors on Color {
  static final Map<Color, double> _luminanceCache = {};
  Color withAlpha(int alpha) => Color.fromARGB(alpha, red, green, blue);

  double get luminance =>
      BSColors._luminanceCache.putIfAbsent(this, () => computeLuminance());

  /// With [this] as the background color, computes the appropriate text color.
  Color textColor({Color subBackgroundColor}) {
    if (luminance > 0.5) {
      return Colors.black;
    }
    return Colors.white;
  }
}
