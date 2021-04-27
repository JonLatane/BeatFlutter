// import 'export_models.dart';
import 'package:beatscratch_flutter_redux/messages/messages_ui.dart';
import 'package:beatscratch_flutter_redux/storage/universe_manager.dart';
import 'package:beatscratch_flutter_redux/widget/my_buttons.dart';

import '../widget/my_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../colors.dart';
import '../ui_models.dart';
import '../util/util.dart';
import 'universe_icon.dart';
import '../widget/my_platform.dart';

class UniverseViewUI {
  static final REDDIT_CLIENT_ID = 'rSA9vlCRCznMCw';
  static final REDDIT_REDIRECT_URI = 'https://beatscratch.io/app';
  static final SUPPORTS_WEBVIEW =
      false; //MyPlatform.isAndroid || MyPlatform.isIOS;
  MessagesUI messagesUI;
  bool visible = false;
  final UniverseManager universeManager;
  final Function(VoidCallback) setAppState;
  bool signingIn = false;
  final Completer<WebViewController> _webViewController =
      Completer<WebViewController>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UniverseViewUI(this.setAppState, this.universeManager);
  dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
  }

  double toolbarHeight(BuildContext context,
          {@required double keyboardHeight, @required double settingsHeight}) =>
      visible ? 40 : 0;
  double authFormHeight(BuildContext context,
          {@required double keyboardHeight, @required double settingsHeight}) =>
      visible && signingIn ? 200 : 0;
  double height(BuildContext context,
          {@required double keyboardHeight, @required double settingsHeight}) =>
      toolbarHeight(context,
          keyboardHeight: keyboardHeight, settingsHeight: settingsHeight) +
      authFormHeight(context,
          keyboardHeight: keyboardHeight, settingsHeight: settingsHeight);

  Widget build(
      {@required BuildContext context,
      @required Color sectionColor,
      @required double keyboardHeight,
      @required double settingsHeight}) {
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
                Column(
                  children: [
                    Expanded(child: Container(child: SizedBox())),
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
                          )),
                      SizedBox(width: 8),
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
                      SizedBox(width: 5),
                      Text("Universe",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500)),
                    ]),
                    Expanded(child: Container(child: SizedBox()))
                  ],
                ),
                Expanded(child: SizedBox()),
                // MyPopupMenuButton(itemBuilder: itemBuilder)
                MyPopupMenuButton(
//                        onPressed: _doNothing,
                    tooltip: null,
                    color: musicBackgroundColor.luminance < 0.5
                        ? subBackgroundColor
                        : musicBackgroundColor,
                    offset: Offset(0, MediaQuery.of(context).size.height),
                    onSelected: (value) {
                      switch (value) {
                        case "signIn":
                          _initiateSignIn();
                          break;
                        case "signOut":
                          setAppState(() {
                            universeManager.redditAccessToken = "";
                            universeManager.redditUsername = "";
                            universeManager.redditRefreshToken = "";
                            messagesUI.sendMessage(
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
        ]));
  }

  _initiateSignIn() {
    setAppState(() {
      if (SUPPORTS_WEBVIEW && false) {
        signingIn = !signingIn;
        if (signingIn) {
          _webViewController.future
              .then((controller) => controller.loadUrl(createAuthUrl()));
        }
      } else {
        launchURL(createAuthUrl());
      }
    });
  }

  String authState;
  String createAuthUrl() {
    authState = uuid.v4();
    return "https://www.reddit.com/api/v1/authorize?"
        "client_id=$REDDIT_CLIENT_ID&response_type=code&"
        "state=$authState&"
        "redirect_uri=${REDDIT_REDIRECT_URI}&"
        "duration=permanent&"
        "scope=identity%20vote%20submit%20subscribe";
  }

  loadAuthPage() {
    launchURL(createAuthUrl());
  }

  bool tryAuthentication(String authUrl) {
    final uri = Uri.parse(authUrl);
    String state = uri.queryParameters["state"];
    String code = uri.queryParameters["code"];
    if (state != null && code != null) {
      if (state != authState) {
        setAppState(() {
          messagesUI.sendMessage(
              message: "Auth codes did not match!", isError: true);
        });
      } else {
        setAppState(() {
          messagesUI.sendMessage(message: "Authenticating with Reddit...");
        });
        String credentials = "${REDDIT_CLIENT_ID}:";
        Codec<String, String> stringToBase64 = utf8.fuse(base64);
        String authHeader = stringToBase64.encode(credentials);

        http.post(
          'https://www.reddit.com/api/v1/access_token',
          body: {
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': REDDIT_REDIRECT_URI
          },
          headers: <String, String>{
            'User-Agent': 'BeatScratch App!',
            HttpHeaders.authorizationHeader: "Basic ${authHeader}"
          },
        ).then((response) {
          final data = jsonDecode(response.body);
          String accessToken = data['access_token'];
          String refreshToken = data['refresh_token'];
          if (accessToken != null && refreshToken != null) {
            universeManager.redditRefreshToken = refreshToken;
            universeManager.redditAccessToken = accessToken;
            loadRedditUsername();
          } else {
            setAppState(() {
              messagesUI.sendMessage(
                  message: "Failed to authenticate", isError: true);
            });
          }
        });
      }
      return true;
    }
    return false;
  }

  Map<String, String> get authenticatedRedditRequestHeaders => {
        'User-Agent': 'BeatScratch App!',
        HttpHeaders.authorizationHeader:
            "bearer ${universeManager.redditAccessToken}"
      };

  loadRedditUsername() {
    http
        .get(
      'https://oauth.reddit.com/api/v1/me',
      headers: authenticatedRedditRequestHeaders,
    )
        .then((response) {
      final data = jsonDecode(response.body);
      final username = data['name'];
      if (username != null) {
        universeManager.redditUsername = username;
        if (messagesUI != null) {
          setAppState(() {
            messagesUI.sendMessage(
                message: "Reddit authentication successful!");
          });
        }
      } else {
        if (messagesUI != null) {
          setAppState(() {
            messagesUI.sendMessage(
                message: "Failed to load Reddit user information",
                isError: true);
          });
        }
      }
    });
  }

  bool refreshAccessToken() {
    String credentials = "${REDDIT_CLIENT_ID}:";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String authHeader = stringToBase64.encode(credentials);
    http.post(
      'https://www.reddit.com/api/v1/access_token',
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': universeManager.redditRefreshToken,
      },
      headers: <String, String>{
        'User-Agent': 'BeatScratch App!',
        HttpHeaders.authorizationHeader: "Basic ${authHeader}"
      },
    ).then((response) {
      final data = jsonDecode(response.body);
      String accessToken = data['access_token'];
      if (accessToken != null) {
        universeManager.redditAccessToken = accessToken;
      }
    });
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  static const TextStyle labelStyle =
      TextStyle(fontWeight: FontWeight.w200, color: Colors.white);
  static const TextStyle valueStyle =
      TextStyle(fontWeight: FontWeight.w600, color: Colors.white);
  static const EdgeInsets itemPadding =
      EdgeInsets.only(left: 5, top: 5, bottom: 5);
}
