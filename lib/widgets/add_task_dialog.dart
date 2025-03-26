import 'package:flutter/material.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _useAIBreakdown = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'What do you need to do?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Break down task using AI'),
              subtitle:
                  const Text('Get 2-3 simple steps to complete this task'),
              value: _useAIBreakdown,
              onChanged: (value) =>
                  setState(() => _useAIBreakdown = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        'title': _controller.text.trim(),
        'useAIBreakdown': _useAIBreakdown,
      });
    }
  }
}
