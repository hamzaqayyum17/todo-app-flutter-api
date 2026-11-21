import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'homescreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService auth = AuthService();

  bool isLogin = true; // false = register mode
  bool isBusy = false;
  bool hidePassword = true;
  String? errorText;

  Future<void> submit() async {
    if (isBusy) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        errorText = 'Enter a username and password.';
      });
      return;
    }

    setState(() {
      isBusy = true;
      errorText = null;
    });

    try {
      if (isLogin) {
        await auth.login(username, password);
      } else {
        await auth.register(username, password);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isBusy = false;
        errorText = e.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isBusy = false;
        errorText = 'Something went wrong. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.checklist_rounded, size: 64, color: primary),
                const SizedBox(height: 12),
                Text(
                  isLogin ? 'Welcome back' : 'Create account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isBusy ? null : submit,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isLogin ? 'Log in' : 'Register'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          setState(() {
                            isLogin = !isLogin;
                            errorText = null;
                          });
                        },
                  child: Text(
                    isLogin
                        ? "Don't have an account? Register"
                        : 'Already have an account? Log in',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}