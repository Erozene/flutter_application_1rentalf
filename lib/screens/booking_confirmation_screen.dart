import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'review_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Booking booking;
  const BookingConfirmationScreen({required this.booking, super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.success, width: 2),
                    color: AppColors.successBg,
                  ),
                  child: const Icon(Icons.check,
                      color: AppColors.success, size: 36),
                ),
              ),
              const SizedBox(height: 32),
              AppHeading('Booking\nConfirmed', size: 48),
              const SizedBox(height: 8),
              Text(
                'Your payment was successful and your gear is reserved.',
                style: AppFonts.dmMono(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.6,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 36),
              AppBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLabel('Booking Details'),
                    const SizedBox(height: 16),
                    _row('Gear', booking.equipmentTitle),
                    const SizedBox(height: 10),
                    _row('Duration',
                        '${booking.days} day${booking.days != 1 ? "s" : ""}'),
                    const SizedBox(height: 10),
                    _row('Total Paid',
                        '\$${booking.total.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    _row('Status', 'CONFIRMED'),
                    const SizedBox(height: 10),
                    _row('Booking ID',
                        '#${booking.id.substring(0, 8).toUpperCase()}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (booking.dates.isNotEmpty)
                AppBox(
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 10),
                    Text(
                      '${_fmt(booking.dates.first)}  →  ${_fmt(booking.dates.last)}',
                      style: AppFonts.dmMono(fontSize: 13),
                    ),
                  ]),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18)),
                child: const Text('BACK TO BROWSE →'),
              ),
              const SizedBox(height: 12),
              if (user != null)
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeaveReviewScreen(
                        equipmentId: booking.equipmentId,
                        equipmentTitle: booking.equipmentTitle,
                        bookingId: booking.id,
                        userId: user.uid,
                        userEmail: user.email ?? '',
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('LEAVE A REVIEW'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppFonts.dmMono(
                fontSize: 11,
                color: AppColors.textMuted,
                letterSpacing: 1)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: AppFonts.dmMono(fontSize: 12, color: AppColors.text),
              maxLines: 2),
        ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}
