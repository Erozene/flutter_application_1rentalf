// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import '../services/url_service.dart';
import '../services/connect_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PayoutsScreen extends StatefulWidget {
  final String userId;
  final String userEmail;

  const PayoutsScreen({
    required this.userId,
    required this.userEmail,
    super.key,
  });

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  final _svc = ConnectService();

  bool _loading = false;
  String? _stripeAccountId;
  Map<String, dynamic>? _accountStatus;
  Map<String, dynamic>? _balance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final accountId = await _svc.getStripeAccountId(widget.userId);
      if (accountId != null) {
        final status = await _svc.getAccountStatus(accountId);
        Map<String, dynamic>? balance;
        if (status['charges_enabled'] == true) {
          try {
            balance = await _svc.getBalance(accountId);
          } catch (_) {}
        }
        setState(() {
          _stripeAccountId = accountId;
          _accountStatus = status;
          _balance = balance;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _startOnboarding() async {
    setState(() => _loading = true);
    try {
      final result = await _svc.startOnboarding(
        userId: widget.userId,
        email: widget.userEmail,
      );
      final url = result['onboarding_url'] as String;
      setState(() => _stripeAccountId = result['account_id']);

      await openUrl(url);
      showAppSnackBar(context,
          'Complete Stripe onboarding in the browser, then come back and tap refresh.');
    } catch (e) {
      showAppSnackBar(context, 'Error: $e', isError: true);
    }
    setState(() => _loading = false);
  }

  Future<void> _openDashboard() async {
    if (_stripeAccountId == null) return;
    setState(() => _loading = true);
    try {
      final url = await _svc.getDashboardUrl(_stripeAccountId!);
      await openUrl(url);
    } catch (e) {
      showAppSnackBar(context, 'Error: $e', isError: true);
    }
    setState(() => _loading = false);
  }

  double _totalEarnings(List<Map<String, dynamic>> bookings) {
    return bookings.fold(0.0,
        (sum, b) => sum + ((b['total'] ?? 0) as num).toDouble() * 0.70);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Payouts'),
        backgroundColor: AppColors.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _load,
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_error != null)
                  AppBox(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: AppFonts.dmMono(
                            fontSize: 12, color: AppColors.error)),
                  ),

                // Header
                AppHeading('Stripe Payouts', size: 28),
                const SizedBox(height: 8),
                Text(
                  'Receive payments directly to your bank account via Stripe.',
                  style: AppFonts.dmMono(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.6),
                ),
                const SizedBox(height: 24),

                // Not connected yet
                if (_stripeAccountId == null) ...[
                  AppBox(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppLabel('Get paid for your rentals'),
                        const SizedBox(height: 12),
                        Text(
                          'Connect your bank account via Stripe to receive 70% of every rental. BASERENT takes a 30% platform fee.',
                          style: AppFonts.dmMono(
                              fontSize: 12,
                              color: AppColors.textDim,
                              height: 1.7),
                        ),
                        const SizedBox(height: 20),
                        _InfoRow(
                            icon: Icons.account_balance,
                            text: 'Payments deposited to your bank'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.security,
                            text: 'Secured by Stripe — trusted by millions'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            icon: Icons.speed,
                            text: 'Payouts in 2 business days'),
                        const SizedBox(height: 24),
                        AppButton(
                          label: _loading
                              ? 'CONNECTING...'
                              : 'CONNECT STRIPE ACCOUNT →',
                          onPressed: _loading ? null : _startOnboarding,
                        ),
                      ],
                    ),
                  ),
                ],

                // Connected — show status
                if (_stripeAccountId != null && _accountStatus != null) ...[
                  _StatusCard(
                    status: _accountStatus!,
                    onRefresh: _load,
                    onDashboard: _openDashboard,
                    onReOnboard: _startOnboarding,
                  ),
                  const SizedBox(height: 20),

                  // Balance
                  if (_balance != null) _BalanceCard(balance: _balance!),
                  if (_balance != null) const SizedBox(height: 20),
                ],

                // Earnings from bookings
                const AppDivider(),
                const SizedBox(height: 20),
                const AppLabel('Earnings from bookings'),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _svc.getOwnerEarnings(widget.userId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();
                    final bookings = snap.data!;
                    if (bookings.isEmpty) {
                      return Text('No confirmed bookings yet.',
                          style: AppFonts.dmMono(
                              fontSize: 12,
                              color: AppColors.textMuted));
                    }
                    final total = _totalEarnings(bookings);
                    return Column(
                      children: [
                        AppBox(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const AppLabel('Total Earned (70%)'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${total.toStringAsFixed(2)}',
                                    style: AppFonts.bebasNeue(
                                        fontSize: 36,
                                        color: AppColors.orange,
                                        letterSpacing: 1),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  const AppLabel('Bookings'),
                                  const SizedBox(height: 4),
                                  Text('${bookings.length}',
                                      style: AppFonts.bebasNeue(
                                          fontSize: 36,
                                          color: AppColors.text,
                                          letterSpacing: 1)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...bookings.map((b) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: AppBox(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        b['equipmentTitle'] ?? '',
                                        style: AppFonts.dmMono(
                                            fontSize: 12),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${(((b["total"] ?? 0) as num) * 0.70).toStringAsFixed(2)}',
                                      style: AppFonts.dmMono(
                                          fontSize: 12,
                                          color: AppColors.orange,
                                          weight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> status;
  final VoidCallback onRefresh;
  final VoidCallback onDashboard;
  final VoidCallback onReOnboard;

  const _StatusCard({
    required this.status,
    required this.onRefresh,
    required this.onDashboard,
    required this.onReOnboard,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status['charges_enabled'] == true;
    return AppBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.success : AppColors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'ACCOUNT ACTIVE' : 'SETUP INCOMPLETE',
              style: AppFonts.dmMono(
                  fontSize: 11,
                  letterSpacing: 2,
                  color:
                      isActive ? AppColors.success : AppColors.orange),
            ),
          ]),
          const SizedBox(height: 16),
          _Row('Charges enabled',
              status['charges_enabled'] == true ? '✓ Yes' : '✗ No'),
          const SizedBox(height: 8),
          _Row('Payouts enabled',
              status['payouts_enabled'] == true ? '✓ Yes' : '✗ No'),
          const SizedBox(height: 8),
          _Row('Onboarding',
              status['details_submitted'] == true
                  ? '✓ Complete'
                  : '⚠ Incomplete'),
          if (!isActive) ...[
            const SizedBox(height: 16),
            const AppDivider(),
            const SizedBox(height: 16),
            Text(
              'Complete your Stripe onboarding to start receiving payments.',
              style: AppFonts.dmMono(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.6),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'COMPLETE SETUP →',
              onPressed: onReOnboard,
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onDashboard,
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orange)),
              child: Text('OPEN STRIPE DASHBOARD →',
                  style: AppFonts.dmMono(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: AppColors.orange)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _Row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppFonts.dmMono(
                fontSize: 11, color: AppColors.textMuted)),
        Text(value,
            style: AppFonts.dmMono(fontSize: 11, color: AppColors.text)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Map<String, dynamic> balance;
  const _BalanceCard({required this.balance});

  int _amount(List<dynamic> list) {
    if (list.isEmpty) return 0;
    return (list.first['amount'] ?? 0) as int;
  }

  @override
  Widget build(BuildContext context) {
    final available = _amount(balance['available'] ?? []);
    final pending = _amount(balance['pending'] ?? []);
    return AppBox(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLabel('Stripe Balance'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available',
                        style: AppFonts.dmMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(available / 100).toStringAsFixed(2)}',
                      style: AppFonts.bebasNeue(
                          fontSize: 28,
                          color: AppColors.success,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pending',
                        style: AppFonts.dmMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(pending / 100).toStringAsFixed(2)}',
                      style: AppFonts.bebasNeue(
                          fontSize: 28,
                          color: AppColors.textDim,
                          letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.orange),
      const SizedBox(width: 10),
      Text(text,
          style: AppFonts.dmMono(
              fontSize: 12, color: AppColors.textDim)),
    ]);
  }
}
