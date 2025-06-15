import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:beatscratch_flutter_redux/edit_menu.dart';
import 'package:beatscratch_flutter_redux/main_menu.dart';
import 'package:beatscratch_flutter_redux/universe_view/universe_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'beatscratch_plugin.dart';
import 'cache_management.dart';
import 'colors.dart';
import 'generated/protos/music.pb.dart';
import 'messages/messages_ui.dart';
import 'settings/app_settings.dart';
import 'storage/score_manager.dart';
import 'storage/score_picker.dart';
import 'storage/universe_manager.dart';
import 'storage/url_conversions.dart';
import 'ui_models.dart';
import 'util/music_theory.dart';
import 'util/util.dart';
import 'widget/my_buttons.dart';
import 'widget/my_platform.dart';
// import 'widget/my_popup_menu.dart';

class BeatScratchToolbar extends StatefulWidget {
  final AppSettings appSettings;
  final UniverseManager universeManager;
  final Score score;
  final Section currentSection;
  final Part? currentPart;
  final ScoreManager scoreManager;
  final Function(ScorePickerMode) showScorePicker;
  final VoidCallback viewMode;
  final VoidCallback universeMode;
  final VoidCallback editMode;
  final VoidCallback toggleViewOptions;
  final VoidCallback togglePlaying;
  final Function(bool) toggleSectionListDisplayMode;
  final InteractionMode interactionMode;
  final MusicViewMode musicViewMode;
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
  final bool showSections;
  final bool verticalSections;
  final Melody? openMelody;
  final Melody? prevMelody;
  final Part? openPart;
  final Part? prevPart;
  final bool isMelodyViewOpen;
  final bool leftHalfOnly;
  final bool rightHalfOnly;
  final MessagesUI messagesUI;
  final bool showDownloads;
  final VoidCallback toggleShowDownloads;
  final bool savingScore;
  final BSMethod refreshUniverseData;
  final Function(Object) editObject;
  const BeatScratchToolbar(
      {Key? key,
      required this.appSettings,
      required this.universeManager,
      required this.interactionMode,
      required this.musicViewMode,
      required this.viewMode,
      required this.universeMode,
      required this.editMode,
      required this.toggleViewOptions,
      required this.sectionColor,
      required this.togglePlaying,
      required this.toggleSectionListDisplayMode,
      required this.setRenderingMode,
      required this.renderingMode,
      required this.showMidiInputSettings,
      required this.showBeatCounts,
      required this.toggleShowBeatCounts,
      required this.showScorePicker,
      required this.saveCurrentScore,
      required this.currentScoreName,
      required this.score,
      required this.pasteScore,
      required this.export,
      required this.scoreManager,
      required this.routeToCurrentScore,
      required this.vertical,
      required this.showSections,
      required this.verticalSections,
      required this.openMelody,
      required this.prevMelody,
      required this.openPart,
      required this.prevPart,
      required this.isMelodyViewOpen,
      required this.currentSection,
      required this.currentPart,
      required this.leftHalfOnly,
      required this.rightHalfOnly,
      required this.savingScore, // BeatScratchPlugin.isSynthesizerAvailable
      required this.messagesUI,
      required this.showDownloads,
      required this.toggleShowDownloads,
      required this.refreshUniverseData,
      required this.editObject})
      : super(key: key);

  @override
  _BeatScratchToolbarState createState() => _BeatScratchToolbarState();
}

