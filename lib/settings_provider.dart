import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Default values
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontScale => _fontScale;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void setFontScale(double scale) {
    // Clamp giá trị để tránh lỗi slider
    _fontScale = scale.clamp(0.8, 1.5);
    notifyListeners();
  }
}
