// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String equipmentId;
  final String equipmentTitle;
  final String bookingId;
  final String userId;
  final String userEmail;

  const LeaveReviewScreen({
    required this.equipmentId,
    required this.equipmentTitle,
    required this.bookingId,
    required this.userId,
    required this.userEmail,
    super.key,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  final _svc = ReviewService();
  final _ctrl = TextEditingController();
  double _rating = 5;
  bool _loading = false;

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please write a comment', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _svc.addReview(Review(
        id: '',
        equipmentId: widget.equipmentId,
        bookingId: widget.bookingId,
        userId: widget.userId,
        userEmail: widget.userEmail,
        rating: _rating,
        comment: _ctrl.text.trim(),
      ));
      Navigator.pop(context, true);
      showAppSnackBar(context, 'Review submitted!');
    } catch (e) {
      setState(() => _loading = false);
      showAppSnackBar(context, 'Error submitting review', isError: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Leave a Review'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppHeading(widget.equipmentTitle, size: 22),
          const SizedBox(height: 24),
          Text('Rating',
              style: AppFonts.dmMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star.toDouble()),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.orange,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('${_rating.toInt()} / 5',
              style: AppFonts.bebasNeue(
                  fontSize: 18, color: AppColors.orange, letterSpacing: 2)),
          const SizedBox(height: 24),
          const AppDivider(),
          const SizedBox(height: 24),
          Text('Your review',
              style: AppFonts.dmMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 2)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            style: AppFonts.dmMono(fontSize: 13, height: 1.6),
            decoration: InputDecoration(
              hintText:
                  'How was the equipment? Was it as described? Would you rent again?',
              hintStyle: AppFonts.dmMono(
                  fontSize: 12, color: AppColors.textMuted, height: 1.6),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.orange)),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: _loading ? 'SUBMITTING...' : 'SUBMIT REVIEW',
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
