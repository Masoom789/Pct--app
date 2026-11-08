import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pct_widgets.dart';
import 'course_detail_screen.dart';

/// Courses: read from the Firestore `courses` collection.
/// Tap a course to see its modules (subcollection `modules`).
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<DataResult<List<Course>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DataService.instance.fetchCourses();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = DataService.instance.fetchCourses();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: FutureBuilder<DataResult<List<Course>>>(
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
              message: 'Add google-services.json to connect Firebase, then courses will load here.',
            );
          }
          if (result.error != null) {
            return PctErrorState(message: result.error!, onRetry: _refresh);
          }
          final courses = result.data ?? <Course>[];
          if (courses.isEmpty) {
            return const PctEmptyState(
              icon: Icons.school_outlined,
              title: 'No courses yet',
              message: 'No courses are published right now. Check back soon.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: courses.length,
              itemBuilder: (context, i) {
                final course = courses[i];
                return Card(
                  color: PctColors.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: PctColors.panelBorder),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: PctColors.gold, size: 28),
                    title: Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (course.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            course.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: PctColors.muted),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (course.level.isNotEmpty)
                              PctChip(label: course.level, icon: Icons.bar_chart),
                            if (course.duration.isNotEmpty)
                              PctChip(label: course.duration, icon: Icons.schedule),
                            if (course.moduleCount > 0)
                              PctChip(
                                label: '${course.moduleCount} modules',
                                icon: Icons.list,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: PctColors.muted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CourseDetailScreen(course: course),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
