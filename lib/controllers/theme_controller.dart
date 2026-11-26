import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = ThemeMode.values.asNameMap()[prefs.getString(_key)] ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> toggle(Brightness current) async {
    _mode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
  }
}
