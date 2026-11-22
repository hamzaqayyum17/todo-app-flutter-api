import 'package:flutter/material.dart';
import 'AppTheme/appTheme.dart';
import 'Screens/auth_screen.dart';
import 'Screens/homescreen.dart';
import 'services/api_client.dart';
import 'services/session.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();

  // When the login can no longer be renewed, go back to the login screen.
  ApiClient.onSessionExpired = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(
          notice: 'Your session has expired. Please log in again.',
        ),
      ),
      (route) => false,
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Session.isLoggedIn ? const HomeScreen() : const AuthScreen(),
    );
  }
}