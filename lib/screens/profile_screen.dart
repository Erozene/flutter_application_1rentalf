// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../models/equipment.dart';
import '../services/auth_service.dart';
import '../services/equipment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/equipment_card.dart';
import 'legal_screen.dart';
import 'owner_bookings_screen.dart';
import 'payouts_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({required this.user, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _equipmentSvc = EquipmentService();

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.bg,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.orange,
                ),
                child: Center(
                  child: Text(
                    (widget.user.displayName ?? widget.user.email ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: AppFonts.bebasNeue(fontSize: 32, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.displayName ?? 'User',
                      style: AppFonts.bebasNeue(
                          fontSize: 22, letterSpacing: 2, color: AppColors.text),
                    ),
                    Text(
                      widget.user.email ?? '',
                      style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const AppDivider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppLabel('My Listings'),
              TextButton(
                onPressed: () => _showAddEquipmentSheet(context),
                child: Text('+ ADD GEAR',
                    style: AppFonts.dmMono(
                        fontSize: 10, letterSpacing: 1.5, color: AppColors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Equipment>>(
            stream: _equipmentSvc.getMyListings(widget.user.uid),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.orange, strokeWidth: 2));
              }
              final items = snap.data!;
              if (items.isEmpty) {
                return Text('No listings yet. Add your first piece of gear!',
                    style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted));
              }
              return Column(
                children: items
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EquipmentCard(
                            item: e,
                            onTap: () {},
                            onEdit: () => _showAddEquipmentSheet(context, existing: e),
                            onDelete: () => _confirmDelete(context, e),
                            showActions: true,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const AppDivider(),
          const SizedBox(height: 24),
          AppBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PayoutsScreen(
                    userId: widget.user.uid,
                    userEmail: widget.user.email ?? '',
                  ),
                ),
              ),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 18, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payouts',
                          style: AppFonts.dmMono(
                              fontSize: 13, weight: FontWeight.w500)),
                      Text('Connect Stripe to receive payments',
                          style: AppFonts.dmMono(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textMuted),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const LegalScreen(initialTab: 'terms'))),
              child: Text('Terms of Service',
                  style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
            ),
            Text('·',
                style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const LegalScreen(initialTab: 'privacy'))),
              child: Text('Privacy Policy',
                  style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted)),
            ),
          ]),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _signOut,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, Equipment item) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const AppHeading('Delete Listing', size: 20),
        content: Text('Are you sure you want to delete "${item.title}"?',
            style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppFonts.dmMono(fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _equipmentSvc.deleteEquipment(item.id);
      showAppSnackBar(ctx, 'Listing deleted');
    }
  }

  void _showAddEquipmentSheet(BuildContext context, {Equipment? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (_) => _AddEquipmentSheet(
        ownerId: widget.user.uid,
        existing: existing,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }
}

class _AddEquipmentSheet extends StatefulWidget {
  final String ownerId;
  final Equipment? existing;
  final VoidCallback onSaved;

  const _AddEquipmentSheet({
    required this.ownerId,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_AddEquipmentSheet> createState() => _AddEquipmentSheetState();
}

class _AddEquipmentSheetState extends State<_AddEquipmentSheet> {
  final _svc = EquipmentService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  String _category = 'Camera';
  String? _imageUrl;
  bool _available = true;
  bool _saving = false;

  static const _categories = [
    'Camera', 'Drone', 'Audio', 'Lighting', 'Stabilizer', 'Lens', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _priceCtrl.text = e.price.toStringAsFixed(0);
      _category = e.category;
      _imageUrl = e.imageUrl;
      _available = e.available;
      if (e.depositAmount > 0) _depositCtrl.text = e.depositAmount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _saving = true);
    try {
      final url = await ImageUploadService.pickAndUpload();
      if (url != null) setState(() => _imageUrl = url);
    } catch (e) {
      showAppSnackBar(context, 'Image upload failed: $e', isError: true);
    }
    setState(() => _saving = false);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Please enter a title', isError: true);
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      showAppSnackBar(context, 'Please enter a valid price', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final item = Equipment(
        id: widget.existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: price,
        imageUrl: _imageUrl ?? '',
        category: _category,
        depositAmount: double.tryParse(_depositCtrl.text.trim()) ?? 0,
        ownerId: widget.ownerId,
        available: _available,
        rating: widget.existing?.rating ?? 0,
        reviewCount: widget.existing?.reviewCount ?? 0,
        bookedDates: widget.existing?.bookedDates ?? [],
      );

      if (widget.existing != null) {
        await _svc.updateEquipment(widget.existing!.id, item.toMap());
        showAppSnackBar(context, 'Listing updated');
      } else {
        await _svc.addEquipment(item);
        showAppSnackBar(context, 'Listing added');
      }
      widget.onSaved();
    } catch (e) {
      showAppSnackBar(context, 'Error saving: $e', isError: true);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHeading(widget.existing != null ? 'Edit Listing' : 'Add Gear', size: 24),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  border: Border.all(color: AppColors.border),
                ),
                child: _imageUrl != null
                    ? Image.network(_imageUrl!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              color: AppColors.textMuted, size: 36),
                          const SizedBox(height: 8),
                          Text('Tap to add photo',
                              style: AppFonts.dmMono(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _field('Title', _titleCtrl, 'e.g. Canon EOS R5'),
            const SizedBox(height: 12),
            _field('Description', _descCtrl, "What's included, condition...", maxLines: 3),
            const SizedBox(height: 12),
            _field('Daily Price (\$)', _priceCtrl, '0',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Security Deposit (\$)', _depositCtrl, '0 = no deposit',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories
                  .map((c) => AppChip(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const AppLabel('Available for rent'),
                const Spacer(),
                Switch(
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                  activeColor: AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              label: _saving
                  ? 'SAVING...'
                  : (widget.existing != null ? 'SAVE CHANGES' : 'ADD LISTING'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppFonts.dmMono(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
