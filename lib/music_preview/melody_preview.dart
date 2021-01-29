import '../util/bs_notifiers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import 'score_preview.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../colors.dart';

class MelodyPreview extends StatefulWidget {
  final Section section;
  final Melody melody;
  final Part part;
  final double width;
  final double height;
  final double scale;

  const MelodyPreview({
    Key key,
    this.section,
    this.melody,
    this.part,
    this.width = 300,
    this.height = 100,
    this.scale = 0.15,
  }) : super(key: key);

  @override
  _MelodyPreviewState createState() => _MelodyPreviewState();

  static Gradient generateVolumeDecoration(
      MelodyReference reference, Section section,
      {@required bool isSelectedMelody,
      @required Color bgColor,
      @required Color sectionColor}) {
    if (reference.isEnabled) {
      Color volumeColor = isSelectedMelody
          ? Colors.white
          : sectionColor
              .withOpacity(musicBackgroundColor.luminance > 0.5 ? 1 : 0.5);
      Color notVolumeColor =
          isSelectedMelody && reference.volume == 0.0 ? Colors.white : bgColor;
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment(1.0, 0.0),
        colors: [
          reference.volume > 0.0 ? volumeColor : notVolumeColor,
          reference.volume > 0.1 ? volumeColor : notVolumeColor,
          reference.volume > 0.2 ? volumeColor : notVolumeColor,
          reference.volume > 0.3 ? volumeColor : notVolumeColor,
          reference.volume > 0.4 ? volumeColor : notVolumeColor,
          reference.volume > 0.5 ? volumeColor : notVolumeColor,
          reference.volume > 0.6 ? volumeColor : notVolumeColor,
          reference.volume > 0.7 ? volumeColor : notVolumeColor,
          reference.volume > 0.8 ? volumeColor : notVolumeColor,
          reference.volume > 0.9 ? volumeColor : notVolumeColor,
          reference.volume == 1.0 ? volumeColor : notVolumeColor,
        ],
        tileMode: TileMode.repeated, // repeats the gradient over the canvas
      );
    } else {
      var baseGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment(1.0, 0.0),
        colors: [bgColor, bgColor],
        tileMode: TileMode.repeated, // repeats the gradient over the canvas
      );
      const baseSelectedGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment(1.0, 0.0),
        colors: [Colors.white, Colors.white],
        tileMode: TileMode.repeated, // repeats the gradient over the canvas
      );
      return isSelectedMelody ? baseSelectedGradient : baseGradient;
    }
  }
}

class _MelodyPreviewState extends State<MelodyPreview> {
  String lastPreviewKey;
  Score preview;
  BSMethod notifyUpdate;

  String get previewKey =>
      "${widget.melody.id}-${widget.melody.hashCode}|${widget.part?.id ?? "null"}|" +
      "${widget.section.id}-${widget.section.hashCode}";

  @override
  initState() {
    super.initState();
    preview = melodyPreview(widget.melody ?? Melody(), widget.part ?? Part(),
        widget.section ?? Section());
    notifyUpdate = BSMethod();
  }

  @override
  Widget build(BuildContext context) {
    if (lastPreviewKey != previewKey) {
      preview = melodyPreview(widget.melody ?? Melody(), widget.part ?? Part(),
          widget.section ?? Section());
      lastPreviewKey = previewKey;
      notifyUpdate();
    }
    return IgnorePointer(
      child: ScorePreview(
        preview,
        scale: widget.scale,
        width: widget.width,
        height: widget.height,
        renderPartNames: false,
        renderSections: false,
        notifyUpdate: notifyUpdate,
      ),
    );
  }
}
