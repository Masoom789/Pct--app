import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A push notification received while the app is running, kept in an
/// in-app list (stored on this device only). Tapping the bell shows them.
class StoredNotification {
  StoredNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
  });

  factory StoredNotification.fromJson(Map<String, dynamic> json) {
    return StoredNotification(
      id: json['id'] is String ? json['id'] as String : '',
      title: json['title'] is String ? json['title'] as String : '',
      body: json['body'] is String ? json['body'] as String : '',
      receivedAt: DateTime.tryParse(
            json['receivedAt'] is String ? json['receivedAt'] as String : '',
          ) ??
          DateTime.now(),
      read: json['read'] is bool ? json['read'] as bool : false,
    );
  }

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAt': receivedAt.toIso8601String(),
        'read': read,
      };

  StoredNotification markRead() => StoredNotification(
        id: id,
        title: title,
        body: body,
        receivedAt: receivedAt,
        read: true,
      );
}

/// Push notifications (FCM). Best-effort: never crashes the app if
/// messaging is unavailable (e.g. no Firebase config yet).
///
/// Phase 2: requests permission, saves the FCM token in the user's
/// Firestore doc, and keeps received messages in an in-app list
/// (bell on Home). Everything is wrapped in try/catch — with no
/// Firebase config the app simply runs without push.
class NotificationService {
  NotificationService._({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  static final NotificationService instance = NotificationService._();

  final FlutterSecureStorage _storage;

  static const String _storeKey = 'pct_notifications_v1';
  static const int _maxStored = 30;

  bool _started = false;

  /// All received notifications, newest first. UI listens to this.
  final ValueNotifier<List<StoredNotification>> notifications =
      ValueNotifier<List<StoredNotification>>(<StoredNotification>[]);

  /// Unread count, for the bell badge.
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  Future<void> init() async {
    if (_started) return;
    _started = true;
    await _loadStored();
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      await _saveToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
      // Foreground + tap-to-open messages go to the in-app list.
      FirebaseMessaging.onMessage.listen(_onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessage);
    } catch (_) {
      // Messaging unavailable — app keeps working without push.
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _onMessage(RemoteMessage message) {
    final title = message.notification?.title?.trim() ?? '';
    final body = message.notification?.body?.trim() ?? '';
    if (title.isEmpty && body.isEmpty) return;
    addNotification(
      title: title.isEmpty ? 'PAK Cyber Team' : title,
      body: body,
    );
  }

  /// Adds a notification to the in-app list (newest first, max 30).
  Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    final item = StoredNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.length > 120 ? title.substring(0, 120) : title,
      body: body.length > 500 ? body.substring(0, 500) : body,
      receivedAt: DateTime.now(),
    );
    final list = [item, ...notifications.value];
    if (list.length > _maxStored) list.removeRange(_maxStored, list.length);
    notifications.value = list;
    _refreshUnread();
    await _persist();
  }

  Future<void> markAllRead() async {
    notifications.value =
        notifications.value.map((n) => n.markRead()).toList();
    _refreshUnread();
    await _persist();
  }

  Future<void> clearAll() async {
    notifications.value = <StoredNotification>[];
    _refreshUnread();
    await _persist();
  }

  void _refreshUnread() {
    unreadCount.value =
        notifications.value.where((n) => !n.read).length;
  }

  Future<void> _loadStored() async {
    try {
      final raw = await _storage.read(key: _storeKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(StoredNotification.fromJson)
          .where((n) => n.title.isNotEmpty || n.body.isNotEmpty)
          .toList();
      notifications.value = list;
      _refreshUnread();
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final raw = jsonEncode(
        notifications.value.map((n) => n.toJson()).toList(),
      );
      await _storage.write(key: _storeKey, value: raw);
    } catch (_) {}
  }
}
