import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggleTask;
  final Function(String) onToggleSubtask;
  final VoidCallback onDelete;
  final VoidCallback onGetAIBreakdown;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleTask,
    required this.onToggleSubtask,
    required this.onDelete,
    required this.onGetAIBreakdown,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: widget.task.isCompleted,
              onChanged: (_) => widget.onToggleTask(),
            ),
            title: Text(
              widget.task.title,
              style: TextStyle(
                decoration:
                    widget.task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.task.subtasks.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.psychology),
                    onPressed: widget.onGetAIBreakdown,
                    tooltip: 'Get AI Breakdown',
                  ),
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ),
          if (_isExpanded && widget.task.subtasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: widget.task.subtasks.map((subtask) {
                  return CheckboxListTile(
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    value: subtask.isCompleted,
                    onChanged: (_) => widget.onToggleSubtask(subtask.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
