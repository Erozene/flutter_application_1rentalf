// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../services/connect_service.dart';
import '../services/url_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ConnectScreen extends StatefulWidget {
  final String userId;
  final String userEmail;
  const ConnectScreen({required this.userId, required this.userEmail, super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _svc = ConnectService();
  bool _loading = false;
  String? _error;

  Future<void> _startOnboarding() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _svc.startOnboarding(
        userId: widget.userId,
        email: widget.userEmail,
      );
      final url = result['onboarding_url'] as String;
      await openUrl(url);
      showAppSnackBar(context,
          'Complete Stripe onboarding in your browser, then come back and refresh.');
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Connect Stripe'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppHeading('Get Paid', size: 32),
          const SizedBox(height: 8),
          Text('Connect your bank via Stripe to receive 70% of every rental.',
              style: AppFonts.dmMono(fontSize: 13, color: AppColors.textMuted, height: 1.6)),
          const SizedBox(height: 24),
          if (_error != null) ...[
            AppBox(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: AppFonts.dmMono(fontSize: 12, color: AppColors.error)),
            ),
            const SizedBox(height: 16),
          ],
          AppButton(
            label: _loading ? 'CONNECTING...' : 'CONNECT STRIPE ACCOUNT →',
            onPressed: _loading ? null : _startOnboarding,
          ),
        ],
      ),
    );
  }
}
