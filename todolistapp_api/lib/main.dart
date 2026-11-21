import 'package:flutter/material.dart';
import 'AppTheme/appTheme.dart';
import 'Screens/homescreen.dart';
import 'services/auth_service.dart';
import 'services/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();

  // ---- TEMPORARY TEST: remove after checking ----
  try {
    await AuthService().login('hamza', 'secret123');
    debugPrint('Login OK. Token starts with: ${Session.token!.substring(0, 20)}');
  } catch (e) {
    debugPrint('Login failed: $e');
  }
  // ------------------------------------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}