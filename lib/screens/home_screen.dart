import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/equipment.dart';
import '../services/equipment_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/equipment_card.dart';
import 'auth_screen.dart';
import 'booking_screen.dart';
import 'conversations_screen.dart';
import 'equipment_detail_screen.dart';
import 'profile_screen.dart';

const _categories = [
  'All', 'Camera', 'Drone', 'Audio', 'Lighting', 'Stabilizer', 'Lens', 'Other'
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _equipmentService = EquipmentService();
  String _activeCategory = 'All';
  String _searchQuery = '';
  String _cityQuery = '';
  final _searchCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  int _navIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _browseView(),
          _myBookingsPlaceholder(),
          _messagesView(),
          _profileOrAuthView(),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _browseView() {
    return NestedScrollView(
      headerSliverBuilder: (_, __) => [
        SliverAppBar(
          pinned: true,
          floating: true,
          backgroundColor: AppColors.bg,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            title: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'BASE',
                    style: AppFonts.bebasNeue(
                        fontSize: 26, letterSpacing: 5, color: AppColors.text),
                  ),
                  TextSpan(
                    text: 'RENT',
                    style: AppFonts.bebasNeue(
                        fontSize: 26,
                        letterSpacing: 5,
                        color: AppColors.orange),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (_, snap) {
                  final loggedIn = snap.data != null;
                  return GestureDetector(
                    onTap: () {
                      if (!loggedIn) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()));
                      } else {
                        setState(() => _navIndex = 3);
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: loggedIn ? AppColors.orange : AppColors.surface,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Icon(
                        loggedIn ? Icons.person : Icons.person_outline,
                        size: 18,
                        color: loggedIn ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border),
          ),
        ),
        SliverToBoxAdapter(child: _searchBar()),
        SliverToBoxAdapter(child: _citySearchBar()),
        SliverToBoxAdapter(child: _categoryBar()),
      ],
      body: _equipmentGrid(),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search gear...',
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _citySearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _cityCtrl,
        style: AppFonts.dmMono(fontSize: 13, color: AppColors.text),
        onChanged: (v) => setState(() => _cityQuery = v),
        decoration: InputDecoration(
          hintText: 'Filter by city...',
          prefixIcon: const Icon(Icons.location_on_outlined,
              color: AppColors.textMuted, size: 18),
          suffixIcon: _cityQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 16),
                  onPressed: () {
                    _cityCtrl.clear();
                    setState(() => _cityQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return AppChip(
            label: cat,
            selected: _activeCategory == cat,
            onTap: () => setState(() => _activeCategory = cat),
          );
        },
      ),
    );
  }

  Widget _equipmentGrid() {
    return StreamBuilder<List<Equipment>>(
      stream: _equipmentService.getEquipment(
          category: _activeCategory == 'All' ? null : _activeCategory,
          city: _cityQuery.trim().isEmpty ? null : _cityQuery.trim()),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.orange, strokeWidth: 2));
        }

        if (snap.hasError) {
          return Center(
              child: Text('Error loading gear',
                  style: AppFonts.dmMono(color: AppColors.error)));
        }

        var items = snap.data ?? [];

        if (_searchQuery.isNotEmpty) {
          items = items
              .where((e) =>
                  e.title.toLowerCase().contains(_searchQuery) ||
                  e.category.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.camera_alt_outlined,
            title: 'No Gear Found',
            subtitle: _searchQuery.isNotEmpty
                ? 'No results for "$_searchQuery"'
                : 'No equipment listed yet in this category.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (_, i) => EquipmentCard(
            item: items[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(equipment: items[i])),
            ),
          ),
        );
      },
    );
  }

  Widget _myBookingsPlaceholder() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.data == null) {
          return EmptyState(
            icon: Icons.bookmark_border,
            title: 'Not Signed In',
            subtitle: 'Sign in to view your bookings.',
            action: ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('SIGN IN'),
            ),
          );
        }
        return BookingsListScreen(userId: snap.data!.uid);
      },
    );
  }

  Widget _profileOrAuthView() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.data == null) {
          return EmptyState(
            icon: Icons.person_outline,
            title: 'Not Signed In',
            subtitle: 'Sign in to access your profile.',
            action: ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AuthScreen())),
              child: const Text('SIGN IN'),
            ),
          );
        }
        return ProfileScreen(user: snap.data!);
      },
    );
  }

  Widget _messagesView() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        if (user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: AppColors.textMuted, size: 48),
                const SizedBox(height: 16),
                Text('Sign in to view messages',
                    style: AppFonts.dmMono(
                        fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                AppButton(
                  label: 'SIGN IN',
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthScreen())),
                ),
              ],
            ),
          );
        }
        return ConversationsScreen(
          currentUserId: user.uid,
          currentUserEmail: user.email ?? '',
        );
      },
    );
  }

  Widget _bottomNav() {
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppFonts.dmMono(fontSize: 9, letterSpacing: 1.5),
        unselectedLabelStyle: AppFonts.dmMono(fontSize: 9, letterSpacing: 1.5),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined, size: 20),
              activeIcon: Icon(Icons.grid_view, size: 20),
              label: 'BROWSE'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border, size: 20),
              activeIcon: Icon(Icons.bookmark, size: 20),
              label: 'BOOKINGS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 20),
              activeIcon: Icon(Icons.chat_bubble, size: 20),
              label: 'MESSAGES'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 20),
              activeIcon: Icon(Icons.person, size: 20),
              label: 'PROFILE'),
        ],
      ),
    );
  }
}
