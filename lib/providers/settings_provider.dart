import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/queue_manager.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  ThemeMode get themeMode {
    switch (_settings.themeMode) {
      case ADMThemeMode.light:
        return ThemeMode.light;
      case ADMThemeMode.dark:
      case ADMThemeMode.amoled:
        return ThemeMode.dark;
      case ADMThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isAmoled => _settings.themeMode == ADMThemeMode.amoled;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings.performanceMode = EnginePerformanceMode.values[
        prefs.getInt('performanceMode') ?? EnginePerformanceMode.turbo.index];
    _settings.defaultConnections = prefs.getInt('defaultConnections') ?? 8;
    _settings.maxConcurrentDownloads = prefs.getInt('maxConcurrentDownloads') ?? 3;
    _settings.globalSpeedLimitBytes = prefs.getInt('globalSpeedLimitBytes') ?? 0;
    _settings.wifiOnly = prefs.getBool('wifiOnly') ?? false;
    _settings.autoResumeOnWifi = prefs.getBool('autoResumeOnWifi') ?? true;
    _settings.batterySaverThreshold = prefs.getInt('batterySaverThreshold') ?? 15;
    _settings.themeMode = ADMThemeMode.values[prefs.getInt('themeMode') ?? ADMThemeMode.dark.index];
    _settings.customDownloadPath = prefs.getString('customDownloadPath') ?? '';
    _settings.autoCategorize = prefs.getBool('autoCategorize') ?? true;
    _settings.collisionStrategy = CollisionStrategy.values[
        prefs.getInt('collisionStrategy') ?? CollisionStrategy.rename.index];
    _settings.floatingMonitorEnabled = prefs.getBool('floatingMonitorEnabled') ?? false;
    _settings.incognitoMode = prefs.getBool('incognitoMode') ?? false;
    _settings.soundNotification = prefs.getBool('soundNotification') ?? true;

    QueueManager.instance.settings = _settings;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    QueueManager.instance.settings = _settings;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('performanceMode', _settings.performanceMode.index);
    await prefs.setInt('defaultConnections', _settings.defaultConnections);
    await prefs.setInt('maxConcurrentDownloads', _settings.maxConcurrentDownloads);
    await prefs.setInt('globalSpeedLimitBytes', _settings.globalSpeedLimitBytes);
    await prefs.setBool('wifiOnly', _settings.wifiOnly);
    await prefs.setBool('autoResumeOnWifi', _settings.autoResumeOnWifi);
    await prefs.setInt('batterySaverThreshold', _settings.batterySaverThreshold);
    await prefs.setInt('themeMode', _settings.themeMode.index);
    await prefs.setString('customDownloadPath', _settings.customDownloadPath);
    await prefs.setBool('autoCategorize', _settings.autoCategorize);
    await prefs.setInt('collisionStrategy', _settings.collisionStrategy.index);
    await prefs.setBool('floatingMonitorEnabled', _settings.floatingMonitorEnabled);
    await prefs.setBool('incognitoMode', _settings.incognitoMode);
    await prefs.setBool('soundNotification', _settings.soundNotification);

    notifyListeners();
  }

  void setThemeMode(ADMThemeMode mode) {
    _settings.themeMode = mode;
    updateSettings(_settings);
  }

  void setDefaultConnections(int conn) {
    _settings.defaultConnections = conn;
    updateSettings(_settings);
  }

  void setPerformanceMode(EnginePerformanceMode mode) {
    _settings.performanceMode = mode;
    if (mode == EnginePerformanceMode.turbo) {
      _settings.defaultConnections = 16;
    } else if (mode == EnginePerformanceMode.batterySaver) {
      _settings.defaultConnections = 2;
    } else {
      _settings.defaultConnections = 8;
    }
    updateSettings(_settings);
  }
}
