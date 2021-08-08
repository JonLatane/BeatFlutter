import 'dart:async';
import 'dart:ui';

import '../music_preview/score_preview.dart';
import 'package:dart_midi/dart_midi.dart';
import 'package:dart_midi/src/byte_writer.dart';

import '../messages/messages_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

import '../settings/settings.dart';
import '../beatscratch_plugin.dart';
import '../colors.dart';
import '../generated/protos/protobeats_plugin.pb.dart';
import '../generated/protos/protos.dart';
import '../music_preview/melody_preview.dart';
import '../storage/universe_manager.dart';
import '../ui_models.dart';
import '../universe_view/universe_icon.dart';
import '../util/bs_methods.dart';
import '../util/dummydata.dart';
import '../util/midi_theory.dart';
import '../util/util.dart';
import '../widget/my_buttons.dart';
import '../widget/my_platform.dart';

showUniverseUpload(BuildContext context, Score score, Color sectionColor,
    UniverseManager universeManager, BSMethod onDoDuplicate) {
  double previewWidth = context.isPortraitPhone
      ? MediaQuery.of(context).size.width * 4 / 5
      : MediaQuery.of(context).size.width * 2 / 3;
  double previewHeight = context.isLandscapePhone
      ? MediaQuery.of(context).size.height * 4 / 5
      : MediaQuery.of(context).size.height * 2 / 3;
  universeManager.findDuplicate(score.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: musicBackgroundColor,
      title: Row(children: [
        Text("Universe",
            style: TextStyle(
                color: musicForegroundColor, fontWeight: FontWeight.w900)),
        SizedBox(width: 3),
        Text("Upload",
            style: TextStyle(
                color: musicForegroundColor, fontWeight: FontWeight.w100)),
        SizedBox(width: 15),
        if (context.isLandscapePhone)
          Text(score.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: musicForegroundColor,
                fontWeight: FontWeight.w100,
                fontSize: 14,
              )),
        Expanded(
          child: SizedBox(),
        ),
      ]),
      content: Column(children: [
        if (!context.isLandscapePhone)
          Text(score.name,
              style: TextStyle(
                  color: musicForegroundColor,
                  fontWeight: FontWeight.w100,
                  fontSize: 14)),
        Expanded(
            child: SingleChildScrollView(
          child: ScorePreview(score,
              scale: context.isLandscapePhone ? 0.13 : 0.3,
              width: previewWidth,
              height: previewHeight,
              notifyUpdate: BSMethod()),
        )),
        UniverseUploadWidget(
          score: score,
          universeManager: universeManager,
          onDoDuplicate: onDoDuplicate,
        )
      ]),
      // actions: <Widget>[
      //   MyFlatButton(
      //     color: sectionColor,
      //     onPressed: () => Navigator.of(context).pop(true),
      //     child: Text('OK'),
      //   ),
      // ],
    ),
  );
}

class UniverseUploadWidget extends StatefulWidget {
  final Score score;
  final UniverseManager universeManager;
  final BSMethod onDoDuplicate;

  const UniverseUploadWidget(
      {Key key, this.score, this.universeManager, this.onDoDuplicate})
      : super(key: key);

  @override
  _UniverseUploadWidgetState createState() => _UniverseUploadWidgetState();
}

class _UniverseUploadWidgetState extends State<UniverseUploadWidget> {
  bool didFindDuplicate;
  @override
  void initState() {
    super.initState();
    didFindDuplicate = null;
    widget.universeManager
        .findDuplicate(widget.score.name)
        .then((value) => setState(() {
              didFindDuplicate = value;
            }));
  }

  @override
  Widget build(BuildContext context) {
    double uploadButtonWidth = context.isPortraitPhone ? 80 : 100;
    double detailTextHeight = context.isPortraitPhone ? 96 : 48;
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              IgnorePointer(
                  ignoring: didFindDuplicate != true,
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: didFindDuplicate == true ? 1 : 0,
                    child: Container(
                        height: detailTextHeight,
                        child: SingleChildScrollView(
                            child: RichText(
                          text: TextSpan(
                            text: 'A Score named "',
                            style: TextStyle(
                                color: musicBackgroundColor == Colors.white
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w200,
                                fontFamily: DefaultTextStyle.of(context)
                                    .style
                                    .fontFamily),
                            children: <TextSpan>[
                              TextSpan(
                                  text: widget.score.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          musicBackgroundColor == Colors.white
                                              ? chromaticSteps[11]
                                              : chromaticSteps[5])),
                              TextSpan(
                                  text:
                                      '" has already been uploaded to the Universe. '),
                              TextSpan(text: 'Please '),
                              TextSpan(
                                  text: 'Duplicate',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' it to upload. '),
                              TextSpan(
                                  text:
                                      'Inappropriate, spammy, duplicate, or useless content may be moderated.',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ))),
                  )),
              IgnorePointer(
                  ignoring: didFindDuplicate != false,
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: didFindDuplicate == false ? 1 : 0,
                    child: Container(
                      height: detailTextHeight,
                      child: SingleChildScrollView(
                        child: RichText(
                          text: TextSpan(
                            text: 'The Score "',
                            style: TextStyle(
                                color: musicBackgroundColor == Colors.white
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w200,
                                fontFamily: DefaultTextStyle.of(context)
                                    .style
                                    .fontFamily),
                            children: <TextSpan>[
                              TextSpan(
                                  text: widget.score.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          musicBackgroundColor == Colors.white
                                              ? chromaticSteps[3]
                                              : chromaticSteps[0])),
                              TextSpan(
                                  text:
                                      '" is ready to upload to the Universe. '),
                              TextSpan(
                                  text:
                                      'Inappropriate, spammy, duplicate, or useless content may be moderated.',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(width: 5),
        Stack(
          children: [
            AnimatedOpacity(
                duration: animationDuration,
                opacity: didFindDuplicate == null ? 1 : 0,
                child: Container(
                    width: uploadButtonWidth,
                    child: Text("Preparing...",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: musicForegroundColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w100)))),
            IgnorePointer(
                ignoring: didFindDuplicate != false,
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: didFindDuplicate == false ? 1 : 0,
                    child: Container(
                        width: uploadButtonWidth,
                        child: MyFlatButton(
                          padding: EdgeInsets.all(5),
                          color: chromaticSteps[0],
                          onPressed: () {
                            widget.universeManager.submitScore(widget.score);
                            Navigator.pop(context);
                          },
                          child: Text("Upload"),
                        )))),
            IgnorePointer(
              ignoring: didFindDuplicate != true,
              child: AnimatedOpacity(
                  duration: animationDuration,
                  opacity: didFindDuplicate == true ? 1 : 0,
                  child: Container(
                      width: uploadButtonWidth,
                      child: MyFlatButton(
                        color: chromaticSteps[5],
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDoDuplicate();
                        },
                        child: Text("Duplicate"),
                      ))),
            ),
          ],
        ),
      ],
    );
  }
}
