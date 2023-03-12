import '../layers_view/melody_menu_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
import '../music_preview/melody_preview.dart';
import '../ui_models.dart';
import '../util/dummydata.dart';
import '../util/music_theory.dart';
import '../widget/my_buttons.dart';

// A list of Melodies in a Part, used as a toolbar within the Music View.
class PartMelodyBrowser extends StatefulWidget {
  final Score score;
  final Color sectionColor;
  final Section currentSection;
  final Part part;
  final bool browsingMelodies;
  final Function(Melody) selectOrDeselectMelody;
  final Function(MelodyReference) toggleMelodyReference;
  final Function(Part, Melody, bool) createMelody;

  const PartMelodyBrowser(
      {Key key,
      this.sectionColor,
      this.score,
      this.currentSection,
      this.part,
      this.browsingMelodies,
      this.selectOrDeselectMelody,
      this.createMelody,
      this.toggleMelodyReference})
      : super(key: key);

  @override
  _PartMelodyBrowserState createState() => _PartMelodyBrowserState();
}

class _PartMelodyBrowserState extends State<PartMelodyBrowser>
    with TickerProviderStateMixin {
  ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 5),
      AnimatedOpacity(
          duration: animationDuration,
          opacity: widget.part != null ? 1 : 0,
          child: Container(
            width: 48,
            child: MyRaisedButton(
                color: Color(0x424242).withOpacity(1),
                padding: EdgeInsets.zero,
                onLongPress: null,
                onPressed: () {
                  widget.createMelody(
                      widget.part,
                      defaultMelody(
                          sectionBeats: widget.currentSection.beatCount)
                        ..instrumentType = widget.part.instrument.type,
                      true);
                },
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: widget.browsingMelodies ? 1 : 0,
                    child: Stack(children: [
                      Center(
                          child: Transform.translate(
                              offset: Offset(0, -5),
                              child: Icon(Icons.fiber_manual_record,
                                  color: chromaticSteps[7]))),
                      Center(
                          child: Transform.translate(
                              offset: Offset(0, 10),
                              child: Text("New\nMelody",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 8,
                                      height: 0.9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400)))),
                    ])
                    // Stack(
                    //   children: [
                    //     Align(
                    //         alignment: Alignment.center,
                    //         child: Icon(Icons.fiber_manual_record,
                    //             color: chromaticSteps[7])),
                    //     Align(
                    //         alignment: Alignment.bottomCenter,
                    //         child: Padding(
                    //           padding:
                    //               const EdgeInsets.only(right: 1, bottom: 0),
                    //           child: Transform.translate(
                    //               offset: Offset(0, 0),
                    //               child: Text(
                    //                 "New Melody",
                    //                 textAlign: TextAlign.center,
                    //                 style: TextStyle(
                    //                     fontSize: 8,
                    //                     color: Colors.white,
                    //                     fontWeight: FontWeight.w400),
                    //               )),
                    //         ))
                    //   ],
                    // )
                    )),
          )),
      Expanded(child: getList(context)),
      SizedBox(width: 3),
      AnimatedOpacity(
        duration: animationDuration,
        opacity: widget.part != null ? 1 : 0,
        child: Container(
          color: Color(0x424242).withOpacity(1),
          width: 48,
          child: MelodyMenuBrowser(
            part: widget.part,
            currentSection: widget.currentSection,
            child: Stack(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.folder_open, color: Colors.white)),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 1, bottom: 0),
                      child: Transform.translate(
                          offset: Offset(0, 0),
                          child: Text(
                            "Import",
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w400),
                          )),
                    ))
              ],
            ),
            onMelodySelected: (melody) {
              widget.createMelody(widget.part, melody, false);
            },
          ),
        ),
      ),
      SizedBox(width: 5),
    ]);
  }

  Widget getList(BuildContext context) {
    var items = widget.part?.melodies ?? [];
    items.sort((m1, m2) {
      final r1 = widget.currentSection.referenceTo(m1);
      final r2 = widget.currentSection.referenceTo(m2);
      if (r1.isEnabled == r2.isEnabled) {
        return 0;
      } else if (r1.isEnabled) {
        return -1;
      } else {
        return 1;
      }
    });
    return ImplicitlyAnimatedList<Melody>(
      key: ValueKey("PartMelodyBrowserList"),
      scrollDirection: Axis.horizontal,
      spawnIsolate: false,
      controller: _scrollController,
      items: items,
      areItemsTheSame: (a, b) => a.id == b.id,
      itemBuilder: (context, animation, melody, index) {
        final reference = widget.currentSection.referenceTo(melody);
        final width = 120.0;
        final height = widget.browsingMelodies ? 48.0 : 0.0;

        final tile = AnimatedOpacity(
            duration: animationDuration,
            opacity: reference.isEnabled ? 1 : 0.5,
            child: Stack(
              children: [
                Container(
                    key: ValueKey(melody.id),
                    width: width,
                    height: height,
                    padding: EdgeInsets.only(left: 3),
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: MelodyPreview.generateVolumeDecoration(
                              reference, widget.currentSection,
                              isSelectedMelody: false,
                              bgColor: melodyColor,
                              sectionColor: widget.sectionColor)),
                      child: MyFlatButton(
                          onPressed: () {
                            widget.selectOrDeselectMelody(melody);
                          },
                          onLongPress: () {
                            final reference =
                                widget.currentSection.referenceTo(melody);
                            widget.toggleMelodyReference(reference);
                          },
                          child: Text(melody.canonicalName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: melodyColor.textColor().withOpacity(
                                    melody.canonicalName == melody.name
                                        ? 1
                                        : 0.5),
                              ))),
                    )),
                IgnorePointer(
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: 0.5,
                        child: Transform.translate(
                          offset: Offset(0, 0),
                          child: Container(
                            width: width,
                            height: height,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: MelodyPreview(
                                  section: widget.currentSection,
                                  part: widget.part,
                                  melody: melody,
                                  height: 48,
                                  width: 150,
                                  scale: 0.09),
                            ),
                          ),
                        )))
              ],
            ));
        return SizeFadeTransition(
            sizeFraction: 0.7,
            curve: Curves.easeInOut,
            axis: Axis.horizontal,
            animation: animation,
            child: tile);
      },
    );
  }
}
