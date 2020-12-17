
import 'package:beatscratch_flutter_redux/util/bs_notifiers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/protos/music.pb.dart';
import '../music_view/score_preview.dart';
import '../util/dummydata.dart';

class MelodyPreview extends StatefulWidget {
  final Section section;
  final Melody melody;
  final Part part;
  final double width;
  final double height;
  final double scale;

  const MelodyPreview({Key key, this.section, this.melody, this.part, this.width = 300, this.height = 100, this.scale = 0.15,

  }) : super(key: key);

  @override
  _MelodyPreviewState createState() => _MelodyPreviewState();
}

class _MelodyPreviewState extends State<MelodyPreview> {
  String lastPreviewKey;
  Score preview;
  BSNotifier notifyUpdate;

  String get previewKey => "${widget.melody.id}-${widget.melody.hashCode}|${widget.part.id}|" +
    "${widget.section.id}-${widget.section.hashCode}";

  @override
  initState() {
    super.initState();
    preview =  melodyPreview(widget.melody, widget.part, widget.section);
    notifyUpdate = BSNotifier();
  }
  @override
  Widget build(BuildContext context) {
    if (lastPreviewKey != previewKey) {
      preview =  melodyPreview(widget.melody, widget.part, widget.section);
      lastPreviewKey = previewKey;
      notifyUpdate();
    }
    return IgnorePointer(
      child: ScorePreview(preview,
        scale: widget.scale, width:widget.width, height: widget.height,
        renderPartNames: false, renderSections: false,
        notifyUpdate: notifyUpdate,
      ),
    );
  }
}