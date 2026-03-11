import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LegalScreen extends StatefulWidget {
  final String initialTab;
  const LegalScreen({this.initialTab = 'terms', super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == 'privacy' ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Legal'),
        backgroundColor: AppColors.bg,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.orange,
            indicatorWeight: 2,
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppFonts.dmMono(fontSize: 11, letterSpacing: 2),
            tabs: const [
              Tab(text: 'TERMS OF SERVICE'),
              Tab(text: 'PRIVACY POLICY'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_termsTab(), _privacyTab()],
      ),
    );
  }

  Widget _termsTab() => _legalContent(
        title: 'Terms of Service',
        lastUpdated: 'March 2026',
        sections: [
          _LegalSection('1. Acceptance of Terms',
              'By accessing or using BASERENT, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our platform.'),
          _LegalSection('2. Description of Service',
              'BASERENT is a peer-to-peer equipment rental marketplace that connects equipment owners ("Owners") with people looking to rent equipment ("Renters"). We facilitate transactions but are not a party to the rental agreements between Owners and Renters.'),
          _LegalSection('3. User Accounts',
              'You must create an account to use certain features of BASERENT. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must provide accurate and complete information when creating your account.'),
          _LegalSection('4. Equipment Listings',
              'Owners are solely responsible for the accuracy of their listings, including descriptions, photos, pricing, and availability. All equipment must be in full working condition as described. BASERENT reserves the right to remove listings that violate our policies.'),
          _LegalSection('5. Bookings and Payments',
              'All payments are processed securely through Stripe. By making a booking, you authorize BASERENT to charge your payment method for the total rental amount. Payments are held until the rental period begins.'),
          _LegalSection('6. Cancellation Policy',
              'Renters may cancel a booking free of charge up to 24 hours before the rental start date. Cancellations made within 24 hours of the rental start date are subject to a 50% cancellation fee. No refunds are issued for no-shows.'),
          _LegalSection('7. Damage and Liability',
              'Renters are responsible for any damage to equipment during the rental period beyond normal wear and tear. A damage deposit may be required for certain items. BASERENT is not liable for any damage, loss, or injury arising from the use of rented equipment.'),
          _LegalSection('8. Prohibited Uses',
              'You may not use BASERENT for any illegal purpose, to rent equipment for illegal activities, to misrepresent equipment condition, or to circumvent our payment system. Violations may result in immediate account termination.'),
          _LegalSection('9. Dispute Resolution',
              'In the event of a dispute between an Owner and Renter, both parties agree to first attempt to resolve the issue directly. If unresolved, BASERENT may, at its discretion, assist in mediation but is not obligated to do so.'),
          _LegalSection('10. Changes to Terms',
              'BASERENT reserves the right to modify these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms. We will notify users of significant changes via email.'),
        ],
      );

  Widget _privacyTab() => _legalContent(
        title: 'Privacy Policy',
        lastUpdated: 'March 2026',
        sections: [
          _LegalSection('1. Information We Collect',
              'We collect information you provide directly (name, email, phone number), information generated through your use of our service (bookings, listings, messages), and technical information (device type, IP address, browser type).'),
          _LegalSection('2. How We Use Your Information',
              'We use your information to provide and improve our services, process payments, send booking confirmations and notifications, prevent fraud, and comply with legal obligations. We do not sell your personal information to third parties.'),
          _LegalSection('3. Information Sharing',
              'We share your information with Stripe for payment processing, Firebase/Google for data storage and authentication, and other users only to the extent necessary to complete a rental transaction (e.g. sharing contact details after a booking is confirmed).'),
          _LegalSection('4. Data Security',
              'We implement industry-standard security measures including encryption in transit and at rest. However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security of your data.'),
          _LegalSection('5. Cookies',
              'We use cookies and similar technologies to maintain your session, remember your preferences, and analyze usage patterns. You can control cookie settings through your browser.'),
          _LegalSection('6. Your Rights',
              'You have the right to access, correct, or delete your personal data. You may also object to processing or request data portability. To exercise these rights, contact us at privacy@baserent.com.'),
          _LegalSection('7. Data Retention',
              'We retain your data for as long as your account is active or as needed to provide services. You may request deletion of your account and associated data at any time, subject to legal retention requirements.'),
          _LegalSection('8. Children\'s Privacy',
              'BASERENT is not intended for users under 18 years of age. We do not knowingly collect personal information from children.'),
          _LegalSection('9. Contact Us',
              'If you have questions about this Privacy Policy, please contact us at privacy@baserent.com or write to us at our registered address.'),
        ],
      );

  Widget _legalContent({
    required String title,
    required String lastUpdated,
    required List<_LegalSection> sections,
  }) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AppHeading(title, size: 28),
        const SizedBox(height: 6),
        Text('Last updated: $lastUpdated',
            style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 24),
        const AppDivider(),
        const SizedBox(height: 24),
        ...sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: AppFonts.dmMono(
                          fontSize: 13,
                          weight: FontWeight.w500,
                          color: AppColors.orange,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text(s.body,
                      style: AppFonts.dmMono(
                          fontSize: 12,
                          color: AppColors.textDim,
                          height: 1.8,
                          letterSpacing: 0.3)),
                ],
              ),
            )),
      ],
    );
  }
}

class _LegalSection {
  final String title;
  final String body;
  const _LegalSection(this.title, this.body);
}
