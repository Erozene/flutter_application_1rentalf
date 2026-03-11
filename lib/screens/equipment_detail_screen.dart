// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/review.dart';
import '../services/messaging_service.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'auth_screen.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;
  const EquipmentDetailScreen({required this.equipment, super.key});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  final _reviewSvc = ReviewService();

  Future<void> _openChat(User user) async {
    final svc = MessagingService();
    final convId = await svc.getOrCreateConversation(
      equipmentId: widget.equipment.id,
      equipmentTitle: widget.equipment.title,
      renterId: user.uid,
      renterEmail: user.email ?? '',
      ownerId: widget.equipment.ownerId,
      ownerEmail: 'owner',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          currentUserId: user.uid,
          currentUserEmail: user.email ?? '',
          otherPersonEmail: 'Owner',
          otherPersonId: widget.equipment.ownerId,
          equipmentTitle: widget.equipment.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eq = widget.equipment;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: eq.imageUrl.isNotEmpty
                  ? Image.network(eq.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.camera_alt,
                          color: AppColors.border, size: 64)),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppLabel(eq.category, color: AppColors.orange),
                      const Spacer(),
                      StatusBadge(
                        label: eq.available ? 'AVAILABLE' : 'UNAVAILABLE',
                        color: eq.available
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(eq.title,
                      style: AppFonts.bebasNeue(
                          fontSize: 36,
                          letterSpacing: 2,
                          color: AppColors.text)),
                  const SizedBox(height: 6),
                  StarRating(rating: eq.rating, count: eq.reviewCount),
                  const SizedBox(height: 20),

                  // Price box
                  AppBox(
                    padding: const EdgeInsets.all(20),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '\$${eq.price.toStringAsFixed(0)}',
                          style: AppFonts.bebasNeue(
                              fontSize: 48,
                              color: AppColors.orange,
                              letterSpacing: 1),
                        ),
                        TextSpan(
                          text: ' / day',
                          style: AppFonts.dmMono(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const AppLabel('About this gear'),
                  const SizedBox(height: 10),
                  Text(
                    eq.description.isNotEmpty
                        ? eq.description
                        : 'Professional-grade equipment available for daily rental.',
                    style: AppFonts.dmMono(
                        fontSize: 13,
                        color: AppColors.textDim,
                        height: 1.7,
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 28),
                  const AppDivider(),
                  const SizedBox(height: 20),

                  // Availability calendar
                  const AppLabel('Availability'),
                  const SizedBox(height: 12),
                  _AvailabilityCalendar(bookedDates: eq.bookedDates),
                  const SizedBox(height: 28),
                  const AppDivider(),
                  const SizedBox(height: 20),

                  // What's included
                  const AppLabel('Typically included'),
                  const SizedBox(height: 12),
                  ...['Equipment in full working condition',
                    'Original case / carry bag',
                    'All standard accessories',
                    'Basic usage guide',
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          const Icon(Icons.check,
                              size: 14, color: AppColors.orange),
                          const SizedBox(width: 10),
                          Text(item,
                              style: AppFonts.dmMono(
                                  fontSize: 12,
                                  color: AppColors.textDim,
                                  letterSpacing: 0.3)),
                        ]),
                      )),

                  const SizedBox(height: 28),
                  const AppDivider(),
                  const SizedBox(height: 20),

                  // Reviews section
                  const AppLabel('Reviews'),
                  const SizedBox(height: 12),
                  _ReviewsSection(
                      equipmentId: eq.id, reviewSvc: _reviewSvc),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(equipment: eq, onChat: _openChat),
    );
  }
}

// ── Availability Calendar ────────────────────────────────────────────────────

class _AvailabilityCalendar extends StatefulWidget {
  final List<String> bookedDates;
  const _AvailabilityCalendar({required this.bookedDates});

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  bool _isBooked(DateTime d) {
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return widget.bookedDates.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return AppBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              Text('${months[_month.month]} ${_month.year}',
                  style: AppFonts.dmMono(
                      fontSize: 13,
                      weight: FontWeight.w500,
                      letterSpacing: 1)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppFonts.dmMono(
                                fontSize: 10,
                                color: AppColors.textMuted,
                                letterSpacing: 0)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstWeekday) return const SizedBox();
              final day = i - firstWeekday + 1;
              final date = DateTime(_month.year, _month.month, day);
              final isPast = date.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)));
              final booked = _isBooked(date);
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: booked
                      ? AppColors.error.withOpacity(0.2)
                      : isPast
                          ? Colors.transparent
                          : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: booked
                        ? AppColors.error.withOpacity(0.4)
                        : isPast
                            ? Colors.transparent
                            : AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppFonts.dmMono(
                      fontSize: 10,
                      color: booked
                          ? AppColors.error
                          : isPast
                              ? AppColors.textMuted
                              : AppColors.text,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            _Legend(color: AppColors.success, label: 'Available'),
            const SizedBox(width: 16),
            _Legend(color: AppColors.error, label: 'Booked'),
          ]),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text(label,
          style: AppFonts.dmMono(fontSize: 10, color: AppColors.textMuted)),
    ]);
  }
}

// ── Reviews Section ──────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final String equipmentId;
  final ReviewService reviewSvc;
  const _ReviewsSection(
      {required this.equipmentId, required this.reviewSvc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: reviewSvc.getReviews(equipmentId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final reviews = snap.data!;
        if (reviews.isEmpty) {
          return Text('No reviews yet. Be the first to review!',
              style: AppFonts.dmMono(
                  fontSize: 12, color: AppColors.textMuted));
        }
        return Column(
          children: reviews
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppBox(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            StarRating(rating: r.rating, count: 0),
                            const Spacer(),
                            Text(r.userEmail.split('@').first,
                                style: AppFonts.dmMono(
                                    fontSize: 11,
                                    color: AppColors.textMuted)),
                          ]),
                          const SizedBox(height: 8),
                          Text(r.comment,
                              style: AppFonts.dmMono(
                                  fontSize: 12,
                                  color: AppColors.textDim,
                                  height: 1.6)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ── Bottom Bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Equipment equipment;
  final Future<void> Function(User) onChat;

  const _BottomBar({required this.equipment, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          final user = snap.data;
          return Row(children: [
            // Message button
            if (user != null && user.uid != equipment.ownerId)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  height: 52,
                  width: 52,
                  child: OutlinedButton(
                    onPressed: () => onChat(user),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.orange),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.orange, size: 20),
                  ),
                ),
              ),
            // Book button
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: equipment.available
                      ? () {
                          if (user == null) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()));
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(
                                equipment: equipment,
                                userId: user.uid,
                                userEmail: user.email ?? '',
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: equipment.available
                        ? AppColors.orange
                        : AppColors.border,
                  ),
                  child: Text(
                    equipment.available
                        ? 'BOOK THIS GEAR →'
                        : 'UNAVAILABLE',
                    style: AppFonts.dmMono(
                        fontSize: 13,
                        letterSpacing: 2.5,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
