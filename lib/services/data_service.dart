import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Result of a Firestore read. The app must never crash when Firebase
/// is not configured (no google-services.json) or the network is down:
/// every read returns a [DataResult] describing what happened.
class DataResult<T> {
  const DataResult({this.data, this.error, this.notConfigured = false});

  final T? data;

  /// Human-readable error, or null on success.
  final String? error;

  /// True when Firebase was never initialised (no config on the device).
  final bool notConfigured;

  bool get ok => error == null && !notConfigured;
}

/// Small date formatter (no intl dependency).
String formatDate(DateTime? d) {
  if (d == null) return 'Date TBA';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Firestore models + reads for Phase 2 and Phase 3.
///
/// Collections (public read, admin-only write — see firestore.rules):
///   ctfs    {name, startDate, endDate, format, url, description, isOwn}
///   courses {title, description, level, duration, moduleCount}
///   courses/{id}/modules {title, order, isFinal}
///   rooms   {name, description, difficulty, points, isLab, category}
///   rooms/{id}/challenges {title, points, order}
///   leaderboard {userId, displayName, points, rank, scope}
///   certificates {userId, title, code, issueDate, category, imageUrl}
///
/// Nothing here is ever hardcoded as "real" data: lists come only from
/// Firestore, and empty collections render an empty state.
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  FirebaseFirestore? _firestoreOverride;

  /// Test seam: inject a fake Firestore in widget tests.
  // ignore: use_setters_to_change_properties
  void overrideFirestoreForTest(FirebaseFirestore firestore) {
    _firestoreOverride = firestore;
  }

  bool get _configured => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  // ----- field helpers (defensive: wrong types / over-long text) -----

  static String _str(Map<String, dynamic> d, String key, {int max = 200}) {
    final v = d[key];
    if (v is! String) return '';
    final t = v.trim();
    return t.length > max ? t.substring(0, max) : t;
  }

  static bool _bool(Map<String, dynamic> d, String key) {
    final v = d[key];
    return v is bool ? v : false;
  }

  static int _int(Map<String, dynamic> d, String key) {
    final v = d[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true).toLocal();
    }
    return null;
  }

  /// Only http(s) links are ever shown as tappable.
  static bool _isSafeUrl(String url) {
    final u = url.trim().toLowerCase();
    return u.startsWith('https://') || u.startsWith('http://');
  }

  // ----- CTFs -----

  Future<DataResult<List<Ctf>>> fetchCtfs() async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<Ctf>>(notConfigured: true);
    }
    try {
      final snap = await _db.collection('ctfs').limit(100).get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return Ctf(
          id: doc.id,
          name: _str(d, 'name', max: 120),
          description: _str(d, 'description', max: 1000),
          format: _str(d, 'format', max: 60),
          url: _str(d, 'url', max: 500),
          startDate: _date(d['startDate']),
          endDate: _date(d['endDate']),
          isOwn: _bool(d, 'isOwn'),
        );
      }).where((c) => c.name.isNotEmpty).toList();
      // Own PCT CTFs first, then by start date (undated last).
      list.sort((a, b) {
        if (a.isOwn != b.isOwn) return a.isOwn ? -1 : 1;
        final ad = a.startDate;
        final bd = b.startDate;
        if (ad == null && bd == null) return a.name.compareTo(b.name);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
      return DataResult<List<Ctf>>(data: list);
    } catch (_) {
      return const DataResult<List<Ctf>>(
        error: 'Could not load CTFs. Check your connection and try again.',
      );
    }
  }

  // ----- Courses -----

  Future<DataResult<List<Course>>> fetchCourses() async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<Course>>(notConfigured: true);
    }
    try {
      final snap = await _db.collection('courses').limit(100).get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return Course(
          id: doc.id,
          title: _str(d, 'title', max: 120),
          description: _str(d, 'description', max: 1000),
          level: _str(d, 'level', max: 40),
          duration: _str(d, 'duration', max: 60),
          moduleCount: _int(d, 'moduleCount'),
        );
      }).where((c) => c.title.isNotEmpty).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      return DataResult<List<Course>>(data: list);
    } catch (_) {
      return const DataResult<List<Course>>(
        error: 'Could not load courses. Check your connection and try again.',
      );
    }
  }

  Future<DataResult<List<CourseModule>>> fetchModules(String courseId) async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<CourseModule>>(notConfigured: true);
    }
    try {
      final snap = await _db
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .limit(100)
          .get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return CourseModule(
          id: doc.id,
          title: _str(d, 'title', max: 120),
          order: _int(d, 'order'),
          isFinal: _bool(d, 'isFinal'),
        );
      }).where((m) => m.title.isNotEmpty).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
        });
      return DataResult<List<CourseModule>>(data: list);
    } catch (_) {
      return const DataResult<List<CourseModule>>(
        error: 'Could not load modules. Check your connection and try again.',
      );
    }
  }

  // ----- Rooms / Labs -----

  Future<DataResult<List<Room>>> fetchRooms() async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<Room>>(notConfigured: true);
    }
    try {
      final snap = await _db.collection('rooms').limit(100).get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return Room(
          id: doc.id,
          name: _str(d, 'name', max: 120),
          description: _str(d, 'description', max: 1000),
          difficulty: _str(d, 'difficulty', max: 40),
          points: _int(d, 'points'),
          isLab: _bool(d, 'isLab'),
          category: _str(d, 'category', max: 60),
        );
      }).where((r) => r.name.isNotEmpty).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return DataResult<List<Room>>(data: list);
    } catch (_) {
      return const DataResult<List<Room>>(
        error: 'Could not load rooms. Check your connection and try again.',
      );
    }
  }

  Future<DataResult<List<RoomChallenge>>> fetchChallenges(String roomId) async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<RoomChallenge>>(notConfigured: true);
    }
    try {
      final snap = await _db
          .collection('rooms')
          .doc(roomId)
          .collection('challenges')
          .limit(100)
          .get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return RoomChallenge(
          id: doc.id,
          title: _str(d, 'title', max: 120),
          points: _int(d, 'points'),
          order: _int(d, 'order'),
        );
      }).where((c) => c.title.isNotEmpty).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
        });
      return DataResult<List<RoomChallenge>>(data: list);
    } catch (_) {
      return const DataResult<List<RoomChallenge>>(
        error: 'Could not load challenges. Check your connection and try again.',
      );
    }
  }

  // ----- Leaderboard -----

  /// Reads the `leaderboard` collection (admin-maintained, Phase 4).
  /// If that collection is empty, best-effort fallback: derive the board
  /// from `users` ordered by points. The default rules only let a user
  /// read their own `users` doc, so the fallback usually returns nothing
  /// and the board honestly shows "No scores yet" — it never invents
  /// scores. Results are sorted by points desc, then name.
  Future<DataResult<List<LeaderboardEntry>>> fetchLeaderboard() async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<LeaderboardEntry>>(notConfigured: true);
    }
    try {
      final snap = await _db.collection('leaderboard').limit(100).get();
      var list = snap.docs.map((doc) {
        final d = doc.data();
        return LeaderboardEntry(
          id: doc.id,
          userId: _str(d, 'userId', max: 128),
          displayName: _str(d, 'displayName', max: 80),
          points: _int(d, 'points'),
          rank: _int(d, 'rank'),
          scope: _str(d, 'scope', max: 40).toLowerCase(),
        );
      }).where((e) => e.displayName.isNotEmpty).toList();
      if (list.isEmpty) {
        try {
          final users = await _db
              .collection('users')
              .orderBy('points', descending: true)
              .limit(100)
              .get();
          list = users.docs.map((doc) {
            final d = doc.data();
            return LeaderboardEntry(
              id: doc.id,
              userId: doc.id,
              displayName: _str(d, 'name', max: 80),
              points: _int(d, 'points'),
              rank: 0,
              scope: 'global',
            );
          })
              .where((e) => e.displayName.isNotEmpty && e.points > 0)
              .toList();
        } catch (_) {
          // Rules block cross-user reads — keep the empty board.
        }
      }
      return DataResult<List<LeaderboardEntry>>(
        data: sortLeaderboardEntries(list),
      );
    } catch (_) {
      return const DataResult<List<LeaderboardEntry>>(
        error:
            'Could not load the leaderboard. Check your connection and try again.',
      );
    }
  }

  /// Sort by points desc, then name asc. Pure (no Firestore) so it can
  /// be unit-tested.
  static List<LeaderboardEntry> sortLeaderboardEntries(
    List<LeaderboardEntry> entries,
  ) {
    final sorted = List<LeaderboardEntry>.from(entries);
    sorted.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0 ? byPoints : a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }

  /// Scopes present in the data, in display order. Only the three known
  /// scopes are ever offered as filters; entries with no scope (or an
  /// unknown one) count as Global. Empty data -> Global only.
  static List<String> leaderboardScopes(List<LeaderboardEntry> entries) {
    const known = ['global', 'rooms', 'labs'];
    final found = <String>{};
    for (final e in entries) {
      found.add(known.contains(e.scope) ? e.scope : 'global');
    }
    final scopes = known.where(found.contains).toList();
    return scopes.isEmpty ? ['global'] : scopes;
  }

  /// Entries for one scope tab. Global shows global/unscoped entries
  /// only — a Rooms/Labs entry's points belong to that board. An entry
  /// with an unknown scope is grouped under Global, matching
  /// [leaderboardScopes].
  static List<LeaderboardEntry> entriesForScope(
    List<LeaderboardEntry> entries,
    String scope,
  ) {
    const known = ['global', 'rooms', 'labs'];
    if (scope == 'global') {
      return entries
          .where((e) =>
              e.scope.isEmpty ||
              e.scope == 'global' ||
              !known.contains(e.scope))
          .toList();
    }
    return entries.where((e) => e.scope == scope).toList();
  }

  // ----- Certificates -----

  /// Only the signed-in user's own certificates (where userId == uid).
  /// Newest first (client-side sort, so no composite index is needed).
  Future<DataResult<List<PctCertificate>>> fetchMyCertificates(
    String uid,
  ) async {
    if (!_configured && _firestoreOverride == null) {
      return const DataResult<List<PctCertificate>>(notConfigured: true);
    }
    if (uid.isEmpty) {
      return const DataResult<List<PctCertificate>>(
        error: 'Please sign in again to see your certificates.',
      );
    }
    try {
      final snap = await _db
          .collection('certificates')
          .where('userId', isEqualTo: uid)
          .limit(100)
          .get();
      final list = snap.docs.map((doc) {
        final d = doc.data();
        return PctCertificate(
          id: doc.id,
          userId: _str(d, 'userId', max: 128),
          title: _str(d, 'title', max: 120),
          code: _str(d, 'code', max: 40),
          category: _str(d, 'category', max: 60),
          imageUrl: _str(d, 'imageUrl', max: 500),
          issueDate: _date(d['issueDate']),
        );
      }).where((c) => c.title.isNotEmpty).toList()
        ..sort((a, b) {
          final ad = a.issueDate;
          final bd = b.issueDate;
          if (ad == null && bd == null) return a.title.compareTo(b.title);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad); // Newest first.
        });
      return DataResult<List<PctCertificate>>(data: list);
    } catch (_) {
      return const DataResult<List<PctCertificate>>(
        error:
            'Could not load certificates. Check your connection and try again.',
      );
    }
  }
}

