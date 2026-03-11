import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String title;
  final String description;
  final double price;
  final double depositAmount;
  final String imageUrl;
  final String category;
  final String ownerId;
  final double rating;
  final int reviewCount;
  final bool available;
  final List<String> bookedDates;

  Equipment({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.depositAmount = 0,
    required this.imageUrl,
    required this.category,
    required this.ownerId,
    this.rating = 0,
    this.reviewCount = 0,
    this.available = true,
    this.bookedDates = const [],
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Equipment(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'Other',
      ownerId: data['ownerId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      available: data['available'] ?? true,
      bookedDates: List<String>.from(data['bookedDates'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'price': price,
        'depositAmount': depositAmount,
        'imageUrl': imageUrl,
        'category': category,
        'ownerId': ownerId,
        'rating': rating,
        'reviewCount': reviewCount,
        'available': available,
        'bookedDates': bookedDates,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
