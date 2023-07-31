import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'beatscratch_plugin.dart';
import 'colors.dart';
import 'export/export_ui.dart';
import 'generated/protos/protos.dart';
import 'widget/my_platform.dart';

Future<String> showMainMenu(
    {required BuildContext context,
    required RelativeRect position,
    required bool showDownloads,
    required Score currentScore,
    required String currentScoreName}) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

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
          value: null,
          mouseCursor: SystemMouseCursors.basic,
          child: Column(children: [
            Row(children: [
              Text('Beat',
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 26)),
              Text('Scratch',
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w100,
                      fontSize: 26)),
              Expanded(
                child: SizedBox(),
              ),
              if (packageInfo?.version != null)
                Text('v${packageInfo?.version}',
                    style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                        fontSize: 10)),
              if (packageInfo?.version != null) SizedBox(width: 3),
              if (packageInfo?.version != null)
                Text('(${packageInfo?.buildNumber})',
                    style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                        fontWeight: FontWeight.w100,
                        fontSize: 10)),
              if (packageInfo?.version == null)
                Text('(build ${packageInfo?.buildNumber})',
                    style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                        fontWeight: FontWeight.w100,
                        fontSize: 10)),
            ]),
            if (MyPlatform.isWeb)
              Text('Web Preview',
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                      fontSize: 12)),
            if (MyPlatform.isWeb)
              Text(
                  'Native app strongly recommended for performance and features like recording, file storage, and MIDI export.',
                  style: TextStyle(
                      color: musicForegroundColor.withOpacity(0.5),
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
          ]),
          enabled: false,
        ),
        if (MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "downloadNative",
            child: Row(children: [
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(
                    showDownloads ? Icons.close : Icons.download_rounded,
                    color: musicForegroundColor,
                  )),
              Expanded(child: SizedBox()),
              Text(
                  showDownloads ? 'Hide Download Links' : 'Download Native App',
                  style: TextStyle(
                    color: musicForegroundColor,
                  )),
              Expanded(child: SizedBox()),
            ]),
            enabled: MyPlatform.isWeb,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: null,
            child: Column(children: [
              if (currentScoreName != currentScore.name)
                Row(children: [
                  Text(currentScoreName,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: musicForegroundColor.withOpacity(0.5),
                          fontWeight: FontWeight.w100,
                          fontSize: 10)),
                ]),
              Row(children: [
                Expanded(
                  child: Text(currentScore.name,
                      textAlign: TextAlign.left,
                      // overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                          color: musicForegroundColor.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                          fontSize: 18)),
                ),
              ]),
            ]),
            enabled: false,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "create",
            child: Row(children: [
              Expanded(
                  child: Text('Create Score...',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(
                    Icons.add,
                    color: musicForegroundColor,
                  ))
            ]),
            enabled: BeatScratchPlugin.supportsStorage,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "open",
            child: Row(children: [
              Expanded(
                  child: Text('Open Score...',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(Icons.folder_open, color: musicForegroundColor))
            ]),
            enabled: BeatScratchPlugin.supportsStorage,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "duplicate",
            child: Row(children: [
              Expanded(
                  child: Text('Duplicate Score...',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(FontAwesomeIcons.codeBranch,
                      color: musicForegroundColor))
            ]),
            enabled: BeatScratchPlugin.supportsStorage,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "save",
            child: Row(children: [
              Expanded(
                  child: Text('Save Score',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(Icons.save, color: musicForegroundColor))
            ]),
            enabled: BeatScratchPlugin.supportsStorage,
          ),
        PopupMenuItem(
          mouseCursor: SystemMouseCursors.basic,
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
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Icon(Icons.content_copy, color: musicForegroundColor))
          ]),
          enabled: true,
        ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "pasteScore",
            child: Row(children: [
              Expanded(
                  child: Text('Paste Score Link',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(Icons.content_paste, color: musicForegroundColor))
            ]),
            enabled: BeatScratchPlugin.supportsStorage,
          ),
        if (!MyPlatform.isWeb)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "export",
            enabled: MyPlatform.isNative,
            child: Row(children: [
              Expanded(
                  child: Text('Export...',
                      style: TextStyle(
                        color: musicForegroundColor,
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: ExportUI.exportIcon(color: musicForegroundColor))
            ]),
          ),
        //                    if(interactionMode.isEdit) PopupMenuItem(
        //                          value: "showBeatCounts",
        //                          child: Row(children: [
        //                            Checkbox(value: showBeatCounts, onChanged: null),
        //                            Expanded(child: Text('Show Section Beat Counts'))
        //                          ]),
        //                        ),
        if (kDebugMode)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "clearMutableCaches",
            child: Text('Debug: Clear Rendering Caches',
                style: TextStyle(
                  color: musicForegroundColor,
                )),
          ),
        if (kDebugMode)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "copyUniverseDataCache",
            child: Text('Debug: Copy Universe Data Cache',
                style: TextStyle(
                  color: musicForegroundColor,
                )),
          ),
        PopupMenuItem(
          mouseCursor: SystemMouseCursors.basic,
          value: "midiSettings",
          child: Row(children: [
            Expanded(
                child: Text('Settings...',
                    style: TextStyle(
                      color: musicForegroundColor,
                    ))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Icon(Icons.settings, color: musicForegroundColor))
          ]),
        ),
        if (MyPlatform.isDebug)
          PopupMenuItem(
            mouseCursor: SystemMouseCursors.basic,
            value: "tutorial",
            enabled: false,
            child: Row(children: [
              Expanded(
                  child: Text('Help/Tutorial',
                      style: TextStyle(
                        color: musicForegroundColor.withOpacity(0.5),
                      ))),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                  child: Icon(Icons.help, color: musicForegroundColor))
            ]),
          ),
        PopupMenuItem(
          mouseCursor: SystemMouseCursors.basic,
          value: "feedback",
          enabled: true,
          child: Row(children: [
            Expanded(
                child: Text('Feedback',
                    style: TextStyle(
                      color: musicForegroundColor,
                    ))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
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
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child:
                    Icon(FontAwesomeIcons.github, color: musicForegroundColor))
          ]),
        ),
        PopupMenuItem(
          mouseCursor: SystemMouseCursors.basic,
          value: "about",
          enabled: true,
          child: Row(children: [
            Expanded(
                child: Text('About BeatScratch',
                    style: TextStyle(
                      color: musicForegroundColor,
                    ))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Icon(Icons.info_outline, color: musicForegroundColor))
          ]),
        ),
      ]);
}
