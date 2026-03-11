// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/equipment.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'booking_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final Equipment equipment;
  final String userId;
  final String userEmail;

  const BookingScreen({
    required this.equipment,
    required this.userId,
    required this.userEmail,
    super.key,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _paymentService = PaymentService();

  DateTimeRange? _dateRange;
  List<DateTime> _selectedDates = [];
  bool _loading = false;
  String _loadingMsg = '';

  double get _total => _selectedDates.length * widget.equipment.price;
  double get _deposit => widget.equipment.depositAmount;
  double get _chargeNow => _total + _deposit;
  int get _days => _selectedDates.length;

  List<DateTime> _expandRange(DateTimeRange range) {
    final dates = <DateTime>[];
    for (int i = 0; i <= range.duration.inDays; i++) {
      dates.add(range.start.add(Duration(days: i)));
    }
    return dates;
  }

  bool _isDateBooked(DateTime date) {
    final str = date.toIso8601String().split('T').first;
    return widget.equipment.bookedDates.contains(str);
  }

  Future<void> _pickDates() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.text,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.orange),
          ),
          dialogBackgroundColor: AppColors.surface,
        ),
        child: child!,
      ),
    );

    if (range == null) return;

    final dates = _expandRange(range);
    final hasConflict = dates.any(_isDateBooked);
    if (hasConflict) {
      showAppSnackBar(context,
          'Selected range includes already-booked dates. Please choose another range.',
          isError: true);
      return;
    }

    setState(() {
      _dateRange = range;
      _selectedDates = dates;
    });
  }

  Future<void> _pay() async {
    if (_selectedDates.isEmpty) {
      showAppSnackBar(context, 'Please select rental dates first', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _loadingMsg = 'Preparing payment...';
    });

    try {
      // 1. Charge rental amount
      final paymentIntentId = await _paymentService.processPayment(
        amount: _total,
        currency: 'usd',
        customerEmail: widget.userEmail,
        ownerId: widget.equipment.ownerId,
      );

      // 2. Charge deposit if set
      String? depositIntentId;
      if (_deposit > 0) {
        setState(() => _loadingMsg = 'Processing deposit...');
        depositIntentId = await _paymentService.processDeposit(
          amount: _deposit,
          currency: 'usd',
          customerEmail: widget.userEmail,
          ownerId: widget.equipment.ownerId,
        );
      }

      setState(() => _loadingMsg = 'Confirming booking...');

      final booking = await _paymentService.createBooking(
        equipmentId: widget.equipment.id,
        equipmentTitle: widget.equipment.title,
        equipmentImage: widget.equipment.imageUrl,
        userId: widget.userId,
        ownerId: widget.equipment.ownerId,
        dates: _selectedDates,
        total: _total,
        paymentIntentId: paymentIntentId,
        depositAmount: _deposit,
        depositIntentId: depositIntentId,
        userEmail: widget.userEmail,
      );

      setState(() => _loading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => BookingConfirmationScreen(booking: booking)),
      );
    } catch (e) {
      setState(() => _loading = false);
      final msg = e.toString();
      if (!msg.contains('Canceled') && !msg.contains('cancelled')) {
        showAppSnackBar(context, 'Payment failed. Please try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Book Gear'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gear summary
                AppBox(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      widget.equipment.imageUrl.isNotEmpty
                          ? Image.network(widget.equipment.imageUrl,
                              width: 90, height: 90, fit: BoxFit.cover)
                          : Container(
                              width: 90, height: 90,
                              color: AppColors.surfaceAlt,
                              child: const Icon(Icons.camera_alt, color: AppColors.border)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppLabel(widget.equipment.category, color: AppColors.orange),
                              const SizedBox(height: 4),
                              Text(widget.equipment.title,
                                  style: AppFonts.dmMono(fontSize: 14, weight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Text('\$${widget.equipment.price.toStringAsFixed(0)} / day',
                                  style: AppFonts.bebasNeue(
                                      fontSize: 20, color: AppColors.orange, letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Date picker
                const AppLabel('Select rental dates'),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDates,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                          color: _dateRange != null ? AppColors.orange : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 18,
                            color: _dateRange != null ? AppColors.orange : AppColors.textMuted),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _dateRange == null
                              ? Text('Tap to pick dates',
                                  style: AppFonts.dmMono(fontSize: 13, color: AppColors.textMuted))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_fmt(_dateRange!.start)}  →  ${_fmt(_dateRange!.end)}',
                                      style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$_days day${_days != 1 ? "s" : ""}',
                                        style: AppFonts.dmMono(
                                            fontSize: 11, color: AppColors.orange, letterSpacing: 1)),
                                  ],
                                ),
                        ),
                        TextButton(
                          onPressed: _pickDates,
                          child: Text(_dateRange == null ? 'PICK' : 'CHANGE',
                              style: AppFonts.dmMono(
                                  fontSize: 10, color: AppColors.orange, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Order summary
                const AppLabel('Order Summary'),
                const SizedBox(height: 12),
                AppBox(
                  child: Column(
                    children: [
                      _summaryRow('Equipment', widget.equipment.title, isTitle: true),
                      const SizedBox(height: 10),
                      const AppDivider(),
                      const SizedBox(height: 10),
                      _summaryRow('Daily rate', '\$${widget.equipment.price.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _summaryRow('Duration', '$_days day${_days != 1 ? "s" : ""}'),
                      const SizedBox(height: 8),
                      _summaryRow('Rental total', '\$${_total.toStringAsFixed(0)}'),
                      if (_deposit > 0) ...[
                        const SizedBox(height: 8),
                        _summaryRow('Security deposit', '\$${_deposit.toStringAsFixed(0)}',
                            highlight: true),
                      ],
                      const SizedBox(height: 12),
                      const AppDivider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL TODAY',
                              style: AppFonts.dmMono(
                                  fontSize: 11, letterSpacing: 2, color: AppColors.textMuted)),
                          Text('\$${_chargeNow.toStringAsFixed(0)}',
                              style: AppFonts.bebasNeue(
                                  fontSize: 34, color: AppColors.orange, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_deposit > 0) ...[
                  const SizedBox(height: 12),
                  AppBox(
                    color: AppColors.surfaceAlt,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 16, color: AppColors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A \$${_deposit.toStringAsFixed(0)} security deposit is held and automatically refunded when you confirm the gear has been returned.',
                            style: AppFonts.dmMono(
                                fontSize: 11, color: AppColors.textMuted, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                AppBox(
                  color: AppColors.surfaceAlt,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Free cancellation up to 24 hours before your rental starts. After that, a 50% fee applies.',
                          style: AppFonts.dmMono(
                              fontSize: 11, color: AppColors.textMuted, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_loading) LoadingOverlay(message: _loadingMsg),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text('Secured by Stripe',
                    style: AppFonts.dmMono(
                        fontSize: 10, color: AppColors.textMuted, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedDates.isEmpty ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _selectedDates.isEmpty ? AppColors.borderLight : AppColors.orange,
                ),
                child: Text(
                  _selectedDates.isEmpty
                      ? 'SELECT DATES TO CONTINUE'
                      : 'PAY \$${_chargeNow.toStringAsFixed(0)} →',
                  style: AppFonts.dmMono(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: _selectedDates.isEmpty ? AppColors.textMuted : Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isTitle = false, bool muted = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppFonts.dmMono(
                fontSize: isTitle ? 13 : 12,
                color: muted ? AppColors.textMuted : AppColors.textDim,
                letterSpacing: 0.3)),
        Text(value,
            style: AppFonts.dmMono(
                fontSize: isTitle ? 13 : 12,
                color: highlight ? AppColors.orange : (muted ? AppColors.textMuted : AppColors.text),
                weight: isTitle ? FontWeight.w500 : FontWeight.normal)),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}

// ── BOOKINGS LIST ─────────────────────────────────────────────────────────────

class BookingsListScreen extends StatelessWidget {
  final String userId;
  const BookingsListScreen({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final svc = PaymentService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: svc.getUserBookings(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2));
          }

          final bookings = snap.data ?? [];

          if (bookings.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No Bookings Yet',
              subtitle: 'Your confirmed rentals will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BookingTile(booking: bookings[i]),
          );
        },
      ),
    );
  }
}

class _BookingTile extends StatefulWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  @override
  State<_BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends State<_BookingTile> {
  bool _releasing = false;
  bool _cancelling = false;

  Future<String?> _getUser() async {
    return FirebaseAuth.instance.currentUser?.email;
  }

  Future<void> _cancelBooking() async {
    // Check 24hr policy
    final bool isWithin24hrs = widget.booking.dates.isNotEmpty &&
        widget.booking.dates.first.difference(DateTime.now()).inHours < 24;

    final String policyMessage = isWithin24hrs
        ? 'Your rental starts in less than 24 hours. A 50% cancellation fee applies — you will receive a 50% refund.'
        : 'Free cancellation. You will receive a full refund to your original payment method.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const AppHeading('Cancel Booking', size: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWithin24hrs)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_outlined, size: 14, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('50% cancellation fee applies',
                          style: AppFonts.dmMono(fontSize: 11, color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            Text(policyMessage,
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Booking',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel Booking',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final isWithin24hrs = widget.booking.dates.isNotEmpty &&
          widget.booking.dates.first.difference(DateTime.now()).inHours < 24;

      await PaymentService().cancelBooking(
        widget.booking.id,
        userEmail: currentUser?.email,
        equipmentTitle: widget.booking.equipmentTitle,
        userId: currentUser?.uid,
        paymentIntentId: widget.booking.paymentIntentId,
        depositIntentId: widget.booking.depositIntentId,
        partialRefund: isWithin24hrs,
      );
      if (mounted) {
        showAppSnackBar(context, 'Booking cancelled. Refund is on its way.');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to cancel: \$e', isError: true);
      }
    }
    if (mounted) setState(() => _cancelling = false);
  }

  Future<void> _confirmReturn() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const AppHeading('Confirm Return', size: 20),
        content: Text(
          'Confirm you have returned the gear. Your \$${widget.booking.depositAmount.toStringAsFixed(0)} deposit will be released.',
          style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm Return',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.success)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _releasing = true);
    try {
      // Need user email from Firebase Auth
      final user = await _getUser();
      final currentUser = FirebaseAuth.instance.currentUser;
      await PaymentService().releaseDepositWithEmail(
        bookingId: widget.booking.id,
        depositIntentId: widget.booking.depositIntentId!,
        userEmail: user ?? '',
        equipmentTitle: widget.booking.equipmentTitle,
        depositAmount: widget.booking.depositAmount,
        userId: currentUser?.uid ?? '',
      );
      if (mounted) {
        showAppSnackBar(context, 'Deposit released! Booking marked complete.');
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to release deposit: $e', isError: true);
      }
    }
    if (mounted) setState(() => _releasing = false);
  }

  Color _statusColor() {
    switch (widget.booking.status) {
      case BookingStatus.confirmed: return AppColors.success;
      case BookingStatus.pending: return AppColors.orange;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.completed: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              b.equipmentImage.isNotEmpty
                  ? Image.network(b.equipmentImage,
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
                      Text(b.equipmentTitle,
                          style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${b.days} day${b.days != 1 ? "s" : ""}  ·  \$${b.total.toStringAsFixed(0)}',
                        style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted),
                      ),
                      if (b.hasDeposit) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Deposit: \$${b.depositAmount.toStringAsFixed(0)} · ${b.depositStatusLabel}',
                          style: AppFonts.dmMono(
                              fontSize: 10,
                              color: b.depositStatus == DepositStatus.released
                                  ? AppColors.success
                                  : AppColors.orange),
                        ),
                      ],
                      const SizedBox(height: 8),
                      StatusBadge(label: b.statusLabel, color: _statusColor()),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
          if (b.canConfirmReturn)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: AppButton(
                label: _releasing ? 'RELEASING...' : 'CONFIRM RETURN & RELEASE DEPOSIT →',
                onPressed: _releasing ? null : _confirmReturn,
              ),
            ),
          if (b.status == BookingStatus.confirmed)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: AppButton(
                label: _cancelling ? 'CANCELLING...' : 'CANCEL BOOKING',
                onPressed: _cancelling ? null : _cancelBooking,
                outline: true,
              ),
            ),
        ],
      ),
    );
  }
}
