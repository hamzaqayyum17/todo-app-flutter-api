import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static String? token;
  static String? username;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_username';

  static bool get isLoggedIn => token != null;

  // Called once when the app starts.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    username = prefs.getString(_userKey);
  }

  static Future<void> save(String newToken, String newUsername) async {
    token = newToken;
    username = newUsername;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_userKey, newUsername);
  }

  static Future<void> clear() async {
    token = null;
    username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}