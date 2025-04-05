import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'subtask.dart';
import 'package:uuid/uuid.dart';

enum TaskDifficulty {
  easy,
  medium,
  hard,
  epic,
}

class Task {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final List<Subtask> subtasks;
  final int xpEarned;
  final DateTime? completedAt;
  final DateTime createdAt;
  final Duration? estimatedDuration;
  final bool isRecurring;
  final String? category;
  final TaskDifficulty difficulty;
  final bool isUrgent;
  final DateTime? dueDate;
  final int priority; // 1: Low, 2: Medium, 3: High

  static const int maxTitleLength = 100;
  static const int maxSubtasks = 10;

  // XP multipliers for different difficulties
  static const Map<TaskDifficulty, double> difficultyMultipliers = {
    TaskDifficulty.easy: 1.0,
    TaskDifficulty.medium: 1.5,
    TaskDifficulty.hard: 2.0,
    TaskDifficulty.epic: 3.0,
  };

  // Base XP for different durations
  static const Map<int, int> durationBaseXP = {
    5: 50, // 5 minutes
    15: 100, // 15 minutes
    30: 200, // 30 minutes
    60: 400, // 1 hour
    120: 800, // 2 hours
  };

  Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.priority = 2, // Default to medium priority
    required this.subtasks,
    required this.xpEarned,
    this.completedAt,
    this.estimatedDuration,
    required this.isRecurring,
    this.category,
    required this.difficulty,
    this.isUrgent = false,
  })  : assert(title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(title.length <= maxTitleLength,
            'Title cannot exceed $maxTitleLength characters'),
        assert(subtasks.length <= maxSubtasks,
            'Cannot have more than $maxSubtasks subtasks'),
        assert(
            estimatedDuration == null ||
                    (estimatedDuration.inMinutes >= 5 &&
                        estimatedDuration.inMinutes <= 120)
                ? true
                : false,
            'Estimated duration must be between 5 and 120 minutes');

  // Create a Task from a Map (from Firebase)
  factory Task.fromMap(Map<String, dynamic> map) {
    debugPrint('Creating Task from map: $map');

    // Handle subtasks safely
    List<Subtask> parsedSubtasks = [];
    if (map['subtasks'] != null) {
      try {
        debugPrint('Subtasks data type: ${map['subtasks'].runtimeType}');
        debugPrint('Subtasks data: ${map['subtasks']}');

        if (map['subtasks'] is List) {
          final subtasksData = map['subtasks'] as List;
          debugPrint('Subtasks is a List with ${subtasksData.length} items');

          for (var i = 0; i < subtasksData.length; i++) {
            final subtask = subtasksData[i];
            debugPrint('Subtask $i: $subtask (${subtask.runtimeType})');

            if (subtask is Map) {
              final subtaskMap = Map<String, dynamic>.from(subtask);
              debugPrint('Subtask $i is a Map: $subtaskMap');
              parsedSubtasks.add(Subtask.fromJson(subtaskMap));
            } else if (subtask is String) {
              debugPrint('Subtask $i is a String: $subtask');
              parsedSubtasks.add(Subtask(
                id: const Uuid().v4(),
                title: subtask,
                isCompleted: false,
              ));
            }
          }
        } else if (map['subtasks'] is Map) {
          final subtasksMap = Map<String, dynamic>.from(map['subtasks'] as Map);
          debugPrint('Subtasks is a Map with ${subtasksMap.length} entries');

          subtasksMap.forEach((key, value) {
            debugPrint(
                'Subtask key: $key, value: $value (${value.runtimeType})');

            if (value is Map) {
              final subtaskMap = Map<String, dynamic>.from(value);
              debugPrint('Subtask $key is a Map: $subtaskMap');
              parsedSubtasks.add(Subtask.fromJson(subtaskMap));
            } else if (value is String) {
              debugPrint('Subtask $key is a String: $value');
              parsedSubtasks.add(Subtask(
                id: key,
                title: value,
                isCompleted: false,
              ));
            }
          });
        } else {
          debugPrint('Subtasks is neither List nor Map: ${map['subtasks']}');
        }

        debugPrint('Final subtasks list: ${parsedSubtasks.length} items');
      } catch (e) {
        debugPrint('Error parsing subtasks: $e');
      }
    } else {
      debugPrint('No subtasks found in map');
    }

    // Use the XP value from the map if it exists and is not 0
    int xp = map['xpEarned'] as int? ?? 0;
    if (xp == 0) {
      final difficulty = TaskDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => TaskDifficulty.medium,
      );
      final duration =
          map['estimatedDuration'] as int? ?? 30; // Default to 30 minutes
      xp = (durationBaseXP[duration] ?? 200) *
          difficultyMultipliers[difficulty]!.round();
      debugPrint(
          'Calculated XP: $xp (duration: $duration, difficulty: ${difficulty.name})');
    } else {
      debugPrint('Using XP from map: $xp');
    }

    return Task(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      subtasks: parsedSubtasks,
      xpEarned: xp,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      estimatedDuration: map['estimatedDuration'] != null
          ? Duration(minutes: map['estimatedDuration'] as int)
          : null,
      isRecurring: map['isRecurring'] as bool? ?? false,
      category: map['category'] as String?,
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
      isUrgent: map['isUrgent'] as bool? ?? false,
    );
  }

  // Convert a Task to a Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'xpEarned': xpEarned,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'estimatedDuration': estimatedDuration?.inMinutes,
      'isRecurring': isRecurring,
      'category': category,
      'difficulty': difficulty.name,
      'isUrgent': isUrgent,
    };
  }

  // Create a copy of this Task with some fields replaced
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    int? priority,
    List<Subtask>? subtasks,
    int? xpEarned,
    DateTime? completedAt,
    Duration? estimatedDuration,
    bool? isRecurring,
    String? category,
    TaskDifficulty? difficulty,
    bool? isUrgent,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: completedAt ?? this.completedAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isRecurring: isRecurring ?? this.isRecurring,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'xpEarned': xpEarned,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'estimatedDuration': estimatedDuration?.inMinutes,
      'isRecurring': isRecurring,
      'category': category,
      'difficulty': difficulty.name,
      'isUrgent': isUrgent,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: json['priority'] as int,
      subtasks: (json['subtasks'] as List)
          .map((subtask) => Subtask.fromJson(subtask))
          .toList(),
      xpEarned: json['xpEarned'] as int,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'] as int)
          : null,
      isRecurring: json['isRecurring'] as bool,
      category: json['category'] as String?,
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
      isUrgent: json['isUrgent'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  String toJsonString() => jsonEncode(toJson());

  factory Task.fromJsonString(String jsonString) =>
      Task.fromJson(jsonDecode(jsonString));

  // Calculate base XP for this task
  int calculateBaseXP() {
    if (subtasks.isEmpty) {
      // Random XP between 100-200 for tasks without subtasks
      return 100 + (DateTime.now().millisecondsSinceEpoch % 101);
    }

    // Check if all subtasks are completed
    final allSubtasksCompleted =
        subtasks.every((subtask) => subtask.isCompleted);
    if (!allSubtasksCompleted) {
      return 0; // Return 0 if not all subtasks are completed
    }

    // Base XP for completing a task with all subtasks completed
    return 100;
  }

  // Get task color based on difficulty
  Color getDifficultyColor() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.epic:
        return Colors.purple;
    }
  }

  // Get task icon based on difficulty
  IconData getDifficultyIcon() {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.star;
      case TaskDifficulty.medium:
        return Icons.star_half;
      case TaskDifficulty.hard:
        return Icons.star_border;
      case TaskDifficulty.epic:
        return Icons.auto_awesome;
    }
  }

  void toggleCompletion() {
    // Implementation of toggleCompletion method
  }
}
