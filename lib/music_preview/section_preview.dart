import '../util/bs_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import 'score_preview.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../colors.dart';

class SectionPreview extends StatefulWidget {
  final Section section;
  final Score score;
  final double width;
  final double height;
  final double scale;

  const SectionPreview({
    Key key,
    this.section,
    this.score,
    this.width = 300,
    this.height = 100,
    this.scale = 0.15,
  }) : super(key: key);

  @override
  _SectionPreviewState createState() => _SectionPreviewState();
}

class _SectionPreviewState extends State<SectionPreview> {
  String lastPreviewKey;
  Score preview;
  BSMethod notifyUpdate;

  String get previewKey => "${widget.section.id}-${widget.section.hashCode}";

  @override
  initState() {
    super.initState();
    preview = sectionPreview(widget.score, widget.section);
    notifyUpdate = BSMethod();
  }

  @override
  Widget build(BuildContext context) {
    if (lastPreviewKey != previewKey) {
      preview = sectionPreview(widget.score, widget.section);
      lastPreviewKey = previewKey;
      notifyUpdate();
    }
    return IgnorePointer(
      child: ScorePreview(preview,
          scale: widget.scale,
          width: widget.width,
          height: widget.height,
          renderPartNames: false,
          renderSections: false,
          notifyUpdate: notifyUpdate,
          renderColor: widget.section.color.color.textColor()),
    );
  }
}
