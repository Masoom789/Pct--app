import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// In-app notifications list (bell on Home). Shows push messages the
/// app received while running, plus any stored earlier. Newest first.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list counts as reading everything in it.
    NotificationService.instance.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear all',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: PctColors.panel,
                  title: const Text('Clear all notifications?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await NotificationService.instance.clearAll();
              }
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<StoredNotification>>(
        valueListenable: NotificationService.instance.notifications,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const PctEmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              message:
                  'When PAK Cyber Team posts a new CTF, course or room, it will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final n = list[i];
              return Card(
                color: PctColors.panel,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PctColors.panelBorder),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.notifications,
                    color: PctColors.gold,
                    size: 26,
                  ),
                  title: Text(
                    n.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(n.body),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        formatDate(n.receivedAt),
                        style: const TextStyle(
                          color: PctColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
