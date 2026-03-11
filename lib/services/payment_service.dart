import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import 'email_service.dart';
import 'push_service.dart';
import 'connect_service.dart';

import '../stripe_stub.dart' if (dart.library.io) '../stripe_real.dart';

const String _backendUrl = 'https://baserent.onrender.com';

class PaymentService {
  final _firestore = FirebaseFirestore.instance;

  Future<String> processPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String ownerId,
  }) async {
    if (kIsWeb) {
      throw Exception('Stripe payments are not available on web. Please use the mobile app.');
    }

    final connectSvc = ConnectService();
    final ownerStripeId = await connectSvc.getStripeAccountId(ownerId);

    final response = await http.post(
      Uri.parse('$_backendUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'receipt_email': customerEmail,
        if (ownerStripeId != null) 'owner_stripe_account_id': ownerStripeId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Payment backend error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final clientSecret = data['clientSecret'] as String;
    final paymentIntentId =
        data['paymentIntentId'] as String? ?? clientSecret.split('_secret_').first;

    await initStripePaymentSheet(clientSecret);
    return paymentIntentId;
  }

  Future<String?> processDeposit({
    required double amount,
    required String currency,
    required String customerEmail,
    required String ownerId,
  }) async {
    if (kIsWeb) return null;
    if (amount <= 0) return null;

    final connectSvc = ConnectService();
    final ownerStripeId = await connectSvc.getStripeAccountId(ownerId);

    final response = await http.post(
      Uri.parse('$_backendUrl/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'receipt_email': customerEmail,
        'metadata': {'type': 'deposit'},
        if (ownerStripeId != null) 'owner_stripe_account_id': ownerStripeId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Deposit payment error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final clientSecret = data['clientSecret'] as String;
    final depositIntentId =
        data['paymentIntentId'] as String? ?? clientSecret.split('_secret_').first;

    await initStripePaymentSheet(clientSecret);
    return depositIntentId;
  }

  Future<void> releaseDeposit(String bookingId, String depositIntentId) async {
    final response = await http.post(
      Uri.parse('$_backendUrl/release-deposit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'payment_intent_id': depositIntentId,
        'booking_id': bookingId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to release deposit: ${response.body}');
    }

    await _firestore.collection('bookings').doc(bookingId).update({
      'depositStatus': 'released',
      'status': 'completed',
    });
  }

  Future<void> releaseDepositWithEmail({
    required String bookingId,
    required String depositIntentId,
    required String userEmail,
    required String equipmentTitle,
    required double depositAmount,
    required String userId,
  }) async {
    await releaseDeposit(bookingId, depositIntentId);
    EmailService().depositReleased(
      userEmail: userEmail,
      equipmentTitle: equipmentTitle,
      depositAmount: depositAmount,
      bookingId: bookingId,
    );
    PushService.sendToUser(
      userId: userId,
      title: 'Deposit Released',
      body: 'Your \$${depositAmount.toStringAsFixed(0)} deposit for $equipmentTitle is being refunded.',
      data: {'type': 'deposit_released', 'bookingId': bookingId},
    );
  }

  Future<Booking> createBooking({
    required String equipmentId,
    required String equipmentTitle,
    required String equipmentImage,
    required String userId,
    required String ownerId,
    required List<DateTime> dates,
    required double total,
    required String paymentIntentId,
    double depositAmount = 0,
    String? depositIntentId,
    String? userEmail,
  }) async {
    final ref = _firestore.collection('bookings').doc();

    await ref.set({
      'equipmentId': equipmentId,
      'equipmentTitle': equipmentTitle,
      'equipmentImage': equipmentImage,
      'userId': userId,
      'ownerId': ownerId,
      'dates': dates.map((d) => d.toIso8601String()).toList(),
      'total': total,
      'depositAmount': depositAmount,
      'depositIntentId': depositIntentId,
      'depositStatus': depositAmount > 0 ? 'held' : 'released',
      'status': 'confirmed',
      'paymentIntentId': paymentIntentId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('equipment').doc(equipmentId).update({
      'bookedDates': FieldValue.arrayUnion(
        dates.map((d) => d.toIso8601String().split('T').first).toList(),
      ),
    });

    final booking = Booking(
      id: ref.id,
      equipmentId: equipmentId,
      equipmentTitle: equipmentTitle,
      equipmentImage: equipmentImage,
      userId: userId,
      ownerId: ownerId,
      dates: dates,
      total: total,
      depositAmount: depositAmount,
      depositIntentId: depositIntentId,
      depositStatus: depositAmount > 0 ? DepositStatus.held : DepositStatus.released,
      status: BookingStatus.confirmed,
      paymentIntentId: paymentIntentId,
    );

    // Send confirmation email + push (non-fatal)
    if (userEmail != null) {
      EmailService().bookingConfirmed(
        userEmail: userEmail,
        equipmentTitle: equipmentTitle,
        days: dates.length,
        total: total,
        depositAmount: depositAmount,
        startDate: dates.first,
        endDate: dates.last,
        bookingId: ref.id,
      );
    }
    // Push to renter
    PushService.sendToUser(
      userId: userId,
      title: 'Booking Confirmed',
      body: "$equipmentTitle is reserved. You're all set!",
      data: {'type': 'booking_confirmed', 'bookingId': ref.id},
    );
    // Push to owner
    PushService.sendToUser(
      userId: ownerId,
      title: 'New Booking',
      body: 'Someone just booked your $equipmentTitle.',
      data: {'type': 'new_booking', 'bookingId': ref.id},
    );

    return booking;
  }

  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromFirestore).toList());
  }

  Future<void> cancelBooking(String bookingId, {String? userEmail, String? equipmentTitle, String? userId, String? paymentIntentId, String? depositIntentId, required bool partialRefund}) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .update({'status': 'cancelled'});

    if (userEmail != null && equipmentTitle != null) {
      EmailService().bookingCancelled(
        userEmail: userEmail,
        equipmentTitle: equipmentTitle,
        bookingId: bookingId,
      );
    }
    if (userId != null) {
      PushService.sendToUser(
        userId: userId,
        title: 'Booking Cancelled',
        body: '${equipmentTitle ?? "Your booking"} has been cancelled.',
        data: {'type': 'booking_cancelled', 'bookingId': bookingId},
      );
    }
  }

  getOwnerBookings(String ownerId) {}
}
