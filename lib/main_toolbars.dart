import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'beatscratch_plugin.dart';
import 'cache_management.dart';
import 'colors.dart';
import 'export/export.dart';
import 'generated/protos/music.pb.dart';
import 'messages/messages_ui.dart';
import 'settings/app_settings.dart';
import 'storage/score_manager.dart';
import 'storage/score_picker.dart';
import 'storage/url_conversions.dart';
import 'ui_models.dart';
import 'util/music_theory.dart';
import 'util/util.dart';
import 'widget/my_buttons.dart';
import 'widget/my_platform.dart';
import 'widget/my_popup_menu.dart';

class BeatScratchToolbar extends StatefulWidget {
  final AppSettings appSettings;
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
  final bool savingScore;

  const BeatScratchToolbar(
      {Key key,
      @required this.appSettings,
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
      @required this.savingScore, // BeatScratchPlugin.isSynthesizerAvailable
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
        color: subBackgroundColor.withOpacity(0.5),
        child: columnOrRow(context, children: [
          if (!widget.rightHalfOnly)
            Expanded(
                child: MyPopupMenuButton(
//                        onPressed: _doNothing,
                    tooltip: null,
                    color: musicBackgroundColor.luminance < 0.5
                        ? subBackgroundColor
                        : musicBackgroundColor,
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
                            String urlString;
                            if (widget.appSettings.integratePastee) {
                              widget.messagesUI.sendMessage(
                                  message:
                                      "Generating short URL via https://paste.ee...",
                                  andSetState: true);
                              urlString =
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
                            } else {
                              urlString = widget.score.convertToUrl();
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
                                      color:
                                          musicForegroundColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26)),
                              Text('Scratch',
                                  style: TextStyle(
                                      color:
                                          musicForegroundColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w100,
                                      fontSize: 26)),
                              Expanded(
                                child: SizedBox(),
                              ),
                              if (packageInfo?.version != null)
                                Text('v${packageInfo?.version}',
                                    style: TextStyle(
                                        color: musicForegroundColor
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10)),
                              if (packageInfo?.version != null)
                                SizedBox(width: 3),
                              if (packageInfo?.version != null)
                                Text('(${packageInfo?.buildNumber})',
                                    style: TextStyle(
                                        color: musicForegroundColor
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w100,
                                        fontSize: 10)),
                              if (packageInfo?.version == null)
                                Text('(build ${packageInfo?.buildNumber})',
                                    style: TextStyle(
                                        color: musicForegroundColor
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w100,
                                        fontSize: 10)),
                            ]),
                            if (MyPlatform.isWeb)
                              Text('Web Preview',
                                  style: TextStyle(
                                      color:
                                          musicForegroundColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12)),
                            if (MyPlatform.isWeb)
                              Text(
                                  'Native app strongly recommended for performance and features like recording, file storage, and MIDI export.',
                                  style: TextStyle(
                                      color:
                                          musicForegroundColor.withOpacity(0.5),
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
                                  child: Icon(
                                    widget.showDownloads
                                        ? Icons.close
                                        : Icons.download_rounded,
                                    color: musicForegroundColor,
                                  )),
                              Expanded(child: SizedBox()),
                              Text(
                                  widget.showDownloads
                                      ? 'Hide Download Links'
                                      : 'Download Native App',
                                  style: TextStyle(
                                    color: musicForegroundColor,
                                  )),
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
                                      color:
                                          musicForegroundColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 18)),
                            ]),
                            enabled: false,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "create",
                            child: Row(children: [
                              Expanded(
                                  child: Text('Create Score...',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(
                                    Icons.add,
                                    color: musicForegroundColor,
                                  ))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "open",
                            child: Row(children: [
                              Expanded(
                                  child: Text('Open Score...',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.folder_open,
                                      color: musicForegroundColor))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "duplicate",
                            child: Row(children: [
                              Expanded(
                                  child: Text('Duplicate Score...',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(FontAwesomeIcons.codeBranch,
                                      color: musicForegroundColor))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "save",
                            child: Row(children: [
                              Expanded(
                                  child: Text('Save Score',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.save,
                                      color: musicForegroundColor))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        MyPopupMenuItem(
                          value: "copyScore",
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    MyPlatform.isWeb
                                        ? 'Copy/Update Score Link'
                                        : 'Copy Score Link',
                                    style: TextStyle(
                                      color: musicForegroundColor,
                                    ))),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.content_copy,
                                    color: musicForegroundColor))
                          ]),
                          enabled: true,
                        ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "pasteScore",
                            child: Row(children: [
                              Expanded(
                                  child: Text('Paste Score Link',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.content_paste,
                                      color: musicForegroundColor))
                            ]),
                            enabled: BeatScratchPlugin.supportsStorage,
                          ),
                        if (!MyPlatform.isWeb)
                          MyPopupMenuItem(
                            value: "export",
                            enabled: MyPlatform.isNative,
                            child: Row(children: [
                              Expanded(
                                  child: Text('Export...',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: ExportUI.exportIcon(
                                      color: musicForegroundColor))
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
                          MyPopupMenuItem(
                            value: "clearMutableCaches",
                            child: Text('Debug: Clear Rendering Caches',
                                style: TextStyle(
                                  color: musicForegroundColor,
                                )),
                          ),
                        MyPopupMenuItem(
                          value: "midiSettings",
                          child: Row(children: [
                            Expanded(
                                child: Text('Settings...',
                                    style: TextStyle(
                                      color: musicForegroundColor,
                                    ))),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.settings,
                                    color: musicForegroundColor))
                          ]),
                        ),
                        if (MyPlatform.isDebug)
                          MyPopupMenuItem(
                            value: "tutorial",
                            enabled: false,
                            child: Row(children: [
                              Expanded(
                                  child: Text('Help/Tutorial',
                                      style: TextStyle(
                                        color: musicForegroundColor
                                            .withOpacity(0.5),
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.help,
                                      color: musicForegroundColor))
                            ]),
                          ),
                        MyPopupMenuItem(
                          value: "feedback",
                          enabled: true,
                          child: Row(children: [
                            Expanded(
                                child: Text('Feedback',
                                    style: TextStyle(
                                      color: musicForegroundColor,
                                    ))),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Stack(
                                  children: [
                                    Transform.translate(
                                      offset: Offset(-6, -6),
                                      child: Transform.scale(
                                        scale: 0.8,
                                        child: Icon(FontAwesomeIcons.smile,
                                            color: musicForegroundColor),
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: Offset(6, 6),
                                      child: Transform.scale(
                                          scale: 0.8,
                                          child: Icon(FontAwesomeIcons.sadTear,
                                              color: musicForegroundColor)),
                                    ),
                                  ],
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(FontAwesomeIcons.github,
                                    color: musicForegroundColor))
                          ]),
                        ),
                        MyPopupMenuItem(
                          value: "about",
                          enabled: true,
                          child: Row(children: [
                            Expanded(
                                child: Text('About BeatScratch',
                                    style: TextStyle(
                                      color: musicForegroundColor,
                                    ))),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: 2, horizontal: 5),
                                child: Icon(Icons.info_outline,
                                    color: musicForegroundColor))
                          ]),
                        ),
                      ];
                    },
                    padding: EdgeInsets.only(bottom: 10.0),
                    icon: Stack(children: [
                      Image.asset('assets/logo.png'),
                      Transform.translate(
                          offset:
                              widget.vertical ? Offset(20, 43) : Offset(25, 18),
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: widget.savingScore ? 0.6667 : 0,
                              child: Icon(Icons.save,
                                  size: 16, color: chromaticSteps[0]))),
                      Transform.translate(
                          offset:
                              widget.vertical ? Offset(2, 43) : Offset(25, 3),
                          child: AnimatedOpacity(
                              duration: animationDuration,
                              opacity: !BeatScratchPlugin.isSynthesizerAvailable
                                  ? 0.6667
                                  : 0,
                              child: Icon(Icons.warning,
                                  size: 16, color: chromaticSteps[5])))
                    ]))),
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
          if (!widget.leftHalfOnly && widget.appSettings.enableUniverse)
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
                        child: Transform.translate(
                            offset: Offset(0, 0),
                            child: Icon(FontAwesomeIcons.atom,
                                color: (widget.interactionMode ==
                                        InteractionMode.universe)
                                    ? widget.sectionColor.textColor()
                                    : widget.sectionColor))))),
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
                                    ? widget.sectionColor.textColor()
                                    : widget.sectionColor)))),
          if (!widget.leftHalfOnly)
            Expanded(
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: (widget.interactionMode.isEdit)
                        ? hasMelody
                            ? Colors.white
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
                                                                      ? hasPart
                                                                          ? Colors
                                                                              .white
                                                                          : hasMelody
                                                                              ? Colors.black
                                                                              : widget.sectionColor.textColor()
                                                                      : widget.sectionColor),
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
                                                                      ? hasPart
                                                                          ? Colors
                                                                              .white
                                                                          : hasMelody
                                                                              ? Colors.black
                                                                              : widget.sectionColor.textColor()
                                                                      : widget.sectionColor),
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
                                                    widget.vertical ? 2 : 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    height: widget.vertical
                                                        ? 1
                                                        : 0.9,
                                                    fontSize: 10,
                                                    color: hasPart
                                                        ? Colors.white
                                                        : hasMelody
                                                            ? Colors.black
                                                            : widget.sectionColor
                                                                .textColor(),
                                                    fontWeight: widget.openMelody !=
                                                                null ||
                                                            widget.prevMelody !=
                                                                null
                                                        ? FontWeight.w500
                                                        : widget.openPart != null ||
                                                                widget.prevPart != null
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
}

