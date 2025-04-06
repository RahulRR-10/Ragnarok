import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';

class TaskService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get a reference to the user's tasks
  DatabaseReference get _userTasksRef {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _database.child('users').child(userId).child('tasks');
  }

  // Get a reference to the user's progress
  DatabaseReference get _userProgressRef {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _database.child('users').child(userId).child('progress');
  }

  // Get all tasks for the current user
  Stream<List<Task>> getUserTasks() {
    debugPrint('Getting tasks for user: ${currentUserId}');
    return _userTasksRef.onValue.map((event) {
      debugPrint('Firebase data snapshot: ${event.snapshot.value}');
      if (event.snapshot.value == null) {
        debugPrint('No tasks found in Firebase');
        return <Task>[];
      }

      try {
        final data = event.snapshot.value;
        if (data is! Map) {
          debugPrint('Data is not a Map: $data');
          return <Task>[];
        }

        final Map<dynamic, dynamic> taskMap = data as Map<dynamic, dynamic>;
        debugPrint('Found ${taskMap.length} tasks in Firebase');

        final tasks = taskMap.entries
            .map((entry) {
              try {
                final taskData = Map<String, dynamic>.from(entry.value as Map);
                taskData['id'] = entry.key;
                return Task.fromMap(taskData);
              } catch (e) {
                debugPrint('Error parsing task ${entry.key}: $e');
                return null;
              }
            })
            .whereType<Task>()
            .toList();

        debugPrint(
            'Successfully parsed ${tasks.length} tasks from Firebase data');
        return tasks;
      } catch (e) {
        debugPrint('Error parsing tasks from Firebase: $e');
        return <Task>[];
      }
    });
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    final taskId = _uuid.v4();
    final taskWithId = task.copyWith(id: taskId);

    await _userTasksRef.child(taskId).set(taskWithId.toMap());
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    debugPrint('Updating task ${task.id} in Firebase');
    debugPrint('Task data: ${task.toMap()}');

    try {
      await _userTasksRef.child(task.id).update(task.toMap());
      debugPrint('Successfully updated task in Firebase');
    } catch (e) {
      debugPrint('Error updating task in Firebase: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _userTasksRef.child(taskId).remove();
  }

  // Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _userTasksRef.child(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? DateTime.now().millisecondsSinceEpoch : null,
    });
  }

  // Get a single task by ID
  Future<Task?> getTaskById(String taskId) async {
    final snapshot = await _userTasksRef.child(taskId).get();

    if (!snapshot.exists) {
      return null;
    }

    final taskData = Map<String, dynamic>.from(snapshot.value as Map);
    taskData['id'] = taskId;
    return Task.fromMap(taskData);
  }

  // Save user progress data to Firebase
  Future<void> saveUserProgress({
    required int totalXP,
    required int todayXP,
    required int currentLevel,
    required int streak,
    required DateTime lastCompletionDate,
    required DateTime lastDailyResetDate,
    required Map<String, bool> achievements,
  }) async {
    debugPrint('Saving user progress to Firebase');
    debugPrint('Today\'s XP being saved: $todayXP');

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No current user ID available for saving progress');
        return;
      }

      // Store directly in the progress node (not in stats subnode)
      final progressRef =
          _database.child('users').child(userId).child('progress');

      // Update the user's progress in Firebase
      await progressRef.update({
        'totalXP': totalXP,
        'todayXP': todayXP,
        'currentLevel': currentLevel,
        'streak': streak,
        'lastCompletionDate': lastCompletionDate.millisecondsSinceEpoch,
        'lastDailyResetDate': lastDailyResetDate.millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'achievements': achievements,
      });

      debugPrint(
          'Successfully saved user progress to Firebase with todayXP: $todayXP');
    } catch (e) {
      debugPrint('Error saving user progress to Firebase: $e');
      rethrow; // Allow the caller to handle the error
    }
  }

  // Get user progress from Firebase
  Future<Map<String, dynamic>?> getUserProgress() async {
    debugPrint('Getting user progress from Firebase');
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('No current user ID available for getting progress');
        return null;
      }

      // Load directly from the progress node (not from stats subnode)
      final progressRef =
          _database.child('users').child(userId).child('progress');

      final snapshot = await progressRef.get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        debugPrint('Retrieved user progress from Firebase: $data');

        // Check if todayXP exists in the data
        if (data.containsKey('todayXP')) {
          debugPrint('Today\'s XP from Firebase: ${data['todayXP']}');
        } else {
          debugPrint('Today\'s XP field not found in Firebase data');
        }

        return data;
      } else {
        debugPrint('No progress data found for user $userId');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting user progress from Firebase: $e');
      return null;
    }
  }
}
