import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsProvider with ChangeNotifier {
  Settings _settings = Settings();
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  Settings get settings => _settings;

  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs.getString('settings');
      if (settingsJson != null) {
        _settings = Settings.fromJson(
          jsonDecode(settingsJson) as Map<String, dynamic>,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _prefs.setString(
        'settings',
        jsonEncode(_settings.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateTheme(String theme) async {
    _settings = _settings.copyWith(theme: theme);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool mute) async {
    _settings = _settings.copyWith(muteNotifications: mute);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> toggleWhiteNoise(bool value) async {
    _settings = _settings.copyWith(playWhiteNoise: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateWhiteNoiseType(String type) async {
    _settings = _settings.copyWith(whiteNoiseType: type);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateWhiteNoiseVolume(double value) async {
    _settings = _settings.copyWith(whiteNoiseVolume: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateWorkDuration(int minutes) async {
    _settings = _settings.copyWith(workDuration: minutes);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateShortBreakDuration(int minutes) async {
    _settings = _settings.copyWith(shortBreakDuration: minutes);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLongBreakDuration(int minutes) async {
    _settings = _settings.copyWith(longBreakDuration: minutes);
    await _saveSettings();
    notifyListeners();
  }
}
