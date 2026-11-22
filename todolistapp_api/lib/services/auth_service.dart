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

/// Thrown when the password is right but the email is not verified yet.
class EmailNotVerifiedException extends AuthException {
  EmailNotVerifiedException(String message) : super(message);
}

class AuthService {
  final String _base = '${ApiConfig.baseUrl}/api/auth';
  static const Duration _timeout = Duration(seconds: 20); // sending mail takes a few seconds

  // POST /api/auth/login
  Future<void> login(String email, String password) async {
    final response =
        await _post('login', {'email': email, 'password': password});

    if (response.statusCode == 200) {
      await _saveSession(response);
      return;
    }
    if (response.statusCode == 403) {
      throw EmailNotVerifiedException(_errorText(response));
    }
    throw AuthException(_errorText(response));
  }

  // POST /api/auth/register  (sends the code, returns no token yet)
  Future<void> register(String email, String password) async {
    final response =
        await _post('register', {'email': email, 'password': password});

    if (response.statusCode != 200) {
      throw AuthException(_errorText(response));
    }
  }

  // POST /api/auth/verify-email  (returns the token)
  Future<void> verifyEmail(String email, String code) async {
    final response =
        await _post('verify-email', {'email': email, 'code': code});

    if (response.statusCode == 200) {
      await _saveSession(response);
      return;
    }
    throw AuthException(_errorText(response));
  }

  // POST /api/auth/resend-otp
  Future<void> resendOtp(String email) async {
    final response = await _post('resend-otp', {'email': email});

    if (response.statusCode != 200) {
      throw AuthException(_errorText(response));
    }
  }

  Future<void> logout() => Session.clear();

  Future<http.Response> _post(String action, Map<String, dynamic> body) async {
    try {
      return await http
          .post(
            Uri.parse('$_base/$action'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } catch (_) {
      throw AuthException(
        'Cannot reach the server. Check that the API is running and you are on the same Wi-Fi.',
      );
    }
  }

  Future<void> _saveSession(http.Response response) async {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await Session.save(data['token'] as String, data['email'] as String);
  }

  // The API answers errors with a short plain-text message.
  String _errorText(http.Response response) {
    final text = response.body.trim();
    if (text.isEmpty || text.startsWith('{')) {
      return 'Request failed (${response.statusCode})';
    }
    return text;
  }
}