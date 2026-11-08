import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// Leaderboard: Rank | Name | Points.
///
/// Reads the Firestore `leaderboard` collection (admin-maintained);
/// falls back to `users` ordered by points when the board collection
/// is empty. Top 3 are highlighted gold / silver / bronze. Tabs for
/// Global / Rooms / Labs appear only when the data carries those
/// scopes; otherwise Global only, with a note that the other boards
/// appear once scores are published for them. The signed-in user's
/// own row is highlighted with a "You" chip.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.currentUserId});

  final String? currentUserId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<DataResult<List<LeaderboardEntry>>> _future;
  String _scope = 'global';

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchLeaderboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchLeaderboard();
    });
    await _future;
  }

  static const _scopeLabels = {
    'global': 'Global',
    'rooms': 'Rooms',
    'labs': 'Labs',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<DataResult<List<LeaderboardEntry>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || result.notConfigured) {
            return const PctEmptyState(
              icon: Icons.cloud_off,
              title: 'Firebase is not connected yet',
              message:
                  'Add google-services.json to connect Firebase, then the leaderboard will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(message: result.error!, onRetry: _refresh);
          }
          final all = result.data ?? <LeaderboardEntry>[];
          if (all.isEmpty) {
            return const PctEmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'No scores yet',
              message:
                  'Nobody has scored points yet. Play a CTF or finish a room to get on the board.',
            );
          }
          final scopes = DataService.leaderboardScopes(all);
          // The selected tab may not exist in this data (e.g. only
          // Rooms scores published) — fall back to the first tab.
          final scope = scopes.contains(_scope) ? _scope : scopes.first;
          final entries = DataService.entriesForScope(all, scope);
          return Column(
            children: [
              if (scopes.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      for (final s in scopes) ...[
                        _ScopeChip(
                          label: _scopeLabels[s] ?? s,
                          selected: s == scope,
                          onTap: () => setState(() => _scope = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount:
                        entries.length + (scopes.length == 1 ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= entries.length) {
                        // Footer note: only when there is a single
                        // (Global) board in the data.
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
                          child: Text(
                            'Rooms and Labs leaderboards appear here once scores are published for them.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: PctColors.muted, fontSize: 13),
                          ),
                        );
                      }
                      final entry = entries[i];
                      final rank = i + 1;
                      final isMe = widget.currentUserId != null &&
                          widget.currentUserId!.isNotEmpty &&
                          entry.userId == widget.currentUserId;
                      return _LeaderboardRow(
                        entry: entry,
                        rank: rank,
                        isMe: isMe,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: PctColors.gold,
      backgroundColor: PctColors.panel,
      labelStyle: TextStyle(
        color: selected ? Colors.black : PctColors.text,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: PctColors.panelBorder),
    );
  }
}

/// Rank badge colours for the podium: gold / silver / bronze.
Color? _rankColor(int rank) {
  return switch (rank) {
    1 => PctColors.gold,
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFCD7F32),
    _ => null,
  };
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.isMe,
  });

  final LeaderboardEntry entry;
  final int rank;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _rankColor(rank);
    return Card(
      color: PctColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isMe ? PctColors.gold : PctColors.panelBorder,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeColor ?? PctColors.panelBorder,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: badgeColor == null ? PctColors.text : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PctColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PctColors.gold.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: PctColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: rank == 1
            ? const Text('Top scorer', style: TextStyle(color: PctColors.muted))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: PctColors.gold, size: 18),
            const SizedBox(width: 4),
            Text(
              '${entry.points}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
