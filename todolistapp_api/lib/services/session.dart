import 'package:shared_preferences/shared_preferences.dart';

/// Holds the logged-in user's tokens, in memory and on the phone.
class Session {
  static String? token; // access token, short-lived
  static String? refreshToken; // long-lived, used only to get a new access token
  static String? email;

  static const String _tokenKey = 'auth_token_v2';
  static const String _refreshKey = 'auth_refresh_token';
  static const String _emailKey = 'auth_email';

  static bool get isLoggedIn => token != null;

  // Called once when the app starts.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    refreshToken = prefs.getString(_refreshKey);
    email = prefs.getString(_emailKey);
  }

  static Future<void> save(
    String newToken,
    String newRefreshToken,
    String newEmail,
  ) async {
    token = newToken;
    refreshToken = newRefreshToken;
    email = newEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_refreshKey, newRefreshToken);
    await prefs.setString(_emailKey, newEmail);
  }

  static Future<void> clear() async {
    // The in-memory values are cleared first, before any await.
    token = null;
    refreshToken = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_emailKey);
  }
}