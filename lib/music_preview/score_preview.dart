import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:beatscratch_flutter_redux/settings/app_settings.dart';
import 'package:flutter/foundation.dart';

import '../colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import '../ui_models.dart';
import '../util/bs_notifiers.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../music_view/music_system_painter.dart';
import 'preview_renderer.dart';

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

  double get maxWidth =>
      (MusicSystemPainter.extraBeatsSpaceForClefs + widget.score.beatCount) *
      unscaledStandardBeatWidth *
      widget.scale;
  double get actualWidth => min(maxWidth, widget.width);
  static const double _overSampleScale = 4;

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
      final Uint8List data = await MusicPreviewRenderer(
        scoreData: widget.score.writeToBuffer(),
        scale: widget.scale,
        width: widget.width,
        height: widget.height,
        renderSections: widget.renderSections,
        renderPartNames: widget.renderPartNames,
        musicViewMode: widget.musicViewMode,
      ).renderedScoreImageData;
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

Future<Uint8List> _renderedScoreImageData(MusicPreviewRenderer renderer) {
  return renderer.renderedScoreImageData;
}
