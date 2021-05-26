import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:beatscratch_flutter_redux/settings/app_settings.dart';

import '../colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/bs_methods.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../music_view/music_system_painter.dart';

class MusicPreviewRenderer {
  static const double _overSampleScale = 4;
  final Uint8List scoreData;
  final double scale, width, height;
  final bool renderSections, renderPartNames;
  final MusicViewMode musicViewMode;
  Score get score => Score.fromBuffer(scoreData);

  MusicPreviewRenderer(
      {@required this.scoreData,
      @required this.scale,
      @required this.width,
      @required this.height,
      @required this.renderSections,
      @required this.renderPartNames,
      @required this.musicViewMode});

  MusicSystemPainter get painter {
    final parts = score.parts;
    final staves = parts.map((part) => PartStaff(part)).toList(growable: false);
    final partTopOffsets = Map<String, double>.fromIterable(parts.asMap().keys,
        key: (index) => parts[index].id,
        value: (index) => index * scale * MusicSystemPainter.staffHeight);
    final staffOffsets = Map<String, double>.fromIterable(staves.asMap().keys,
        key: (index) => staves[index].id,
        value: (index) => index * scale * MusicSystemPainter.staffHeight);
    return MusicSystemPainter(
      sectionScaleNotifier: ValueNotifier(renderSections ? 1 : 0),
      score: score,
      section: score.sections.first,
      musicViewMode: musicViewMode,
      xScaleNotifier: ValueNotifier(scale),
      yScaleNotifier: ValueNotifier(scale),
      staves: ValueNotifier(staves),
      partTopOffsets: ValueNotifier(partTopOffsets),
      staffOffsets: ValueNotifier(staffOffsets),
      colorGuideOpacityNotifier: ValueNotifier(0),
      colorblockOpacityNotifier: ValueNotifier(
          AppSettings.globalRenderingMode == RenderingMode.colorblock ? 1 : 0),
      notationOpacityNotifier: ValueNotifier(
          AppSettings.globalRenderingMode == RenderingMode.notation ? 1 : 0),
      colorboardNotesNotifier: ValueNotifier([]),
      keyboardNotesNotifier: ValueNotifier([]),
      visibleRect: () => Rect.fromLTRB(0, 0, width, height),
      keyboardPart: ValueNotifier(null),
      colorboardPart: ValueNotifier(null),
      focusedPart: ValueNotifier(null),
      sectionColor: ValueNotifier(Colors.grey),
      isCurrentScore: false,
      highlightedBeat: ValueNotifier(null),
      focusedBeat: ValueNotifier(null),
      firstBeatOfSection: 0,
      renderPartNames: renderPartNames,
      isPreview: true,
    );
  }

  double get maxWidth =>
      (MusicSystemPainter.extraBeatsSpaceForClefs + score.beatCount) *
      unscaledStandardBeatWidth *
      scale;
  double get actualWidth => min(maxWidth, width);
  Future<ui.Image> get renderedScoreImage async {
    // [CustomPainter] has its own @canvas to pass our
    // [ui.PictureRecorder] object must be passed to [Canvas]#contructor
    // to capture the Image. This way we can pass @recorder to [Canvas]#contructor
    // using @painter[SignaturePainter] we can call [SignaturePainter]#paint
    // with the our newly created @canvas
    final recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    var size = Size(actualWidth * _overSampleScale, height * _overSampleScale);
    final painter = this.painter;
    canvas.save();
    canvas.scale(_overSampleScale);
    painter.paint(canvas, size);
    canvas.restore();
    final data = recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
    return data;
  }

  Future<Uint8List> get renderedScoreImageData async {
    final image = await renderedScoreImage;
    return Uint8List.sublistView(
        await image.toByteData(format: ui.ImageByteFormat.png));
  }
}
