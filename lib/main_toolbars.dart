import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:beatscratch_flutter_redux/export/export.dart';
import 'package:beatscratch_flutter_redux/storage/score_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'beatscratch_plugin.dart';
import 'cache_management.dart';
import 'colors.dart';
import 'generated/protos/music.pb.dart';
import 'messages/messages_ui.dart';
import 'widget/my_buttons.dart';
import 'widget/my_platform.dart';
import 'widget/my_popup_menu.dart';
import 'storage/score_picker.dart';
import 'ui_models.dart';
import 'storage/url_conversions.dart';
import 'util/music_theory.dart';
import 'util/util.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BeatScratchToolbar extends StatefulWidget {
  static final bool enableUniverse = MyPlatform.isDebug;
  final Score score;
  final Section currentSection;
  final ScoreManager scoreManager;
  final Function(ScorePickerMode) showScorePicker;
  final VoidCallback viewMode;
  final VoidCallback universeMode;
  final VoidCallback editMode;
  final VoidCallback toggleViewOptions;
  final VoidCallback togglePlaying;
  final VoidCallback toggleSectionListDisplayMode;
  final InteractionMode interactionMode;
  final Color sectionColor;
  final RenderingMode renderingMode;
  final Function(RenderingMode) setRenderingMode;
  final VoidCallback showMidiInputSettings;
  final bool showBeatCounts;
  final VoidCallback toggleShowBeatCounts;
  final VoidCallback saveCurrentScore;
  final String currentScoreName;
  final VoidCallback pasteScore;
  final VoidCallback export;
  final Function(String) routeToCurrentScore;
  final bool vertical;
  final bool verticalSections;
  final Melody openMelody;
  final Melody prevMelody;
  final Part openPart;
  final Part prevPart;
  final bool isMelodyViewOpen;
  final bool leftHalfOnly;
  final bool rightHalfOnly;
  final MessagesUI messagesUI;
  final bool showDownloads;
  final VoidCallback toggleShowDownloads;

  const BeatScratchToolbar(
      {Key key,
      @required this.interactionMode,
      @required this.viewMode,
      @required this.universeMode,
      @required this.editMode,
      @required this.toggleViewOptions,
      @required this.sectionColor,
      @required this.togglePlaying,
      @required this.toggleSectionListDisplayMode,
      @required this.setRenderingMode,
      @required this.renderingMode,
      @required this.showMidiInputSettings,
      @required this.showBeatCounts,
      @required this.toggleShowBeatCounts,
      @required this.showScorePicker,
      @required this.saveCurrentScore,
      @required this.currentScoreName,
      @required this.score,
      @required this.pasteScore,
      @required this.export,
      @required this.scoreManager,
      @required this.routeToCurrentScore,
      @required this.vertical,
      @required this.verticalSections,
      @required this.openMelody,
      @required this.prevMelody,
      @required this.openPart,
      @required this.prevPart,
      @required this.isMelodyViewOpen,
      @required this.currentSection,
      @required this.leftHalfOnly,
      @required this.rightHalfOnly,
      this.messagesUI,
      this.showDownloads,
      this.toggleShowDownloads})
      : super(key: key);

  @override
  _BeatScratchToolbarState createState() => _BeatScratchToolbarState();
}