class _BeatScratchToolbarState extends State<BeatScratchToolbar>
    with TickerProviderStateMixin {
  late AnimationController sectionRotationController;
  late Animation<double> sectionOrPlayRotation;
  late AnimationController editController;
  late Animation<double> editRotation;
  late Animation<double> editTranslation;
  late Animation<double> editScale;
  late AnimationController editRotationOnlyController;
  late Animation<double> editRotationOnlyRotation;

  bool get hasMelody => widget.openMelody != null || widget.prevMelody != null;
  bool get hasPart => !hasMelody || widget.prevPart != null;
  bool get hasDrumPart =>
      hasPart && (widget.openPart?.isDrum ?? widget.prevPart?.isDrum ?? false);

  @override
  void initState() {
    super.initState();
    sectionRotationController = AnimationController(
      // animationBehavior: AnimationBehavior.preserve,
      duration: animationDuration,
      vsync: this,
    )..repeat(reverse: true);
    sectionOrPlayRotation = Tween<double>(
      begin: 0,
      end: 0.5 * pi,
    ).animate(sectionRotationController);

    editController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    editRotation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(editController);

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
  }

  @override
  void dispose() {
    sectionRotationController.dispose();
    editRotationOnlyController.dispose();
    editController.dispose();
    super.dispose();
    // clipboardContentStream.close();
    // clipboardTriggerTime.cancel();
  }

  Widget columnOrRow(BuildContext context, {required List<Widget> children}) {
    if (widget.vertical) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (/*!widget.showSections || */ widget.verticalSections) {
      sectionRotationController.reverse();
    } else {
      sectionRotationController.forward();
    }
    if (!widget.interactionMode.isEdit) {
      editController.reverse();
    } else {
      editController.forward();
    }
    if (widget.interactionMode.isEdit && !widget.isMelodyViewOpen) {
      editRotationOnlyController.reverse();
    } else {
      editRotationOnlyController.forward();
    }
    var totalSpace = widget.vertical
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width;
    if (widget.leftHalfOnly == true) {
      totalSpace *= 2 / 10;
    } else if (widget.rightHalfOnly == true) {
      totalSpace *= 3 / 10;
    }
    int numberOfButtons = 0;
    if (widget.rightHalfOnly != true) {
      numberOfButtons += 2;
    }
    if (widget.leftHalfOnly != true) {
      numberOfButtons += 3;
    }
    bool showMenuButton = true;
    return Container(
        height: widget.vertical ? null : 48,
        width: widget.vertical ? 48 : null,
        color: subBackgroundColor.withOpacity(0.5),
        child: columnOrRow(context, children: [
          if (!widget.rightHalfOnly)
            Expanded(
                child: MyFlatButton(
                    onPressed: () {
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;
                      final RenderBox overlay = Overlay.of(context)
                          .context
                          .findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                              button.size.bottomRight(Offset.zero),
                              ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );
                      showMainMenu(
                              context: context,
                              position: position,
                              showDownloads: widget.showDownloads,
                              currentScore: widget.score,
                              currentScoreName: widget.currentScoreName)
                          .then(onMenuItemChosen);
                    },
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;
                      final RenderBox overlay = Overlay.of(context)
                          .context
                          .findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                              button.size.bottomRight(Offset.zero),
                              ancestor: overlay),
                        ),
                        Offset.zero & overlay.size,
                      );
                      showMainMenu(
                              context: context,
                              position: position,
                              showDownloads: widget.showDownloads,
                              currentScore: widget.score,
                              currentScoreName: widget.currentScoreName)
                          .then(onMenuItemChosen);
                    },
                    padding: EdgeInsets.zero,
                    lightHighlight: true,
                    child: Align(
                        alignment: Alignment.center,
                        child: Stack(children: [
                          Transform.translate(
                              offset: widget.vertical
                                  ? Offset(0, 0)
                                  : Offset(0, -5),
                              child: Transform.scale(
                                  scale: 0.7,
                                  child: Image.asset('assets/logo.png'))),
                          Transform.translate(
                              offset: widget.vertical
                                  ? Offset(20, 43)
                                  : Offset(25, 18),
                              child: AnimatedOpacity(
                                  duration: animationDuration,
                                  opacity: widget.savingScore ? 0.6667 : 0,
                                  child: Icon(Icons.save,
                                      size: 16, color: chromaticSteps[0]))),
                          Transform.translate(
                              offset: widget.vertical
                                  ? Offset(2, 43)
                                  : Offset(25, 3),
                              child: AnimatedOpacity(
                                  duration: animationDuration,
                                  opacity:
                                      !BeatScratchPlugin.isSynthesizerAvailable
                                          ? 0.6667
                                          : 0,
                                  child: Icon(Icons.warning,
                                      size: 16, color: chromaticSteps[5])))
                        ])))),
          if (!widget.rightHalfOnly)
            Expanded(
                child: MyFlatButton(
                    onPressed: () {
                      widget.toggleSectionListDisplayMode(true);
                    },
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      widget.toggleSectionListDisplayMode(false);
                    },
                    padding: EdgeInsets.all(0.0),
                    lightHighlight: true,
                    child: Align(
                        alignment: Alignment.center,
                        child: AnimatedBuilder(
                            animation: sectionRotationController,
                            builder: (_, child) => Transform(
                                transform: Matrix4.rotationZ(
                                    sectionOrPlayRotation.value),
                                alignment: Alignment.center,
                                child: Stack(
                                  children: [
                                    AnimatedOpacity(
                                        duration: animationDuration,
                                        opacity:
                                            widget.interactionMode.isEdit &&
                                                    widget.showSections
                                                ? 1
                                                : 0,
                                        child: Icon(Icons.reorder,
                                            color: chromaticSteps[0])),
                                    AnimatedOpacity(
                                        duration: animationDuration,
                                        opacity:
                                            widget.interactionMode.isEdit &&
                                                    !widget.showSections
                                                ? 1
                                                : 0,
                                        child: Icon(Icons.reorder,
                                            color: Colors.white)),
                                    AnimatedOpacity(
                                        duration: animationDuration,
                                        opacity:
                                            !widget.interactionMode.isEdit &&
                                                    widget.showSections
                                                ? 1
                                                : 0,
                                        child: Icon(Icons.menu,
                                            color: chromaticSteps[0])),
                                    AnimatedOpacity(
                                        duration: animationDuration,
                                        opacity:
                                            !widget.interactionMode.isEdit &&
                                                    !widget.showSections
                                                ? 1
                                                : 0,
                                        child: Icon(Icons.menu,
                                            color: Colors.white)),
                                  ],
                                )))))),
          if (!widget.leftHalfOnly && widget.appSettings.enableUniverse)
            Expanded(
              child: AnimatedContainer(
                duration: animationDuration,
                color: (widget.interactionMode.isUniverse)
                    ? widget.sectionColor
                    : Colors.transparent,
                child: MyFlatButton(
                    onPressed: widget.interactionMode.isUniverse
                        ? () => widget.refreshUniverseData()
                        : widget.universeMode,
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      if (widget.interactionMode.isUniverse) {
                        widget.refreshUniverseData();
                      } else {
                        widget.universeMode();
                      }
                    },
                    lightHighlight: !widget.interactionMode.isUniverse,
                    padding: EdgeInsets.all(0.0),
                    child: Align(
                        alignment: Alignment.center,
                        child: UniverseIcon(
                            interactionMode: widget.interactionMode,
                            sectionColor: widget.sectionColor,
                            animateIcon: widget.refreshUniverseData))),
              ),
            ),
          if (!widget.leftHalfOnly)
            Expanded(
                child: AnimatedContainer(
                    duration: animationDuration,
                    color: (widget.interactionMode.isView)
                        ? widget.sectionColor
                        : Colors.transparent,
                    child: MyFlatButton(
                        onPressed: (widget.interactionMode.isView)
                            ? widget.toggleViewOptions
                            : widget.viewMode,
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          widget.toggleViewOptions();
                        },
                        lightHighlight: !widget.interactionMode.isView,
                        padding: EdgeInsets.all(0.0),
                        child: Align(
                            alignment: Alignment.center,
                            child: Icon(Icons.remove_red_eye,
                                color: (widget.interactionMode ==
                                        InteractionMode.view)
                                    ? widget.sectionColor.textColor()
                                    : widget.sectionColor))))),
          if (!widget.leftHalfOnly)
            Expanded(
                child: _EditButton(
              score: widget.score,
              currentSection: widget.currentSection,
              currentPart: widget.currentPart,
              openPart: widget.openPart,
              prevPart: widget.prevPart,
              openMelody: widget.openMelody,
              prevMelody: widget.prevMelody,
              interactionMode: widget.interactionMode,
              musicViewMode: widget.musicViewMode,
              editMode: widget.editMode,
              sectionColor: widget.sectionColor,
              editController: editController,
              vertical: widget.vertical,
              isMelodyViewOpen: widget.isMelodyViewOpen,
              editRotation: editRotation,
              editTranslation: editTranslation,
              editScale: editScale,
              editRotationOnlyController: editRotationOnlyController,
              editRotationOnlyRotation: editRotationOnlyRotation,
              editObject: widget.editObject,
            ))
        ]));
  }

  onMenuItemChosen(value) {
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
        widget.showScorePicker(ScorePickerMode.duplicate);
        break;
      case "save":
        widget.saveCurrentScore();
        break;
      case "import":
        print("Showing file picker");
        break;
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
      case "copyUniverseDataCache":
        print('hi"');

        Future.microtask(() async {
          Clipboard.setData(ClipboardData(
              text: jsonEncode(widget.universeManager.cachedUniverseData
                  .map((e) => e.toJson())
                  .toList())));
        });
        break;
      case "copyScore":
        Future.microtask(() async {
          widget.score.name = widget.scoreManager.currentScoreName;
          String urlString;
          if (widget.appSettings.integratePastee) {
            widget.messagesUI.sendMessage(
                message: "Generating short URL via https://paste.ee...",
                andSetState: true);
            urlString = (await widget.score.convertToShortUrl()) ??
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
        launchURL("https://github.com/falrm/falrm.github.io/issues");
        break;
      case "about":
        launchURL("https://beatscratch.io/about.html");
        break;
      case "downloadNative":
        widget.toggleShowDownloads();
        break;
    }
    //setState(() {});
  }
}

class _EditButton extends StatelessWidget {
  final Score score;
  final Section currentSection;
  final Part? openPart, prevPart, currentPart;
  final Melody? openMelody, prevMelody;
  final InteractionMode interactionMode;
  final MusicViewMode musicViewMode;
  final VoidCallback editMode;
  final Color sectionColor;
  final AnimationController editController;
  final bool vertical, isMelodyViewOpen;
  final Animation<double> editRotation;
  final Animation<double> editTranslation;
  final Animation<double> editScale;
  final AnimationController editRotationOnlyController;
  final Animation<double> editRotationOnlyRotation;
  final Function(Object) editObject;

  const _EditButton({
    Key? key,
    required this.score,
    required this.currentSection,
    required this.currentPart,
    this.openPart,
    this.prevPart,
    required this.openMelody,
    required this.prevMelody,
    required this.interactionMode,
    required this.musicViewMode,
    required this.editMode,
    required this.sectionColor,
    required this.editController,
    required this.vertical,
    required this.isMelodyViewOpen,
    required this.editRotation,
    required this.editTranslation,
    required this.editScale,
    required this.editRotationOnlyController,
    required this.editRotationOnlyRotation,
    required this.editObject,
  }) : super(key: key);

  bool get hasMelody => openMelody != null || prevMelody != null;
  bool get hasPart => !hasMelody || prevPart != null;
  bool get hasDrumPart =>
      hasPart && (openPart?.isDrum ?? prevPart?.isDrum ?? false);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnimatedContainer(
        duration: animationDuration,
        color: (interactionMode.isEdit)
            ? hasMelody
                ? Colors.white
                : hasPart
                    ? (hasDrumPart ? Colors.brown : Colors.grey)
                    : sectionColor
            : Colors.transparent,
        child: MyFlatButton(
            onPressed: editMode,
            onLongPress: () {
              HapticFeedback.lightImpact();
              final RenderBox button = context.findRenderObject() as RenderBox;
              final RenderBox overlay =
                  Overlay.of(context).context.findRenderObject() as RenderBox;
              final RelativeRect position = RelativeRect.fromRect(
                Rect.fromPoints(
                  button.localToGlobal(Offset.zero, ancestor: overlay),
                  button.localToGlobal(button.size.bottomRight(Offset.zero),
                      ancestor: overlay),
                ),
                Offset.zero & overlay.size,
              );
              showEditMenu(
                  context: context,
                  position: position,
                  score: score,
                  section: currentSection,
                  selectedMelody: openMelody,
                  musicViewMode: musicViewMode,
                  part: currentPart,
                  editObject: editObject); //.then(onMenuItemChosen);
            },
            padding: EdgeInsets.all(0.0),
            lightHighlight: !interactionMode.isEdit,
            child: Stack(
              children: [
                Align(
                    alignment: Alignment.center,
                    child: AnimatedBuilder(
                        animation: editController,
                        builder: (_, child) => Transform(
                            transform: Matrix4.translationValues(0,
                                -(vertical ? 2 : 1) * editTranslation.value, 0),
                            alignment: Alignment.center,
                            child: AnimatedBuilder(
                                animation: editRotationOnlyController,
                                builder: (_, child) => Transform(
                                      transform: Matrix4.rotationZ(
                                          editRotationOnlyRotation.value),
                                      alignment: Alignment.center,
                                      child: Transform(
                                          transform: Matrix4.rotationZ(
                                              editRotation.value),
                                          alignment: Alignment.center,
                                          child: ScaleTransition(
                                            scale: editScale,
                                            alignment: Alignment.center,
                                            child: Stack(
                                              children: [
                                                AnimatedOpacity(
                                                  duration: animationDuration,
                                                  opacity:
                                                      !interactionMode.isEdit ||
                                                              !isMelodyViewOpen
                                                          ? 1
                                                          : 0,
                                                  child: Icon(Icons.edit,
                                                      color: (interactionMode
                                                              .isEdit)
                                                          ? hasPart
                                                              ? Colors.white
                                                              : hasMelody
                                                                  ? Colors.black
                                                                  : sectionColor
                                                                      .textColor()
                                                          : sectionColor),
                                                ),
                                                AnimatedOpacity(
                                                  duration: animationDuration,
                                                  opacity:
                                                      interactionMode.isEdit &&
                                                              isMelodyViewOpen
                                                          ? 1
                                                          : 0,
                                                  child: Icon(Icons.close,
                                                      color: (interactionMode
                                                              .isEdit)
                                                          ? hasPart
                                                              ? Colors.white
                                                              : hasMelody
                                                                  ? Colors.black
                                                                  : sectionColor
                                                                      .textColor()
                                                          : sectionColor),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ))))),
                Transform.translate(
                  offset: Offset(0, 8),
                  child: AnimatedOpacity(
                      duration: animationDuration,
                      opacity: interactionMode == InteractionMode.edit ? 1 : 0,
                      child: Row(
                        children: [
                          Expanded(child: SizedBox()),
                          Column(
                            children: [
                              Expanded(child: SizedBox()),
                              Container(
                                width: vertical ? 44 : 60,
                                child: Text(
                                    openMelody != null
                                        ? openMelody!.canonicalName
                                        : openPart != null
                                            ? openPart!.midiName
                                            : isMelodyViewOpen ||
                                                    (prevPart == null &&
                                                        prevMelody == null)
                                                ? currentSection.canonicalName
                                                : prevMelody != null
                                                    ? prevMelody!.canonicalName
                                                    : prevPart != null
                                                        ? prevPart!.midiName
                                                        : "Oops",
                                    textAlign: TextAlign.center,
                                    maxLines: vertical ? 2 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        height: vertical ? 1 : 0.9,
                                        fontSize: 10,
                                        color: hasPart
                                            ? Colors.white
                                            : hasMelody
                                                ? Colors.black
                                                : sectionColor.textColor(),
                                        fontWeight: openMelody != null ||
                                                prevMelody != null
                                            ? FontWeight.w500
                                            : openPart != null ||
                                                    prevPart != null
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
            )));
  }
}

class SecondToolbar extends StatefulWidget {
  final AppSettings appSettings;
  final VoidCallback? toggleKeyboard;
  final VoidCallback? toggleColorboard;
  final VoidCallback? toggleKeyboardConfiguration;
  final VoidCallback? toggleColorboardConfiguration;
  final VoidCallback toggleTempoConfiguration;
  final VoidCallback? tempoLongPress;
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
    Key? key,
    required this.appSettings,
    required this.toggleKeyboard,
    required this.toggleColorboard,
    required this.showKeyboard,
    required this.showColorboard,
    required this.interactionMode,
    required this.showViewOptions,
    required this.showKeyboardConfiguration,
    required this.showColorboardConfiguration,
    required this.toggleKeyboardConfiguration,
    required this.toggleColorboardConfiguration,
    required this.sectionColor,
    required this.enableColorboard,
    required this.recordingMelody,
    required this.toggleTempoConfiguration,
    required this.showTempoConfiguration,
    required this.vertical,
    required this.visible,
    required this.tempoLongPress,
    required this.rewind,
    required this.setAppState,
  }) : super(key: key);

  @override
  _SecondToolbarState createState() => _SecondToolbarState();
}

class _SecondToolbarState extends State<SecondToolbar> {
  DateTime lastMetronomeAudioToggleTime = DateTime(0);
  double? tempoButtonGestureStartMultiplier;
  double? tempoButtonGestureStartPosition;
  Widget columnOrRow(BuildContext context, {List<Widget> children = const []}) {
    if (widget.vertical) {
      return Column(children: children);
    } else {
      return Row(children: children);
    }
  }

  bool get showPlayButton => true; //widget.interactionMode.isEdit;

  @override
  Widget build(BuildContext context) {
    var totalSpace = widget.vertical
        ? MediaQuery.of(context).size.height
        : MediaQuery.of(context).size.width;
    if (context.isTabletOrLandscapey && !widget.vertical) {
      totalSpace = totalSpace / 2;
    }
    int numberOfButtons = showPlayButton ? 4 : 3;
    if (widget.enableColorboard) {
      numberOfButtons += 1;
    }
    Widget createPlayIcon(IconData icon, {bool visible = true, Color? color}) {
      return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: animationDuration,
          child: Transform.scale(
              scale: 0.8, child: Icon(icon, color: color, size: 32)));
    }

    final buttonBackgroundColor = widget.appSettings.darkMode
        ? musicBackgroundColor
        : Colors.grey.shade500;
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
          AnimatedContainer(
              height: !widget.vertical
                  ? null
                  : showPlayButton
                      ? totalSpace / numberOfButtons
                      : 0,
              width: widget.vertical
                  ? null
                  : showPlayButton
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
                            color: chromaticSteps[0],
                            visible: showPlayButton &&
                                !BeatScratchPlugin.playing &&
                                !widget.recordingMelody),
                        createPlayIcon(Icons.pause,
                            color: chromaticSteps[0],
                            visible:
                                showPlayButton && BeatScratchPlugin.playing),
                        createPlayIcon(Icons.fiber_manual_record,
                            visible: showPlayButton &&
                                !BeatScratchPlugin.playing &&
                                widget.recordingMelody,
                            color: chromaticSteps[7]),
                        AnimatedOpacity(
                            opacity: showPlayButton &&
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
                            key: ValueKey(
                                "PianoIcon-filtered-bg-${keyboardBackgroundColor}"),
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
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      widget.toggleKeyboardConfiguration?.call();
                    },
                    color: keyboardBackgroundColor,
                  ))),
        ]));
  }

  Widget tempoButton(BuildContext context, {required Color backgroundColor}) {
    double sensitivity = 7;
    tempoDragStart(DragStartDetails details) {
      tempoButtonGestureStartPosition =
          widget.vertical ? details.localPosition.dy : details.localPosition.dx;
      tempoButtonGestureStartMultiplier = BeatScratchPlugin.bpmMultiplier;
    }

    tempoDragUpdate(DragUpdateDetails details) {
      final change = widget.vertical
          ? -(details.localPosition.dy - tempoButtonGestureStartPosition!)
          : details.localPosition.dx - tempoButtonGestureStartPosition!;
      widget.setAppState(() {
        var startTempo = (BeatScratchPlugin.unmultipliedBpm *
                BeatScratchPlugin.bpmMultiplier)
            .toStringAsFixed(0);
        double newMultiplier =
            tempoButtonGestureStartMultiplier! + change / 250;
        BeatScratchPlugin.bpmMultiplier = max(0.1, min(newMultiplier, 2));
        var endTempo = (BeatScratchPlugin.unmultipliedBpm *
                BeatScratchPlugin.bpmMultiplier)
            .toStringAsFixed(0);
        if (startTempo != endTempo) {
          HapticFeedback.lightImpact();
        }
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
          HapticFeedback.lightImpact();
        });
        lastMetronomeAudioToggleTime = DateTime.now();
      } else if (isToggleTempoTo1x) {
        widget.setAppState(() {
          if (BeatScratchPlugin.bpmMultiplier != 1) {
            HapticFeedback.lightImpact();
          }
          BeatScratchPlugin.bpmMultiplier = 1;
        });
      }
    }

    final buttonBackgroundColor =
        (widget.showTempoConfiguration) ? Colors.white : backgroundColor;
    final buttonForegroundColor = buttonBackgroundColor!.textColor();
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
                        key: ValueKey(
                            "MetronomeIcon-filtered-${buttonForegroundColor}"),
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
                    offset: Offset(15, 0),
                    child: Transform.scale(
                        scale: 0.55,
                        child: Icon(
                          BeatScratchPlugin.metronomeEnabled
                              ? Icons.volume_up
                              : Icons.not_interested,
                          color: buttonForegroundColor,
                        )))),
            Opacity(
                opacity: 0.85,
                child: Align(
                    alignment: Alignment.center,
                    child: Transform.translate(
                        offset:
                            widget.vertical ? Offset(4, 0.5) : Offset(13, 10),
                        child: Transform.scale(
                            scale: widget.vertical ? 0.4 : 0.35,
                            child: Icon(
                              FontAwesomeIcons.arrowsAlt,
                              color: buttonForegroundColor,
                            )))))
          ]),
          onPressed: widget.toggleTempoConfiguration,
          onLongPress: () {
            HapticFeedback.lightImpact();
            widget.tempoLongPress?.call();
          },
        ));
  }
}
