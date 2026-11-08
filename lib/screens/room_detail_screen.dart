import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// Room detail: challenges from `rooms/{id}/challenges`, in order.
/// Sequential flow — a challenge is locked until the previous one is
/// solved. Solve state is stored on this device only (Phase 2).
class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.room});

  final Room room;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final ProgressService _progress = ProgressService();
  late Future<DataResult<List<RoomChallenge>>> _future;
  Set<String> _solved = <String>{};
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchChallenges(widget.room.id);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final solved = await _progress.solvedChallenges(widget.room.id);
    if (mounted) {
      setState(() {
        _solved = solved;
        _loadingProgress = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchChallenges(widget.room.id);
    });
    await Future.wait([_future, _loadProgress()]);
  }

  Future<void> _tapChallenge(
    RoomChallenge challenge,
    bool unlocked,
    bool solved,
  ) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solve the previous challenge first.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PctColors.panel,
        title: Text(solved ? 'Mark as unsolved?' : 'Mark as solved?'),
        content: Text(
          '${challenge.title} — ${challenge.points} pts\n\nProgress is stored on this device only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _progress.setChallengeSolved(widget.room.id, challenge.id, !solved);
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      body: FutureBuilder<DataResult<List<RoomChallenge>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _loadingProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data;
          if (result == null || result.notConfigured) {
            return const PctEmptyState(
              icon: Icons.cloud_off,
              title: 'Firebase is not connected yet',
              message: 'Add google-services.json to connect Firebase, then challenges will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(message: result.error!, onRetry: _refresh);
          }
          final challenges = result.data ?? <RoomChallenge>[];
          if (challenges.isEmpty) {
            return const PctEmptyState(
              icon: Icons.flag_outlined,
              title: 'No challenges yet',
              message: 'This room has no challenges published yet.',
            );
          }
          final unlocked =
              ProgressService.challengeUnlockStates(challenges, _solved);
          final solvedCount =
              challenges.where((c) => _solved.contains(c.id)).length;
          final totalPoints =
              challenges.fold<int>(0, (sum, c) => sum + c.points);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (room.description.isNotEmpty) ...[
                  Text(room.description),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    PctChip(
                      label: room.isLab ? 'Lab' : 'Room',
                      icon: room.isLab ? Icons.science : Icons.meeting_room,
                    ),
                    if (room.difficulty.isNotEmpty)
                      PctChip(label: room.difficulty, icon: Icons.bar_chart),
                    if (totalPoints > 0)
                      PctChip(label: '$totalPoints pts total', icon: Icons.star),
                    if (room.category.isNotEmpty)
                      PctChip(label: room.category, icon: Icons.category),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$solvedCount/${challenges.length} solved',
                  style: const TextStyle(
                    color: PctColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Solve in order — the next challenge unlocks after the previous one. Progress is stored on this device only.',
                  style: TextStyle(color: PctColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < challenges.length; i++)
                  _ChallengeTile(
                    challenge: challenges[i],
                    index: i,
                    unlocked: unlocked[i],
                    solved: _solved.contains(challenges[i].id),
                    onTap: () => _tapChallenge(
                      challenges[i],
                      unlocked[i],
                      _solved.contains(challenges[i].id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.index,
    required this.unlocked,
    required this.solved,
    required this.onTap,
  });

  final RoomChallenge challenge;
  final int index;
  final bool unlocked;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = solved
        ? Icons.check_circle
        : unlocked
            ? Icons.flag
            : Icons.lock;
    final iconColor = solved
        ? PctColors.success
        : unlocked
            ? PctColors.gold
            : PctColors.muted;
    return Card(
      color: PctColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: PctColors.panelBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 28),
        title: Text(
          challenge.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: unlocked ? PctColors.text : PctColors.muted,
          ),
        ),
        subtitle: Row(
          children: [
            Text('Challenge ${index + 1}', style: const TextStyle(color: PctColors.muted)),
            const SizedBox(width: 6),
            PctChip(label: '${challenge.points} pts', icon: Icons.star),
            if (!unlocked) ...[
              const SizedBox(width: 6),
              const PctChip(label: 'Locked', icon: Icons.lock),
            ],
          ],
        ),
        trailing: solved
            ? const Icon(Icons.check, color: PctColors.success)
            : const Icon(Icons.chevron_right, color: PctColors.muted),
        onTap: onTap,
      ),
    );
  }
}
