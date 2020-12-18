
import 'package:flutter/foundation.dart';

enum InteractionMode { view, edit }

enum MusicViewMode { score, section, part, melody, none }

enum SplitMode { half, full }

enum ScrollingMode { sideScroll, pitch, roll }

enum RenderingMode { notation, colorblock }

const Duration animationDuration = Duration(milliseconds: kIsWeb || true ? 500 : 300);
const Duration slowAnimationDuration = Duration(milliseconds: kIsWeb || true ? 800 : 500);