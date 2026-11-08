import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Phase 1 home shell. Home + Profile are real; CTFs, Courses and Rooms
/// are placeholders until Phase 2 fills them in.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Best-effort push setup; never blocks the UI.
    NotificationService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(authService: widget.authService),
      const _ComingSoonTab(title: 'CTFs', note: 'Upcoming CTFs will appear here in Phase 2.'),
      const _ComingSoonTab(title: 'Courses', note: 'Academy courses will appear here in Phase 2.'),
      const _ComingSoonTab(title: 'Rooms', note: 'Challenge rooms will appear here in Phase 2.'),
      _ProfileTab(authService: widget.authService),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'CTFs'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Hacker';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your cybersecurity journey starts here.',
            style: TextStyle(color: PctColors.muted),
          ),
          const SizedBox(height: 24),
          _FeatureCard(
            icon: Icons.flag,
            title: 'CTFs',
            subtitle: 'Upcoming competitions — play solo or with your team.',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.school,
            title: 'Courses',
            subtitle: 'Learn step by step and earn certificates.',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.meeting_room,
            title: 'Rooms',
            subtitle: 'Hands-on challenge rooms, easy to expert.',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.leaderboard,
            title: 'Leaderboard',
            subtitle: 'See where you stand. (Phase 3)',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PctColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PctColors.panelBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: PctColors.gold, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: PctColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: PctColors.muted),
        onTap: onTap,
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 48, color: PctColors.gold),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PctColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final name = user?.displayName ?? '—';
    final email = user?.email ?? '—';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: PctColors.gold,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: PctColors.muted)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: PctColors.success, size: 18),
              SizedBox(width: 6),
              Text('Email verified', style: TextStyle(color: PctColors.success)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => authService.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
