// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class RateRenterScreen extends StatefulWidget {
  final Booking booking;
  const RateRenterScreen({required this.booking, super.key});

  @override
  State<RateRenterScreen> createState() => _RateRenterScreenState();
}

class _RateRenterScreenState extends State<RateRenterScreen> {
  double _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;

      // Save renter review
      await db.collection('renterReviews').add({
        'renterId': widget.booking.userId,
        'ownerId': widget.booking.ownerId,
        'bookingId': widget.booking.id,
        'equipmentTitle': widget.booking.equipmentTitle,
        'rating': _rating,
        'comment': _commentCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark booking as rated
      await db.collection('bookings').doc(widget.booking.id).update({
        'renterRating': _rating,
      });

      // Update renter's average rating on their user profile
      final reviewsSnap = await db
          .collection('renterReviews')
          .where('renterId', isEqualTo: widget.booking.userId)
          .get();

      if (reviewsSnap.docs.isNotEmpty) {
        final avg = reviewsSnap.docs
                .map((d) => (d.data()['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            reviewsSnap.docs.length;

        await db.collection('users').doc(widget.booking.userId).set({
          'renterRating': double.parse(avg.toStringAsFixed(1)),
          'renterReviewCount': reviewsSnap.docs.length,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        showAppSnackBar(context, 'Renter rated. Thanks for your feedback!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to submit: $e', isError: true);
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Rate the Renter'),
        backgroundColor: AppColors.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBox(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking', style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(widget.booking.equipmentTitle,
                      style: AppFonts.dmMono(fontSize: 14, weight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Rating', style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: AppColors.orange,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _rating == 5 ? 'Excellent renter' :
              _rating == 4 ? 'Good renter' :
              _rating == 3 ? 'Average' :
              _rating == 2 ? 'Below average' : 'Poor experience',
              style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text('Comments (optional)',
                style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Was the renter responsible and communicative?',
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: _saving ? 'SUBMITTING...' : 'SUBMIT RATING →',
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
