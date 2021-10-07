import 'package:beatscratch_flutter_redux/util/music_theory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'beatscratch_plugin.dart';
import 'colors.dart';
import 'export/export_ui.dart';
import 'generated/protos/protos.dart';
import 'music_preview/melody_preview.dart';
import 'music_preview/part_preview.dart';
import 'music_preview/section_preview.dart';
import 'widget/beats_badge.dart';
import 'widget/my_platform.dart';

Future<Object> showEditMenu(
    {@required BuildContext context,
    @required RelativeRect position,
    @required Score score,
    @required Part part,
    @required Section section,
    @required Function(Object) editObject}) async {
  onSelected(Object object) {
    Navigator.pop(context);
    editObject(object);
  }

  final melodies = part.melodies.where((m) => section.referenceTo(m).isEnabled);
  return showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: (musicBackgroundColor.luminance < 0.5
              ? subBackgroundColor
              : musicBackgroundColor)
          .withOpacity(0.95),
      items: [
        PopupMenuItem(
          mouseCursor: SystemMouseCursors.basic,
          value: null,
          child: Column(children: [
            Row(children: [
              Text("Quick",
                  textAlign: TextAlign.left,
                  // overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              SizedBox(width: 3),
              Text("Edit",
                  textAlign: TextAlign.left,
                  // overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w100,
                      fontSize: 18)),
            ]),
          ]),
          enabled: false,
        ),
        sectionMenuItem(score, section, onSelected),
        partMenuItem(score, part, section, onSelected),
        if (melodies.isNotEmpty)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: null,
            child: Column(children: [
              Row(children: [
                Text(part.midiName,
                    textAlign: TextAlign.left,
                    // overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                SizedBox(width: 2),
                Text("Melodies",
                    textAlign: TextAlign.left,
                    // overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                        fontWeight: FontWeight.w100,
                        fontSize: 12)),
              ]),
            ]),
            enabled: false,
          ),
        ...melodies
            .map((m) => melodyMenuItem(score, m, part, section, onSelected)),
      ]);
}

PopupMenuItem<Section> sectionMenuItem(
    Score score, Section section, Function(Object) onSelected) {
  final backgroundColor = section.color.color;
  final foregroundColor = backgroundColor.textColor();
  double scale, height;
  if (score.parts.length == 1) {
    scale = 0.15;
    height = 100;
  } else if (score.parts.length <= 3) {
    scale = 0.12;
    height = 70.0 * score.parts.length;
  } else {
    scale = 0.076;
    height = 40.0 * score.parts.length;
  }
  return PopupMenuItem(
      value: section,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            onSelected(section);
          },
          child: Column(
            children: [
              SizedBox(height: 3),
              Row(children: [
                SizedBox(width: 16),
                Expanded(
                    child: Opacity(
                        opacity: 1,
                        child: Text(section.canonicalName,
                            style: TextStyle(
                                color: foregroundColor.withOpacity(
                                    section.name.isNotEmpty ? 1 : 0.5),
                                fontWeight: FontWeight.w100)))),
                SizedBox(width: 3),
                Opacity(
                    opacity: 1, child: BeatsBadge(beats: section.beatCount)),
                SizedBox(width: 3),
              ]),
              Opacity(
                  opacity: 1,
                  child: SectionPreview(
                      score: score,
                      section: section,
                      scale: scale,
                      height: height)),
            ],
          ),
        ),
      ),
      enabled: true //melody.instrumentType == widget.part?.instrument?.type,
      );
}

PopupMenuItem<Part> partMenuItem(
    Score score, Part part, Section section, Function(Object) onSelected) {
  final backgroundColor = part.isDrum ? Colors.brown : Colors.grey;
  final foregroundColor = Colors.white;
  return PopupMenuItem(
      value: part,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            onSelected(part);
          },
          child: Column(
            children: [
              SizedBox(height: 3),
              Row(children: [
                SizedBox(width: 16),
                Expanded(
                    child: Opacity(
                        opacity: 1,
                        child: Text(part.midiName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: foregroundColor,
                                fontWeight: FontWeight.w900)))),

                // Padding(
                //     padding: EdgeInsets.symmetric(vertical: 2),
                //     child: Icon(Icons.add)),
                // if (!isDuplicate &&
                //     widget.part?.instrument?.type == melody.instrumentType)
                SizedBox(width: 3),
              ]),
              Opacity(
                  opacity: 1,
                  child: PartPreview(
                    score: score,
                    section: section,
                    part: part,
                  )),
            ],
          ),
        ),
      ),
      enabled: true //melody.instrumentType == widget.part?.instrument?.type,
      );
}

PopupMenuItem<Melody> melodyMenuItem(Score score, Melody melody, Part part,
    Section section, Function(Object) onSelected) {
  final backgroundColor = Colors.transparent;
  final foregroundColor = musicForegroundColor;
  return PopupMenuItem(
      value: melody,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            onSelected(melody);
          },
          child: Column(
            children: [
              SizedBox(height: 3),
              Row(children: [
                SizedBox(width: 16),
                Expanded(
                    child: Opacity(
                        opacity: 1,
                        child: Text(melody.canonicalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor.withOpacity(
                                  melody.name.isNotEmpty ? 1 : 0.5),
                            )))),
                SizedBox(width: 3),
                Expanded(child: SizedBox()),
                Opacity(opacity: 1, child: BeatsBadge(beats: melody.beatCount)),
                // Padding(
                //     padding: EdgeInsets.symmetric(vertical: 2),
                //     child: Icon(Icons.add)),
                // if (!isDuplicate &&
                //     widget.part?.instrument?.type == melody.instrumentType)
                SizedBox(width: 3),
              ]),
              Opacity(
                  opacity: 1,
                  child: MelodyPreview(
                    melody: melody,
                    section: section,
                    part: part,
                  )),
            ],
          ),
        ),
      ),
      enabled: true //melody.instrumentType == widget.part?.instrument?.type,
      );
}
