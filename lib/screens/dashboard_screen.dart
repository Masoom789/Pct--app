import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';
import 'course_detail_screen.dart';
import 'ctfs_screen.dart';
import 'notifications_screen.dart';

/// Dashboard tab (first tab of the app shell).
///
/// Everything here is read live through [DataService], so content the
/// admin publishes — new courses, CTFs, rooms, scores — appears here
/// automatically, and pull-to-refresh picks up anything newer. Nothing
/// is hardcoded: a section whose data is missing or unreachable shows
/// a quiet placeholder instead of fake content, and never crashes.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
    required this.onNavigate,
  });

  final AuthService authService;

  /// Switches the shell to another bottom tab (CTFs = 1, Courses = 2,
  /// Rooms = 3, Profile = 4).
  final void Function(int index) onNavigate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DataResult<List<Course>>> _coursesFuture;
  late Future<DataResult<List<Ctf>>> _ctfsFuture;
  late Future<DataResult<List<Room>>> _roomsFuture;
  late Future<DataResult<List<LeaderboardEntry>>> _boardFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _coursesFuture = DataService.instance.fetchCourses();
    _ctfsFuture = DataService.instance.fetchCtfs();
    _roomsFuture = DataService.instance.fetchRooms();
    _boardFuture = DataService.instance.fetchLeaderboard();
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([
      _coursesFuture,
      _ctfsFuture,
      _roomsFuture,
      _boardFuture,
    ]);
  }

  String get _greetingName {
    final user = widget.authService.currentUser;
    final display = user?.displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Hacker';
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $_greetingName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your cybersecurity journey starts here.',
              style: TextStyle(color: PctColors.muted),
            ),
            const SizedBox(height: 20),
            _ScoreCard(
              boardFuture: _boardFuture,
              userId: widget.authService.currentUser?.uid,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.flag,
                    label: 'CTFs',
                    future: _ctfsFuture,
                    onTap: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.school,
                    label: 'Courses',
                    future: _coursesFuture,
                    onTap: () => widget.onNavigate(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.meeting_room,
                    label: 'Rooms',
                    future: _roomsFuture,
                    onTap: () => widget.onNavigate(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Latest Courses',
              actionLabel: 'See all',
              onAction: () => widget.onNavigate(2),
            ),
            _CoursesSection(future: _coursesFuture),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Upcoming CTFs',
              actionLabel: 'See all',
              onAction: () => widget.onNavigate(1),
            ),
            _CtfsSection(future: _ctfsFuture),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Recent Notifications',
              actionLabel: 'See all',
              onAction: _openNotifications,
            ),
            const _NotificationsSection(),
          ],
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }
}

