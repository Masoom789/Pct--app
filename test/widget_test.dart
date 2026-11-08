// Smoke test: without a Firebase config the app must open the
// Firebase setup screen instead of crashing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pct_app/main.dart';
import 'package:pct_app/screens/certificates_screen.dart';
import 'package:pct_app/screens/ctfs_screen.dart';
import 'package:pct_app/screens/leaderboard_screen.dart';
import 'package:pct_app/screens/rooms_screen.dart';
import 'package:pct_app/services/data_service.dart';
import 'package:pct_app/services/progress_service.dart';
import 'package:pct_app/theme/app_theme.dart';

void main() {
  testWidgets('App opens the Firebase setup screen without config',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PctApp(firebaseReady: false));
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });

  testWidgets('CTFs screen explains Firebase is not connected',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: PctTheme.dark(), home: const CtfsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });

  testWidgets('Rooms screen shows filter chips without Firebase',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: PctTheme.dark(), home: const RoomsScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Rooms'), findsOneWidget);
    expect(find.text('Labs'), findsOneWidget);
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });

  testWidgets('Leaderboard screen explains Firebase is not connected',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: PctTheme.dark(), home: const LeaderboardScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });

  testWidgets('Certificates screen explains Firebase is not connected',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PctTheme.dark(),
        home: const CertificatesScreen(userId: 'test-uid'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Firebase is not connected yet'), findsOneWidget);
  });

  group('Leaderboard ordering and scopes', () {
    LeaderboardEntry entry(
      String id,
      String name,
      int points, {
      String scope = 'global',
    }) =>
        LeaderboardEntry(
          id: id,
          userId: 'u-$id',
          displayName: name,
          points: points,
          rank: 0,
          scope: scope,
        );

    test('sorts by points desc, name breaks ties', () {
      final sorted = DataService.sortLeaderboardEntries([
        entry('a', 'Zara', 100),
        entry('b', 'Ali', 300),
        entry('c', 'Bilal', 300),
        entry('d', 'Omar', 50),
      ]);
      expect(
        sorted.map((e) => e.displayName).toList(),
        ['Ali', 'Bilal', 'Zara', 'Omar'],
      );
    });

    test('negative points are clamped to zero', () {
      final sorted = DataService.sortLeaderboardEntries([
        entry('a', 'Zara', -5),
        entry('b', 'Ali', 10),
      ]);
      expect(sorted.first.displayName, 'Ali');
      expect(sorted.last.points, 0);
    });

    test('scopes: only scopes present in the data are offered', () {
      final entries = [
        entry('a', 'Ali', 300),
        entry('b', 'Bilal', 200, scope: 'rooms'),
      ];
      expect(
        DataService.leaderboardScopes(entries),
        ['global', 'rooms'],
      );
      expect(
        DataService.leaderboardScopes([entry('a', 'Ali', 300)]),
        ['global'],
      );
      expect(DataService.leaderboardScopes([]), ['global']);
    });

    test('entriesForScope keeps each board separate', () {
      final entries = [
        entry('a', 'Ali', 300),
        entry('b', 'Bilal', 200, scope: 'rooms'),
        entry('c', 'Sara', 150, scope: 'labs'),
        entry('d', 'Omar', 90, scope: 'unknown-scope'),
      ];
      expect(
        DataService.entriesForScope(entries, 'global')
            .map((e) => e.displayName)
            .toList(),
        ['Ali', 'Omar'],
      );
      expect(
        DataService.entriesForScope(entries, 'rooms')
            .map((e) => e.displayName)
            .toList(),
        ['Bilal'],
      );
      expect(
        DataService.entriesForScope(entries, 'labs')
            .map((e) => e.displayName)
            .toList(),
        ['Sara'],
      );
    });
  });

  group('Course module locks', () {
    final modules = [
      const CourseModule(id: 'm1', title: 'Intro', order: 1, isFinal: false),
      const CourseModule(id: 'm2', title: 'Basics', order: 2, isFinal: false),
      const CourseModule(id: 'm3', title: 'Final Exam', order: 3, isFinal: true),
    ];

    test('nothing done: only the first module is open', () {
      expect(
        ProgressService.moduleUnlockStates(modules, <String>{}),
        [true, false, false],
      );
    });

    test('first done: second opens, final stays locked', () {
      expect(
        ProgressService.moduleUnlockStates(modules, {'m1'}),
        [true, true, false],
      );
    });

    test('all non-final done: final exam opens', () {
      expect(
        ProgressService.moduleUnlockStates(modules, {'m1', 'm2'}),
        [true, true, true],
      );
    });

    test('final exam cannot open by skipping a module', () {
      expect(
        ProgressService.moduleUnlockStates(modules, {'m2'}),
        [true, false, false],
      );
    });
  });

  group('Room challenge locks', () {
    final challenges = [
      const RoomChallenge(id: 'c1', title: 'One', points: 100, order: 1),
      const RoomChallenge(id: 'c2', title: 'Two', points: 200, order: 2),
      const RoomChallenge(id: 'c3', title: 'Three', points: 300, order: 3),
    ];

    test('nothing solved: only the first challenge is open', () {
      expect(
        ProgressService.challengeUnlockStates(challenges, <String>{}),
        [true, false, false],
      );
    });

    test('sequential unlock as challenges are solved', () {
      expect(
        ProgressService.challengeUnlockStates(challenges, {'c1'}),
        [true, true, false],
      );
      expect(
        ProgressService.challengeUnlockStates(challenges, {'c1', 'c2'}),
        [true, true, true],
      );
    });

    test('solving out of order does not unlock ahead', () {
      expect(
        ProgressService.challengeUnlockStates(challenges, {'c2'}),
        [true, false, false],
      );
    });
  });
}
