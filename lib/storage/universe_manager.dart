import 'package:beatscratch_flutter_redux/messages/messages.dart';
import 'package:beatscratch_flutter_redux/storage/score_manager.dart';
import 'package:beatscratch_flutter_redux/storage/score_picker_preview.dart';
import 'package:beatscratch_flutter_redux/util/util.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../colors.dart';
import '../generated/protos/music.pb.dart';
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
  BSMethod refreshUniverseData;

  UniverseManager() {
    _initialize();
  }

  bool get useWebViewSignIn => _prefs?.getBool('useWebViewSignIn') ?? false;
  set useWebViewSignIn(bool v) => _prefs?.setBool("useWebViewSignIn", v);

  String get currentUniverseScore =>
      _prefs?.getString('currentUniverseScore') ?? '';
  set currentUniverseScore(String v) =>
      _prefs?.setString("currentUniverseScore", v);

  ScoreFuture get currentUniverseScoreFuture => currentUniverseScore == ''
      ? null
      : cachedUniverseData.firstWhere((d) => d.identity == currentUniverseScore,
          orElse: () => null);

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

  static const String DEFAULT_UNIVERSE_DATA_STRING =
      '[{"filePath":null,"title":"Tropico-Pastoral","author":"pseudocomposer","commentUrl":"https://reddit.com/r/BeatScratch/comments/n5f1s1/tropicopastoral/","voteCount":1,"likes":true,"fullName":"t3_n5f1s1","scoreUrl":"https://beatscratch.io/app/#/s/CZZX0"},{"filePath":null,"title":"A cheesy educational intro","author":"pseudocomposer","commentUrl":"https://reddit.com/r/BeatScratch/comments/myliqr/a_cheesy_educational_intro/","voteCount":1,"likes":true,"fullName":"t3_myliqr","scoreUrl":"https://beatscratch.io/app/#/s/ORXsf"},{"filePath":null,"title":"A longer, original demo using 5 instruments","author":"pseudocomposer","commentUrl":"https://reddit.com/r/BeatScratch/comments/my7ajg/a_longer_original_demo_using_5_instruments/","voteCount":1,"likes":true,"fullName":"t3_my7ajg","scoreUrl":"https://beatscratch.io/app/#/s/Z4hZh"},{"filePath":null,"title":"2021, From Jacob Collier’s Insta","author":"pseudocomposer","commentUrl":"https://reddit.com/r/BeatScratch/comments/mwyv7m/2021_from_jacob_colliers_insta/","voteCount":1,"likes":null,"fullName":"t3_mwyv7m","scoreUrl":"https://beatscratch.io/app/#/s/5dVNM"},{"filePath":null,"title":"Tee Time 2.6","author":"pseudocomposer","commentUrl":"https://reddit.com/r/BeatScratch/comments/lnmxyh/tee_time_26/","voteCount":1,"likes":null,"fullName":"t3_lnmxyh","scoreUrl":"https://beatscratch.io/app/#/s/rx0w0"}]';
  static final List<String> DEFAULT_UNIVERSE_DATA =
      (jsonDecode(DEFAULT_UNIVERSE_DATA_STRING) as List<dynamic>)
          .map((e) => jsonEncode(((e as Map<String, dynamic>)
            ..remove("likes")
            ..putIfAbsent("likes", () => null))))
          .toList();
  List<ScoreFuture> get __cachedUniverseData =>
      (_prefs?.getStringList('cachedUniverseData') ?? DEFAULT_UNIVERSE_DATA)
          .map((it) => ScoreFuture.fromJson(jsonDecode(it)))
          .toList();
  List<ScoreFuture> _cachedUniverseData = [];

  List<ScoreFuture> get cachedUniverseData => _cachedUniverseData;
  set cachedUniverseData(List<ScoreFuture> value) {
    _cachedUniverseData = value;
    Future.microtask(() => _prefs?.setStringList("cachedUniverseData",
        value.map((it) => jsonEncode(it.toJson())).toList()));
  }

  bool get isAuthenticated =>
      redditRefreshToken.isNotEmpty && redditUsername.isNotEmpty;

  _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedUniverseData = __cachedUniverseData;
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
        "scope=identity%20vote%20submit%20subscribe%20read%20mysubreddits";
    launchURL(authUrl,
        forceWebView: MyPlatform.isAndroid,
        webOnlyWindowName: MyPlatform.isWeb ? '_self' : null);
  }

  bool tryAuthentication(String authUrl) {
    final uri = Uri.parse(authUrl);
    String state = uri.queryParameters["state"];
    String code = uri.queryParameters["code"];
    if (state != null && code != null) {
      if (state != _authState) {
        messagesUI.sendMessage(
            message: "Auth codes did not match!",
            isError: true,
            andSetState: true);
      } else {
        //   messagesUI.sendMessage(message: "Authenticating with Reddit...", andSetState: true);
        String credentials = "${REDDIT_CLIENT_ID}:";
        Codec<String, String> stringToBase64 = utf8.fuse(base64);
        String authHeader = stringToBase64.encode(credentials);

        http.post(
          Uri.parse('https://www.reddit.com/api/v1/access_token'),
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
            messagesUI.sendMessage(
                message: "Failed to authenticate!",
                isError: true,
                andSetState: true);
          }
        });
      }
      return true;
    }
    return false;
  }

  static final Map<String, String> BASE_REQUEST_HEADERS = {
    if (!MyPlatform.isWeb) 'User-Agent': MyPlatform.userAgent,
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
    cachedUniverseData =
        cachedUniverseData.map((sf) => ScoreFuture.fromJson(sf.toJson()
          ..remove("likes")
          ..putIfAbsent("likes", () => null)));
    refreshAccessToken();
  }

  loadRedditUsername() {
    http
        .get(
      Uri.parse('https://oauth.reddit.com/api/v1/me'),
      headers: authenticatedRedditRequestHeaders,
    )
        .then((response) {
      final data = jsonDecode(response.body);
      final username = data['name'];
      if (username != null) {
        redditUsername = username;
        if (messagesUI != null) {
          messagesUI.sendMessage(
              message: "Reddit authentication successful!", andSetState: true);
        }
      } else {
        if (messagesUI != null) {
          messagesUI.sendMessage(
              message: "Failed to load Reddit user information!",
              isError: true,
              andSetState: true);
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
      Uri.parse('https://www.reddit.com/api/v1/access_token'),
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
      Uri.parse('https://www.reddit.com/api/v1/access_token'),
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
        .get(Uri.parse('https://oauth.reddit.com/r/BeatScratch/hot'),
            headers: authenticatedRedditRequestHeaders)
        .onError((error, stackTrace) {
      print(error);
      messagesUI.sendMessage(
          message: "Error loading data from Reddit!",
          isError: true,
          andSetState: true);
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

        return ScoreFuture(
            scoreUrl: url,
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
        messagesUI.sendMessage(
            message: "Error loading data from Reddit!",
            isError: true,
            andSetState: true);
      }

      List<ScoreFuture> result =
          redditEntries.map(convertRedditData).where((e) => e != null).toList();
      cachedUniverseData = result;
      return result;
    } catch (e) {
      print(e);
      messagesUI.sendMessage(
          message: "Error parsing data from Reddit!",
          isError: true,
          andSetState: true);

      return Future.value([]);
    }
  }

  vote(String fullName, bool likes, {bool andReauth = true}) async {
    http
        .post(Uri.parse('https://oauth.reddit.com/api/vote'),
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
      if (response.statusCode == 401 && andReauth) {
        await refreshAccessToken();
        return await vote(fullName, likes, andReauth: false);
      } else if (response.statusCode != 200) {
        messagesUI.sendMessage(
            message: "Error sending vote!", isError: true, andSetState: true);
      }
    });
  }

  Future<bool> findDuplicate(String scoreName, {bool andReauth = true}) async {
    return http
        .get(
            Uri.parse(
                "https://oauth.reddit.com/r/BeatScratch/search?q=${Uri.encodeComponent(scoreName)}"),
            headers: authenticatedRedditRequestHeaders)
        .then((response) async {
      if (response.statusCode != 200) {
        if (response.statusCode == 401 && andReauth) {
          await refreshAccessToken();
          return await findDuplicate(scoreName, andReauth: false);
        } else {
          messagesUI.sendMessage(
              message: "Error searching for duplicates!",
              isError: true,
              andSetState: true);
          return true;
        }
      }
      dynamic data = jsonDecode(response.body);
      List<dynamic> titles = data["data"]["children"]
          .where((it) => it["data"]["subreddit"] == "BeatScratch")
          .map((it) => it["data"]["title"] as String)
          .toList();
      return titles
          .any((t) => t.trim().toLowerCase() == scoreName.trim().toLowerCase());
    });
  }

  submitScore(Score score, {bool andReauth = true}) async {
    messagesUI.sendMessage(
        icon: Icon(FontAwesomeIcons.atom, color: chromaticSteps[0]),
        message: "Generating short URL via https://paste.ee...",
        andSetState: true);
    String scoreUrl = await score.convertToShortUrl();
    messagesUI.sendMessage(
        icon: Icon(FontAwesomeIcons.atom, color: chromaticSteps[0]),
        message: "Uploading to the Universe...",
        andSetState: true);
    http
        .post(Uri.parse('https://oauth.reddit.com/api/submit'),
            body: {
              'sr': 'BeatScratch',
              'kind': 'link',
              'title': score.name,
              'url': scoreUrl,
              'resubmit': 'true',
            },
            headers: authenticatedRedditRequestHeaders)
        .then((response) async {
      if (response.statusCode == 401 && andReauth) {
        await refreshAccessToken();
        return await submitScore(score, andReauth: false);
      } else if (response.statusCode != 200) {
        messagesUI.sendMessage(
            message: "Error uploading Score!",
            isError: true,
            andSetState: true);
      } else {
        messagesUI.sendMessage(
            icon: Icon(FontAwesomeIcons.atom, color: chromaticSteps[0]),
            message: "Upload successful!",
            andSetState: true);
        tryToSelectScore(int retries) {
          Future.delayed(Duration(seconds: 2), () {
            refreshUniverseData();
            ScoreFuture scoreFuture = cachedUniverseData.firstWhere(
                (it) => it.scoreUrl == scoreUrl,
                orElse: () => null);
            if (scoreFuture != null) {
              messagesUI.setAppState(() {
                currentUniverseScore = scoreFuture.identity;
              });
            } else if (retries > 0) {
              tryToSelectScore(retries - 1);
            }
          });
        }

        tryToSelectScore(10);
      }
    });
  }
}
