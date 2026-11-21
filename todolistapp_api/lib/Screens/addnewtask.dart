import 'package:flutter/material.dart';
import 'package:todolistapp/db/task_repository.dart';
import 'package:todolistapp/model/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TaskRepository repo = TaskRepository();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int priority = 2;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      titleController.text = t.title;
      descriptionController.text = t.description;
      selectedDate = t.date;
      priority = t.priority;
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]}${date.year}';
  }

  Future<void> pickedDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year + 10, 12, 31),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveTask() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    try {
      if (isEditing) {
        final t = widget.task!;
        t.title = title;
        t.description = descriptionController.text.trim();
        t.date = selectedDate;
        t.priority = priority;
        await repo.update(t);
      } else {
        await repo.insert(
          Task(
            title: title,
            description: descriptionController.text.trim(),
            date: selectedDate,
            priority: priority,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save the task. Is the server running?'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Widget sectionTitle(String title, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        required ? '$title *' : title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget priorityOption(String label, int value) {
    return RadioListTile<int>(
      value: value,
      groupValue: priority,
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (int? newValue) {
        if (newValue != null) {
          setState(() {
            priority = newValue;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Add Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle('Task Title', required: true),
                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Enter task title',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                SizedBox(height: 24),
                sectionTitle('Description'),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Enter task description...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 24),
                InkWell(
                  onTap: pickedDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_month),
                      suffixIcon: Icon(Icons.keyboard_arrow_down),
                    ),
                    child: Text(formatDate(selectedDate)),
                  ),
                ),
                SizedBox(height: 24),
                sectionTitle('Priority', required: true),
                Card(
                  child: Column(
                    children: [
                      priorityOption('Low', 1),
                      priorityOption('Medium', 2),
                      priorityOption('High', 3),
                    ],
                  ),
                ),
                SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveTask,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Task' : 'Save Task'),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