class Ctf {
  const Ctf({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.url,
    required this.startDate,
    required this.endDate,
    required this.isOwn,
  });

  final String id;
  final String name;
  final String description;
  final String format;
  final String url;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isOwn;

  bool get hasSafeUrl => DataService._isSafeUrl(url);

  /// "12 Nov 2026 – 14 Nov 2026" or "Date TBA".
  String get dateRange {
    if (startDate == null && endDate == null) return 'Date TBA';
    if (startDate != null && endDate != null) {
      return '${formatDate(startDate)} – ${formatDate(endDate)}';
    }
    return formatDate(startDate ?? endDate);
  }
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.moduleCount,
  });

  final String id;
  final String title;
  final String description;
  final String level;
  final String duration;
  final int moduleCount;
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.title,
    required this.order,
    required this.isFinal,
  });

  final String id;
  final String title;
  final int order;
  final bool isFinal;
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.isLab,
    required this.category,
  });

  final String id;
  final String name;
  final String description;
  final String difficulty;
  final int points;
  final bool isLab;
  final String category;
}

class RoomChallenge {
  const RoomChallenge({
    required this.id,
    required this.title,
    required this.points,
    required this.order,
  });

  final String id;
  final String title;
  final int points;
  final int order;
}

/// One leaderboard row. `scope` is 'global', 'rooms' or 'labs'
/// (lowercase; '' means unscoped, shown under Global). `rank` is the
/// rank stored in Firestore (0 when absent); the screen shows the
/// computed position after sorting, which matches it when the admin
/// maintains the board correctly.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    required int points,
    required this.rank,
    required this.scope,
  }) : points = points < 0 ? 0 : points;

  final String id;
  final String userId;
  final String displayName;
  final int points;
  final int rank;
  final String scope;
}

/// A certificate issued to one user. Only ever listed for its owner.
class PctCertificate {
  const PctCertificate({
    required this.id,
    required this.userId,
    required this.title,
    required this.code,
    required this.category,
    required this.imageUrl,
    required this.issueDate,
  });

  final String id;
  final String userId;
  final String title;
  final String code;
  final String category;
  final String imageUrl;
  final DateTime? issueDate;

  bool get hasSafeImageUrl => DataService._isSafeUrl(imageUrl);

  /// "12 Nov 2026" or "Date not set".
  String get issueDateLabel =>
      issueDate == null ? 'Date not set' : formatDate(issueDate);
}
