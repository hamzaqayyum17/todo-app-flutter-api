import 'package:flutter/material.dart';
import 'package:todolistapp/model/task.dart';
import '../db/task_repository.dart';
import 'addnewtask.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskRepository repo = TaskRepository();

  List<Task> tasks = []; // now loaded from the database
  bool isLoading = true;
  String filter = 'All'; // All, Pending, Done
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final result = await repo.getAll();
      if (!mounted) return;
      setState(() {
        tasks = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e is UnauthorizedException
            ? e.toString()
            : 'Cannot reach the server.\nCheck that the API is running and the phone is on the same Wi-Fi.';
      });
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  List<Task> get visibleTasks {
    final list = tasks.where((t) {
      if (filter == 'Pending') return !t.isCompleted;
      if (filter == 'Done') return t.isCompleted;
      return true;
    }).toList();

    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      return a.date.compareTo(b.date);
    });

    return list;
  }

  Future<void> deleteTask(Task task) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          '"${task.title}" will be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await repo.delete(task.id!);
      await loadTasks();
    } catch (e) {
      showMessage('Could not delete the task. Is the server running?');
    }
  }

  Future<void> toggleComplete(Task task) async {
    final bool old = task.isCompleted;
    task.isCompleted = !old;
    try {
      await repo.update(task);
      await loadTasks();
    } catch (e) {
      task.isCompleted = old; // undo the change
      showMessage('Could not update the task. Is the server running?');
      if (mounted) setState(() {});
    }
  }

  Future<void> openEditScreen(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );
    await loadTasks();
  }

  Widget buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                loadTasks();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterBar() {
    const options = ['All', 'Pending', 'Done'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: options.map((option) {
          final bool selected = filter == option;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option),
              selected: selected,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              showCheckmark: false,
              onSelected: (_) {
                setState(() {
                  filter = option;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildTaskCard(Task task) {
    final Color priorityColor = switch (task.priority) {
      1 => Colors.green,
      3 => Colors.red,
      _ => Colors.orange,
    };

    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  task.isCompleted
                      ? Icons.check_circle
                      : Icons.pending_outlined,
                  size: 19,
                  color: task.isCompleted ? Colors.green : primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  task.isCompleted ? 'Done' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    color: task.isCompleted ? Colors.green : primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Description (only if not empty)
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 7),

            // Date and priority
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: primaryColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.priorityText,
                    style: TextStyle(
                      fontSize: 11,
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit',
                  onPressed: () => openEditScreen(task),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  onPressed: () => deleteTask(task),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: Colors.red,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: task.isCompleted
                      ? 'Mark as pending'
                      : 'Mark as complete',
                  onPressed: () => toggleComplete(task),
                  icon: Icon(
                    task.isCompleted ? Icons.undo : Icons.check_circle_outline,
                    size: 19,
                    color: task.isCompleted ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadTasks,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
          await loadTasks();
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? buildError()
          : Column(
              children: [
                buildFilterBar(),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            tasks.isEmpty ? 'No tasks yet' : 'No $filter tasks',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: list.length,
                          itemBuilder: (context, index) =>
                              buildTaskCard(list[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
