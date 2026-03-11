import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Review>> getReviews(String equipmentId) {
    return _db
        .collection('reviews')
        .where('equipmentId', isEqualTo: equipmentId)
        .snapshots()
        .map((s) => s.docs.map(Review.fromFirestore).toList());
  }

  Future<bool> hasReviewed(String bookingId, String userId) async {
    final snap = await _db
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('userId', isEqualTo: userId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> addReview(Review review) async {
    await _db.collection('reviews').add(review.toMap());

    // Recalculate average rating on equipment
    final snap = await _db
        .collection('reviews')
        .where('equipmentId', isEqualTo: review.equipmentId)
        .get();

    final reviews = snap.docs.map(Review.fromFirestore).toList();
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    await _db.collection('equipment').doc(review.equipmentId).update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': reviews.length,
    });
  }
}