class _BeatScratchToolbarState extends State<BeatScratchToolbar>
    with TickerProviderStateMixin {
//  FilePickerCross filePicker = FilePickerCross(type: FileTypeCross.custom, fileExtension: "beatscratch");
//  FilePicker asdf = FilePicker();
//   final clipboardContentStream = StreamController<String>.broadcast();

  // Timer clipboardTriggerTime;

  AnimationController sectionOrPlayController;
  Animation<double> sectionOrPlayRotation;
  AnimationController editController;
  Animation<double> editRotation;
  Animation<double> editTranslation;
  Animation<double> editScale;
  AnimationController editRotationOnlyController;
  Animation<double> editRotationOnlyRotation;
  PackageInfo packageInfo;

  bool get hasMelody => widget.openMelody != null || widget.prevMelody != null;
  bool get hasPart =>
      !hasMelody && widget.openPart != null || widget.prevPart != null;
  bool get hasDrumPart =>
      hasPart && (widget.openPart?.isDrum ?? widget.prevPart?.isDrum ?? false);

  @override
  void initState() {
    super.initState();
    sectionOrPlayController = AnimationController(
      // animationBehavior: AnimationBehavior.preserve,
      duration: animationDuration,
      vsync: this,
    )..repeat(reverse: true);
    sectionOrPlayRotation = Tween<double>(
      begin: 0,
      end: 0.5 * pi,
    ).animate(sectionOrPlayController);

    editController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    editRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(editController);

    Future.microtask(() async {
      print("getting PackageInfo");
      final info = await PackageInfo.fromPlatform();
      print("got PackageInfo!!!!");
      setState(() {
        packageInfo = info;
      });
    });

    editTranslation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(editController);

    editScale = Tween<double>(
      begin: 1,
      end: 0.8,
    ).animate(editController);

    editRotationOnlyController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    editRotationOnlyRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(editRotationOnlyController);

    // editController.repeat();
    // _controller.forward();

    // clipboardTriggerTime = Timer.periodic(
    //   // you can specify any duration you want, roughly every 20 read from the system
    //   const Duration(seconds: 5),
    //     (timer) {
    //     Clipboard.getData(Clipboard.kTextPlain).then((clipboardContent) {
    //       print('Clipboard content ${clipboardContent.text}');
    //
    //       // post to a Stream you're subscribed to
    //       clipboardContentStream.add(clipboardContent.text);
    //     });
    //   },
    // );
  }
  // Stream get clipboardText => clipboardContentStream.stream;

  @override
  void dispose() {
    sectionOrPlayController.dispose();
    editRotationOnlyController.dispose();
    editController.dispose();
    super.dispose();
    // clipboardContentStream.close();
    // clipboardTriggerTime.cancel();
  }

  Widget columnOrRow(BuildContext context, {List<Widget> children}) {
    if (widget.vertical) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.interactionMode.isEdit || widget.verticalSections) {
      sectionOrPlayController.reverse();
    } else {
      sectionOrPlayController.forward();
    }
    if (!widget.interactionMode.isEdit) {
      editController.reverse();
    } else {
      editController.forward();
    }
    if (widget.interactionMode == InteractionMode.edit &&
        !widget.isMelodyViewOpen) {
      editRotationOnlyController.reverse();
    } else {
      editRotationOnlyController.forward();
    }
    return Container(
        height: widget.vertical ? null : 48,
        width: widget.vertical ? 48 : null,
        child: columnOrRow(context, children: [
          if (!widget.rightHalfOnly)
            Expanded(
                child: MyPopupMenuButton(
//                        onPressed: _doNothing,
                    tooltip: null,
                    offset: Offset(0, MediaQuery.of(context).size.height),
                    onSelected: (value) {
                      switch (value) {
                        case "create":
                          widget.saveCurrentScore();
                          ScoreManager.suggestScoreName("");
                          widget.showScorePicker(ScorePickerMode.create);
                          break;
                        case "open":
                          widget.saveCurrentScore();
                          widget.showScorePicker(ScorePickerMode.open);
                          break;
                        case "duplicate":
                          widget.saveCurrentScore();
                          ScoreManager.suggestScoreName(
                              widget.scoreManager.currentScoreName);
                          widget.showScorePicker(ScorePickerMode.duplicate);
                          break;
                        case "save":
                          widget.saveCurrentScore();
                          break;
                        case "import":
                          print("Showing file picker");
//                        filePicker.pick().then((value) {
////                          filePicker.
//                        });
                          break;
//                      case "duplicate":
//                        if(Platform.isMacOS) {
//                          print("Showing save panel");
//                          showSavePanel(
//                            allowedFileTypes: [FileTypeFilterGroup(label: "BeatScratch Score", fileExtensions: ["beatscratch"])]
//                          );
////                          FileChooserChannelController.instance.
//                        } else {
//                          print("This shouldn't be happening");
//                        }
//                        break;
                        case "chooseBeatscratchFolder":
                          break;
                        case "notationUi":
                          widget.setRenderingMode(RenderingMode.notation);
                          break;
                        case "colorblockUi":
                          widget.setRenderingMode(RenderingMode.colorblock);
                          break;
                        case "midiSettings":
                          widget.showMidiInputSettings();
                          break;
                        case "showBeatCounts":
                          widget.toggleShowBeatCounts();
                          break;
                        case "clearMutableCaches":
                          clearMutableCaches();
                          break;
                        case "copyScore":
                          Future.microtask(() async {
                            widget.score.name =
                                widget.scoreManager.currentScoreName;
                            widget.messagesUI.sendMessage(
                                message:
                                    "Generating short URL via https://paste.ee...",
                                andSetState: true);
                            final String urlString =
                                (await widget.score.convertToShortUrl()) ??
                                    widget.score.convertToUrl();
                            if (!urlString.contains("#/s/")) {
                              widget.messagesUI.sendMessage(
                                  message:
                                      "Failed to shorten URL via https://paste.ee! Creating long-form Score Link...",
                                  andSetState: true,
                                  isError: true,
                                  color: chromaticSteps[5]);
                            }
                            String pastebinCode = urlString.split('/').last;
                            Clipboard.setData(ClipboardData(text: urlString));
                            widget.messagesUI.sendMessage(
                              message: "Copied Score Link: $urlString",
                              andSetState: true,
                            );
                            if (MyPlatform.isWeb) {
                              widget.routeToCurrentScore(pastebinCode);
                            }
                          });
                          break;
                        case "pasteScore":
                          widget.pasteScore();
                          break;
                        case "export":
                          widget.export();
                          break;
                        case "tutorial":
                          break;
                        case "feedback":
                          launchURL(
                              "https://github.com/falrm/falrm.github.io/issues");
                          break;
                        case "about":
                          launchURL("https://beatscratch.io/about.html");
                          break;
                        case "downloadNative":
                          widget.toggleShowDownloads();
                          break;
                      }
                      //setState(() {});
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        MyPopupMenuItem(
                          value: null,
                          child: Column(children: [
                            Row(children: [
                              Text('Beat',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26)),
                              Text('Scratch',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w100,
                                      fontSize: 26)),
                              Expanded(
                                child: SizedBox(),
                              ),
                              if (packageInfo?.version != null)
                                Text('v${packageInfo?.version}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10)),
                              if (packageInfo?.version != null)
                                SizedBox(width: 3),
                              if (packageInfo?.version != null)
                                Text('(${packageInfo?.buildNumber})',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w100,
                                        fontSize: 10)),
                              if (packageInfo?.version == null)
                                Text('(build ${packageInfo?.buildNumber})',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w100,
                                        fontSize: 10)),
                            ]),
                            if (MyPlatform.isWeb)
                              Text('Web Preview',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12)),
                            if (MyPlatform.isWeb)
                              Text(
                                  'Native app strongly recommended for performance and features like recording, file storage, and MIDI export.',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12)),
                          ]),
                          enabled: false,
                        ),
                        if (MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "downloadNative",
                            child: Row(children: [
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(widget.showDownloads
                                      ? Icons.close
                                      : Icons.download_rounded)),
                              Expanded(child: SizedBox()),
                              Text(widget.showDownloads
                                  ? 'Hide Download Links'
                                  : 'Download Native App'),
                              Expanded(child: SizedBox()),
                            ]),
                            enabled: MyPlatform.isWeb,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: null,
                            child: Column(children: [
                              Text(widget.currentScoreName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18)),
                            ]),
                            enabled: false,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "create",
                            child: Row(children: [
                              Expanded(child: Text('Create Score...')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.add))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "open",
                            child: Row(children: [
                              Expanded(child: Text('Open Score...')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.folder_open))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "duplicate",
                            child: Row(children: [
                              Expanded(child: Text('Duplicate Score...')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.control_point_duplicate))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "save",
                            child: Row(children: [
                              Expanded(child: Text('Save Score')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.save))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        MyPopupMenuItem(
                          value: "copyScore",
                          child: Row(children: [
                            Expanded(
                                child: Text(MyPlatform.isWeb
                                    ? 'Copy/Update Score Link'
                                    : 'Copy Score Link')),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.content_copy))
                          ]),
                          enabled: true,
                        ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "pasteScore",
                            child: Row(children: [
                              Expanded(child: Text('Paste Score Link')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.content_paste))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "export",
                            enabled: MyPlatform.isNative,
                            child: Row(children: [
                              Expanded(child: Text('Export...')),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: ExportUI.exportIcon())
                            ]),
                          ),
//                    if(interactionMode == InteractionMode.edit) MyPopupMenuItem(
//                          value: "showBeatCounts",
//                          child: Row(children: [
//                            Checkbox(value: showBeatCounts, onChanged: null),
//                            Expanded(child: Text('Show Section Beat Counts'))
//                          ]),
//                        ),
                        if (kDebugMode)
                          const MyPopupMenuItem(
                            value: "clearMutableCaches",
                            child: Text('Debug: Clear Rendering Caches'),
                          ),
                        MyPopupMenuItem(
                          value: "midiSettings",
                          child: Row(children: [
                            Expanded(child: Text('Settings...')),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.settings))
                          ]),
                        ),
                        MyPopupMenuItem(
                          value: "tutorial",
                          enabled: false,
                          child: Row(children: [
                            Expanded(child: Text('Help/Tutorial')),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.help))
                          ]),
                        ),
                        MyPopupMenuItem(
                          value: "feedback",
                          enabled: true,
                          child: Row(children: [
                            Expanded(child: Text('Feedback')),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Stack(
                                  children: [
                                    Transform.translate(
                                      offset: Offset(-6, -6),
                                      child: Transform.scale(
                                        scale: 0.8,
                                        child: Icon(FontAwesomeIcons.smile),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(6, 6),
                                      child: Transform.scale(
                                          scale: 0.8,
                                          child:
                                              Icon(FontAwesomeIcons.sadTear)),
                                    ),
                                  ],
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(FontAwesomeIcons.github))
                          ]),
                        ),

                        MyPopupMenuItem(
                          value: "about",
                          enabled: true,
                          child: Row(children: [
                            Expanded(child: Text('About BeatScratch')),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.info_outline))
                          ]),
                        ),
                      ];
                    },
                    padding: EdgeInsets.only(bottom: 10.0),
                    icon: Image.asset('assets/logo.png'))),
          if (!widget.rightHalfOnly)
            Expanded(
                child: MyFlatButton(
                    onPressed: (!widget.interactionMode.isEdit)
                        ? (BeatScratchPlugin.supportsPlayback
                            ? () {
                                widget.togglePlaying();
                              }
                            : null)
                        : () {
                            widget.toggleSectionListDisplayMode();
                          },
                    padding: EdgeInsets.all(0.0),
                    child: AnimatedBuilder(
                        animation: sectionOrPlayController,
                        builder: (_, child) => Transform(
                            transform:
                                Matrix4.rotationZ(sectionOrPlayRotation.value),
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                AnimatedOpacity(
                                    duration: animationDuration,
                                    opacity: widget.interactionMode ==
                                            InteractionMode.edit
                                        ? 1
                                        : 0,
                                    child: Icon(Icons.menu,
                                        color: widget.sectionColor)),
                                AnimatedOpacity(
                                    duration: animationDuration,
                                    opacity: !widget.interactionMode.isEdit &&
                                            !BeatScratchPlugin.playing
                                        ? 1
                                        : 0,
                                    child: Icon(Icons.play_arrow,
                                        color:
                                            (!widget.interactionMode.isEdit &&
                                                    !BeatScratchPlugin
                                                        .supportsPlayback)
                                                ? Colors.grey
                                                : widget.sectionColor)),
                                AnimatedOpacity(
                                    duration: animationDuration,
                                    opacity: !widget.interactionMode.isEdit &&
                                            BeatScratchPlugin.playing
                                        ? 1
                                        : 0,
                                    child: Icon(Icons.pause,
                                        color: widget.sectionColor)),
                                // (widget.interactionMode == InteractionMode.view)
                                //   ? (BeatScratchPlugin.playing ? Icons.pause : Icons.play_arrow)
                                //   : Icons.menu,
                              ],
                            ))))),
          if (!widget.leftHalfOnly && BeatScratchToolbar.enableUniverse)
            Expanded(
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: (widget.interactionMode == InteractionMode.universe)
                        ? widget.sectionColor
                        : Colors.transparent,
                    child: MyFlatButton(
                        onPressed: widget.universeMode,
                        onLongPress: widget.universeMode,
                        padding: EdgeInsets.all(0.0),
                        child: Icon(FontAwesomeIcons.globe,
                            color: (widget.interactionMode ==
                                    InteractionMode.universe)
                                ? Colors.white
                                : widget.sectionColor)))),
          if (!widget.leftHalfOnly)
            Expanded(
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: (widget.interactionMode == InteractionMode.view)
                        ? widget.sectionColor
                        : Colors.transparent,
                    child: MyFlatButton(
                        onPressed:
                            (widget.interactionMode == InteractionMode.view)
                                ? widget.toggleViewOptions
                                : widget.viewMode,
                        onLongPress: widget.toggleViewOptions,
                        padding: EdgeInsets.all(0.0),
                        child: Icon(Icons.remove_red_eye,
                            color:
                                (widget.interactionMode == InteractionMode.view)
                                    ? Colors.white
                                    : widget.sectionColor)))),
          if (!widget.leftHalfOnly)
            Expanded(
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: (widget.interactionMode.isEdit)
                        ? hasMelody
                            ? melodyColor
                            : hasPart
                                ? (hasDrumPart ? Colors.brown : Colors.grey)
                                : widget.sectionColor
                        : Colors.transparent,
                    child: MyFlatButton(
                        onPressed: widget.editMode,
                        padding: EdgeInsets.all(0.0),
                        child: Stack(
                          children: [
                            Align(
                                alignment: Alignment.center,
                                child: AnimatedBuilder(
                                    animation: editController,
                                    builder: (_, child) => Transform(
                                        transform: Matrix4.translationValues(
                                            0,
                                            -(widget.vertical ? 2 : 1) *
                                                editTranslation.value,
                                            0),
                                        alignment: Alignment.center,
                                        child: AnimatedBuilder(
                                            animation:
                                                editRotationOnlyController,
                                            builder: (_, child) => Transform(
                                                  transform: Matrix4.rotationZ(
                                                      editRotationOnlyRotation
                                                          .value),
                                                  alignment: Alignment.center,
                                                  child: Transform(
                                                      transform:
                                                          Matrix4.rotationZ(
                                                              editRotation
                                                                  .value),
                                                      alignment:
                                                          Alignment.center,
                                                      child: ScaleTransition(
                                                        scale: editScale,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Stack(
                                                          children: [
                                                            AnimatedOpacity(
                                                              duration:
                                                                  animationDuration,
                                                              opacity: !widget
                                                                          .interactionMode
                                                                          .isEdit ||
                                                                      !widget
                                                                          .isMelodyViewOpen
                                                                  ? 1
                                                                  : 0,
                                                              child: Icon(
                                                                  Icons.edit,
                                                                  color: (widget
                                                                          .interactionMode
                                                                          .isEdit)
                                                                      ? hasMelody
                                                                          ? Colors
                                                                              .black
                                                                          : Colors
                                                                              .white
                                                                      : widget
                                                                          .sectionColor),
                                                            ),
                                                            AnimatedOpacity(
                                                              duration:
                                                                  animationDuration,
                                                              opacity: widget
                                                                          .interactionMode
                                                                          .isEdit &&
                                                                      widget
                                                                          .isMelodyViewOpen
                                                                  ? 1
                                                                  : 0,
                                                              child: Icon(
                                                                  Icons.close,
                                                                  color: (widget
                                                                          .interactionMode
                                                                          .isEdit)
                                                                      ? hasMelody
                                                                          ? Colors
                                                                              .black
                                                                          : Colors
                                                                              .white
                                                                      : widget
                                                                          .sectionColor),
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ))))),
                            Transform.translate(
                              offset: Offset(0, 8),
                              child: AnimatedOpacity(
                                  duration: animationDuration,
                                  opacity: widget.interactionMode ==
                                          InteractionMode.edit
                                      ? 1
                                      : 0,
                                  child: Row(
                                    children: [
                                      Expanded(child: SizedBox()),
                                      Column(
                                        children: [
                                          Expanded(child: SizedBox()),
                                          Container(
                                            width: widget.vertical ? 44 : 60,
                                            child: Text(
                                                widget.openMelody != null
                                                    ? widget.openMelody
                                                        .canonicalName
                                                    : widget.openPart != null
                                                        ? widget
                                                            .openPart.midiName
                                                        : widget.isMelodyViewOpen ||
                                                                (widget.prevPart ==
                                                                        null &&
                                                                    widget.prevMelody ==
                                                                        null)
                                                            ? widget
                                                                .currentSection
                                                                .canonicalName
                                                            : widget.prevMelody !=
                                                                    null
                                                                ? widget
                                                                    .prevMelody
                                                                    .canonicalName
                                                                : widget.prevPart !=
                                                                        null
                                                                    ? widget
                                                                        .prevPart
                                                                        .midiName
                                                                    : "Oops",
                                                textAlign: TextAlign.center,
                                                maxLines:
                                                    widget.vertical ? 2 : 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: hasMelody
                                                        ? Colors.black
                                                        : Colors.white,
                                                    fontWeight: widget.openMelody !=
                                                                null ||
                                                            widget.prevMelody !=
                                                                null
                                                        ? FontWeight.w500
                                                        : widget.openPart != null ||
                                                                widget.prevPart !=
                                                                    null
                                                            ? FontWeight.w800
                                                            : FontWeight.w200)),
                                          ),
                                          Expanded(child: SizedBox()),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                    ],
                                  )),
                            )
                          ],
                        ))))
        ]));
  }

  showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About BeatScratch'),
        content: Column(children: [
          Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text("Icons provided by:")),
          Row(children: [
            Image.asset(
              "assets/piano.png",
              width: 24,
              height: 24,
            ),
            Text("Piano by André Luiz Gollo from the Noun Project")
          ]),
        ]),
        actions: <Widget>[
          MyFlatButton(
            color: widget.sectionColor,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class SecondToolbar extends StatelessWidget {
  final VoidCallback toggleKeyboard;
  final VoidCallback toggleColorboard;
  final VoidCallback toggleKeyboardConfiguration;
  final VoidCallback toggleColorboardConfiguration;
  final VoidCallback toggleTempoConfiguration;
  final VoidCallback tempoLongPress;
  final VoidCallback rewind;
  final bool recordingMelody;
  final bool showKeyboard;
  final bool showKeyboardConfiguration;
  final bool showColorboard;
  final bool showColorboardConfiguration;
  final bool showTempoConfiguration;
  final InteractionMode interactionMode;
  final bool showViewOptions;
  final Color sectionColor;
  final bool enableColorboard;
  final bool vertical;
  final bool visible;

  const SecondToolbar({
    Key key,
    this.toggleKeyboard,
    this.toggleColorboard,
    this.showKeyboard,
    this.showColorboard,
    this.interactionMode,
    this.showViewOptions,
    this.showKeyboardConfiguration,
    this.showColorboardConfiguration,
    this.toggleKeyboardConfiguration,
    this.toggleColorboardConfiguration,
    this.sectionColor,
    this.enableColorboard,
    this.recordingMelody,
    this.toggleTempoConfiguration,
    this.showTempoConfiguration,
    this.vertical,
    this.visible,
    this.tempoLongPress,
    this.rewind,
  }) : super(key: key);

  Widget columnOrRow(BuildContext context, {List<Widget> children}) {
    if (vertical) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }

  @override
  Widget build(BuildContext context) {
    var totalSpace = vertical
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey && !vertical) {
      totalSpace = totalSpace / 2;
    }
    bool editMode = interactionMode == InteractionMode.edit;
    int numberOfButtons = editMode ? 4 : 3;
    if (enableColorboard) {
      numberOfButtons += 1;
    }
    Widget createPlayIcon(IconData icon,
        {bool visible, Color color = Colors.black}) {
      return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: animationDuration,
          child: Transform.scale(
              scale: 0.8, child: Icon(icon, color: color, size: 32)));
    }

    return columnOrRow(context, children: [
      AnimatedContainer(
          height: !vertical
              ? null
              : editMode
                  ? totalSpace / numberOfButtons
                  : 0,
          width: vertical
              ? null
              : editMode
                  ? totalSpace / numberOfButtons
                  : 0,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: MyRaisedButton(
                  padding: EdgeInsets.zero,
                  child: Stack(children: [
                    createPlayIcon(Icons.play_arrow,
                        visible: editMode &&
                            !BeatScratchPlugin.playing &&
                            !recordingMelody),
                    createPlayIcon(Icons.pause,
                        visible: editMode && BeatScratchPlugin.playing),
                    createPlayIcon(Icons.fiber_manual_record,
                        visible: editMode &&
                            !BeatScratchPlugin.playing &&
                            recordingMelody,
                        color: chromaticSteps[7]),
                    AnimatedOpacity(
                        opacity: editMode &&
                                BeatScratchPlugin.playing &&
                                recordingMelody
                            ? 0.6
                            : 0,
                        duration: animationDuration,
                        child: Transform.translate(
                            offset: Offset(12, 6),
                            child: Transform.scale(
                                scale: 0.5,
                                child: Icon(Icons.fiber_manual_record,
                                    color: chromaticSteps[7], size: 32)))),
                  ]),
                  onPressed: BeatScratchPlugin.supportsPlayback
                      ? () {
                          if (BeatScratchPlugin.playing) {
                            BeatScratchPlugin.pause();
                          } else {
                            BeatScratchPlugin.play();
                          }
                        }
                      : null))),
      AnimatedContainer(
          height: !vertical ? null : totalSpace / numberOfButtons,
          width: vertical ? null : totalSpace / numberOfButtons,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: MyRaisedButton(
                  padding: EdgeInsets.zero,
                  child: AnimatedOpacity(
                      opacity: visible ? 1 : 0,
                      duration: animationDuration,
                      child: Align(
                          alignment: Alignment.center,
                          child: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.skip_previous, size: 32)))),
                  onPressed:
                      BeatScratchPlugin.supportsPlayback ? rewind : null))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: MyRaisedButton(
                padding: EdgeInsets.zero,
                child: Stack(children: [
                  Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                        scale: 0.8,
                        child: Opacity(
                            opacity: 0.5,
                            child: Image.asset('assets/metronome.png'))),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: EdgeInsets.only(right: 3.5),
                        child: Text(
                            (BeatScratchPlugin.unmultipliedBpm *
                                    BeatScratchPlugin.bpmMultiplier)
                                .toStringAsFixed(0),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(fontSize: 16))),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                        padding: EdgeInsets.only(left: 10.5),
                        child: Text(
                            BeatScratchPlugin.unmultipliedBpm
                                .toStringAsFixed(0),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                                fontWeight: FontWeight.w200,
                                fontSize: 12,
                                fontStyle: FontStyle.normal))),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                        padding: EdgeInsets.only(left: 3.5),
                        child: Text(
                            "x${BeatScratchPlugin.bpmMultiplier.toStringAsPrecision(3)}",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ))),
                  )
                ]),
                onPressed: toggleTempoConfiguration,
                onLongPress: tempoLongPress,
                color: (showTempoConfiguration) ? Colors.white : Colors.grey,
              ))),
      AnimatedContainer(
          height: !vertical
              ? null
              : (enableColorboard)
                  ? totalSpace / numberOfButtons
                  : 0,
          width: vertical
              ? null
              : (enableColorboard)
                  ? totalSpace / numberOfButtons
                  : 0,
          duration: animationDuration,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: MyRaisedButton(
                child: AnimatedOpacity(
                    duration: animationDuration,
                    opacity: toggleColorboard != null ? 1 : 0.25,
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.scale(
                          scale: vertical
                              ? MyPlatform.isMacOS || MyPlatform.isWeb
                                  ? 0.8
                                  : 2.5
                              : 0.8,
                          child: Image.asset('assets/colorboard.png')),
                    )),
                onPressed: toggleColorboard,
                onLongPress: toggleColorboardConfiguration,
                color: (showColorboardConfiguration)
                    ? sectionColor
                    : (showColorboard)
                        ? Colors.white
                        : Colors.grey,
              ))),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: MyRaisedButton(
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                      scale: vertical
                          ? MyPlatform.isMacOS || MyPlatform.isWeb
                              ? 0.8
                              : 2.5
                          : 0.8,
                      child: Image.asset('assets/piano.png')),
                ),
                onPressed: toggleKeyboard,
                onLongPress: toggleKeyboardConfiguration,
                color: (showKeyboardConfiguration)
                    ? sectionColor
                    : (showKeyboard)
                        ? Colors.white
                        : Colors.grey,
              ))),
    ]);
  }
}
