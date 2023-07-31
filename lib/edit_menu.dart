import 'package:beatscratch_flutter_redux/util/music_theory.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'generated/protos/protos.dart';
import 'music_preview/melody_preview.dart';
import 'music_preview/part_preview.dart';
import 'music_preview/section_preview.dart';
import 'ui_models.dart';
import 'widget/beats_badge.dart';

Future<Object> showEditMenu(
    {@required BuildContext context,
    @required RelativeRect position,
    @required Score score,
    @required Part part,
    @required Melody selectedMelody,
    @required MusicViewMode musicViewMode,
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
        // if (!context.isPortraitPhone)
        //   sectionAndPartMenuItem(
        //       score, section, part, onSelected, musicViewMode),
        // if (context.isPortraitPhone)
        sectionMenuItem(
            score, section, onSelected, musicViewMode == MusicViewMode.section),
        // if (context.isPortraitPhone)
        partMenuItem(score, part, section, onSelected,
            musicViewMode == MusicViewMode.part),
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
        ...melodies.map((m) => melodyMenuItem(
            score, m, part, section, onSelected, m == selectedMelody)),
      ]);
}

PopupMenuItem<void> sectionAndPartMenuItem(Score score, Section section,
    Part part, Function(Object) onSelected, MusicViewMode musicViewMode) {
  Widget sectionView = sectionPreview(
          score, section, onSelected, musicViewMode == MusicViewMode.section),
      partView = partPreview(score, part, section, onSelected,
          musicViewMode == MusicViewMode.part);
  return PopupMenuItem(
      value: null,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Container(width: 300, child: sectionView),
          Container(width: 300, child: partView)
        ],
      ));
}

PopupMenuItem<Section> sectionMenuItem(Score score, Section section,
    Function(Object) onSelected, bool isSelected) {
  return PopupMenuItem(
      value: section,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: sectionPreview(score, section, onSelected, isSelected),
      enabled: true);
}

Material sectionPreview(Score score, Section section,
    Function(Object) onSelected, bool isSelected) {
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
  return Material(
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
            SizedBox(
              width: 16,
              child: isSelected
                  ? Transform.translate(
                      offset: Offset(1, 1),
                      child: Icon(Icons.chevron_right,
                          size: 14, color: foregroundColor))
                  : null,
            ),
            Expanded(
                child: Opacity(
                    opacity: 1,
                    child: Text(section.canonicalName,
                        style: TextStyle(
                            color: foregroundColor
                                .withOpacity(section.name.isNotEmpty ? 1 : 0.5),
                            fontWeight: FontWeight.w100)))),
            SizedBox(width: 3),
            Opacity(opacity: 1, child: BeatsBadge(beats: section.beatCount)),
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
  );
}

PopupMenuItem<Part> partMenuItem(Score score, Part part, Section section,
    Function(Object) onSelected, bool isSelected) {
  return PopupMenuItem(
      value: part,
      mouseCursor: SystemMouseCursors.basic,
      padding: EdgeInsets.zero,
      child: partPreview(score, part, section, onSelected, isSelected),
      enabled: true);
}

Material partPreview(Score score, Part part, Section section,
    Function(Object) onSelected, bool isSelected) {
  final backgroundColor = part.isDrum ? Colors.brown : Colors.grey;
  final foregroundColor = Colors.white;
  return Material(
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
            SizedBox(
              width: 16,
              child: isSelected
                  ? Transform.translate(
                      offset: Offset(1, 1),
                      child: Icon(Icons.chevron_right,
                          size: 14, color: foregroundColor))
                  : null,
            ),
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
  );
}

PopupMenuItem<Melody> melodyMenuItem(Score score, Melody melody, Part part,
    Section section, Function(Object) onSelected, bool isSelected) {
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
                SizedBox(
                  width: 16,
                  child: isSelected
                      ? Transform.translate(
                          offset: Offset(1, 1),
                          child: Icon(Icons.chevron_right,
                              size: 14, color: foregroundColor))
                      : null,
                ),
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