class SecondToolbar extends StatefulWidget {
  final AppSettings appSettings;
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
  final Function(VoidCallback) setAppState;

  const SecondToolbar({
    Key key,
    this.appSettings,
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
    this.setAppState,
  }) : super(key: key);

  @override
  _SecondToolbarState createState() => _SecondToolbarState();
}

class _SecondToolbarState extends State<SecondToolbar> {
  DateTime lastMetronomeAudioToggleTime = DateTime(0);
  double tempoButtonGestureStartMultiplier;
  double tempoButtonGestureStartPosition;
  Widget columnOrRow(BuildContext context, {List<Widget> children}) {
    if (widget.vertical) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }

  @override
  Widget build(BuildContext context) {
    var totalSpace = widget.vertical
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey && !widget.vertical) {
      totalSpace = totalSpace / 2;
    }
    bool editMode = widget.interactionMode == InteractionMode.edit;
    int numberOfButtons = editMode ? 4 : 3;
    if (widget.enableColorboard) {
      numberOfButtons += 1;
    }
    Widget createPlayIcon(IconData icon, {bool visible, Color color}) {
      return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: animationDuration,
          child: Transform.scale(
              scale: 0.8, child: Icon(icon, color: color, size: 32)));
    }

    final buttonBackgroundColor =
        widget.appSettings.darkMode ? musicBackgroundColor : melodyColor;
    final buttonForegroundColor = buttonBackgroundColor.textColor();

    final keyboardBackgroundColor = (widget.showKeyboardConfiguration)
        ? widget.sectionColor
        : (widget.showKeyboard)
            ? Colors.white
            : buttonBackgroundColor;

    return AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: animationDuration,
        child: columnOrRow(context, children: [
          AnimatedContainer(
              height: !widget.vertical
                  ? null
                  : editMode
                      ? totalSpace / numberOfButtons
                      : 0,
              width: widget.vertical
                  ? null
                  : editMode
                      ? totalSpace / numberOfButtons
                      : 0,
              duration: animationDuration,
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: MyRaisedButton(
                      color: buttonBackgroundColor,
                      padding: EdgeInsets.zero,
                      child: Stack(children: [
                        createPlayIcon(Icons.play_arrow,
                            color: buttonForegroundColor,
                            visible: editMode &&
                                !BeatScratchPlugin.playing &&
                                !widget.recordingMelody),
                        createPlayIcon(Icons.pause,
                            color: buttonForegroundColor,
                            visible: editMode && BeatScratchPlugin.playing),
                        createPlayIcon(Icons.fiber_manual_record,
                            visible: editMode &&
                                !BeatScratchPlugin.playing &&
                                widget.recordingMelody,
                            color: chromaticSteps[7]),
                        AnimatedOpacity(
                            opacity: editMode &&
                                    BeatScratchPlugin.playing &&
                                    widget.recordingMelody
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
              height: !widget.vertical ? null : totalSpace / numberOfButtons,
              width: widget.vertical ? null : totalSpace / numberOfButtons,
              duration: animationDuration,
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: MyRaisedButton(
                      color: buttonBackgroundColor,
                      padding: EdgeInsets.zero,
                      child: Align(
                          alignment: Alignment.center,
                          child: Transform.scale(
                              scale: 0.8,
                              child: Icon(Icons.skip_previous,
                                  color: buttonForegroundColor, size: 32))),
                      onPressed: BeatScratchPlugin.supportsPlayback
                          ? widget.rewind
                          : null))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: tempoButton(
                    context,
                    backgroundColor: buttonBackgroundColor,
                  ))),
          AnimatedContainer(
              height: !widget.vertical
                  ? null
                  : (widget.enableColorboard)
                      ? totalSpace / numberOfButtons
                      : 0,
              width: widget.vertical
                  ? null
                  : (widget.enableColorboard)
                      ? totalSpace / numberOfButtons
                      : 0,
              duration: animationDuration,
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: MyRaisedButton(
                    child: AnimatedOpacity(
                        duration: animationDuration,
                        opacity: widget.toggleColorboard != null ? 1 : 0.25,
                        child: Align(
                          alignment: Alignment.center,
                          child: Transform.scale(
                              scale: widget.vertical
                                  ? MyPlatform.isMacOS || MyPlatform.isWeb
                                      ? 0.8
                                      : 2.5
                                  : 0.8,
                              child: Image.asset('assets/colorboard.png')),
                        )),
                    onPressed: widget.toggleColorboard,
                    onLongPress: widget.toggleColorboardConfiguration,
                    color: (widget.showColorboardConfiguration)
                        ? widget.sectionColor
                        : (widget.showColorboard)
                            ? Colors.white
                            : buttonBackgroundColor,
                  ))),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: MyRaisedButton(
                    child: Align(
                      alignment: Alignment.center,
                      child: Transform.scale(
                          scale: widget.vertical
                              ? MyPlatform.isMacOS || MyPlatform.isWeb
                                  ? 0.8
                                  : 2.5
                              : 0.8,
                          child: ColorFiltered(
                            child: Image.asset(
                              "assets/piano.png",
                              scale: 1,
                            ),
                            colorFilter: ColorFilter.mode(
                                keyboardBackgroundColor.textColor(),
                                BlendMode.srcIn),
                          )),
                    ),
                    onPressed: widget.toggleKeyboard,
                    onLongPress: widget.toggleKeyboardConfiguration,
                    color: keyboardBackgroundColor,
                  ))),
        ]));
  }

  Widget tempoButton(BuildContext context, {Color backgroundColor}) {
    double sensitivity = 7;
    tempoDragStart(DragStartDetails details) {
      tempoButtonGestureStartPosition =
          widget.vertical ? details.localPosition.dy : details.localPosition.dx;
      tempoButtonGestureStartMultiplier = BeatScratchPlugin.bpmMultiplier;
    }

    tempoDragUpdate(DragUpdateDetails details) {
      final change = widget.vertical
          ? -(details.localPosition.dy - tempoButtonGestureStartPosition)
          : details.localPosition.dx - tempoButtonGestureStartPosition;
      widget.setAppState(() {
        double newMultiplier = tempoButtonGestureStartMultiplier + change / 250;
        BeatScratchPlugin.bpmMultiplier = max(0.1, min(newMultiplier, 2));
      });
    }

    tempoDragEnd() {
      tempoButtonGestureStartPosition = null;
      tempoButtonGestureStartMultiplier = null;
    }

    otherAxisUpdate(DragUpdateDetails details) {
      // Up swipe (normal) or right swipe (vertical)
      bool isToggleMetronomeSound =
          !widget.vertical && details.delta.dy < -sensitivity ||
              widget.vertical && details.delta.dx > sensitivity;
      isToggleMetronomeSound &= DateTime.now()
              .difference(lastMetronomeAudioToggleTime)
              .inMilliseconds >
          600;
      // Down swipe (normal) or left swipe (vertical)
      bool isToggleTempoTo1x =
          !widget.vertical && details.delta.dy > sensitivity ||
              widget.vertical && details.delta.dx < -sensitivity;
      if (isToggleMetronomeSound) {
        widget.setAppState(() {
          BeatScratchPlugin.metronomeEnabled =
              !BeatScratchPlugin.metronomeEnabled;
        });
        lastMetronomeAudioToggleTime = DateTime.now();
      } else if (isToggleTempoTo1x) {
        widget.setAppState(() {
          BeatScratchPlugin.bpmMultiplier = 1;
        });
      }
    }

    final buttonBackgroundColor =
        (widget.showTempoConfiguration) ? Colors.white : backgroundColor;
    final buttonForegroundColor = buttonBackgroundColor.textColor();
    return GestureDetector(
        onVerticalDragStart: widget.vertical ? tempoDragStart : null,
        onVerticalDragUpdate:
            widget.vertical ? tempoDragUpdate : otherAxisUpdate,
        onVerticalDragCancel: widget.vertical ? tempoDragEnd : null,
        onVerticalDragEnd: widget.vertical
            ? (_) {
                tempoDragEnd();
              }
            : null,
        onHorizontalDragStart: !widget.vertical ? tempoDragStart : null,
        onHorizontalDragUpdate:
            !widget.vertical ? tempoDragUpdate : otherAxisUpdate,
        onHorizontalDragCancel: !widget.vertical ? tempoDragEnd : null,
        onHorizontalDragEnd: !widget.vertical
            ? (_) {
                tempoDragEnd();
              }
            : null,
        child: MyRaisedButton(
          color: buttonBackgroundColor,
          padding: EdgeInsets.zero,
          child: Stack(children: [
            Align(
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: 0.8,
                  child: Opacity(
                      opacity: 0.5,
                      child: ColorFiltered(
                        child: Image.asset(
                          "assets/metronome.png",
                          scale: 1,
                        ),
                        colorFilter: ColorFilter.mode(
                            buttonForegroundColor, BlendMode.srcIn),
                      )),
                )),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: EdgeInsets.only(
                      right: 3.5, top: widget.vertical ? 26 : 0),
                  child: Text(
                      (BeatScratchPlugin.unmultipliedBpm *
                              BeatScratchPlugin.bpmMultiplier)
                          .toStringAsFixed(0),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontSize: 16,
                        color: buttonForegroundColor,
                      ))),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                  padding: EdgeInsets.only(left: 10.5),
                  child: Text(
                      BeatScratchPlugin.unmultipliedBpm.toStringAsFixed(0),
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                          fontWeight: FontWeight.w200,
                          color: buttonForegroundColor,
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
                        color: buttonForegroundColor,
                        fontSize: 12,
                      ))),
            ),
            Align(
                alignment: Alignment.center,
                child: Transform.translate(
                    offset: Offset(15, widget.vertical ? 0 : 0),
                    child: Transform.scale(
                        scale: 0.55,
                        child: Icon(
                          BeatScratchPlugin.metronomeEnabled
                              ? Icons.volume_up
                              : Icons.not_interested,
                          color: buttonForegroundColor,
                        ))))
          ]),
          onPressed: widget.toggleTempoConfiguration,
          onLongPress: widget.tempoLongPress,
        ));
  }
}
