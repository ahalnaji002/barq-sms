import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _darkMode = false;

  bool get isDarkMode => _darkMode;

  ThemeMode get themeMode => _darkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool("darkMode") ?? false;

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _darkMode = !_darkMode;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("darkMode", _darkMode);

    notifyListeners();
  }
}