/// Panel card shape shared by the dashboard sections.
BoxDecoration get _panelDecoration => BoxDecoration(
      color: PctColors.panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: PctColors.panelBorder),
    );

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: PctColors.gold,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// The signed-in user's points + rank, read from the leaderboard's
/// Global board. Shows a clean placeholder — never an error, never
/// invented numbers — until a score for this user is published.
class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.boardFuture, required this.userId});

  final Future<DataResult<List<LeaderboardEntry>>> boardFuture;
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: FutureBuilder<DataResult<List<LeaderboardEntry>>>(
        future: boardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ScoreRow(
              title: 'My Score',
              subtitle: 'Loading your score…',
            );
          }
          final result = snapshot.data;
          if (result == null || !result.ok) {
            return const _ScoreRow(
              title: 'My Score',
              subtitle: 'Your points and rank will appear here once '
                  'scores are published.',
            );
          }
          final global = DataService.entriesForScope(
            result.data ?? <LeaderboardEntry>[],
            'global',
          );
          LeaderboardEntry? mine;
          for (final e in global) {
            if (userId != null && e.userId == userId) {
              mine = e;
              break;
            }
          }
          if (mine == null) {
            return const _ScoreRow(
              title: 'My Score',
              subtitle: 'No score yet — finish courses and solve room '
                  'challenges to earn your first points.',
            );
          }
          final rank = mine.rank > 0 ? mine.rank : global.indexOf(mine) + 1;
          return Row(
            children: [
              const Icon(Icons.emoji_events, color: PctColors.gold, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Score',
                      style: TextStyle(color: PctColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mine.points} pts',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              PctChip(label: 'Rank #$rank', icon: Icons.leaderboard),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: PctColors.gold, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: PctColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// One quick-stat card: how many items a section currently holds.
/// Shows '—' while loading or when the data is unavailable.
class _StatCard<T> extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.future,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<DataResult<List<T>>> future;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: PctColors.gold, size: 26),
              const SizedBox(height: 8),
              FutureBuilder<DataResult<List<T>>>(
                future: future,
                builder: (context, snapshot) {
                  final result = snapshot.data;
                  final value = (snapshot.connectionState ==
                              ConnectionState.done &&
                          result != null &&
                          result.ok)
                      ? '${result.data?.length ?? 0}'
                      : '—';
                  return Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: PctColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Newest courses (the courses feed's first three). The course model
/// carries no publish date, so these are the first three of the same
/// list the Courses tab shows. Tap opens the course detail.
class _CoursesSection extends StatelessWidget {
  const _CoursesSection({required this.future});

  final Future<DataResult<List<Course>>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataResult<List<Course>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionPlaceholder(text: 'Loading courses…');
        }
        final result = snapshot.data;
        if (result == null || !result.ok) {
          return const _SectionPlaceholder(
            text: 'Courses will appear here once they are published.',
          );
        }
        final courses = (result.data ?? <Course>[]).take(3).toList();
        if (courses.isEmpty) {
          return const _SectionPlaceholder(text: 'No courses published yet.');
        }
        return Column(
          children: [
            for (final course in courses)
              Card(
                color: PctColors.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PctColors.panelBorder),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.school,
                    color: PctColors.gold,
                    size: 28,
                  ),
                  title: Text(
                    course.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if (course.level.isNotEmpty) course.level,
                      if (course.duration.isNotEmpty) course.duration,
                    ].join(' • '),
                    style: const TextStyle(color: PctColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: PctColors.muted,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CourseDetailScreen(course: course),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Next competitions: the CTF feed is already sorted own-first, then
/// by start date; this takes the next three that have not ended yet.
class _CtfsSection extends StatelessWidget {
  const _CtfsSection({required this.future});

  final Future<DataResult<List<Ctf>>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataResult<List<Ctf>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SectionPlaceholder(text: 'Loading CTFs…');
        }
        final result = snapshot.data;
        if (result == null || !result.ok) {
          return const _SectionPlaceholder(
            text: 'CTFs will appear here once they are published.',
          );
        }
        final all = result.data ?? <Ctf>[];
        final now = DateTime.now();
        final upcoming = all
            .where((c) => c.endDate == null || !c.endDate!.isBefore(now))
            .toList();
        final shown = (upcoming.isNotEmpty ? upcoming : all).take(3).toList();
        if (shown.isEmpty) {
          return const _SectionPlaceholder(text: 'No CTFs listed yet.');
        }
        return Column(
          children: [
            for (final ctf in shown)
              Card(
                color: PctColors.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PctColors.panelBorder),
                ),
                child: ListTile(
                  leading: Icon(
                    ctf.isOwn ? Icons.shield : Icons.public,
                    color: PctColors.gold,
                    size: 28,
                  ),
                  title: Text(
                    ctf.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    ctf.dateRange,
                    style: const TextStyle(color: PctColors.muted),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: PctColors.muted,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CtfDetailScreen(ctf: ctf),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Latest three entries of the in-app notification list. Tapping any
/// of them opens the full notifications screen.
class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StoredNotification>>(
      valueListenable: NotificationService.instance.notifications,
      builder: (context, items, _) {
        if (items.isEmpty) {
          return const _SectionPlaceholder(text: 'No notifications yet.');
        }
        final latest = items.take(3).toList();
        return Container(
          decoration: _panelDecoration,
          child: Column(
            children: [
              for (var i = 0; i < latest.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: PctColors.panelBorder),
                ListTile(
                  leading: Icon(
                    latest[i].read
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: latest[i].read ? PctColors.muted : PctColors.gold,
                  ),
                  title: Text(
                    latest[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          latest[i].read ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    latest[i].body.isNotEmpty
                        ? latest[i].body
                        : formatDate(latest[i].receivedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: PctColors.muted),
                  ),
                  trailing: latest[i].read
                      ? null
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: PctColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: Text(text, style: const TextStyle(color: PctColors.muted)),
    );
  }
}
