import 'dart:convert';
import '../model/task.dart';
import '../services/api_client.dart';

class TaskRepository {
  static const String _path = '/api/tasks';

  // GET /api/tasks
  Future<List<Task>> getAll() async {
    final response = await ApiClient.get(_path);

    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // POST /api/tasks
  Future<int> insert(Task task) async {
    final response = await ApiClient.post(_path, task.toJson());

    if (response.statusCode != 201) {
      throw Exception('Failed to add task (${response.statusCode})');
    }

    return Task.fromJson(jsonDecode(response.body)).id!;
  }

  // PUT /api/tasks/{id}
  Future<void> update(Task task) async {
    final response = await ApiClient.put('$_path/${task.id}', task.toJson());

    if (response.statusCode != 204) {
      throw Exception('Failed to update task (${response.statusCode})');
    }
  }

  // DELETE /api/tasks/{id}
  Future<void> delete(int id) async {
    final response = await ApiClient.delete('$_path/$id');

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task (${response.statusCode})');
    }
  }
}