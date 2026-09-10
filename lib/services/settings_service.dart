import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeModeKey = 'theme_mode';
  static const String _animationsKey = 'animations_enabled';
  static const String _geminiKey = 'gemini_api_key';
  static const String _geminiModelKey = 'gemini_model';
  static const String defaultGeminiModel = 'gemini-3.6-flash';

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final ValueNotifier<bool> animationsNotifier = ValueNotifier<bool>(true);

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_themeModeKey)) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    themeModeNotifier.value = mode;
  }

  static Future<bool> getAnimationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_animationsKey) ?? true;
  }

  static Future<void> setAnimationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsKey, enabled);
    animationsNotifier.value = enabled;
  }

  static Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiKey) ?? '';
  }

  static Future<void> setGeminiApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiKey, value.trim());
  }

  static Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_geminiModelKey);
    // Migrate old model selections that may no longer be available to new users.
    if (saved == 'gemini-2.5-flash' || saved == 'gemini-2.5-flash-lite' || saved == null || saved.isEmpty) {
      await prefs.setString(_geminiModelKey, defaultGeminiModel);
      return defaultGeminiModel;
    }
    if (saved != 'gemini-3.6-flash' && saved != 'gemini-3.5-flash-lite') {
      await prefs.setString(_geminiModelKey, defaultGeminiModel);
      return defaultGeminiModel;
    }
    return saved;
  }

  static Future<void> setGeminiModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, value.trim());
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove(_animationsKey);
    await prefs.remove(_geminiKey);
    await prefs.remove(_geminiModelKey);
    themeModeNotifier.value = ThemeMode.system;
    animationsNotifier.value = true;
  }
}
