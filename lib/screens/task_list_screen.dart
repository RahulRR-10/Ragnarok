import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../config/gemini_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';
import 'package:uuid/uuid.dart';
import 'main_screen.dart';
import 'focus_screen.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late ConfettiController _confettiController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showCompletionPopup(Task task) {
    _confettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              'Well done! +${task.xpEarned} XP',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<(List<Task>, TaskDifficulty, int)> _getAIBreakdown(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('${GeminiConfig.endpoint}?key=${GeminiConfig.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''Analyze this task and provide a response in this exact format:

DIFFICULTY: [easy/medium/hard/epic]
XP: [number between 10-100]
STEPS:
1. [First step]
2. [Second step]
3. [Third step]

Task to analyze: ${task.title}'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 150,
          },
        }),
      );

      if (response.statusCode == 429) {
        debugPrint('Rate limited by Gemini AI');
        return (<Task>[], TaskDifficulty.medium, 20);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        final difficultyMatch =
            RegExp(r'DIFFICULTY:\s*(\w+)').firstMatch(content);
        TaskDifficulty difficulty = TaskDifficulty.medium;

        if (difficultyMatch != null) {
          final difficultyStr = difficultyMatch.group(1)?.toLowerCase() ?? '';
          switch (difficultyStr) {
            case 'easy':
              difficulty = TaskDifficulty.easy;
              break;
            case 'hard':
              difficulty = TaskDifficulty.hard;
              break;
            case 'epic':
              difficulty = TaskDifficulty.epic;
              break;
          }
        }

        final xpMatch = RegExp(r'XP:\s*(\d+)').firstMatch(content);
        int xp = 20;
        if (xpMatch != null) {
          xp = int.tryParse(xpMatch.group(1) ?? '20') ?? 20;
        }

        final steps = RegExp(r'STEPS:\s*((?:\d+\.\s*[^\n]+\n?)+)')
                .firstMatch(content)
                ?.group(1)
                ?.split('\n')
                .where((step) => step.trim().isNotEmpty)
                .map((step) {
                  final cleanStep =
                      step.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
                  return cleanStep.length > 90
                      ? '${cleanStep.substring(0, 90)}...'
                      : cleanStep;
                })
                .where((step) => step.isNotEmpty)
                .take(3)
                .toList() ??
            [];

        if (steps.isEmpty) {
          debugPrint('No steps found in AI response');
          return (
            [
              Task(
                id: const Uuid().v4(),
                title: task.title.length > 90
                    ? '${task.title.substring(0, 90)}...'
                    : task.title,
                isCompleted: false,
                subtasks: const [],
                xpEarned: xp,
                completedAt: null,
                createdAt: DateTime.now(),
                estimatedDuration: null,
                isRecurring: false,
                category: null,
                difficulty: difficulty,
                isUrgent: task.isUrgent,
              )
            ],
            difficulty,
            xp
          );
        }

        return (
          steps
              .map((step) => Task(
                    id: const Uuid().v4(),
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
                    isUrgent: false,
                  ))
              .toList(),
          difficulty,
          xp
        );
      }

      debugPrint('Gemini AI error: ${response.statusCode} - ${response.body}');
      return (<Task>[], TaskDifficulty.medium, 20);
    } catch (e) {
      debugPrint('Error getting AI breakdown: $e');
      return (<Task>[], TaskDifficulty.medium, 20);
    }
  }

  Future<void> _showAddTaskDialog() async {
    final titleController = TextEditingController();
    bool useAIBreakdown = false;
    bool isUrgent = false;

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
                CheckboxListTile(
                  title: const Text('Use AI to analyze task'),
                  subtitle:
                      const Text('Get difficulty level, XP, and subtasks'),
                  value: useAIBreakdown,
                  onChanged: (value) {
                    setState(() {
                      useAIBreakdown = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('High Priority'),
                  subtitle: const Text('Mark this task as high priority'),
                  value: isUrgent,
                  onChanged: (value) {
                    setState(() {
                      isUrgent = value ?? false;
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
                  setState(() {
                    _isLoading = true;
                  });

                  final task = Task(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    isCompleted: false,
                    subtasks: const [],
                    xpEarned: useAIBreakdown ? 0 : 50,
                    completedAt: null,
                    createdAt: DateTime.now(),
                    estimatedDuration: null,
                    isRecurring: false,
                    category: null,
                    difficulty: TaskDifficulty.medium,
                    isUrgent: isUrgent,
                  );
                  context.read<TaskProvider>().addTask(task);

                  if (useAIBreakdown) {
                    final (subtasks, difficulty, xp) =
                        await _getAIBreakdown(task);

                    context
                        .read<TaskProvider>()
                        .updateTaskDifficulty(task.id, difficulty);
                    context.read<TaskProvider>().updateTaskXP(task.id, xp);

                    if (subtasks.isNotEmpty) {
                      await context.read<TaskProvider>().addSubtasksToTask(
                            task.id,
                            subtasks.map((task) => task.title).toList(),
                          );
                    }
                  }

                  setState(() {
                    _isLoading = false;
                  });
                  Navigator.pop(context);
                }
              },
              child: _isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.emoji_nature,
                          size: 20,
                          color: Colors.amber[300],
                        ),
                      ],
                    )
                  : const Text('Add Task'),
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
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Tasks'),
              backgroundColor: Colors.deepPurple,
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
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  if (taskProvider.tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks yet. Add one to get started!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
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
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.amber,
                Colors.purple,
                Colors.blue,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.deepPurple.shade50,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FocusScreen(task: task),
            ),
          ).then((completed) {
            if (completed == true) {
              setState(() {}); // Force UI update
              final taskProvider = context.read<TaskProvider>();
              final updatedTask =
                  taskProvider.tasks.firstWhere((t) => t.id == task.id);
              if (updatedTask.isCompleted) {
                _showCompletionPopup(updatedTask);
              }
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDifficultyIcon(task.difficulty),
                    size: 16,
                    color: _getDifficultyColor(task.difficulty),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(task.difficulty),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  if (task.isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber,
                              size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            'HIGH PRIORITY',
                            style: TextStyle(
                              color: Colors.amber[900],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  decorationColor: Colors.deepPurple.shade900,
                  decorationThickness: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FocusScreen(task: task),
                        ),
                      ).then((completed) {
                        if (completed == true) {
                          setState(() {}); // Force UI update
                          final taskProvider = context.read<TaskProvider>();
                          final updatedTask = taskProvider.tasks
                              .firstWhere((t) => t.id == task.id);
                          if (updatedTask.isCompleted) {
                            _showCompletionPopup(updatedTask);
                          }
                        }
                      });
                    },
                    icon: Icons.emoji_nature,
                    label: 'Focus',
                    color: Colors.deepPurple.shade900,
                    textColor: Colors.amber[300]!,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    onPressed: () {
                      context
                          .read<TaskProvider>()
                          .toggleTaskCompletion(task.id);
                      if (!task.isCompleted) {
                        _showCompletionPopup(task);
                      }
                      setState(() {}); // Force UI update after completion
                    },
                    icon: Icons.check_circle_outline,
                    label: 'Quick Complete',
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text(
                              'Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                context
                                    .read<TaskProvider>()
                                    .deleteTask(task.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.shade400,
                    tooltip: 'Delete Task',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  IconData _getDifficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.sentiment_satisfied;
      case TaskDifficulty.medium:
        return Icons.sentiment_neutral;
      case TaskDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case TaskDifficulty.epic:
        return Icons.emoji_events;
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
}
