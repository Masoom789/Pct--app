import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'data_service.dart';

/// Local-only progress: which course modules are complete and which room
/// challenges are solved. Stored on this device only (secure storage) —
/// Phase 2 has no server-side progress. Nothing here is sent anywhere.
///
/// Lock rules (standing rules from the website):
/// - Course final exam: locked until ALL non-final modules are complete.
///   Non-final modules open in order: a module is locked until every
///   earlier non-final module is complete.
/// - Room challenges: sequential — challenge N is locked until challenge
///   N-1 is solved. The first challenge is always open.
class ProgressService {
  ProgressService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _coursePrefix = 'pct_progress_course_';
  static const String _roomPrefix = 'pct_progress_room_';

  // Only Firestore doc ids (letters, digits, _ and -) are stored.
  static final RegExp _idRegex = RegExp(r'^[A-Za-z0-9_\-]{1,128}$');
  static bool _validId(String id) => _idRegex.hasMatch(id);

  Future<Set<String>> _load(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().where(_validId).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _save(String key, Set<String> ids) async {
    try {
      await _storage.write(key: key, value: jsonEncode(ids.toList()));
    } catch (_) {}
  }

  // ----- courses -----

  Future<Set<String>> completedModules(String courseId) async {
    if (!_validId(courseId)) return <String>{};
    return _load('$_coursePrefix$courseId');
  }

  Future<void> setModuleComplete(
    String courseId,
    String moduleId,
    bool complete,
  ) async {
    if (!_validId(courseId) || !_validId(moduleId)) return;
    final key = '$_coursePrefix$courseId';
    final done = await _load(key);
    if (complete) {
      done.add(moduleId);
    } else {
      done.remove(moduleId);
    }
    await _save(key, done);
  }

  // ----- rooms -----

  Future<Set<String>> solvedChallenges(String roomId) async {
    if (!_validId(roomId)) return <String>{};
    return _load('$_roomPrefix$roomId');
  }

  Future<void> setChallengeSolved(
    String roomId,
    String challengeId,
    bool solved,
  ) async {
    if (!_validId(roomId) || !_validId(challengeId)) return;
    final key = '$_roomPrefix$roomId';
    final done = await _load(key);
    if (solved) {
      done.add(challengeId);
    } else {
      done.remove(challengeId);
    }
    await _save(key, done);
  }

  // ----- pure lock logic (unit-tested) -----

  /// Unlock state per module, in list order.
  /// A non-final module is open when every earlier non-final module is
  /// done. A final module is open only when every non-final module is done.
  static List<bool> moduleUnlockStates(
    List<CourseModule> modules,
    Set<String> doneIds,
  ) {
    final nonFinal = modules.where((m) => !m.isFinal).toList();
    // Empty non-final list means nothing blocks the final exam.
    final allNonFinalDone = nonFinal.every((m) => doneIds.contains(m.id));
    final states = <bool>[];
    var earlierNonFinalDone = true;
    for (final m in modules) {
      if (m.isFinal) {
        states.add(allNonFinalDone);
      } else {
        states.add(earlierNonFinalDone);
        if (!doneIds.contains(m.id)) earlierNonFinalDone = false;
      }
    }
    return states;
  }

  /// Unlock state per challenge, in list order.
  /// The first challenge is always open; each later one needs the
  /// previous challenge solved.
  static List<bool> challengeUnlockStates(
    List<RoomChallenge> challenges,
    Set<String> solvedIds,
  ) {
    final states = <bool>[];
    var previousSolved = true;
    for (final c in challenges) {
      states.add(previousSolved);
      if (!solvedIds.contains(c.id)) previousSolved = false;
    }
    return states;
  }
}
