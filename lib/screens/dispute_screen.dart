// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DisputeScreen extends StatefulWidget {
  final Booking booking;
  const DisputeScreen({required this.booking, super.key});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please describe the issue', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
        'disputeStatus': 'open',
        'disputeReason': _reasonCtrl.text.trim(),
        'depositStatus': 'disputed',
        'disputeOpenedAt': FieldValue.serverTimestamp(),
      });

      // Also create a dispute record for admin review
      await FirebaseFirestore.instance.collection('disputes').add({
        'bookingId': widget.booking.id,
        'equipmentId': widget.booking.equipmentId,
        'equipmentTitle': widget.booking.equipmentTitle,
        'renterId': widget.booking.userId,
        'ownerId': widget.booking.ownerId,
        'depositAmount': widget.booking.depositAmount,
        'depositIntentId': widget.booking.depositIntentId,
        'reason': _reasonCtrl.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showAppSnackBar(context, 'Dispute submitted. Our team will review within 48 hours.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to submit dispute: $e', isError: true);
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('File a Dispute'),
        backgroundColor: AppColors.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.orange.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Text('How disputes work',
                        style: AppFonts.dmMono(
                            fontSize: 12,
                            weight: FontWeight.w500,
                            color: AppColors.orange)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    '1. File the dispute with evidence below\n'
                    '2. Our team reviews within 48 hours\n'
                    '3. The deposit is held until resolved\n'
                    '4. We contact both parties and issue a decision',
                    style: AppFonts.dmMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.8),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Booking summary
            AppBox(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking',
                      style: AppFonts.dmMono(
                          fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text(widget.booking.equipmentTitle,
                      style: AppFonts.dmMono(
                          fontSize: 14, weight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                      'Deposit held: \$${widget.booking.depositAmount.toStringAsFixed(0)}',
                      style: AppFonts.dmMono(
                          fontSize: 12, color: AppColors.orange)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text('Describe the issue',
                style: AppFonts.dmMono(
                    fontSize: 13, weight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              maxLines: 6,
              maxLength: 1000,
              style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
              decoration: const InputDecoration(
                hintText:
                    'Describe the damage or issue in detail. Include what was damaged, estimated repair cost, and any evidence you have...',
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Tip: photos sent via the chat are the best evidence. Make sure you have sent them to the renter before filing.',
              style: AppFonts.dmMono(
                  fontSize: 10, color: AppColors.textMuted, height: 1.6),
            ),

            const SizedBox(height: 32),

            AppButton(
              label: _submitting ? 'SUBMITTING...' : 'SUBMIT DISPUTE →',
              onPressed: _submitting ? null : _submitDispute,
            ),
          ],
        ),
      ),
    );
  }
}
