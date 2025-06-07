// import 'export_models.dart';
import 'package:beatscratch_flutter_redux/messages/messages_ui.dart';
import 'package:beatscratch_flutter_redux/storage/universe_manager.dart';
import 'package:beatscratch_flutter_redux/util/bs_methods.dart';
import 'package:beatscratch_flutter_redux/widget/my_buttons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../colors.dart';
import '../ui_models.dart';
import '../util/util.dart';
import '../widget/my_platform.dart';
import '../widget/my_popup_menu.dart';
import 'universe_icon.dart';

class UniverseViewUI {
  BSMethod? refreshUniverseData;
  VoidCallback? switchToLocalScores;
  MessagesUI? messagesUI;
  bool visible = true;
  final UniverseManager universeManager;
  final Function(VoidCallback) setAppState;
  bool signingIn = false;
  // final Completer<WebViewController> _webViewController =
  //     Completer<WebViewController>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UniverseViewUI(this.setAppState, this.universeManager);
  dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
  }

  double toolbarHeight(BuildContext context,
          {required double keyboardHeight, required double settingsHeight}) =>
      visible ? 44 : 0;
  double authFormHeight(BuildContext context,
          {required double keyboardHeight, required double settingsHeight}) =>
      visible && signingIn ? 200 : 0;
  double height(BuildContext context,
          {required double keyboardHeight, required double settingsHeight}) =>
      toolbarHeight(context,
          keyboardHeight: keyboardHeight, settingsHeight: settingsHeight) +
      authFormHeight(context,
          keyboardHeight: keyboardHeight, settingsHeight: settingsHeight);

  Widget build(
      {required BuildContext context,
      required Color sectionColor,
      required double keyboardHeight,
      required double settingsHeight,
      VoidCallback? showDownloads,
      required double scorePickerWidth}) {
    double abbreviateAtWidth = 340;
    return AnimatedOpacity(
        duration: animationDuration,
        opacity: visible ? 1 : 0,
        child: Column(children: [
          AnimatedContainer(
            duration: animationDuration,
            padding: EdgeInsets.all(3),
            height: toolbarHeight(context,
                keyboardHeight: keyboardHeight, settingsHeight: settingsHeight),
            child: Row(
              children: [
                AnimatedOpacity(
                  duration: animationDuration,
                  opacity: switchToLocalScores != null ? 1 : 0,
                  child: AnimatedContainer(
                      duration: animationDuration,
                      width: switchToLocalScores != null ? 42 : 0,
                      // height: showDownloads != null ? 40 : 0,
                      child: MyFlatButton(
                        lightHighlight: true,
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Icon(Icons.folder_open, color: Colors.white),
                        onPressed: switchToLocalScores,
                      )),
                ),
                SizedBox(width: 3),
                Transform.translate(
                  offset: Offset(0, 0),
                  child: MyFlatButton(
                    onPressed: () => refreshUniverseData?.call(),
                    padding: EdgeInsets.all(5),
                    lightHighlight: true,
                    child: Transform.translate(
                      offset: Offset(0, MyPlatform.isIOS ? -1.5 : -4.5),
                      child: Column(
                        children: [
                          Expanded(child: SizedBox()),
                          // SizedBox(height: 2),
                          Row(children: [
                            SizedBox(width: 5),
                            Transform.translate(
                                offset: Offset(0, 1.5),
                                child: UniverseIcon(
                                  interactionMode: visible
                                      ? InteractionMode.universe
                                      : InteractionMode.view,
                                  sectionColor: subBackgroundColor,
                                  animateIcon: refreshUniverseData,
                                )),
                            SizedBox(width: 8),
                            Stack(
                              children: [
                                Transform.translate(
                                    offset: Offset(0, -7),
                                    child: Row(
                                      children: [
                                        Text("Beat",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w900)),
                                        Text("Scratch",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w100)),
                                      ],
                                    )),
                                Transform.translate(
                                    offset: Offset(0, 15),
                                    child: Text(
                                        MyPlatform.isWeb ? "Web" : "Universe",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400))),
                                if (MyPlatform.isWeb)
                                  Transform.translate(
                                      offset: Offset(40, 15),
                                      child: Text("BETA",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800))),
                              ],
                            ),
                            SizedBox(width: 2.5),
                          ]),
                          // Expanded(child: Container(child: SizedBox()))
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: SizedBox()),
                AnimatedOpacity(
                  duration: animationDuration,
                  opacity: showDownloads != null ? 1 : 0,
                  child: AnimatedContainer(
                      duration: animationDuration,
                      width: showDownloads != null ? 48 : 0,
                      // height: showDownloads != null ? 40 : 0,
                      child: Transform.translate(
                          offset: Offset(0, 4),
                          child: MyFlatButton(
                            padding: EdgeInsets.zero,
                            child: Icon(Icons.download_rounded,
                                color: Colors.white),
                            onPressed: showDownloads,
                          ))),
                ),
                // MyPopupMenuButton(itemBuilder: itemBuilder)
                MyPopupMenuButton(
//                        onPressed: _doNothing,
                    tooltip: null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    color: (musicBackgroundColor.luminance < 0.5
                            ? subBackgroundColor
                            : musicBackgroundColor)
                        .withOpacity(0.95),
                    offset: Offset(0, MediaQuery.of(context).size.height),
                    onSelected: (value) {
                      switch (value) {
                        case "signIn":
                          universeManager.initiateSignIn();
                          break;
                        case "signOut":
                          setAppState(() {
                            universeManager.signOut();
                            messagesUI?.sendMessage(
                                message: "Signed out of Reddit");
                          });
                          break;
                      }
                      //setState(() {});
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        if (universeManager.redditUsername.isEmpty)
                          MyPopupMenuItem(
                            value: "signIn",
                            enabled: true,
                            child: Row(children: [
                              Expanded(
                                  child: Text('Sign In with Reddit',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(FontAwesomeIcons.redditAlien,
                                      color: musicForegroundColor))
                            ]),
                          ),
                        if (universeManager.redditUsername.isNotEmpty)
                          MyPopupMenuItem(
                            value: "signedIn",
                            enabled: false,
                            child: Row(children: [
                              Expanded(
                                  child: Text(universeManager.redditUsername,
                                      style: TextStyle(
                                        color: musicForegroundColor
                                            .withOpacity(0.5),
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(FontAwesomeIcons.redditAlien,
                                      color: musicForegroundColor
                                          .withOpacity(0.5)))
                            ]),
                          ),
                        if (universeManager.redditUsername.isNotEmpty)
                          MyPopupMenuItem(
                            value: "signOut",
                            enabled: true,
                            child: Row(children: [
                              Expanded(
                                  child: Text('Sign Out of Reddit',
                                      style: TextStyle(
                                        color: musicForegroundColor,
                                      ))),
                              Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 5),
                                  child: Icon(Icons.logout,
                                      color: musicForegroundColor))
                            ]),
                          ),
                      ];
                    },
                    padding: EdgeInsets.only(bottom: 10.0),
                    icon: Icon(FontAwesomeIcons.reddit,
                        size: 36,
                        color: universeManager.redditUsername.isNotEmpty
                            ? sectionColor
                            : Colors.white)),
              ],
            ),
          ),
          // Container(height: 5, width: 50, color: Colors.red)
        ]));
  }

  static const TextStyle labelStyle =
      TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding =
      EdgeInsets.only(left: 5, top: 5, bottom: 5);
}
