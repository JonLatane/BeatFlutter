import 'package:beatscratch_flutter_redux/beatscratch_plugin.dart';
import 'package:beatscratch_flutter_redux/colors.dart';
import 'package:beatscratch_flutter_redux/widget/keyboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ui_models.dart';

class AppSettings {
  SharedPreferences _preferences;
  AppSettings() {
    _initialize();
  }

  _initialize() async {
    _preferences = await SharedPreferences.getInstance();
    updateColors();
  }

  updateColors() {
    subBackgroundColor = darkMode ? Color(0xFF212121) : Color(0xFF424242);
    musicBackgroundColor = darkMode ? Color(0xFF424242) : Colors.white;
    musicForegroundColor = darkMode ? Colors.white : Colors.black;
    melodyColor = darkMode ? Color(0xFF424242) : Color(0xFFDDDDDD);
    BeatScratchPlugin.onSynthesizerStatusChange?.call();
  }

  String get currentScoreName =>
      _preferences?.getString('currentScoreName') ?? "Untitled Score";
  set currentScoreName(String value) =>
      _preferences?.setString("currentScoreName", value);

  bool get integratePastee => _preferences?.getBool('integratePastee') ?? true;
  set integratePastee(bool value) =>
      _preferences?.setBool("integratePastee", value);

  bool get darkMode => _preferences?.getBool('darkMode') ?? false;
  set darkMode(bool value) {
    _preferences?.setBool("darkMode", value);
    updateColors();
  }

  RenderingMode get renderMode => RenderingMode.values.firstWhere(
      (m) => m.toString().endsWith(_preferences.getString('renderMode')),
      orElse: () => RenderingMode.notation);
  set renderMode(RenderingMode value) => _preferences?.setString(
      "musicRenderingType", value.toString().split('.').last);

  double get keyboardHalfStepWidth =>
      _preferences?.getDouble('keyboardHalfStepWidth') ?? 35.0;
  set keyboardHalfStepWidth(double value) =>
      _preferences?.setDouble("keyboardHalfStepWidth", value);
}
