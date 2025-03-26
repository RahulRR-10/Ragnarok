import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../config/openai_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/xp_config.dart';
import '../models/task.dart';
import 'package:uuid/uuid.dart';
import 'progress_screen.dart';
import 'main_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  Future<(List<Task>, TaskDifficulty)> _getAIBreakdown(Task task) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${OpenAIConfig.endpoint}openai/deployments/${OpenAIConfig.deploymentName}/chat/completions?api-version=2024-02-15-preview'),
        headers: {
          'Content-Type': 'application/json',
          'api-key': OpenAIConfig.apiKey,
        },
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a helpful assistant that analyzes tasks and provides:
1. A difficulty level (easy, medium, hard, or epic) based on complexity, time required, and mental effort
2. 2-3 simple, manageable steps for people with ADHD
Keep each step very short, under 50 characters.'''
            },
            {
              'role': 'user',
              'content':
                  'Analyze this task and provide difficulty level and steps: ${task.title}'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 429) {
        debugPrint('Rate limited by Azure OpenAI');
        return (<Task>[], TaskDifficulty.medium);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Extract difficulty level
        TaskDifficulty difficulty = TaskDifficulty.medium;
        if (content.toLowerCase().contains('easy')) {
          difficulty = TaskDifficulty.easy;
        } else if (content.toLowerCase().contains('hard')) {
          difficulty = TaskDifficulty.hard;
        } else if (content.toLowerCase().contains('epic')) {
          difficulty = TaskDifficulty.epic;
        }

        // Extract steps
        final steps = content
            .split('\n')
            .where((step) => step.trim().isNotEmpty)
            .map((step) {
              final cleanStep =
                  step.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
              return cleanStep.length > 90
                  ? cleanStep.substring(0, 90) + '...'
                  : cleanStep;
            })
            .where((step) => !step.toLowerCase().contains('difficulty'))
            .take(3)
            .toList();

        if (steps.isEmpty) {
          return (
            [
              Task(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: task.title.length > 90
                    ? task.title.substring(0, 90) + '...'
                    : task.title,
                isCompleted: false,
                subtasks: const [],
                xpEarned: 0,
                completedAt: null,
                createdAt: DateTime.now(),
                estimatedDuration: null,
                isRecurring: false,
                category: null,
                difficulty: difficulty,
              )
            ],
            difficulty
          );
        }

        return (
          steps
              .map((step) => Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString() +
                        '_${steps.indexOf(step)}',
                    title: step,
                    isCompleted: false,
                    subtasks: const [],
                    xpEarned: 0,
                    completedAt: null,
                    createdAt: DateTime.now(),
                    estimatedDuration: null,
                    isRecurring: false,
                    category: null,
                    difficulty: difficulty,
                  ))
              .toList(),
          difficulty
        );
      }

      debugPrint(
          'Azure OpenAI error: ${response.statusCode} - ${response.body}');
      return (<Task>[], TaskDifficulty.medium);
    } catch (e) {
      debugPrint('Error getting AI breakdown: $e');
      return (<Task>[], TaskDifficulty.medium);
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool useAIBreakdown = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Use AI to analyze task'),
                  subtitle: const Text('Get difficulty level and subtasks'),
                  value: useAIBreakdown,
                  onChanged: (value) {
                    setState(() {
                      useAIBreakdown = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final task = Task(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    isCompleted: false,
                    subtasks: const [],
                    xpEarned: 0,
                    completedAt: null,
                    createdAt: DateTime.now(),
                    estimatedDuration: null,
                    isRecurring: false,
                    category: null,
                    difficulty: TaskDifficulty.medium,
                  );
                  context.read<TaskProvider>().addTask(task);

                  if (useAIBreakdown) {
                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing task...'),
                          ],
                        ),
                      ),
                    );

                    // Get AI breakdown
                    final (subtasks, difficulty) = await _getAIBreakdown(task);

                    // Close loading dialog
                    Navigator.pop(context);

                    // Update task difficulty
                    context
                        .read<TaskProvider>()
                        .updateTaskDifficulty(task.id, difficulty);

                    if (subtasks.isNotEmpty) {
                      // Show confirmation dialog
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Task Analysis'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Difficulty: ${difficulty.name.toUpperCase()}'),
                              const SizedBox(height: 16),
                              const Text('Generated subtasks:'),
                              const SizedBox(height: 8),
                              ...subtasks.map((subtask) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text('• ${subtask.title}'),
                                  )),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Use These Subtasks'),
                            ),
                          ],
                        ),
                      );

                      if (shouldProceed == true) {
                        // Add subtasks to the task
                        await context.read<TaskProvider>().addSubtasksToTask(
                              task.id,
                              subtasks.map((task) => task.title).toList(),
                            );
                      }
                    }
                  }

                  Navigator.pop(context);
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          backgroundColor: Colors.deepPurple.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings screen
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade300,
                Colors.deepPurple.shade600,
              ],
            ),
          ),
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.tasks.isEmpty) {
                return Center(
                  child: Text(
                    'No tasks yet. Add one to get started!',
                    style: TextStyle(
                      color: Colors.amber[300],
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: taskProvider.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskProvider.tasks[index];
                  return _buildTaskItem(task);
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTaskDialog,
          backgroundColor: Colors.amber[300],
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              context.read<TaskProvider>().toggleTaskCompletion(task.id);
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${task.subtasks.length} subtasks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(task.difficulty).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.difficulty.name.toUpperCase(),
                  style: TextStyle(
                    color: _getDifficultyColor(task.difficulty),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.isCompleted && task.xpEarned > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${task.xpEarned} XP',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: Text(
                          'Are you sure you want to delete "${task.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    context.read<TaskProvider>().deleteTask(task.id);
                  }
                },
              ),
              if (task.subtasks.isNotEmpty) const Icon(Icons.expand_more),
            ],
          ),
          children: [
            if (task.subtasks.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = task.subtasks[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: Checkbox(
                      value: subtask.isCompleted,
                      onChanged: (value) {
                        context.read<TaskProvider>().toggleSubtaskCompletion(
                              task.id,
                              subtask.id,
                            );
                      },
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: subtask.isCompleted ? Colors.grey : null,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
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
}
