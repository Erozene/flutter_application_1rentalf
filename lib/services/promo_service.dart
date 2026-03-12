import 'package:cloud_firestore/cloud_firestore.dart';

class PromoResult {
  final bool valid;
  final String? error;
  final double discountPercent;
  final double discountAmount;
  final String? promoId;

  PromoResult({
    required this.valid,
    this.error,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.promoId,
  });
}

class PromoService {
  final _db = FirebaseFirestore.instance;

  Future<PromoResult> validatePromo(String code, String userId, double total) async {
    final snap = await _db
        .collection('promoCodes')
        .where('code', isEqualTo: code.toUpperCase().trim())
        .where('active', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) {
      return PromoResult(valid: false, error: 'Invalid promo code');
    }

    final doc = snap.docs.first;
    final data = doc.data();

    // Check expiry
    final expiry = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiry != null && expiry.isBefore(DateTime.now())) {
      return PromoResult(valid: false, error: 'This promo code has expired');
    }

    // Check usage limit
    final maxUses = data['maxUses'] as int?;
    final uses = data['uses'] as int? ?? 0;
    if (maxUses != null && uses >= maxUses) {
      return PromoResult(valid: false, error: 'This promo code has reached its limit');
    }

    // Check single use per user
    final usedBy = List<String>.from(data['usedBy'] ?? []);
    if (usedBy.contains(userId)) {
      return PromoResult(valid: false, error: 'You have already used this promo code');
    }

    final discountPercent = (data['discountPercent'] as num?)?.toDouble() ?? 0;
    final discountFlat = (data['discountAmount'] as num?)?.toDouble() ?? 0;
    final discountAmount = discountPercent > 0
        ? total * (discountPercent / 100)
        : discountFlat;

    return PromoResult(
      valid: true,
      discountPercent: discountPercent,
      discountAmount: discountAmount.clamp(0, total),
      promoId: doc.id,
    );
  }

  Future<void> redeemPromo(String promoId, String userId) async {
    await _db.collection('promoCodes').doc(promoId).update({
      'uses': FieldValue.increment(1),
      'usedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // Referral: generate a referral code for a user
  Future<String> getOrCreateReferralCode(String userId, String email) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final existing = userDoc.data()?['referralCode'] as String?;
    if (existing != null) return existing;

    // Generate code from email prefix
    final prefix = email.split('@').first.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').substring(0, 5.clamp(0, email.split('@').first.length));
    final code = '$prefix${userId.substring(0, 4).toUpperCase()}';

    // Create promo code for this referral
    await _db.collection('promoCodes').add({
      'code': code,
      'discountPercent': 10,
      'discountAmount': 0,
      'active': true,
      'type': 'referral',
      'referrerId': userId,
      'uses': 0,
      'usedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).set({
      'referralCode': code,
    }, SetOptions(merge: true));

    return code;
  }
}
