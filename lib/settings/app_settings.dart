import '../beatscratch_plugin.dart';
import '../colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui_models.dart';

class AppSettings {
  static bool initializingState = true;
  static RenderingMode globalRenderingMode = RenderingMode.notation;
  SharedPreferences _preferences;
  AppSettings() {
    _initialize();
  }

  _initialize() async {
    _preferences = await SharedPreferences.getInstance();
    _updateColors();
  }

  _updateColors() {
    subBackgroundColor = darkMode ? Color(0xFF212121) : Color(0xFF424242);
    musicBackgroundColor = darkMode ? Color(0xFF424242) : Colors.white;
    musicForegroundColor = darkMode ? Colors.white : Colors.black;
    melodyColor = darkMode ? Color(0xFF424242) : Color(0xFFDDDDDD);
    globalRenderingMode = renderingMode;
    if (!initializingState) {
      BeatScratchPlugin.onSynthesizerStatusChange?.call();
    }
  }

  String get currentScoreName =>
      _preferences?.getString('currentScoreName') ?? "Untitled Score";
  set currentScoreName(String value) =>
      _preferences?.setString("currentScoreName", value);

  RenderingMode get renderingMode => RenderingMode.values.firstWhere(
      (rm) => rm.index == (_preferences?.getInt('renderingMode') ?? 0));
  set renderingMode(RenderingMode rm) {
    globalRenderingMode = rm;
    _preferences?.setInt('renderingMode', rm.index);
  }

  List<String> get controllersReplacingKeyboard =>
      _preferences?.getStringList('controllersReplacingKeyboard') ?? [];
  set controllersReplacingKeyboard(List<String> value) =>
      _preferences?.setStringList("controllersReplacingKeyboard", value);

  bool get integratePastee => _preferences?.getBool('integratePastee') ?? true;
  set integratePastee(bool value) =>
      _preferences?.setBool("integratePastee", value);

  bool get darkMode => _preferences?.getBool('darkMode') ?? false;
  set darkMode(bool value) {
    _preferences?.setBool("darkMode", value);
    _updateColors();
  }

  bool get autoScrollLayers =>
      _preferences?.getBool('autoScrollLayers') ?? true;
  set autoScrollLayers(bool value) {
    _preferences?.setBool("autoScrollLayers", value);
  }

  double get layersColumnWidth =>
      _preferences?.getDouble('layersColumnWidth') ?? 100;
  set layersColumnWidth(double value) =>
      _preferences?.setDouble("layersColumnWidth", value);

  bool get autoScrollMusic => _preferences?.getBool('autoScrollMusic') ?? true;
  set autoScrollMusic(bool value) {
    _preferences?.setBool("autoScrollMusic", value);
  }

  bool get autoSortMusic => _preferences?.getBool('autoSortMusic') ?? true;
  set autoSortMusic(bool value) {
    _preferences?.setBool("autoSortMusic", value);
  }

  double get musicScale => _preferences?.getDouble('musicScale');
  set musicScale(double value) => _preferences?.setDouble("musicScale", value);

  bool get alignMusic => _preferences?.getBool('alignMusic') ?? true;
  set alignMusic(bool value) {
    _preferences?.setBool("alignMusic", value);
  }

  bool get partAlignMusic => _preferences?.getBool('partAlignMusic') ?? false;
  set partAlignMusic(bool value) {
    _preferences?.setBool("partAlignMusic", value);
  }

  RenderingMode get renderMode => RenderingMode.values.firstWhere(
      (m) => m.toString().endsWith(_preferences.getString('renderMode')),
      orElse: () => RenderingMode.notation);
  set renderMode(RenderingMode value) => _preferences?.setString(
      "musicRenderingType", value.toString().split('.').last);

  bool get keyboard3DTouch => _preferences?.getBool('keyboard3DTouch') ?? false;
  set keyboard3DTouch(bool value) {
    _preferences?.setBool("keyboard3DTouch", value);
  }

  bool get showBeatsBadges => _preferences?.getBool('showBeatsBadges') ?? false;
  set showBeatsBadges(bool value) {
    _preferences?.setBool("showBeatsBadges", value);
  }

  double get keyboardHalfStepWidth =>
      _preferences?.getDouble('keyboardHalfStepWidth') ?? 35.0;
  set keyboardHalfStepWidth(double value) =>
      _preferences?.setDouble("keyboardHalfStepWidth", value);
}
