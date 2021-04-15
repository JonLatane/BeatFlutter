import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:beatscratch_flutter_redux/settings/app_settings.dart';

import '../colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/bs_notifiers.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../music_view/music_system_painter.dart';

class ScorePreview extends StatefulWidget {
  final Score score;
  final MusicViewMode musicViewMode;
  final bool renderPartNames;
  final bool renderSections;
  final double width;
  final double height;
  final double scale;
  final BSMethod notifyUpdate;

  const ScorePreview(
    this.score, {
    Key key,
    this.width = 300,
    this.height = 100,
    this.scale = 0.15,
    this.musicViewMode = MusicViewMode.score,
    this.renderPartNames = true,
    this.renderSections = true,
    this.notifyUpdate,
  }) : super(key: key);

  @override
  _ScorePreviewState createState() => _ScorePreviewState();
}

enum _Thumbnail { a, b }

class _ScorePreviewState extends State<ScorePreview> {
  bool hasBuilt;
  String _prevScoreId;
  RenderingMode _prevRenderingMode;
  double _prevScale, _prevWidth, _prevHeight;
  Color _prevMusicForegroundColor;
  _Thumbnail currentThumbnail;
  Uint8List thumbnailA, thumbnailB;

  Uint8List get currentThumbnailData =>
      currentThumbnail == _Thumbnail.a ? thumbnailA : thumbnailB;
  set currentThumbnailData(Uint8List value) => currentThumbnail == _Thumbnail.a
      ? thumbnailA = value
      : thumbnailB = value;
  Uint8List get otherThumbnailData =>
      currentThumbnail == _Thumbnail.b ? thumbnailA : thumbnailB;
  set otherThumbnailData(Uint8List value) => currentThumbnail == _Thumbnail.b
      ? thumbnailA = value
      : thumbnailB = value;

  MusicSystemPainter get painter {
    final parts = widget.score.parts;
    final staves = parts.map((part) => PartStaff(part)).toList(growable: false);
    final partTopOffsets = Map<String, double>.fromIterable(parts.asMap().keys,
        key: (index) => parts[index].id,
        value: (index) =>
            index * widget.scale * MusicSystemPainter.staffHeight);
    final staffOffsets = Map<String, double>.fromIterable(staves.asMap().keys,
        key: (index) => staves[index].id,
        value: (index) =>
            index * widget.scale * MusicSystemPainter.staffHeight);
    return MusicSystemPainter(
      sectionScaleNotifier: ValueNotifier(widget.renderSections ? 1 : 0),
      score: widget.score,
      section: widget.score.sections.first,
      musicViewMode: widget.musicViewMode,
      xScaleNotifier: ValueNotifier(widget.scale),
      yScaleNotifier: ValueNotifier(widget.scale),
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
      visibleRect: () => Rect.fromLTRB(0, 0, widget.width, widget.height),
      keyboardPart: ValueNotifier(null),
      colorboardPart: ValueNotifier(null),
      focusedPart: ValueNotifier(null),
      sectionColor: ValueNotifier(Colors.grey),
      isCurrentScore: false,
      highlightedBeat: ValueNotifier(null),
      focusedBeat: ValueNotifier(null),
      firstBeatOfSection: 0,
      renderPartNames: widget.renderPartNames,
      isPreview: true,
    );
  }

  double get maxWidth =>
      (MusicSystemPainter.extraBeatsSpaceForClefs + widget.score.beatCount) *
      unscaledStandardBeatWidth *
      widget.scale;
  double get actualWidth => min(maxWidth, widget.width);
  static const double _overSampleScale = 4;
  Future<ui.Image> get renderedScoreImage async {
    // [CustomPainter] has its own @canvas to pass our
    // [ui.PictureRecorder] object must be passed to [Canvas]#contructor
    // to capture the Image. This way we can pass @recorder to [Canvas]#contructor
    // using @painter[SignaturePainter] we can call [SignaturePainter]#paint
    // with the our newly created @canvas
    final recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);
    var size =
        Size(actualWidth * _overSampleScale, widget.height * _overSampleScale);
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

  double get thumbnailAOpacity => thumbnailA != null
      ? currentThumbnail == _Thumbnail.a
          ? 1
          : 0
      : 0;
  double get thumbnailBOpacity => thumbnailB != null
      ? currentThumbnail == _Thumbnail.b
          ? 1
          : 0
      : 0;

  double renderableWidth;
  bool disposed = false;
  @override
  initState() {
    super.initState();
    currentThumbnail = _Thumbnail.a;
    widget.notifyUpdate?.addListener(_updateScoreImage);
    renderableWidth = actualWidth;
    _prevMusicForegroundColor = musicForegroundColor;
    _prevRenderingMode = AppSettings.globalRenderingMode;
    _prevScale = widget.scale;
    _prevWidth = widget.width;
    _prevHeight = widget.height;
  }

  @override
  dispose() {
    widget.notifyUpdate?.removeListener(_updateScoreImage);
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_prevScoreId != widget.score.id ||
        _prevMusicForegroundColor != musicForegroundColor ||
        _prevRenderingMode != AppSettings.globalRenderingMode ||
        _prevScale != widget.scale ||
        _prevWidth != widget.width ||
        _prevHeight != widget.height) {
      _updateScoreImage();
      _prevScoreId = widget.score.id;
      _prevMusicForegroundColor = musicForegroundColor;
      _prevRenderingMode = AppSettings.globalRenderingMode;
      _prevScale = widget.scale;
      _prevWidth = widget.width;
      _prevHeight = widget.height;
    }
    return AnimatedContainer(
      duration: animationDuration,
      width: renderableWidth,
      height: widget.height,
      child: Stack(children: [
        AnimatedOpacity(
            opacity: thumbnailAOpacity,
            duration: animationDuration,
            child: thumbnailA == null ? SizedBox() : Image.memory(thumbnailA)),
        AnimatedOpacity(
            opacity: thumbnailBOpacity,
            duration: animationDuration,
            child: thumbnailB == null ? SizedBox() : Image.memory(thumbnailB))
      ]),
    );
  }

  _switchThumbnails() => currentThumbnail =
      currentThumbnail == _Thumbnail.a ? _Thumbnail.b : _Thumbnail.a;

  _updateScoreImage() {
    Future.delayed(animationDuration, () async {
      final data = await renderedScoreImageData;
      if (disposed) return;
      setState(() {
        if (actualWidth > renderableWidth) {
          renderableWidth = actualWidth;
        }
        otherThumbnailData = data;
        _switchThumbnails();
      });
      if (actualWidth < renderableWidth) {
        Future.delayed(animationDuration, () async {
          setState(() {
            renderableWidth = actualWidth;
          });
        });
      }
    });
  }
}
