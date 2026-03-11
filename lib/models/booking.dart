import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }
enum DepositStatus { held, released, claimed }

class Booking {
  final String id;
  final String equipmentId;
  final String equipmentTitle;
  final String equipmentImage;
  final String userId;
  final String ownerId;
  final List<DateTime> dates;
  final double total;
  final double depositAmount;
  final BookingStatus status;
  final DepositStatus depositStatus;
  final String? paymentIntentId;
  final String? depositIntentId;
  final DateTime? createdAt;

  Booking({
    required this.id,
    required this.equipmentId,
    required this.equipmentTitle,
    required this.equipmentImage,
    required this.userId,
    required this.ownerId,
    required this.dates,
    required this.total,
    this.depositAmount = 0,
    this.status = BookingStatus.pending,
    this.depositStatus = DepositStatus.held,
    this.paymentIntentId,
    this.depositIntentId,
    this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      equipmentId: data['equipmentId'] ?? '',
      equipmentTitle: data['equipmentTitle'] ?? '',
      equipmentImage: data['equipmentImage'] ?? '',
      userId: data['userId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      dates: List<String>.from(data['dates'] ?? [])
          .map((d) => DateTime.parse(d))
          .toList(),
      total: (data['total'] ?? 0).toDouble(),
      depositAmount: (data['depositAmount'] ?? 0).toDouble(),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => BookingStatus.pending,
      ),
      depositStatus: DepositStatus.values.firstWhere(
        (s) => s.name == (data['depositStatus'] ?? 'held'),
        orElse: () => DepositStatus.held,
      ),
      paymentIntentId: data['paymentIntentId'],
      depositIntentId: data['depositIntentId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.pending: return 'PENDING';
      case BookingStatus.confirmed: return 'CONFIRMED';
      case BookingStatus.completed: return 'COMPLETED';
      case BookingStatus.cancelled: return 'CANCELLED';
    }
  }

  String get depositStatusLabel {
    switch (depositStatus) {
      case DepositStatus.held: return 'HELD';
      case DepositStatus.released: return 'RELEASED';
      case DepositStatus.claimed: return 'CLAIMED';
    }
  }

  bool get hasDeposit => depositAmount > 0;
  bool get canConfirmReturn =>
      status == BookingStatus.confirmed &&
      hasDeposit &&
      depositStatus == DepositStatus.held;

  int get days => dates.length;
}
