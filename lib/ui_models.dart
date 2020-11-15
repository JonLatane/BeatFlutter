
import 'package:flutter/foundation.dart';

enum InteractionMode { view, edit }

enum MelodyViewMode { score, section, part, melody, none }

enum SplitMode { half, full }

enum ScrollingMode { sideScroll, pitch, roll }

enum RenderingMode { notation, colorblock }

Duration animationDuration = const Duration(milliseconds: kIsWeb || true ? 500 : 300);
Duration slowAnimationDuration = const Duration(milliseconds: kIsWeb || true ? 800 : 500);