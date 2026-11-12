import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'certificates_screen.dart';
import 'courses_screen.dart';
import 'ctfs_screen.dart';
import 'dashboard_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'rooms_screen.dart';

/// App shell (post-login landing). Bottom tabs: Dashboard, CTFs,
/// Courses, Rooms, Profile — hosted in an [IndexedStack] so each tab
/// keeps its state while switching. A drawer gives access to every
/// section (including Labs, Leaderboard and Certificates), and the
/// bell opens the in-app notifications list.
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

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(authService: widget.authService, onNavigate: _goToTab),
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
      drawer: _AppDrawer(
        authService: widget.authService,
        currentIndex: _index,
        onSelectTab: _goToTab,
        onOpenScreen: _openScreen,
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'CTFs'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// Sidebar with the signed-in user's header and every app section.
/// Tab destinations switch the bottom tab; the rest push their screen,
/// exactly like the dashboard shortcuts do.
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.authService,
    required this.currentIndex,
    required this.onSelectTab,
    required this.onOpenScreen,
  });

  final AuthService authService;
  final int currentIndex;
  final void Function(int index) onSelectTab;
  final void Function(Widget screen) onOpenScreen;

  void _goTab(BuildContext context, int index) {
    Navigator.of(context).pop();
    onSelectTab(index);
  }

  void _goScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    onOpenScreen(screen);
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final name =
        user?.displayName ?? user?.email?.split('@').first ?? 'Hacker';
    final email = user?.email ?? '';
    final uid = user?.uid;
    return Drawer(
      backgroundColor: PctColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              name: name,
              email: email,
              photoUrl: user?.photoURL,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    selected: currentIndex == 0,
                    onTap: () => _goTab(context, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.flag,
                    label: 'CTFs',
                    selected: currentIndex == 1,
                    onTap: () => _goTab(context, 1),
                  ),
                  _DrawerItem(
                    icon: Icons.school,
                    label: 'Courses',
                    selected: currentIndex == 2,
                    onTap: () => _goTab(context, 2),
                  ),
                  _DrawerItem(
                    icon: Icons.meeting_room,
                    label: 'Rooms',
                    selected: currentIndex == 3,
                    onTap: () => _goTab(context, 3),
                  ),
                  _DrawerItem(
                    icon: Icons.science,
                    label: 'Labs',
                    onTap: () => _goScreen(
                      context,
                      const RoomsScreen(startWithLabs: true),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.leaderboard,
                    label: 'Leaderboard',
                    onTap: () => _goScreen(
                      context,
                      LeaderboardScreen(currentUserId: uid),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium,
                    label: 'Certificates',
                    onTap: () => _goScreen(
                      context,
                      CertificatesScreen(userId: uid),
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    trailing: const _UnreadBadge(),
                    onTap: () => _goScreen(context, const NotificationsScreen()),
                  ),
                  _DrawerItem(
                    icon: Icons.person,
                    label: 'Profile / Team',
                    selected: currentIndex == 4,
                    onTap: () => _goTab(context, 4),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PctColors.panelBorder),
            ListTile(
              leading: const Icon(Icons.logout, color: PctColors.danger),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: PctColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                authService.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Drawer header: avatar (profile photo when one exists, otherwise
/// the user's initial on gold), name and email.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: double.infinity,
      color: PctColors.panel,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: PctColors.gold,
            child: hasPhoto
                ? ClipOval(
                    child: Image.network(
                      photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialText(initial: initial),
                    ),
                  )
                : _InitialText(initial: initial),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: PctColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _InitialText extends StatelessWidget {
  const _InitialText({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Text(
      initial,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.black,
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? PctColors.gold : PctColors.muted,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? PctColors.gold : PctColors.text,
        ),
      ),
      trailing: trailing,
      selected: selected,
      selectedTileColor: PctColors.gold.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}

/// Small red count bubble used by the drawer's Notifications item.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (context, unread, _) {
        if (unread <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: const BoxDecoration(
            color: PctColors.danger,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Text(
            unread > 99 ? '99+' : '$unread',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
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
