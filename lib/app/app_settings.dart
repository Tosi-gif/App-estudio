import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeSetting { light, dark }

enum AppTextSize { normal, large, extraLarge }

enum AppSortCriterion { date, priority, subject }

class AppSettings {
  const AppSettings({
    required this.theme,
    required this.use24HourFormat,
    required this.textSize,
    required this.sortCriterion,
  });

  final AppThemeSetting theme;
  final bool use24HourFormat;
  final AppTextSize textSize;
  final AppSortCriterion sortCriterion;

  static const AppSettings defaults = AppSettings(
    theme: AppThemeSetting.light,
    use24HourFormat: true,
    textSize: AppTextSize.normal,
    sortCriterion: AppSortCriterion.date,
  );

  static const String _themeKey = 'settings.theme';
  static const String _hourFormatKey = 'settings.use_24_hour_format';
  static const String _textSizeKey = 'settings.text_size';
  static const String _sortCriterionKey = 'settings.sort_criterion';

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
      case AppTextSize.extraLarge:
        return 1.32;
    }
  }

  AppSettings copyWith({
    AppThemeSetting? theme,
    bool? use24HourFormat,
    AppTextSize? textSize,
    AppSortCriterion? sortCriterion,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      textSize: textSize ?? this.textSize,
      sortCriterion: sortCriterion ?? this.sortCriterion,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      theme: _readTheme(prefs.getString(_themeKey)),
      use24HourFormat: prefs.getBool(_hourFormatKey) ?? true,
      textSize: _readTextSize(prefs.getString(_textSizeKey)),
      sortCriterion: _readSortCriterion(prefs.getString(_sortCriterionKey)),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    await prefs.setBool(_hourFormatKey, use24HourFormat);
    await prefs.setString(_textSizeKey, textSize.name);
    await prefs.setString(_sortCriterionKey, sortCriterion.name);
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

  static AppSortCriterion _readSortCriterion(String? raw) {
    for (final value in AppSortCriterion.values) {
      if (value.name == raw) return value;
    }
    return AppSortCriterion.date;
  }
}
