import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math' show pi;

class FocusScreen extends StatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late ConfettiController _confettiController;
  Timer? _timer;
  int _timeLeft = 25 * 60; // 25 minutes in seconds
  bool _isBreak = false;
  int _sessions = 0;
  bool _isRunning = false;
  final List<String> _selectedSubtasks = [];
  double _bookmarkTop = 0.3; // Default position at 30% from top
  double _bookmarkRight = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          if (!_isBreak) {
            _sessions++;
            _isBreak = true;
            _timeLeft = 5 * 60; // 5 minutes break
            _startTimer();
          } else {
            _isBreak = false;
            _timeLeft = 25 * 60; // 25 minutes work
          }
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _timeLeft = _isBreak ? 5 * 60 : 25 * 60;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleSubtask(String subtaskId) {
    setState(() {
      if (_selectedSubtasks.contains(subtaskId)) {
        _selectedSubtasks.remove(subtaskId);
      } else {
        _selectedSubtasks.add(subtaskId);
      }
    });
  }

  void _completeSelectedSubtasks() {
    final taskProvider = context.read<TaskProvider>();
    debugPrint(
        'Completing ${_selectedSubtasks.length} subtasks for task ${widget.task.id}');

    for (final subtaskId in _selectedSubtasks) {
      debugPrint('Toggling subtask completion: $subtaskId');
      taskProvider.toggleSubtaskCompletion(widget.task.id, subtaskId);
    }
    setState(() {
      _selectedSubtasks.clear();
    });

    // Get the updated task after completing subtasks
    final updatedTask =
        taskProvider.tasks.firstWhere((t) => t.id == widget.task.id);
    debugPrint('Updated task after completing subtasks: ${updatedTask.id}');
    debugPrint(
        'All subtasks completed: ${updatedTask.subtasks.every((subtask) => subtask.isCompleted)}');
    debugPrint('Task already completed: ${updatedTask.isCompleted}');

    // Check if all subtasks are completed
    if (updatedTask.subtasks.every((subtask) => subtask.isCompleted)) {
      // Mark the main task as complete and award XP only if not already completed
      if (!updatedTask.isCompleted) {
        debugPrint('Marking task as complete: ${widget.task.id}');
        taskProvider.toggleTaskCompletion(widget.task.id, true);
        _showCompletionPopup(updatedTask);
      }

      // Navigate back to task list screen after showing completion popup
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(
              context, true); // Return true to indicate task completion
        }
      });
    }
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

  Widget _buildBookmark() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 50,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber.shade300,
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(-2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back,
              color: Colors.deepPurple.shade800,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              'Back',
              style: TextStyle(
                color: Colors.deepPurple.shade800,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.drag_indicator),
          onPressed: () {
            // DnD functionality will be added later
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Drag and drop functionality coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Drag to reorder',
        ),
        actions: [
          if (_selectedSubtasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _completeSelectedSubtasks,
              tooltip: 'Complete selected subtasks',
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
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
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subtasks',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildSubtaskList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isBreak ? 'Break Time' : 'Focus Time',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatTime(_timeLeft),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isRunning ? _pauseTimer : _startTimer,
                            icon: Icon(
                                _isRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(_isRunning ? 'Pause' : 'Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sessions completed: $_sessions',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Draggable Curved Bookmark Bee Button
          Positioned(
            right: _bookmarkRight,
            top: screenSize.height * _bookmarkTop,
            child: Draggable(
              feedback: _buildBookmark(),
              childWhenDragging: Container(), // Empty container when dragging
              onDragEnd: (details) {
                setState(() {
                  // Calculate new position as percentage of screen height
                  _bookmarkTop = (details.offset.dy / screenSize.height)
                      .clamp(0.1, 0.9); // Keep within 10-90% of screen height
                  _bookmarkRight = 0; // Keep at right edge
                });
              },
              child: _buildBookmark(),
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

  Widget _buildSubtaskList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final task =
            taskProvider.tasks.firstWhere((t) => t.id == widget.task.id);

        if (task.subtasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'No subtasks created yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use AI breakdown when creating tasks\nto get step-by-step guidance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: task.subtasks.length,
          itemBuilder: (context, index) {
            final subtask = task.subtasks[index];
            final isSelected = _selectedSubtasks.contains(subtask.id);
            final isCompleted = subtask.isCompleted;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Colors.deepPurple.shade300
                      : Colors.deepPurple.shade100,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  // If in selection mode, toggle selection
                  if (_selectedSubtasks.isNotEmpty) {
                    _toggleSubtask(subtask.id);
                  } else {
                    // Otherwise, toggle completion directly
                    taskProvider.toggleSubtaskCompletion(task.id, subtask.id);
                    setState(() {}); // Force UI update

                    // Get the updated task after toggling subtask
                    final updatedTask =
                        taskProvider.tasks.firstWhere((t) => t.id == task.id);

                    // Check if all subtasks are completed after toggling
                    if (updatedTask.subtasks.every((s) => s.isCompleted)) {
                      // Mark the main task as complete and award XP only if not already completed
                      if (!updatedTask.isCompleted) {
                        taskProvider.toggleTaskCompletion(task.id, true);
                        _showCompletionPopup(updatedTask);
                      }

                      // Navigate back to task list screen after showing completion popup
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          Navigator.pop(context, true);
                        }
                      });
                    }
                  }
                },
                onLongPress: () {
                  // Start selection mode on long press
                  _toggleSubtask(subtask.id);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isCompleted,
                        onChanged: (value) {
                          taskProvider.toggleSubtaskCompletion(
                              task.id, subtask.id);
                          setState(() {}); // Force UI update

                          // Get the updated task after toggling subtask
                          final updatedTask = taskProvider.tasks
                              .firstWhere((t) => t.id == task.id);

                          // Check if all subtasks are completed after toggling
                          if (updatedTask.subtasks
                              .every((s) => s.isCompleted)) {
                            // Mark the main task as complete and award XP only if not already completed
                            if (!updatedTask.isCompleted) {
                              taskProvider.toggleTaskCompletion(task.id, true);
                              _showCompletionPopup(updatedTask);
                            }

                            // Navigate back to task list screen after showing completion popup
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                Navigator.pop(context, true);
                              }
                            });
                          }
                        },
                        activeColor: Colors.deepPurple.shade700,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple.shade900,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: Colors.deepPurple.shade900,
                            decorationThickness: 2,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
