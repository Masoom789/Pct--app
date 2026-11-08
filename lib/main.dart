import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    // No Firebase config yet (google-services.json missing).
    // App still opens and shows the setup steps instead of crashing.
    firebaseReady = false;
  }
  runApp(PctApp(firebaseReady: firebaseReady));
}

class PctApp extends StatelessWidget {
  const PctApp({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MaterialApp(
      title: 'PAK Cyber Team',
      debugShowCheckedModeBanner: false,
      theme: PctTheme.dark(),
      home: firebaseReady
          ? AuthGate(authService: authService)
          : const FirebaseSetupScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(authService: authService);
        }
        if (!user.emailVerified) {
          return VerifyEmailScreen(authService: authService);
        }
        return HomeScreen(authService: authService);
      },
    );
  }
}
