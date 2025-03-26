class Progress {
  final int totalXp;
  final int level;
  final int streak;
  final List<Achievement> achievements;
  final Map<String, int> dailyXp;

  Progress({
    this.totalXp = 0,
    this.level = 1,
    this.streak = 0,
    List<Achievement>? achievements,
    Map<String, int>? dailyXp,
  }) : achievements = achievements ?? [],
       dailyXp = dailyXp ?? {};

  int get xpForNextLevel => level * 100;

  int get currentLevelProgress => totalXp - ((level - 1) * 100);

  double get levelProgressPercentage =>
      (currentLevelProgress / xpForNextLevel) * 100;

  Map<String, dynamic> toJson() {
    return {
      'totalXp': totalXp,
      'level': level,
      'streak': streak,
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'dailyXp': dailyXp,
    };
  }

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      streak: json['streak'] as int? ?? 0,
      achievements:
          (json['achievements'] as List?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
      dailyXp:
          (json['dailyXp'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
    );
  }

  Progress copyWith({
    int? totalXp,
    int? level,
    int? streak,
    List<Achievement>? achievements,
    Map<String, int>? dailyXp,
  }) {
    return Progress(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      achievements: achievements ?? this.achievements,
      dailyXp: dailyXp ?? this.dailyXp,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
    );
  }
}
