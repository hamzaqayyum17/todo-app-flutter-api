import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'homescreen.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  /// true when the user came from a login that said "verify your email first":
  /// no code has been sent yet in that case, so we request one on open.
  final bool sendCodeOnOpen;

  const OtpScreen({
    super.key,
    required this.email,
    this.sendCodeOnOpen = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController codeController = TextEditingController();
  final AuthService auth = AuthService();

  bool isBusy = false;
  String? errorText;
  String? infoText;
  int secondsLeft = 60; // the API allows one new code per 60 seconds
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (widget.sendCodeOnOpen) {
      secondsLeft = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => sendNewCode());
    } else {
      startTimer();
    }
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (secondsLeft <= 1) {
        t.cancel();
        setState(() {
          secondsLeft = 0;
        });
      } else {
        setState(() {
          secondsLeft--;
        });
      }
    });
  }

  void restartCooldown(int seconds) {
    setState(() {
      secondsLeft = seconds;
    });
    startTimer();
  }

  Future<void> verify() async {
    if (isBusy) return;

    final code = codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        errorText = 'Enter the 6-digit code.';
      });
      return;
    }

    setState(() {
      isBusy = true;
      errorText = null;
      infoText = null;
    });

    try {
      await auth.verifyEmail(widget.email, code);
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> sendNewCode() async {
    if (isBusy) return;

    setState(() {
      isBusy = true;
      errorText = null;
      infoText = null;
    });

    try {
      await auth.resendOtp(widget.email);
      if (!mounted) return;
      setState(() {
        isBusy = false;
        infoText = 'A new code was sent to ${widget.email}.';
      });
      restartCooldown(60);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        isBusy = false;
        errorText = e.message;
      });
      // "Please wait 42 seconds..." -> start the countdown from 42.
      final match = RegExp(r'(\d+) seconds').firstMatch(e.message);
      if (match != null) restartCooldown(int.parse(match.group(1)!));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isBusy = false;
        errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final bool canResend = secondsLeft == 0 && !isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 64, color: primary),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code we sent to',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => verify(),
                  style: const TextStyle(fontSize: 28, letterSpacing: 8),
                  decoration: const InputDecoration(
                    hintText: '------',
                    counterText: '',
                  ),
                ),

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (infoText != null) ...[
                  const SizedBox(height: 12),
                  Text(infoText!, textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isBusy ? null : verify,
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: canResend ? sendNewCode : null,
                  child: Text(
                    secondsLeft > 0
                        ? 'Resend code in ${secondsLeft}s'
                        : 'Resend code',
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