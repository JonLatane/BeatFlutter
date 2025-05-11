import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dcache/dcache.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../settings/app_settings.dart';
import '../ui_models.dart';
import '../util/music_notation_theory.dart';
import '../util/music_theory.dart';
import '../util/util.dart';
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
  final Color renderColor;

  const ScorePreview(this.score,
      {Key key,
      this.width = 300,
      this.height = 100,
      this.scale = 0.15,
      this.musicViewMode = MusicViewMode.score,
      this.renderPartNames = true,
      this.renderSections = true,
      this.notifyUpdate,
      this.renderColor})
      : super(key: key);

  @override
  _ScorePreviewState createState() => _ScorePreviewState();
}

enum _Thumbnail { a, b }

class _ScorePreviewState extends State<ScorePreview> {
  bool hasBuilt;
  String _prevScoreId;
  RenderingMode _prevRenderingMode;
  double _prevScale, _prevWidth, _prevHeight;
  Color _prevRenderColor;
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
      (extraBeatsSpaceForClefs + widget.score.beatCount) *
      beatWidth *
      widget.scale;
  double get actualWidth => min(maxWidth, widget.width);

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
    widget.notifyUpdate.addListener(_updateScoreImage);
    renderableWidth = actualWidth;
    _prevRenderColor = widget.renderColor ?? musicForegroundColor;
    _prevRenderingMode = AppSettings.globalRenderingMode;
    _prevScale = widget.scale;
    _prevWidth = widget.width;
    _prevHeight = widget.height;
  }

  @override
  dispose() {
    widget.notifyUpdate.removeListener(_updateScoreImage);
    disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_prevScoreId != widget.score.id ||
        _prevRenderColor != (widget.renderColor ?? musicForegroundColor) ||
        _prevRenderingMode != AppSettings.globalRenderingMode ||
        _prevScale != widget.scale ||
        _prevWidth != widget.width ||
        _prevHeight != widget.height) {
      _updateScoreImage();
      _prevScoreId = widget.score.id;
      _prevRenderColor = widget.renderColor ?? musicForegroundColor;
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

  static final Cache RENDER_CACHE = new LruCache<ArgumentList, Uint8List>(
      storage: new InMemoryStorage<ArgumentList, Uint8List>(500))
    ..loader = (key, oldValue) async =>
        oldValue ??
        await MusicPreviewRenderer(
          scoreData: key.arguments[0].writeToBuffer(),
          scale: key.arguments[1],
          width: key.arguments[2],
          height: key.arguments[3],
          renderSections: key.arguments[4],
          renderPartNames: key.arguments[5],
          musicViewMode: key.arguments[6],
          renderColor: key.arguments[7],
        ).renderedScoreImageData;

  ArgumentList get renderingArguments => ArgumentList([
        widget.score,
        widget.scale,
        widget.width,
        widget.height,
        widget.renderPartNames,
        widget.renderSections,
        widget.musicViewMode,
        widget.renderColor ?? musicForegroundColor,
        AppSettings.globalRenderingMode
      ]);
  _updateScoreImage() {
    Future.delayed(animationDuration, () async {
      final Uint8List data = RENDER_CACHE.get(renderingArguments);
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
          if (disposed) return;
          setState(() {
            renderableWidth = actualWidth;
          });
        });
      }
    });
  }
}
