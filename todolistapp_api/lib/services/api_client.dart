import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'session.dart';

/// Thrown when the login can no longer be renewed.
class UnauthorizedException implements Exception {
  @override
  String toString() => 'Your session has expired. Please log in again.';
}

/// Sends requests with the access token. On a 401 it refreshes the token
/// once and retries the request.
class ApiClient {
  static const Duration _timeout = Duration(seconds: 10);

  /// Set in main.dart: called when the session cannot be renewed.
  static void Function()? onSessionExpired;

  // While one refresh is running, other requests wait for the same result.
  static Future<bool>? _refreshing;

  static Future<http.Response> get(String path) => _send('GET', path);
  static Future<http.Response> post(String path, Object body) =>
      _send('POST', path, body);
  static Future<http.Response> put(String path, Object body) =>
      _send('PUT', path, body);
  static Future<http.Response> delete(String path) => _send('DELETE', path);

  static Future<http.Response> _send(
    String method,
    String path, [
    Object? body,
  ]) async {
    final usedToken = Session.token;
    var response = await _once(method, path, body);

    if (response.statusCode == 401) {
      if (Session.token != usedToken) {
        // Another request already renewed the token: just try again.
        response = await _once(method, path, body);
      } else if (Session.refreshToken != null && await _refresh()) {
        response = await _once(method, path, body);
      }
    }

    if (response.statusCode == 401) {
      await _expire();
      throw UnauthorizedException();
    }

    return response;
  }

  static Future<http.Response> _once(String method, String path, Object? body) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (Session.token != null) 'Authorization': 'Bearer ${Session.token}',
    };
    final encoded = body == null ? null : jsonEncode(body);

    final Future<http.Response> request;
    switch (method) {
      case 'POST':
        request = http.post(uri, headers: headers, body: encoded);
        break;
      case 'PUT':
        request = http.put(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        request = http.delete(uri, headers: headers);
        break;
      default:
        request = http.get(uri, headers: headers);
    }
    return request.timeout(_timeout);
  }

  static Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  /// true = renewed, false = the server rejected the refresh token.
  /// Network or server problems are thrown, so the user is NOT logged out
  /// just because the connection dropped.
  static Future<bool> _doRefresh() async {
    final refresh = Session.refreshToken;
    if (refresh == null) return false;

    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refresh}),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await Session.save(
        data['token'] as String,
        data['refreshToken'] as String,
        data['email'] as String,
      );
      return true;
    }

    if (response.statusCode == 401) return false;

    throw Exception('Could not renew the session (${response.statusCode}).');
  }

  static Future<void> _expire() async {
    final wasLoggedIn = Session.isLoggedIn;
    await Session.clear();
    if (wasLoggedIn) onSessionExpired?.call(); // only once, even if several requests fail
  }
}