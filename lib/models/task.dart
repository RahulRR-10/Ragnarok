import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

enum TaskDifficulty {
  easy,
  medium,
  hard,
  epic,
}

class Subtask {
  final String id;
  final String title;
  bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool,
      );
}

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final List<Subtask> subtasks;
  final int xpEarned;
  final DateTime? completedAt;
  final DateTime createdAt;
  final Duration? estimatedDuration;
  final bool isRecurring;
  final String? category;
  final TaskDifficulty difficulty;

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
    required this.title,
    required this.isCompleted,
    required this.subtasks,
    required this.xpEarned,
    this.completedAt,
    required this.createdAt,
    this.estimatedDuration,
    required this.isRecurring,
    this.category,
    this.difficulty = TaskDifficulty.medium,
  })  : assert(title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(title.length <= maxTitleLength,
            'Title cannot exceed $maxTitleLength characters'),
        assert(subtasks.length <= maxSubtasks,
            'Cannot have more than $maxSubtasks subtasks'),
        assert(
            estimatedDuration == null ||
                    (estimatedDuration!.inMinutes >= 5 &&
                        estimatedDuration!.inMinutes <= 120)
                ? true
                : false,
            'Estimated duration must be between 5 and 120 minutes');

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    List<Subtask>? subtasks,
    int? xpEarned,
    DateTime? completedAt,
    DateTime? createdAt,
    Duration? estimatedDuration,
    bool? isRecurring,
    String? category,
    TaskDifficulty? difficulty,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isRecurring: isRecurring ?? this.isRecurring,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'xpEarned': xpEarned,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'estimatedDuration': estimatedDuration?.inMinutes,
      'isRecurring': isRecurring,
      'category': category,
      'difficulty': difficulty.toString(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      subtasks: (json['subtasks'] as List)
          .map((s) => Subtask.fromJson(s as Map<String, dynamic>))
          .toList(),
      xpEarned: json['xpEarned'] as int,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedDuration: json['estimatedDuration'] != null
          ? Duration(minutes: json['estimatedDuration'] as int)
          : null,
      isRecurring: json['isRecurring'] as bool,
      category: json['category'] as String?,
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
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
