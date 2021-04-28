import 'package:beatscratch_flutter_redux/messages/messages.dart';
import 'package:beatscratch_flutter_redux/storage/score_manager.dart';
import 'package:beatscratch_flutter_redux/util/util.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../beatscratch_plugin.dart';
import '../generated/protos/music.pb.dart';
import '../util/dummydata.dart';
import '../util/proto_utils.dart';
import '../widget/my_platform.dart';
import 'url_conversions.dart';

class UniverseManager {
  static final REDDIT_CLIENT_ID = 'rSA9vlCRCznMCw';
  static final REDDIT_REDIRECT_URI = 'https://beatscratch.io/app';
  Function(Score) doOpenScore;
  Directory scoresDirectory;
  SharedPreferences _prefs;
  MessagesUI messagesUI;
  Function(VoidCallback) setAppState;

  UniverseManager() {
    _initialize();
  }

  String get currentUniverseScore =>
      _prefs?.getString('currentUniverseScore') ?? "";
  set currentUniverseScore(String value) =>
      _prefs?.setString("currentUniverseScore", value);

  String get redditRefreshToken =>
      _prefs?.getString('redditRefreshToken') ?? "";
  set redditRefreshToken(String value) =>
      _prefs?.setString("redditRefreshToken", value);

  String get redditAccessToken => _prefs?.getString('redditAccessToken') ?? "";
  set redditAccessToken(String value) =>
      _prefs?.setString("redditAccessToken", value);

  String get redditUsername => _prefs?.getString('redditUsername') ?? "";
  set redditUsername(String value) =>
      _prefs?.setString("redditUsername", value);

  String get redditModHash => _prefs?.getString('redditModHash') ?? "";
  set redditModHash(String value) => _prefs?.setString("redditModHash", value);

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String _authState;

  initiateSignIn() {
    _authState = uuid.v4();
    final authUrl = "https://www.reddit.com/api/v1/authorize?"
        "client_id=${UniverseManager.REDDIT_CLIENT_ID}&response_type=code&"
        "state=$_authState&"
        "redirect_uri=${UniverseManager.REDDIT_REDIRECT_URI}&"
        "duration=permanent&"
        "scope=identity%20vote%20submit%20subscribe";
    launchURL(authUrl);
  }

  bool tryAuthentication(String authUrl) {
    final uri = Uri.parse(authUrl);
    String state = uri.queryParameters["state"];
    String code = uri.queryParameters["code"];
    if (state != null && code != null) {
      if (state != _authState) {
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
            redditRefreshToken = refreshToken;
            redditAccessToken = accessToken;
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
        HttpHeaders.authorizationHeader: "bearer ${redditAccessToken}"
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
        redditUsername = username;
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
        'refresh_token': redditRefreshToken,
      },
      headers: <String, String>{
        'User-Agent': 'BeatScratch App!',
        HttpHeaders.authorizationHeader: "Basic ${authHeader}"
      },
    ).then((response) {
      final data = jsonDecode(response.body);
      String accessToken = data['access_token'];
      if (accessToken != null) {
        redditAccessToken = accessToken;
      }
    });
  }
}
