import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = false;
  bool _checking = false;
  String? _error;
  String? _info;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendCooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.authService.sendEmailVerification();
      setState(() => _info = 'Verification link sent. Check your inbox (and spam).');
      _startCooldown();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final verified = await widget.authService.reloadAndCheckVerified();
      if (!verified && mounted) {
        setState(
          () => _error = 'Email is not verified yet. Open the link in your email, then try again.',
        );
      }
      // If verified, AuthGate switches to Home automatically.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.authService.currentUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const PctLogoHeader(subtitle: 'Verify your email'),
              const SizedBox(height: 28),
              const Icon(Icons.mark_email_read_outlined, size: 56, color: PctColors.gold),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to\n$email',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Open the link in your email to activate your account. '
                'You cannot use the app until your email is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(color: PctColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                PctErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              if (_info != null) ...[
                PctInfoBanner(message: _info!),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _checking ? null : _checkVerified,
                child: _checking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text("I've verified — Continue"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: (_loading || _resendCooldown > 0) ? null : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend link in $_resendCooldown s'
                      : 'Resend verification link',
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => widget.authService.signOut(),
                  child: const Text('Use a different account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
