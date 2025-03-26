import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../config/xp_config.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class TaskProvider extends ChangeNotifier {
  static const int _maxTitleLength = 100;
  static const int _maxSubtasks = 10;

  List<Task> _tasks = [];
  late final SharedPreferences _prefs;
  final bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();
  DateTime? _lastTaskCompletionTime;
  int _tasksCompletedInSession = 0;
  int _sessionCompletions = 0;
  int _totalXP = 0;
  int _currentLevel = 1;
  int _streak = 0;
  DateTime? _lastCompletionDate;

  static const int BASE_XP = 100;
  static const int SUBTASK_XP = 50;
  static const double STREAK_MULTIPLIER = 1.5;
  static const double DAILY_STREAK_MULTIPLIER = 0.1;
  static const int PERFECT_WEEK_BONUS = 300;

  // XP thresholds for levels
  static const List<int> levelThresholds = [
    0, // Level 1
    1000, // Level 2
    2500, // Level 3
    5000, // Level 4
    10000, // Level 5
    20000, // Level 6
    35000, // Level 7
    50000, // Level 8
    75000, // Level 9
    100000, // Level 10
  ];

  // Achievement thresholds
  static const Map<String, int> achievementThresholds = {
    'first_task': 1,
    'streak_master': 7,
    'subtask_star': 10,
    'ai_friend': 5,
    'speed_demon': 3,
    'task_master': 50,
    'epic_warrior': 10,
    'daily_champion': 5,
  };

  TaskProvider() {
    _initPrefs();
  }

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get sessionCompletions => _sessionCompletions;
  int get totalXP => _totalXP;
  int get currentLevel => _currentLevel;
  int get streak => _streak;

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadTasks();
    } catch (e) {
      _error = 'Failed to initialize storage: $e';
      debugPrint(_error);
    }
  }

  Future<void> _loadTasks() async {
    try {
      final tasksJson = _prefs.getStringList('tasks');
      final xp = _prefs.getInt('totalXP') ?? 0;
      final level = _prefs.getInt('currentLevel') ?? 1;
      final streak = _prefs.getInt('streak') ?? 0;
      final lastCompletionStr = _prefs.getString('lastCompletionDate');
      final tasksCompletedInSession =
          _prefs.getInt('tasksCompletedInSession') ?? 0;

      if (lastCompletionStr != null) {
        _lastCompletionDate = DateTime.parse(lastCompletionStr);
      }

      _totalXP = xp;
      _currentLevel = level;
      _streak = streak;
      _tasksCompletedInSession = tasksCompletedInSession;

      if (tasksJson != null) {
        _tasks = tasksJson
            .map((taskJson) => Task.fromJson(jsonDecode(taskJson)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load tasks: $e';
      debugPrint(_error);
    }
  }

  Future<void> _saveTasks() async {
    try {
      final tasksJson =
          _tasks.map((task) => jsonEncode(task.toJson())).toList();
      await _prefs.setStringList('tasks', tasksJson);
      await _prefs.setInt('totalXP', _totalXP);
      await _prefs.setInt('currentLevel', _currentLevel);
      await _prefs.setInt('streak', _streak);
      await _prefs.setInt('tasksCompletedInSession', _tasksCompletedInSession);
      if (_lastCompletionDate != null) {
        await _prefs.setString(
            'lastCompletionDate', _lastCompletionDate!.toIso8601String());
      }
    } catch (e) {
      _error = 'Failed to save tasks: $e';
      debugPrint(_error);
    }
  }

  bool _validateTitle(String title) {
    if (title.trim().isEmpty) {
      _error = 'Task title cannot be empty';
      return false;
    }
    if (title.length > _maxTitleLength) {
      _error = 'Task title cannot exceed $_maxTitleLength characters';
      return false;
    }
    return true;
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  void toggleTaskCompletion(String taskId) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final previousState = task.isCompleted;

      // Create a new task with toggled completion state
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        isCompleted: !previousState,
        subtasks: task.subtasks,
        xpEarned: !previousState ? calculateTaskXP(task) : 0,
        completedAt: !previousState ? DateTime.now() : null,
        createdAt: task.createdAt,
        estimatedDuration: task.estimatedDuration,
        isRecurring: task.isRecurring,
        category: task.category,
        difficulty: task.difficulty,
      );

      _tasks[taskIndex] = updatedTask;

      if (!previousState && updatedTask.isCompleted) {
        _tasksCompletedInSession++;
        _lastTaskCompletionTime = DateTime.now();
        addXP(updatedTask.xpEarned);
        _saveTasks(); // Save after updating XP and completion
      }

      notifyListeners();
    }
  }

  void addXP(int amount) {
    _totalXP += amount;
    _updateLevel();
    _saveTasks(); // Save after updating XP
    notifyListeners();
  }

  void toggleSubtaskCompletion(String taskId, String subtaskId) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final subtaskIndex =
          task.subtasks.indexWhere((subtask) => subtask.id == subtaskId);
      if (subtaskIndex != -1) {
        final subtask = task.subtasks[subtaskIndex];
        final updatedSubtask = Subtask(
          id: subtask.id,
          title: subtask.title,
          isCompleted: !subtask.isCompleted,
        );
        final updatedSubtasks = List<Subtask>.from(task.subtasks);
        updatedSubtasks[subtaskIndex] = updatedSubtask;
        _tasks[taskIndex] = task.copyWith(subtasks: updatedSubtasks);
        notifyListeners();
      }
    }
  }

  void _updateLevel() {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (_totalXP >= levelThresholds[i]) {
        _currentLevel = i + 1;
        break;
      }
    }
  }

  // Helper method to get XP needed for next level
  int getXPToNextLevel() {
    if (_currentLevel >= levelThresholds.length) {
      return 0; // Max level reached
    }
    return levelThresholds[_currentLevel] - _totalXP;
  }

  // Helper method to get XP progress in current level
  double getLevelProgress() {
    if (_currentLevel >= levelThresholds.length) {
      return 1.0; // Max level reached
    }
    final currentLevelXP = levelThresholds[_currentLevel - 1];
    final nextLevelXP = levelThresholds[_currentLevel];
    final xpInCurrentLevel = _totalXP - currentLevelXP;
    final xpNeededForLevel = nextLevelXP - currentLevelXP;
    return xpInCurrentLevel / xpNeededForLevel;
  }

  // Helper method to get XP earned today
  int getTodayXP() {
    final now = DateTime.now();
    return _tasks
        .where((task) =>
            task.isCompleted &&
            task.completedAt?.day == now.day &&
            task.completedAt?.month == now.month &&
            task.completedAt?.year == now.year)
        .fold(0, (sum, task) => sum + task.xpEarned);
  }

  // Helper method to check achievements
  Map<String, bool> checkAchievements() {
    final now = DateTime.now();
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final epicTasksCompleted = _tasks
        .where((task) =>
            task.isCompleted && task.difficulty == TaskDifficulty.epic)
        .length;
    final tasksCompletedToday = _tasks
        .where((task) =>
            task.isCompleted &&
            task.completedAt?.day == now.day &&
            task.completedAt?.month == now.month &&
            task.completedAt?.year == now.year)
        .length;

    return {
      'first_task': completedTasks >= achievementThresholds['first_task']!,
      'streak_master': _hasSevenDayStreak(),
      'subtask_star': _getCompletedSubtasksCount() >=
          achievementThresholds['subtask_star']!,
      'ai_friend': _tasks.where((task) => task.subtasks.isNotEmpty).length >=
          achievementThresholds['ai_friend']!,
      'speed_demon':
          _tasksCompletedInSession >= achievementThresholds['speed_demon']!,
      'task_master': completedTasks >= achievementThresholds['task_master']!,
      'epic_warrior':
          epicTasksCompleted >= achievementThresholds['epic_warrior']!,
      'daily_champion':
          tasksCompletedToday >= achievementThresholds['daily_champion']!,
    };
  }

  bool _hasSevenDayStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastCompletionDate == null) return false;

    final lastCompletion = DateTime(
      _lastCompletionDate!.year,
      _lastCompletionDate!.month,
      _lastCompletionDate!.day,
    );

    // If the last completion was yesterday, increment streak
    if (lastCompletion
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      _streak++;
    }
    // If the last completion was today, keep the streak
    else if (lastCompletion.isAtSameMomentAs(today)) {
      // Keep current streak
    }
    // If the last completion was more than 1 day ago, reset streak
    else {
      _streak = 1;
    }

    _lastCompletionDate = today;
    _saveTasks();

    return _streak >= 7;
  }

  int _getCompletedSubtasksCount() {
    return _tasks.fold(
        0,
        (sum, task) =>
            sum + task.subtasks.where((subtask) => subtask.isCompleted).length);
  }

  int calculateTaskXP(Task task) {
    int xp = 0;

    // Base XP for completing the task
    xp += BASE_XP;

    // Handle subtasks if they exist
    if (task.subtasks.isNotEmpty) {
      final completedSubtasks =
          task.subtasks.where((subtask) => subtask.isCompleted).length;
      final totalSubtasks = task.subtasks.length;

      // Add XP for each completed subtask
      xp += completedSubtasks * SUBTASK_XP;

      // Bonus for completing all subtasks
      if (completedSubtasks == totalSubtasks) {
        xp += PERFECT_WEEK_BONUS;
      }

      // AI breakdown bonus
      if (totalSubtasks > 0) {
        xp += XPConfig.aiBreakdownBonus;
      }
    }

    // Apply streak multiplier if available
    final streak = _calculateCurrentStreak();
    if (streak > 0) {
      final streakMultiplier = 1.0 + (streak * DAILY_STREAK_MULTIPLIER);
      xp = (xp * streakMultiplier).round();
    }

    // Apply same session multiplier if completing multiple tasks
    if (_tasksCompletedInSession > 0) {
      xp = (xp * XPConfig.sameSessionMultiplier).round();
    }

    return xp;
  }

  int _calculateCurrentStreak() {
    final dates = _tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .map((task) => DateTime(task.completedAt!.year, task.completedAt!.month,
            task.completedAt!.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a));

    var currentDate = dates[0];
    var streakDays = 1;

    for (var i = 1;
        i < dates.length && streakDays < XPConfig.maxStreakMultiplier;
        i++) {
      final expectedPreviousDay = currentDate.subtract(const Duration(days: 1));
      if (dates[i] == expectedPreviousDay) {
        streakDays++;
        currentDate = dates[i];
      } else if (dates[i].isBefore(expectedPreviousDay)) {
        break;
      }
    }

    return streakDays;
  }

  String getLevelTitle(int level) {
    const titles = [
      'Novice',
      'Apprentice',
      'Adept',
      'Expert',
      'Master',
      'Grandmaster',
      'Legend',
      'Mythic',
      'Divine',
      'Immortal'
    ];
    return titles[(level - 1) % titles.length];
  }

  Future<void> addSubtasksToTask(
      String taskId, List<String> subtaskTitles) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final subtasks = subtaskTitles
        .map((title) => Subtask(
              id: const Uuid().v4(),
              title: title,
              isCompleted: false,
            ))
        .toList();

    _tasks[taskIndex] = task.copyWith(subtasks: subtasks);
    await _saveTasks();
    notifyListeners();
  }

  void updateTaskDifficulty(String taskId, TaskDifficulty difficulty) {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      _tasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        isCompleted: task.isCompleted,
        subtasks: task.subtasks,
        xpEarned: task.xpEarned,
        completedAt: task.completedAt,
        createdAt: task.createdAt,
        estimatedDuration: task.estimatedDuration,
        isRecurring: task.isRecurring,
        category: task.category,
        difficulty: difficulty,
      );
      notifyListeners();
    }
  }
}
