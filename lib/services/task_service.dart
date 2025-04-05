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
}
