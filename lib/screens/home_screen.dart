import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'certificates_screen.dart';
import 'courses_screen.dart';
import 'ctfs_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'rooms_screen.dart';

/// Phase 2 home shell: Home + Profile are real; CTFs, Courses and
/// Rooms are now live Firestore lists. The bell opens the in-app
/// notifications list.
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

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(authService: widget.authService, onNavigate: _goToTab),
      const CtfsScreen(),
      const CoursesScreen(),
      const RoomsScreen(),
      _ProfileTab(authService: widget.authService),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAK Cyber Team'),
        actions: [_NotificationBell()],
      ),
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

/// Bell with an unread-count badge; opens the notifications list.
class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (context, unread, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(
                    color: PctColors.danger,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.authService, required this.onNavigate});

  final AuthService authService;
  final void Function(int index) onNavigate;

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
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.school,
            title: 'Courses',
            subtitle: 'Learn step by step and earn certificates.',
            onTap: () => onNavigate(2),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.meeting_room,
            title: 'Rooms',
            subtitle: 'Hands-on challenge rooms, easy to expert.',
            onTap: () => onNavigate(3),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.leaderboard,
            title: 'Leaderboard',
            subtitle: 'See where you stand.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LeaderboardScreen(
                    currentUserId: authService.currentUser?.uid,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.workspace_premium,
            title: 'My Certificates',
            subtitle: 'Certificates you earned, with verify codes.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CertificatesScreen(
                    userId: authService.currentUser?.uid,
                  ),
                ),
              );
            },
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
  final VoidCallback? onTap;

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
          Card(
            color: PctColors.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: PctColors.panelBorder),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.workspace_premium,
                color: PctColors.gold,
                size: 28,
              ),
              title: const Text(
                'My Certificates',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: PctColors.muted,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CertificatesScreen(
                      userId: authService.currentUser?.uid,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
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
