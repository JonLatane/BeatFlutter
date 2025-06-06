import 'package:flutter/foundation.dart';

enum InteractionMode { view, edit, universe }

extension EditInteractions on InteractionMode {
  bool get isEdit => this == InteractionMode.edit;
  bool get isView => this == InteractionMode.view;
  bool get isUniverse => this == InteractionMode.universe;
}

enum MusicViewMode { score, section, part, melody, none }

enum SplitMode { half, full }

enum ScrollingMode { sideScroll, pitch, roll }

enum RenderingMode { notation, colorblock }

const int animationMultiplier = 1;
const Duration animationDuration = Duration(milliseconds: 300);
const Duration slowAnimationDuration = Duration(milliseconds: 400);
