import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';

class ProgressProvider with ChangeNotifier {
  late final SharedPreferences _prefs;
  Progress _progress = Progress();
  bool _isLoading = false;

  ProgressProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
  }

  Progress get progress => _progress;
  bool get isLoading => _isLoading;

  double get currentProgress {
    final xpInCurrentLevel = _progress.totalXp % 100;
    return xpInCurrentLevel / 100;
  }

  Future<void> _loadProgress() async {
    try {
      final progressJson = _prefs.getString('progress');
      if (progressJson != null) {
        _progress = Progress.fromJson(jsonDecode(progressJson));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      await _prefs.setString('progress', jsonEncode(_progress.toJson()));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> addXP(int amount) async {
    _isLoading = true;
    notifyListeners();

    try {
      final totalXp = _progress.totalXp + amount;
      final newLevel = (totalXp / 100).floor() + 1;

      // Add daily XP
      final today = DateTime.now().toIso8601String().split('T')[0];
      final dailyXp = Map<String, int>.from(_progress.dailyXp);
      dailyXp[today] = (dailyXp[today] ?? 0) + amount;

      // Update streak
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')[0];

      int streak = _progress.streak;
      if (dailyXp.containsKey(yesterday)) {
        streak++;
      } else if (!dailyXp.containsKey(today)) {
        streak = 0;
      }

      // Check for achievements
      final achievements = List<Achievement>.from(_progress.achievements);

      // Level up achievement
      if (newLevel > _progress.level) {
        achievements.add(
          Achievement(
            id: 'level_${newLevel}',
            title: 'Level Up!',
            description: 'Reached level $newLevel',
            icon: '🎯',
            unlockedAt: DateTime.now(),
          ),
        );
      }

      // Streak achievements
      if (streak >= 7 && !achievements.any((a) => a.id == 'streak_7')) {
        achievements.add(
          Achievement(
            id: 'streak_7',
            title: 'Week Warrior',
            description: 'Maintained a 7-day streak',
            icon: '🔥',
            unlockedAt: DateTime.now(),
          ),
        );
      }

      if (streak >= 30 && !achievements.any((a) => a.id == 'streak_30')) {
        achievements.add(
          Achievement(
            id: 'streak_30',
            title: 'Monthly Master',
            description: 'Maintained a 30-day streak',
            icon: '👑',
            unlockedAt: DateTime.now(),
          ),
        );
      }

      _progress = Progress(
        totalXp: totalXp,
        level: newLevel,
        streak: streak,
        achievements: achievements,
        dailyXp: dailyXp,
      );

      await _saveProgress();
    } catch (e) {
      debugPrint('Error adding XP: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      _progress = Progress();
      await _saveProgress();
    } catch (e) {
      debugPrint('Error resetting progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Achievement> getRecentAchievements({int limit = 5}) {
    final sorted = _progress.achievements.toList()
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    return sorted.take(limit).toList();
  }

  Map<String, int> getWeeklyXP() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Map.fromEntries(
      _progress.dailyXp.entries.where((entry) {
        final date = DateTime.parse(entry.key);
        return date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart);
      }),
    );
  }

  double getAverageXPPerDay() {
    if (_progress.dailyXp.isEmpty) return 0;

    final totalXP = _progress.dailyXp.values.reduce((a, b) => a + b);
    return totalXP / _progress.dailyXp.length;
  }
}
