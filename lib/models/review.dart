import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String equipmentId;
  final String bookingId;
  final String userId;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.equipmentId,
    required this.bookingId,
    required this.userId,
    required this.userEmail,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      equipmentId: d['equipmentId'] ?? '',
      bookingId: d['bookingId'] ?? '',
      userId: d['userId'] ?? '',
      userEmail: d['userEmail'] ?? '',
      rating: (d['rating'] ?? 0).toDouble(),
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'equipmentId': equipmentId,
        'bookingId': bookingId,
        'userId': userId,
        'userEmail': userEmail,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
