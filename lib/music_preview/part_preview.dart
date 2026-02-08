import '../util/bs_methods.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import 'score_preview.dart';
import '../util/dummydata.dart';

class PartPreview extends StatefulWidget {
  final Section section;
  final Score score;
  final Part part;
  final double width;
  final double height;
  final double scale;

  const PartPreview({
    Key? key,
    required this.section,
    required this.score,
    required this.part,
    this.width = 300,
    this.height = 100,
    this.scale = 0.15,
  }) : super(key: key);

  @override
  _PartPreviewState createState() => _PartPreviewState();
}

class _PartPreviewState extends State<PartPreview> {
  String? lastPreviewKey;
  late Score preview;
  late BSMethod notifyUpdate;

  String get previewKey => "${widget.section.id}-${widget.section.hashCode}";

  @override
  initState() {
    super.initState();
    preview = partPreview(widget.score, widget.part, widget.section);
    notifyUpdate = BSMethod();
  }

  @override
  Widget build(BuildContext context) {
    if (lastPreviewKey != previewKey) {
      preview = partPreview(widget.score, widget.part, widget.section);
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
          renderColor: Colors.white),
    );
  }
}
