enum EnginePerformanceMode {
  turbo,
  balanced,
  batterySaver,
}

enum CollisionStrategy {
  rename,
  overwrite,
  resume,
}

enum ADMThemeMode {
  system,
  light,
  dark,
  amoled,
}

class AppSettings {
  EnginePerformanceMode performanceMode;
  int defaultConnections;
  int maxConcurrentDownloads;
  int globalSpeedLimitBytes; // 0 = unlimited
  bool wifiOnly;
  bool autoResumeOnWifi;
  int batterySaverThreshold;
  ADMThemeMode themeMode;
  String customDownloadPath;
  bool autoCategorize;
  CollisionStrategy collisionStrategy;
  bool floatingMonitorEnabled;
  bool incognitoMode;
  bool soundNotification;

  AppSettings({
    this.performanceMode = EnginePerformanceMode.turbo,
    this.defaultConnections = 8,
    this.maxConcurrentDownloads = 3,
    this.globalSpeedLimitBytes = 0,
    this.wifiOnly = false,
    this.autoResumeOnWifi = true,
    this.batterySaverThreshold = 15,
    this.themeMode = ADMThemeMode.dark,
    this.customDownloadPath = '',
    this.autoCategorize = true,
    this.collisionStrategy = CollisionStrategy.rename,
    this.floatingMonitorEnabled = false,
    this.incognitoMode = false,
    this.soundNotification = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'performanceMode': performanceMode.index,
      'defaultConnections': defaultConnections,
      'maxConcurrentDownloads': maxConcurrentDownloads,
      'globalSpeedLimitBytes': globalSpeedLimitBytes,
      'wifiOnly': wifiOnly ? 1 : 0,
      'autoResumeOnWifi': autoResumeOnWifi ? 1 : 0,
      'batterySaverThreshold': batterySaverThreshold,
      'themeMode': themeMode.index,
      'customDownloadPath': customDownloadPath,
      'autoCategorize': autoCategorize ? 1 : 0,
      'collisionStrategy': collisionStrategy.index,
      'floatingMonitorEnabled': floatingMonitorEnabled ? 1 : 0,
      'incognitoMode': incognitoMode ? 1 : 0,
      'soundNotification': soundNotification ? 1 : 0,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      performanceMode: EnginePerformanceMode.values[map['performanceMode'] as int? ?? 0],
      defaultConnections: map['defaultConnections'] as int? ?? 8,
      maxConcurrentDownloads: map['maxConcurrentDownloads'] as int? ?? 3,
      globalSpeedLimitBytes: map['globalSpeedLimitBytes'] as int? ?? 0,
      wifiOnly: (map['wifiOnly'] as int? ?? 0) == 1,
      autoResumeOnWifi: (map['autoResumeOnWifi'] as int? ?? 1) == 1,
      batterySaverThreshold: map['batterySaverThreshold'] as int? ?? 15,
      themeMode: ADMThemeMode.values[map['themeMode'] as int? ?? 2], // default dark
      customDownloadPath: map['customDownloadPath'] as String? ?? '',
      autoCategorize: (map['autoCategorize'] as int? ?? 1) == 1,
      collisionStrategy: CollisionStrategy.values[map['collisionStrategy'] as int? ?? 0],
      floatingMonitorEnabled: (map['floatingMonitorEnabled'] as int? ?? 0) == 1,
      incognitoMode: (map['incognitoMode'] as int? ?? 0) == 1,
      soundNotification: (map['soundNotification'] as int? ?? 1) == 1,
    );
  }
}
