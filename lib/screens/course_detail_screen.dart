import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';

/// Course detail: modules from `courses/{id}/modules`, in order.
/// Standing rule — the final exam stays LOCKED until every non-final
/// module is complete. Progress is stored on this device only (Phase 2).
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ProgressService _progress = ProgressService();
  late Future<DataResult<List<CourseModule>>> _future;
  Set<String> _done = <String>{};
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchModules(widget.course.id);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final done = await _progress.completedModules(widget.course.id);
    if (mounted) {
      setState(() {
        _done = done;
        _loadingProgress = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchModules(widget.course.id);
    });
    await Future.wait([_future, _loadProgress()]);
  }

  Future<void> _toggleModule(
    CourseModule module,
    bool unlocked,
    bool complete,
  ) async {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            module.isFinal
                ? 'Complete all other modules first to unlock the final exam.'
                : 'Complete the previous modules first.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PctColors.panel,
        title: Text(complete ? 'Mark as complete?' : 'Mark as not complete?'),
        content: Text(
          '${module.title}\n\nProgress is stored on this device only.',
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
    await _progress.setModuleComplete(widget.course.id, module.id, complete);
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: FutureBuilder<DataResult<List<CourseModule>>>(
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
              message: 'Add google-services.json to connect Firebase, then modules will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(message: result.error!, onRetry: _refresh);
          }
          final modules = result.data ?? <CourseModule>[];
          if (modules.isEmpty) {
            return const PctEmptyState(
              icon: Icons.list_alt,
              title: 'No modules yet',
              message: 'This course has no modules published yet.',
            );
          }
          final unlocked = ProgressService.moduleUnlockStates(modules, _done);
          final doneCount = modules.where((m) => _done.contains(m.id)).length;
          final progress = modules.isEmpty ? 0.0 : doneCount / modules.length;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                if (course.description.isNotEmpty) ...[
                  Text(course.description),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: PctColors.panelBorder,
                        color: PctColors.gold,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$doneCount/${modules.length} done',
                      style: const TextStyle(color: PctColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Progress is stored on this device only.',
                  style: TextStyle(color: PctColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < modules.length; i++)
                  _ModuleTile(
                    module: modules[i],
                    index: i,
                    unlocked: unlocked[i],
                    complete: _done.contains(modules[i].id),
                    onTap: () => _toggleModule(
                      modules[i],
                      unlocked[i],
                      !_done.contains(modules[i].id),
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

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.index,
    required this.unlocked,
    required this.complete,
    required this.onTap,
  });

  final CourseModule module;
  final int index;
  final bool unlocked;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = complete
        ? Icons.check_circle
        : module.isFinal
            ? Icons.emoji_events
            : unlocked
                ? Icons.play_circle_outline
                : Icons.lock;
    final iconColor = complete
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
          module.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: unlocked ? PctColors.text : PctColors.muted,
          ),
        ),
        subtitle: Row(
          children: [
            Text('Module ${index + 1}', style: const TextStyle(color: PctColors.muted)),
            if (module.isFinal) ...[
              const SizedBox(width: 6),
              const PctChip(label: 'Final Exam', icon: Icons.emoji_events),
            ],
            if (!unlocked) ...[
              const SizedBox(width: 6),
              const PctChip(label: 'Locked', icon: Icons.lock),
            ],
          ],
        ),
        trailing: complete
            ? const Icon(Icons.check, color: PctColors.success)
            : const Icon(Icons.chevron_right, color: PctColors.muted),
        onTap: onTap,
      ),
    );
  }
}
