import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show pi;
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_dialog.dart';
import '../config/openai_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/xp_config.dart';
import 'package:confetti/confetti.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  static Future<List<String>> getAIBreakdown(String taskTitle) async {
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
                  'You are a helpful assistant that breaks down tasks into 2-3 simple, manageable steps for people with ADHD. Keep each step very short, under 50 characters.'
            },
            {
              'role': 'user',
              'content':
                  'Break down this task into 2-3 simple steps: $taskTitle'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 429) {
        debugPrint('Rate limited by Azure OpenAI');
        return [
          'Step 1: ${taskTitle.length > 90 ? taskTitle.substring(0, 90) + '...' : taskTitle}'
        ];
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
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
            .take(3)
            .toList();

        return steps.isEmpty
            ? [
                'Step 1: ${taskTitle.length > 90 ? taskTitle.substring(0, 90) + '...' : taskTitle}'
              ]
            : steps;
      }

      debugPrint(
          'Azure OpenAI error: ${response.statusCode} - ${response.body}');
      return [
        'Step 1: ${taskTitle.length > 90 ? taskTitle.substring(0, 90) + '...' : taskTitle}'
      ];
    } catch (e) {
      debugPrint('Error getting AI breakdown: $e');
      return [
        'Step 1: ${taskTitle.length > 90 ? taskTitle.substring(0, 90) + '...' : taskTitle}'
      ];
    }
  }

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showXPNotification(BuildContext context, int xp) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber[300], size: 24),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+$xp XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Keep up the great work!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  Future<List<String>> _showAddSubtasksDialog() async {
    final List<String> subtasks = [];
    final controller = TextEditingController();
    bool isAdding = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subtasks'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter subtask',
                    hintText: 'Type a subtask and press Enter',
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        subtasks.add(value.trim());
                        controller.clear();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (subtasks.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(subtasks[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                subtasks.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                isAdding = false;
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                isAdding = false;
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );

    return isAdding ? [] : subtasks;
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();
    TaskDifficulty selectedDifficulty = TaskDifficulty.easy;
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
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskDifficulty>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskDifficulty.values.map((difficulty) {
                    return DropdownMenuItem(
                      value: difficulty,
                      child: Text(difficulty.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDifficulty = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Use AI to break down task'),
                  subtitle: const Text('Automatically create subtasks'),
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
                  final duration = int.tryParse(durationController.text) ?? 0;
                  final taskId = await context.read<TaskProvider>().addTask(
                        titleController.text,
                        difficulty: selectedDifficulty,
                        duration: duration,
                      );

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
                            Text('Breaking down task...'),
                          ],
                        ),
                      ),
                    );

                    // Get AI breakdown
                    final subtasks = await _getAIBreakdown(Task(
                      id: taskId,
                      title: titleController.text,
                      difficulty: selectedDifficulty,
                      estimatedDuration: duration,
                      isCompleted: false,
                      subtasks: [],
                    ));

                    // Close loading dialog
                    Navigator.pop(context);

                    if (subtasks.isNotEmpty) {
                      // Show confirmation dialog
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Task Breakdown'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              taskId,
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

  Future<List<Task>> _getAIBreakdown(Task task) async {
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
                  'You are a helpful assistant that breaks down tasks into 2-3 simple, manageable steps for people with ADHD. Keep each step very short, under 50 characters.'
            },
            {
              'role': 'user',
              'content':
                  'Break down this task into 2-3 simple steps: ${task.title}'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 429) {
        debugPrint('Rate limited by Azure OpenAI');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many requests. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        return [];
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
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
            .take(3)
            .toList();

        if (steps.isEmpty) {
          return [
            Task(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: task.title.length > 90
                  ? task.title.substring(0, 90) + '...'
                  : task.title,
              difficulty: task.difficulty,
              estimatedDuration: task.estimatedDuration,
              isCompleted: false,
              subtasks: [],
            )
          ];
        }

        return steps
            .map((step) => Task(
                  id: DateTime.now().millisecondsSinceEpoch.toString() +
                      '_${steps.indexOf(step)}',
                  title: step,
                  difficulty: task.difficulty,
                  estimatedDuration:
                      (task.estimatedDuration / steps.length).round(),
                  isCompleted: false,
                  subtasks: [],
                ))
            .toList();
      }

      debugPrint(
          'Azure OpenAI error: ${response.statusCode} - ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get AI breakdown. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    } catch (e) {
      debugPrint('Error getting AI breakdown: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to get AI breakdown. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return [];
    }
  }

  IconData _getDifficultyIcon(TaskDifficulty difficulty) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.tasks.isEmpty) {
                return const Center(
                  child: Text('No tasks yet. Add one to get started!'),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              maxBlastForce: 5,
              minBlastForce: 1,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
              child: Container(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
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
            onChanged: (bool? value) async {
              if (value != null) {
                final previousState = task.isCompleted;
                final earnedXP = task.calculateBaseXP();
                await context
                    .read<TaskProvider>()
                    .toggleTaskCompletion(task.id);

                if (!previousState && value) {
                  _confettiController.play();
                  _showXPNotification(context, earnedXP);
                }
              }
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
              if (task.category != null)
                Text(
                  task.category!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              Row(
                children: [
                  Icon(
                    task.getDifficultyIcon(),
                    size: 16,
                    color: task.getDifficultyColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.difficulty.name.toUpperCase()} • ${task.estimatedDuration} min',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.xpEarned > 0)
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
              if (task.subtasks.isEmpty)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Break down task',
                  onPressed: () async {
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
                            Text('Breaking down task...'),
                          ],
                        ),
                      ),
                    );

                    // Get AI breakdown
                    final subtasks = await _getAIBreakdown(task);

                    // Close loading dialog
                    Navigator.pop(context);

                    if (subtasks.isNotEmpty) {
                      // Show confirmation dialog
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Task Breakdown'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                  },
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete task',
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
                    await context.read<TaskProvider>().deleteTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Task deleted'),
                        backgroundColor: Colors.red[700],
                        duration: const Duration(seconds: 2),
                      ),
                    );
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
                      onChanged: (bool? value) async {
                        if (value != null) {
                          final previousState = subtask.isCompleted;
                          final earnedXP = XPConfig.subtaskXP;
                          await context
                              .read<TaskProvider>()
                              .toggleSubtaskCompletion(task.id, subtask.id);

                          if (!previousState && value) {
                            _confettiController.play();
                            _showXPNotification(context, earnedXP);
                          }
                        }
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
                    trailing: subtask.xpEarned > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star,
                                    size: 14, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '${subtask.xpEarned} XP',
                                  style: TextStyle(
                                    color: Colors.amber[900],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
