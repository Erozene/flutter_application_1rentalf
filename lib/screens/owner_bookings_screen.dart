// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OwnerBookingsScreen extends StatelessWidget {
  final String ownerId;
  const OwnerBookingsScreen({required this.ownerId, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Incoming Bookings'),
          backgroundColor: AppColors.bg,
          bottom: const TabBar(
            indicatorColor: AppColors.orange,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'UPCOMING'),
              Tab(text: 'ACTIVE'),
              Tab(text: 'PAST'),
            ],
          ),
        ),
        body: StreamBuilder<List<Booking>>(
          stream: PaymentService().getOwnerBookings(ownerId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.orange, strokeWidth: 2));
            }

            final all = snap.data ?? [];
            final now = DateTime.now();

            final upcoming = all.where((b) =>
                b.status == BookingStatus.confirmed &&
                b.dates.isNotEmpty &&
                b.dates.first.isAfter(now)).toList();

            final active = all.where((b) =>
                b.status == BookingStatus.confirmed &&
                b.dates.isNotEmpty &&
                !b.dates.first.isAfter(now) &&
                !b.dates.last.isBefore(now)).toList();

            final past = all.where((b) =>
                b.status == BookingStatus.completed ||
                b.status == BookingStatus.cancelled ||
                (b.dates.isNotEmpty && b.dates.last.isBefore(now))).toList();

            return TabBarView(
              children: [
                _BookingList(bookings: upcoming, emptyTitle: 'No Upcoming Bookings', emptySubtitle: 'New bookings will appear here.'),
                _BookingList(bookings: active, emptyTitle: 'No Active Rentals', emptySubtitle: 'Currently active rentals will appear here.'),
                _BookingList(bookings: past, emptyTitle: 'No Past Bookings', emptySubtitle: 'Completed and cancelled bookings will appear here.'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyTitle;
  final String emptySubtitle;

  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OwnerBookingTile(booking: bookings[i]),
    );
  }
}

class _OwnerBookingTile extends StatelessWidget {
  final Booking booking;
  const _OwnerBookingTile({required this.booking});

  Color _statusColor() {
    switch (booking.status) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.pending: return AppColors.orange;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.completed: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              booking.equipmentImage.isNotEmpty
                  ? Image.network(booking.equipmentImage,
                      width: 80, height: 80, fit: BoxFit.cover)
                  : Container(
                      width: 80, height: 80,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image, color: AppColors.border, size: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.equipmentTitle,
                          style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.days} day${booking.days != 1 ? "s" : ""}  ·  \$${booking.total.toStringAsFixed(0)}',
                        style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (booking.hasDeposit) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Deposit: \$${booking.depositAmount.toStringAsFixed(0)} · ${booking.depositStatusLabel}',
                          style: AppFonts.dmMono(
                              fontSize: 10,
                              color: booking.depositStatus == DepositStatus.released
                                  ? AppColors.success
                                  : AppColors.orange),
                        ),
                      ],
                      const SizedBox(height: 8),
                      StatusBadge(label: booking.statusLabel, color: _statusColor()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          if (booking.dates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(booking.dates.first)}  →  ${_fmt(booking.dates.last)}',
                    style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }
}
