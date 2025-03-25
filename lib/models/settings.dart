class Settings {
  final String theme;
  final bool muteNotifications;
  final bool playWhiteNoise;
  final String whiteNoiseType;
  final double whiteNoiseVolume;
  final int workDuration;
  final int shortBreakDuration;
  final int longBreakDuration;
  final String openAIKey;

  Settings({
    this.theme = 'system',
    this.muteNotifications = false,
    this.playWhiteNoise = false,
    this.whiteNoiseType = 'rain',
    this.whiteNoiseVolume = 0.5,
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.openAIKey = '',
  });

  Settings copyWith({
    String? theme,
    bool? muteNotifications,
    bool? playWhiteNoise,
    String? whiteNoiseType,
    double? whiteNoiseVolume,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    String? openAIKey,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      playWhiteNoise: playWhiteNoise ?? this.playWhiteNoise,
      whiteNoiseType: whiteNoiseType ?? this.whiteNoiseType,
      whiteNoiseVolume: whiteNoiseVolume ?? this.whiteNoiseVolume,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      openAIKey: openAIKey ?? this.openAIKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'muteNotifications': muteNotifications,
      'playWhiteNoise': playWhiteNoise,
      'whiteNoiseType': whiteNoiseType,
      'whiteNoiseVolume': whiteNoiseVolume,
      'workDuration': workDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'openAIKey': openAIKey,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      theme: json['theme'] as String? ?? 'system',
      muteNotifications: json['muteNotifications'] as bool? ?? false,
      playWhiteNoise: json['playWhiteNoise'] as bool? ?? false,
      whiteNoiseType: json['whiteNoiseType'] as String? ?? 'rain',
      whiteNoiseVolume: json['whiteNoiseVolume'] as double? ?? 0.5,
      workDuration: json['workDuration'] as int? ?? 25,
      shortBreakDuration: json['shortBreakDuration'] as int? ?? 5,
      longBreakDuration: json['longBreakDuration'] as int? ?? 15,
      openAIKey: json['openAIKey'] as String? ?? '',
    );
  }
}
