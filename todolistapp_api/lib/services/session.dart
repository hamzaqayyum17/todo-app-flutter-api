import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user's token, in memory and on the phone.
class Session {
  static String? token;
  static String? email;

  // New key names: a token saved by the old username-based version is ignored.
  static const String _tokenKey = 'auth_token_v2';
  static const String _emailKey = 'auth_email';

  static bool get isLoggedIn => token != null;

  // Called once when the app starts.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
  }

  static Future<void> save(String newToken, String newEmail) async {
    token = newToken;
    email = newEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_emailKey, newEmail);
  }

  static Future<void> clear() async {
    token = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }
}