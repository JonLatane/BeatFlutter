import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:beatscratch_flutter_redux/settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../music_view/music_system_painter.dart';
import '../ui_models.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../widget/my_platform.dart';

class MusicPreviewRenderer {
  static final double _overSampleScale = MyPlatform.isAppleOS ? 2 : 1;
  final Uint8List scoreData;
  final double scale, width, height;
  final bool renderSections, renderPartNames;
  final MusicViewMode musicViewMode;
  final Color renderColor;
  Score get score => Score.fromBuffer(scoreData);

  MusicPreviewRenderer(
      {required this.scoreData,
      required this.scale,
      required this.width,
      required this.height,
      required this.renderSections,
      required this.renderPartNames,
      required this.musicViewMode,
      required this.renderColor});

  MusicSystemPainter get painter {
    final parts = score.parts;
    final staves = parts.map((part) => PartStaff(part)).toList(growable: false);
    final partTopOffsets = Map<String, double>.fromIterable(parts.asMap().keys,
        key: (index) => parts[index].id, value: (index) => index * staffHeight);
    final staffOffsets = Map<String, double>.fromIterable(staves.asMap().keys,
        key: (index) => staves[index].id,
        value: (index) => index * staffHeight);
    return MusicSystemPainter(
      sectionScaleNotifier: ValueNotifier(renderSections ? 1 : 0),
      score: score,
      section: score.sections.first,
      musicViewMode: musicViewMode,
      transformationController: TransformationController()..value.scale(scale),
      rescale: true,
      staves: ValueNotifier(staves),
      partTopOffsets: ValueNotifier(partTopOffsets),
      staffOffsets: ValueNotifier(staffOffsets),
      colorGuideOpacityNotifier: ValueNotifier(0),
      tappedBeat: ValueNotifier(null),
      tappedPart: ValueNotifier(null),
      bluetoothControllerPressedNotes: ValueNotifier(Map()),
      colorblockOpacityNotifier: ValueNotifier(
          AppSettings.globalRenderingMode == RenderingMode.colorblock ? 1 : 0),
      notationOpacityNotifier: ValueNotifier(
          AppSettings.globalRenderingMode == RenderingMode.notation ? 1 : 0),
      colorboardNotesNotifier: ValueNotifier([]),
      keyboardNotesNotifier: ValueNotifier([]),
      visibleRect: () => Rect.fromLTRB(0, 0, width / scale, height / scale),
      verticallyVisibleRect: () =>
          Rect.fromLTRB(0, 0, width / scale, height / scale),
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
      (extraBeatsSpaceForClefs + score.beatCount) * beatWidth * scale;
  double get actualWidth => min(maxWidth, width);
  Future<ui.Image?> get renderedScoreImage async {
    if (height < 1 || width < 1) {
      return null;
    }
    // [CustomPainter] has its own @canvas to pass our
    // [ui.PictureRecorder] object must be passed to [Canvas]#contructor
    // to capture the Image. This way we can pass @recorder to [Canvas]#contructor
    // using @painter[SignaturePainter] we can call [SignaturePainter]#paint
    // with the our newly created @canvas
    final recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final size =
        Size(actualWidth * _overSampleScale, height * _overSampleScale);
    final painter = this.painter;
    canvas.save();
    canvas.scale(_overSampleScale);
    // await () async {
    final originalForegroundColor = musicForegroundColor;
    musicForegroundColor = renderColor;
    painter.paint(canvas, size);
    musicForegroundColor = originalForegroundColor;
    // };
    canvas.restore();
    final data = recorder
        .endRecording()
        .toImage(size.width.floor(), size.height.floor());
    return data;
  }

  Future<Uint8List?> get renderedScoreImageData async {
    final image = await renderedScoreImage;
    return Uint8List.sublistView(
        (await image?.toByteData(format: ui.ImageByteFormat.png))!);
  }
}
