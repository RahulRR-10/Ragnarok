import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class Subtask {
  final String id;
  final String title;
  final bool isCompleted;

  Subtask({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    debugPrint('Creating Subtask from json: $json');
    try {
      // Ensure we have a valid ID
      String id = json['id']?.toString() ?? const Uuid().v4();

      // Ensure we have a valid title
      String title = json['title']?.toString() ?? '';
      if (title.isEmpty) {
        debugPrint('Warning: Empty title for subtask with ID $id');
      }

      // Ensure we have a valid isCompleted value
      bool isCompleted = false;
      if (json['isCompleted'] != null) {
        if (json['isCompleted'] is bool) {
          isCompleted = json['isCompleted'] as bool;
        } else if (json['isCompleted'] is int) {
          isCompleted = (json['isCompleted'] as int) == 1;
        } else if (json['isCompleted'] is String) {
          isCompleted = (json['isCompleted'] as String).toLowerCase() == 'true';
        }
      }

      debugPrint(
          'Created Subtask: id=$id, title=$title, isCompleted=$isCompleted');
      return Subtask(
        id: id,
        title: title,
        isCompleted: isCompleted,
      );
    } catch (e) {
      debugPrint('Error creating Subtask from json: $e');
      return Subtask(
        id: const Uuid().v4(),
        title: json['title']?.toString() ?? 'Unknown Subtask',
        isCompleted: false,
      );
    }
  }
}
