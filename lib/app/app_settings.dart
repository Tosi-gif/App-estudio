import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeSetting { light, dark }

enum AppTextSize { normal, large }

class AppSettings {
  const AppSettings({
    required this.theme,
    required this.notificationsEnabled,
    required this.use24HourFormat,
    required this.textSize,
  });

  final AppThemeSetting theme;
  final bool notificationsEnabled;
  final bool use24HourFormat;
  final AppTextSize textSize;

  static const AppSettings defaults = AppSettings(
    theme: AppThemeSetting.light,
    notificationsEnabled: true,
    use24HourFormat: true,
    textSize: AppTextSize.normal,
  );

  static const String _themeKey = 'settings.theme';
  static const String _notificationsKey = 'settings.notifications_enabled';
  static const String _hourFormatKey = 'settings.use_24_hour_format';
  static const String _textSizeKey = 'settings.text_size';

  ThemeMode get themeMode {
    switch (theme) {
      case AppThemeSetting.light:
        return ThemeMode.light;
      case AppThemeSetting.dark:
        return ThemeMode.dark;
    }
  }

  double get textScaleFactor {
    switch (textSize) {
      case AppTextSize.normal:
        return 1.0;
      case AppTextSize.large:
        return 1.18;
    }
  }

  AppSettings copyWith({
    AppThemeSetting? theme,
    bool? notificationsEnabled,
    bool? use24HourFormat,
    AppTextSize? textSize,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      textSize: textSize ?? this.textSize,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      theme: _readTheme(prefs.getString(_themeKey)),
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
      use24HourFormat: prefs.getBool(_hourFormatKey) ?? true,
      textSize: _readTextSize(prefs.getString(_textSizeKey)),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    await prefs.setBool(_notificationsKey, notificationsEnabled);
    await prefs.setBool(_hourFormatKey, use24HourFormat);
    await prefs.setString(_textSizeKey, textSize.name);
  }

  static AppThemeSetting _readTheme(String? raw) {
    for (final value in AppThemeSetting.values) {
      if (value.name == raw) return value;
    }
    return AppThemeSetting.light;
  }

  static AppTextSize _readTextSize(String? raw) {
    for (final value in AppTextSize.values) {
      if (value.name == raw) return value;
    }
    return AppTextSize.normal;
  }
}
