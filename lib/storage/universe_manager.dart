import 'package:beatscratch_flutter_redux/messages/messages.dart';
import 'package:beatscratch_flutter_redux/storage/score_manager.dart';
import 'package:beatscratch_flutter_redux/storage/score_picker_preview.dart';
import 'package:beatscratch_flutter_redux/util/util.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_icons/flutter_icons.dart';
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
  ScoreManager scoreManager;
  MessagesUI messagesUI;
  Function(VoidCallback) setAppState;

  UniverseManager() {
    _initialize();
  }

  bool get useWebViewSignIn => _prefs?.getBool('useWebViewSignIn') ?? false;
  set useWebViewSignIn(bool v) => _prefs?.setBool("useWebViewSignIn", v);

  String get currentUniverseScore =>
      _prefs?.getString('currentUniverseScore') ?? "";
  set currentUniverseScore(String v) =>
      _prefs?.setString("currentUniverseScore", v);

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

  bool get isAuthenticated =>
      redditRefreshToken.isNotEmpty && redditUsername.isNotEmpty;

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    refreshAccessToken(andPoll: true);
  }

  String get _authState => _prefs?.getString('redditAuthState') ?? "";
  set _authState(String value) => _prefs?.setString("redditAuthState", value);

  initiateSignIn() {
    _authState = uuid.v4();
    final authUrl =
        "https://www.reddit.com/api/v1/authorize${MyPlatform.isMobile || true ? '.compact' : ''}?"
        "client_id=${UniverseManager.REDDIT_CLIENT_ID}&response_type=code&"
        "state=$_authState&"
        "redirect_uri=${UniverseManager.REDDIT_REDIRECT_URI}&"
        "duration=permanent&"
        "scope=identity%20vote%20submit%20subscribe%20read";
    launchURL(authUrl,
        forceWebView: true, forceSafariVC: true, webOnlyWindowName: '_self');
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
        // setAppState(() {
        //   messagesUI.sendMessage(message: "Authenticating with Reddit...");
        // });
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
            ...BASE_REQUEST_HEADERS,
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
                  message: "Failed to authenticate!", isError: true);
            });
          }
        });
      }
      return true;
    }
    return false;
  }

  static final Map<String, String> BASE_REQUEST_HEADERS = {
    'User-Agent': MyPlatform.userAgent,
    // 'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  Map<String, String> get authenticatedRedditRequestHeaders => {
        ...BASE_REQUEST_HEADERS,
        HttpHeaders.authorizationHeader: "bearer ${redditAccessToken}"
      };

  signOut() {
    redditAccessToken = "";
    redditUsername = "";
    redditRefreshToken = "";
    refreshAccessToken();
  }

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
                message: "Failed to load Reddit user information!",
                isError: true);
          });
        }
      }
    });
  }

  Future refreshAccessToken({bool andPoll = false}) async {
    Future result = isAuthenticated
        ? _refreshAuthenticatedAccessToken()
        : _refreshAnonymousAccessToken();

    if (andPoll) {
      Future.delayed(Duration(minutes: 30), () {});
    }
    return result;
  }

  Future _refreshAuthenticatedAccessToken() async {
    String credentials = "${REDDIT_CLIENT_ID}:";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String authHeader = stringToBase64.encode(credentials);
    return await http.post(
      'https://www.reddit.com/api/v1/access_token',
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': redditRefreshToken,
      },
      headers: <String, String>{
        ...BASE_REQUEST_HEADERS,
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

  Future _refreshAnonymousAccessToken() async {
    String credentials = "${REDDIT_CLIENT_ID}:";
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String authHeader = stringToBase64.encode(credentials);
    return await http.post(
      'https://www.reddit.com/api/v1/access_token',
      body: {
        'grant_type': 'https://oauth.reddit.com/grants/installed_client',
        'device_id': 'DO_NOT_TRACK_THIS_DEVICE',
      },
      headers: <String, String>{
        ...BASE_REQUEST_HEADERS,
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

  Future<List<ScoreFuture>> loadUniverseData() async {
    http.Response response = await http
        .get('https://oauth.reddit.com/r/BeatScratch/hot',
            headers: authenticatedRedditRequestHeaders)
        .onError((error, stackTrace) {
      setAppState(() {
        print(error);
        messagesUI.sendMessage(
            message: "Error loading data from Reddit!", isError: true);
      });
      return null;
    });
    if (response == null) {
      return [];
    }
    if (response.statusCode == 401) {
      await refreshAccessToken();
      return await loadUniverseData();
    }
    try {
      dynamic data = jsonDecode(response.body);
      ScoreFuture convertRedditData(Map<String, dynamic> redditData) {
        String title = redditData["data"]["title"];
        String author = redditData["data"]["author"];
        int voteCount = redditData["data"]["score"];
        String fullName = redditData["data"]["name"];
        bool likes = redditData["data"]["likes"]; // MUST be nullable
        String url = redditData["data"]["url_overridden_by_dest"];
        String commentUrl =
            "https://reddit.com${redditData["data"]["permalink"]}";
        Future<Score> loadScore() async {
          String scoreUrl = url;
          scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#score='), '');
          scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/score/'), '');
          scoreUrl = scoreUrl.replaceFirst(new RegExp(r'http.*#/s/'), '');
          try {
            final score = scoreFromUrlHashValue(scoreUrl);
            if (score == null) {
              throw "failed to load";
            }
            return score..name = title;
          } catch (e) {
            try {
              return scoreManager.loadPastebinScore(scoreUrl,
                  titleOverride: title);
            } catch (e) {
              return Future.value(defaultScore());
            }
          }
        }

        return ScoreFuture(loadScore(), "//universe-score://$fullName",
            title: title,
            author: author,
            commentUrl: commentUrl,
            voteCount: voteCount,
            likes: likes,
            fullName: fullName);
      }

      List<Map<String, dynamic>> redditEntries = [];
      if (data["data"] != null && data["data"]["children"] != null) {
        redditEntries = data["data"]["children"]
            .map<Map<String, dynamic>>((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        setAppState(() {
          messagesUI.sendMessage(
              message: "Error loading data from Reddit!", isError: true);
        });
      }

      return redditEntries
          .map(convertRedditData)
          .where((e) => e != null)
          .toList();
    } catch (e) {
      print(e);
      setAppState(() {
        messagesUI.sendMessage(
            message: "Error parsing data from Reddit!", isError: true);
      });
    }
  }

  vote(String fullName, bool likes, {bool andReauthorize}) async {
    http
        .post('https://oauth.reddit.com/api/vote',
            body: {
              'id': fullName,
              'dir': (likes == true
                      ? 1
                      : likes == false
                          ? -1
                          : 0)
                  .toString(),
            },
            headers: authenticatedRedditRequestHeaders)
        .then((response) async {
      if (response.statusCode == 401) {
        await refreshAccessToken();
        return await vote(fullName, likes);
      } else if (response.statusCode != 200) {
        setAppState(() {
          messagesUI.sendMessage(message: "Error sending vote!", isError: true);
        });
      }
    });
  }
}
