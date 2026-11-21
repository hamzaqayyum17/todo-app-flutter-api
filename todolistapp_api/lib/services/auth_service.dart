import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'session.dart';

/// An error with a message that is safe to show to the user.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final String _base = '${ApiConfig.baseUrl}/api/auth';

  Future<void> login(String username, String password) =>
      _send('login', username, password);

  Future<void> register(String username, String password) =>
      _send('register', username, password);

  Future<void> logout() => Session.clear();

  Future<void> _send(String action, String username, String password) async {
    http.Response response;

    try {
      response = await http
          .post(
            Uri.parse('$_base/$action'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AuthException(
        'Cannot reach the server. Check that the API is running and you are on the same Wi-Fi.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await Session.save(data['token'] as String, data['username'] as String);
      return;
    }

    // The API answers errors (400, 401, 409) with a short plain-text message.
    throw AuthException(
      response.body.isNotEmpty
          ? response.body
          : 'Request failed (${response.statusCode})',
    );
  }
}