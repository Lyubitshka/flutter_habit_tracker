import 'package:flutter/material.dart';
import 'package:minimal_habit_tracker/theme/dark_mode.dart';
import 'package:minimal_habit_tracker/theme/light_mode.dart';

class ThemeProvider extends ChangeNotifier {
  //initially - ligth mode:
  ThemeData _themeData = lightMode;

//get current theme
  ThemeData get themeData => _themeData;

  //is current theme dark?
  bool get isDarkMode => _themeData == darkMode;

//set Theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
