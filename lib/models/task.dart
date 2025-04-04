import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

enum TaskDifficulty {
  easy,
  medium,
  hard,
  epic,
}

class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final List<Task> subtasks;
  final int xpEarned;
  final DateTime? completedAt;
  final DateTime createdAt;
  final TaskDifficulty difficulty;
  final int estimatedDuration; // in minutes
  final bool isRecurring;
  final String? category;

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
    this.xpEarned = 0,
    this.completedAt,
    DateTime? createdAt,
    this.difficulty = TaskDifficulty.medium,
    this.estimatedDuration = 15,
    this.isRecurring = false,
    this.category,
  })  : assert(title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(title.length <= maxTitleLength,
            'Title cannot exceed $maxTitleLength characters'),
        assert(subtasks.length <= maxSubtasks,
            'Cannot have more than $maxSubtasks subtasks'),
        createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    List<Task>? subtasks,
    int? xpEarned,
    DateTime? completedAt,
    DateTime? createdAt,
    TaskDifficulty? difficulty,
    int? estimatedDuration,
    bool? isRecurring,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      xpEarned: xpEarned ?? this.xpEarned,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isRecurring: isRecurring ?? this.isRecurring,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((st) => st.toJson()).toList(),
      'xpEarned': xpEarned,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'difficulty': difficulty.toString(),
      'estimatedDuration': estimatedDuration,
      'isRecurring': isRecurring,
      'category': category,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      subtasks: (json['subtasks'] as List<dynamic>)
          .map((st) => Task.fromJson(st as Map<String, dynamic>))
          .toList(),
      xpEarned: json['xpEarned'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => TaskDifficulty.medium,
      ),
      estimatedDuration: json['estimatedDuration'] as int? ?? 15,
      isRecurring: json['isRecurring'] as bool? ?? false,
      category: json['category'] as String?,
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
    // Find the closest duration base XP
    final baseXP = durationBaseXP.entries
        .reduce((a, b) => (a.key - estimatedDuration).abs() <
                (b.key - estimatedDuration).abs()
            ? a
            : b)
        .value;

    // Apply difficulty multiplier
    return (baseXP * difficultyMultipliers[difficulty]!).round();
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
}
