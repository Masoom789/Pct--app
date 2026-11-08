import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// Shown when Firebase could not start — the Firebase project config
/// (google-services.json) has not been added yet. The app never crashes;
/// it tells the owner exactly what to do.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24),
              PctLogoHeader(subtitle: 'Setup needed'),
              SizedBox(height: 28),
              Icon(Icons.cloud_off, size: 56, color: PctColors.gold),
              SizedBox(height: 16),
              Text(
                'Firebase is not connected yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              Text(
                'This app uses Firebase for login, data and notifications. '
                'To connect it:',
                textAlign: TextAlign.center,
                style: TextStyle(color: PctColors.muted),
              ),
              SizedBox(height: 20),
              _Step(number: '1', text: 'Go to console.firebase.google.com and create a project (free).'),
              SizedBox(height: 10),
              _Step(number: '2', text: 'Add an Android app with package name com.pakcyberteam.app.'),
              SizedBox(height: 10),
              _Step(number: '3', text: 'Download google-services.json and put it in android/app/.'),
              SizedBox(height: 10),
              _Step(number: '4', text: 'Enable Email/Password sign-in under Authentication.'),
              SizedBox(height: 10),
              _Step(number: '5', text: 'Rebuild the app — login will work.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PctColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PctColors.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: PctColors.gold,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
