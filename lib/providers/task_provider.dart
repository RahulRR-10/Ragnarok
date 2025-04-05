import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../config/xp_config.dart';
import '../services/task_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../utils/firebase_utils.dart';

class TaskProvider extends ChangeNotifier {
  static const int _maxTitleLength = 100;
  static const int _maxSubtasks = 10;

  List<Task> _tasks = [];
  late final SharedPreferences _prefs;
  final TaskService _taskService = TaskService();
  bool _isLoading = false;
  String? _error;
  final _uuid = const Uuid();
  DateTime? _lastTaskCompletionTime;
  int _tasksCompletedInSession = 0;
  final int _sessionCompletions = 0;
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
    'task_master': 50,
    'epic_warrior': 10,
    'daily_champion': 5,
    'xp_master': 1000, // New achievement for XP milestones
    'quick_completer': 3, // Tasks completed in quick succession
    'consistent_planner': 5, // Tasks created with AI breakdown
    'subtask_star': 10, // New achievement for completing 10 subtasks
  };

  // Add public getter for currentUserId
  String? get currentUserId => _taskService.currentUserId;

  TaskProvider() {
    _initPrefs();
    _setupTaskListener();
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
      await _loadUserStats();
    } catch (e) {
      _error = 'Failed to initialize storage: $e';
      debugPrint(_error);
    }
  }

  void _setupTaskListener() {
    try {
      debugPrint(
          'Setting up task listener for user: ${_taskService.currentUserId}');
      _taskService.getUserTasks().listen(
        (tasks) {
          debugPrint('Received ${tasks.length} tasks from Firebase');
          _tasks = tasks;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Failed to load tasks: $error';
          debugPrint(_error);
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to setup task listener: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> _loadUserStats() async {
    try {
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
    } catch (e) {
      _error = 'Failed to load user stats: $e';
      debugPrint(_error);
    }
  }

  Future<void> addTask(Task task) async {
    _isLoading = true;
    _error = null; // Clear any previous errors
    notifyListeners();

    try {
      // Make sure authentication is fresh before proceeding
      await FirebaseUtils.reauthenticateIfNeeded();

      final userId = _taskService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Make sure the task has the current user ID
      final taskWithUserId = task.copyWith(userId: userId);

      // First add to local list for immediate UI update
      _tasks.add(taskWithUserId);
      notifyListeners();

      // Then try to save to Firebase
      try {
        // Check permissions first
        final hasPermission = await FirebaseUtils.checkDatabasePermissions();
        if (!hasPermission) {
          _error = 'Unable to save task to cloud: Permission denied';
          notifyListeners();
          return;
        }

        await _taskService.addTask(taskWithUserId);
        debugPrint('Task added successfully: ${taskWithUserId.id}');
      } catch (e) {
        // If Firebase save fails, show error but keep task in local list
        debugPrint('Error saving task to Firebase: $e');
        _error = 'Failed to sync task to cloud: $e';
        notifyListeners();

        // Handle specific Firebase errors
        if (e.toString().contains('permission-denied')) {
          _error =
              'Permission denied when saving task. Please check your connection and try again.';
        }
      }
    } catch (e) {
      debugPrint('Failed to add task: $e');
      _error = 'Failed to add task: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskInFirebase(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskService.updateTask(task);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update task: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> deleteTaskFromFirebase(String taskId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskService.deleteTask(taskId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete task: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskService.toggleTaskCompletion(taskId, isCompleted);

      // Update local stats
      if (isCompleted) {
        _updateTaskCompletionStats();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to toggle task completion: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  void _updateTaskCompletionStats() {
    final now = DateTime.now();

    // Update session completions
    _tasksCompletedInSession++;
    _prefs.setInt('tasksCompletedInSession', _tasksCompletedInSession);

    // Update streak
    _updateStreak(now);

    // Update last completion time
    _lastTaskCompletionTime = now;
    _prefs.setString('lastTaskCompletionDate', now.toIso8601String());

    // Save stats
    _saveUserStats();
  }

  void _updateStreak(DateTime now) {
    if (_lastCompletionDate == null) {
      // First completion
      _streak = 1;
    } else {
      final difference = now.difference(_lastCompletionDate!).inDays;

      if (difference == 0) {
        // Same day, streak unchanged
      } else if (difference == 1) {
        // Next day, increment streak
        _streak++;
      } else {
        // Streak broken
        _streak = 1;
      }
    }

    _lastCompletionDate = now;
    _prefs.setString('lastCompletionDate', now.toIso8601String());
    _prefs.setInt('streak', _streak);
  }

  void _saveUserStats() {
    _prefs.setInt('totalXP', _totalXP);
    _prefs.setInt('currentLevel', _currentLevel);
    _prefs.setInt('streak', _streak);
    _prefs.setInt('tasksCompletedInSession', _tasksCompletedInSession);
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

  void deleteTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }

  void toggleSubtaskCompletion(String taskId, String subtaskId) {
    debugPrint('Toggling subtask completion: task=$taskId, subtask=$subtaskId');

    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      debugPrint(
          'Found task: ${task.id}, subtasks count: ${task.subtasks.length}');

      final subtaskIndex = task.subtasks.indexWhere((s) => s.id == subtaskId);
      if (subtaskIndex != -1) {
        final subtask = task.subtasks[subtaskIndex];
        debugPrint(
            'Found subtask: ${subtask.id}, current completion status: ${subtask.isCompleted}');

        final updatedSubtask =
            subtask.copyWith(isCompleted: !subtask.isCompleted);
        final updatedSubtasks = List<Subtask>.from(task.subtasks);
        updatedSubtasks[subtaskIndex] = updatedSubtask;

        // Check if all subtasks are completed
        final allSubtasksCompleted =
            updatedSubtasks.every((s) => s.isCompleted);
        debugPrint('All subtasks completed: $allSubtasksCompleted');

        // Create updated task with completed status and timestamp
        final updatedTask = task.copyWith(
          subtasks: updatedSubtasks,
          isCompleted: allSubtasksCompleted,
          completedAt: allSubtasksCompleted ? DateTime.now() : null,
        );

        _tasks[taskIndex] = updatedTask;
        debugPrint(
            'Updated task completion status: ${updatedTask.isCompleted}');

        // Award XP when all subtasks are completed
        if (allSubtasksCompleted && !task.isCompleted) {
          _totalXP += task.xpEarned;
          _updateLevel();
          _tasksCompletedInSession++;
          debugPrint('Awarded XP: ${task.xpEarned}, new total: $_totalXP');
        }
        // Remove XP if uncompleting the last subtask
        else if (!allSubtasksCompleted && task.isCompleted) {
          _totalXP -= task.xpEarned;
          _updateLevel();
          _tasksCompletedInSession = math.max(0, _tasksCompletedInSession - 1);
          debugPrint('Removed XP: ${task.xpEarned}, new total: $_totalXP');
        }

        _saveUserStats(); // Save immediately after toggling subtask
        notifyListeners();

        // Update Firebase
        debugPrint('Updating task in Firebase');
        _taskService.updateTask(updatedTask).then((_) {
          debugPrint('Successfully updated task in Firebase');
        }).catchError((error) {
          debugPrint('Error updating task in Firebase: $error');
        });
      } else {
        debugPrint('Subtask not found: $subtaskId');
      }
    } else {
      debugPrint('Task not found: $taskId');
    }
  }

  void addXP(int amount) {
    _totalXP += amount;
    _updateLevel();
    _saveUserStats(); // Save after updating XP
    notifyListeners();
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
    final tasksWithAIBreakdown =
        _tasks.where((task) => task.subtasks.isNotEmpty).length;
    final completedSubtasks = _getCompletedSubtasksCount();

    return {
      'first_task': completedTasks >= achievementThresholds['first_task']!,
      'streak_master': _hasSevenDayStreak(),
      'subtask_star':
          completedSubtasks >= achievementThresholds['subtask_star']!,
      'task_master': completedTasks >= achievementThresholds['task_master']!,
      'epic_warrior':
          epicTasksCompleted >= achievementThresholds['epic_warrior']!,
      'daily_champion':
          tasksCompletedToday >= achievementThresholds['daily_champion']!,
      'xp_master': _totalXP >= achievementThresholds['xp_master']!,
      'quick_completer':
          _tasksCompletedInSession >= achievementThresholds['quick_completer']!,
      'consistent_planner':
          tasksWithAIBreakdown >= achievementThresholds['consistent_planner']!,
    };
  }

  bool _hasSevenDayStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastCompletionDate == null) {
      _streak = 0;
      return false;
    }

    final lastCompletion = DateTime(
      _lastCompletionDate!.year,
      _lastCompletionDate!.month,
      _lastCompletionDate!.day,
    );

    // If the last completion was today, keep the streak
    if (lastCompletion.isAtSameMomentAs(today)) {
      return _streak >= 7;
    }

    // If the last completion was yesterday, increment streak
    if (lastCompletion
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      _streak++;
      _lastCompletionDate = today;
      _saveUserStats();
      return _streak >= 7;
    }

    // If the last completion was more than 1 day ago, reset streak
    _streak = 1;
    _lastCompletionDate = today;
    _saveUserStats();
    return false;
  }

  int _calculateCurrentStreak() {
    if (_lastCompletionDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCompletion = DateTime(
      _lastCompletionDate!.year,
      _lastCompletionDate!.month,
      _lastCompletionDate!.day,
    );

    // If the last completion was today, return current streak
    if (lastCompletion.isAtSameMomentAs(today)) {
      return _streak;
    }

    // If the last completion was yesterday, increment streak
    if (lastCompletion
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      _streak++;
      _lastCompletionDate = today;
      _saveUserStats();
      return _streak;
    }

    // If the last completion was more than 1 day ago, reset streak
    _streak = 1;
    _lastCompletionDate = today;
    _saveUserStats();
    return _streak;
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
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        final task = _tasks[taskIndex];
        final subtasks = subtaskTitles
            .map((title) => Subtask(
                  id: const Uuid().v4(),
                  title: title,
                  isCompleted: false,
                ))
            .toList();

        debugPrint('Adding ${subtasks.length} subtasks to task $taskId');
        for (var subtask in subtasks) {
          debugPrint('Subtask: ${subtask.title} (${subtask.id})');
        }

        final updatedTask = task.copyWith(subtasks: subtasks);
        _tasks[taskIndex] = updatedTask;

        // Save to Firebase
        await _taskService.updateTask(updatedTask);

        debugPrint('Successfully saved subtasks to Firebase');
        notifyListeners();
      } else {
        debugPrint('Task not found: $taskId');
      }
    } catch (e) {
      debugPrint('Error adding subtasks to task: $e');
      _error = 'Failed to add subtasks: $e';
      notifyListeners();
    }
  }

  void updateTaskDifficulty(String taskId, TaskDifficulty difficulty) {
    debugPrint(
        'Updating task difficulty: task=$taskId, difficulty=$difficulty');

    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(difficulty: difficulty);
      _tasks[taskIndex] = updatedTask;

      // Save to Firebase
      debugPrint('Saving updated task difficulty to Firebase');
      _taskService.updateTask(updatedTask).then((_) {
        debugPrint('Successfully saved task difficulty to Firebase');
      }).catchError((error) {
        debugPrint('Error saving task difficulty to Firebase: $error');
      });

      notifyListeners();
    } else {
      debugPrint('Task not found: $taskId');
    }
  }

  void updateTaskXP(String taskId, int xp) {
    debugPrint('Updating task XP: task=$taskId, xp=$xp');

    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final updatedTask = task.copyWith(xpEarned: xp);
      _tasks[taskIndex] = updatedTask;

      // Save to Firebase
      debugPrint('Saving updated task XP to Firebase');
      _taskService.updateTask(updatedTask).then((_) {
        debugPrint('Successfully saved task XP to Firebase');
        notifyListeners(); // Notify listeners after successful update
      }).catchError((error) {
        debugPrint('Error saving task XP to Firebase: $error');
        _error = 'Failed to update task XP: $error';
        notifyListeners();
      });
    } else {
      debugPrint('Task not found: $taskId');
    }
  }

  int get completedTasksCount =>
      _tasks.where((task) => task.isCompleted).length;

  int get totalTasksCount => _tasks.length;

  double get completionRate =>
      totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0.0;

  List<String> get achievements {
    final achievements = <String>[];
    final totalXP = this.totalXP;
    final completedTasks = completedTasksCount;

    if (totalXP >= 1000) achievements.add('xp_master');
    if (completedTasks >= 10) achievements.add('task_master');
    if (completedTasks >= 5) achievements.add('task_warrior');
    if (completionRate >= 0.8) achievements.add('efficiency_expert');
    if (completedTasks >= 3) achievements.add('quick_completer');

    return achievements;
  }
}
