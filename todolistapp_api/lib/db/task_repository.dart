import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../model/task.dart';

class TaskRepository {
  final String _url = '${ApiConfig.baseUrl}/api/tasks';
  final Map<String, String> _headers = {'Content-Type': 'application/json'};
  final Duration _timeout = const Duration(seconds: 10);

  // GET /api/tasks
  Future<List<Task>> getAll() async {
    final response = await http.get(Uri.parse(_url)).timeout(_timeout);

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
    final response = await http
        .post(
          Uri.parse(_url),
          headers: _headers,
          body: jsonEncode(task.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 201) {
      throw Exception('Failed to add task (${response.statusCode})');
    }

    return Task.fromJson(jsonDecode(response.body)).id!;
  }

  // PUT /api/tasks/{id}
  Future<void> update(Task task) async {
    final response = await http
        .put(
          Uri.parse('$_url/${task.id}'),
          headers: _headers,
          body: jsonEncode(task.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to update task (${response.statusCode})');
    }
  }

  // DELETE /api/tasks/{id}
  Future<void> delete(int id) async {
    final response =
        await http.delete(Uri.parse('$_url/$id')).timeout(_timeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete task (${response.statusCode})');
    }
  }
}