import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

const String _backendUrl = 'https://baserent.onrender.com';

class ConnectService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveStripeAccountId(String userId, String accountId) async {
    await _db.collection('users').doc(userId).set({
      'stripeAccountId': accountId,
      'stripeOnboardingComplete': false,
    }, SetOptions(merge: true));
  }

  Future<String?> getStripeAccountId(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return (doc.data() as Map<String, dynamic>?)?['stripeAccountId'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> startOnboarding({
    required String userId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/connect/onboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'email': email,
        'return_url': '$_backendUrl/connect/return',
        'refresh_url': '$_backendUrl/connect/refresh',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Onboarding failed: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await saveStripeAccountId(userId, data['account_id'] as String);
    return data;
  }

  Future<Map<String, dynamic>> getAccountStatus(String stripeAccountId) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/connect/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'stripe_account_id': stripeAccountId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Status check failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> getDashboardUrl(String stripeAccountId) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/connect/dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'stripe_account_id': stripeAccountId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Dashboard link failed: ${response.body}');
    }
    return jsonDecode(response.body)['url'] as String;
  }

  Future<Map<String, dynamic>> getBalance(String stripeAccountId) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/connect/balance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'stripe_account_id': stripeAccountId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Balance check failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Stream<List<Map<String, dynamic>>> getOwnerEarnings(String ownerId) {
    return _db
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
            .toList());
  }
}
