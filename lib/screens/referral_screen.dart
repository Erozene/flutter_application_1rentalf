// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/promo_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _referralCode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final code = await PromoService().getOrCreateReferralCode(user.uid, user.email ?? '');
    if (mounted) setState(() { _referralCode = code; _loading = false; });
  }

  void _copyCode() {
    if (_referralCode == null) return;
    Clipboard.setData(ClipboardData(text: _referralCode!));
    showAppSnackBar(context, 'Code copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Refer a Friend'),
        backgroundColor: AppColors.bg,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard_outlined,
                      size: 40, color: AppColors.orange),
                  const SizedBox(height: 16),
                  Text('Give 10%, Get 10%',
                      style: AppFonts.bebasNeue(
                          fontSize: 28, letterSpacing: 3, color: AppColors.text),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Share your referral code. Your friend gets 10% off their first rental. You get 10% off your next one.',
                    style: AppFonts.dmMono(
                        fontSize: 12, color: AppColors.textMuted, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text('Your referral code',
                style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500)),
            const SizedBox(height: 10),

            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2))
            else
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.orange),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _referralCode ?? '',
                          style: AppFonts.bebasNeue(
                              fontSize: 24, letterSpacing: 6, color: AppColors.orange),
                        ),
                      ),
                      const Icon(Icons.copy_outlined,
                          size: 18, color: AppColors.orange),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 28),

            const AppDivider(),
            const SizedBox(height: 24),

            Text('How it works',
                style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500)),
            const SizedBox(height: 16),

            _step('1', 'Share your code with a friend'),
            _step('2', 'They enter it at checkout for 10% off'),
            _step('3', 'You automatically get a 10% discount on your next rental'),
          ],
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: Text(num,
                style: AppFonts.dmMono(
                    fontSize: 12,
                    weight: FontWeight.w500,
                    color: AppColors.bg)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text,
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
