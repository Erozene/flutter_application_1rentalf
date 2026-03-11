import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

const String _backendUrl = 'https://baserent.onrender.com';

class PushService {
  final _db = FirebaseFirestore.instance;
  final _fcm = FirebaseMessaging.instance;

  /// Call once on app start after user logs in
  Future<void> init(String userId) async {
    if (kIsWeb) return; // FCM push not supported on web

    // Request permission (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token and save to Firestore
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // In-app notification handled by snackbar in main.dart
      print('FCM foreground: ${message.notification?.title}');
    });
  }

  Future<void> _saveToken(String userId, String token) async {
    await _db.collection('users').doc(userId).set({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Send push to a specific user by userId (calls backend)
  static Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      await http.post(
        Uri.parse('$_backendUrl/push/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );
    } catch (e) {
      print('Push send error: $e');
    }
  }
}
