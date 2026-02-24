// Paste this entire file into lib/main.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BaserentApp());
}

class BaserentApp extends StatelessWidget {
  const BaserentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BASERENT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  String selectedCategory = 'All';
  String searchQuery = '';

  final List<String> categories = [
    'All',
    'Cameras',
    'Lenses',
    'Audio',
    'Lighting',
    'Tripods',
    'Gimbals',
    'Control Panels',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BASERENT', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onPressed: _showProfileModal,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: categories.map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (_) => setState(() => selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search equipment...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Post'),
                    onPressed: _openPostDialog,
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('equipment').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final list = snapshot.data!.docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    data['id'] = d.id;
                    return data;
                  }).where((item) {
                    final matchesCategory = selectedCategory == 'All' || item['category'] == selectedCategory;
                    final matchesSearch = item['title'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                    return matchesCategory && matchesSearch;
                  }).toList();

                  return GridView.builder(
                    itemCount: list.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (_, i) {
                      final item = list[i];
                      return EquipmentCard(
                        item: item,
                        currentUserId: auth.currentUser?.uid,
                        onEdit: _openEditDialog,
                        onDelete: _deleteEquipment,
                        onBook: _openBookingDialog,
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showProfileModal() {
    final user = auth.currentUser;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Profile'),
        content: user == null
            ? const Text('Not logged in')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Email: ${user.email}'),
                  const SizedBox(height: 8),
                  Text('UID: ${user.uid}'),
                ],
              ),
        actions: [
          if (user == null)
            TextButton(onPressed: _openAuthDialog, child: const Text('Login / Sign Up'))
          else
            TextButton(onPressed: () => auth.signOut(), child: const Text('Logout')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _openAuthDialog() {
    Navigator.pop(context);
    showDialog(context: context, builder: (_) => const AuthDialog());
  }

  void _openPostDialog() {
    final user = auth.currentUser;
    if (user == null) {
      _openAuthDialog();
      return;
    }

    showDialog(context: context, builder: (_) => PostDialog(userId: user.uid));
  }

  void _openEditDialog(Map<String, dynamic> item) {
    final user = auth.currentUser;
    if (user == null) return;

    if (item['ownerId'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot edit this item')));
      return;
    }

    showDialog(context: context, builder: (_) => EditDialog(item: item));
  }

  void _deleteEquipment(Map<String, dynamic> item) async {
    final user = auth.currentUser;
    if (user == null) return;

    if (item['ownerId'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot delete this item')));
      return;
    }

    await firestore.collection('equipment').doc(item['id']).delete();
  }

  void _openBookingDialog(Map<String, dynamic> item) {
    final user = auth.currentUser;
    if (user == null) {
      _openAuthDialog();
      return;
    }

    showDialog(context: context, builder: (_) => BookingDialog(item: item, userId: user.uid));
  }
}

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool isLogin = true;
  String email = '';
  String password = '';
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isLogin ? 'Login' : 'Sign Up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(onChanged: (v) => email = v, decoration: const InputDecoration(labelText: 'Email')),
          TextField(onChanged: (v) => password = v, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? 'Switch to Sign Up' : 'Switch to Login')),
        FilledButton(
          onPressed: () async {
            try {
              if (isLogin) {
                await auth.signInWithEmailAndPassword(email: email, password: password);
              } else {
                await auth.createUserWithEmailAndPassword(email: email, password: password);
              }
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: Text(isLogin ? 'Login' : 'Sign Up'),
        )
      ],
    );
  }
}

class PostDialog extends StatefulWidget {
  final String userId;
  const PostDialog({required this.userId, super.key});

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  String title = '';
  String category = 'Cameras';
  int price = 0;
  String imageUrl = '';
  XFile? pickedImage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post Equipment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(onChanged: (v) => title = v, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(onChanged: (v) => price = int.tryParse(v) ?? 0, decoration: const InputDecoration(labelText: 'Price per day')),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            initialValue: category,
            items: const [
              DropdownMenuItem(value: 'Cameras', child: Text('Cameras')),
              DropdownMenuItem(value: 'Lenses', child: Text('Lenses')),
              DropdownMenuItem(value: 'Audio', child: Text('Audio')),
              DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
              DropdownMenuItem(value: 'Tripods', child: Text('Tripods')),
              DropdownMenuItem(value: 'Gimbals', child: Text('Gimbals')),
              DropdownMenuItem(value: 'Control Panels', child: Text('Control Panels')),
            ],
            onChanged: (v) => setState(() => category = v!),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _pickImage,
            child: const Text('Pick Image'),
          ),
          if (pickedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(pickedImage!.path, height: 80),
            )
        ],
      ),
      actions: [
        FilledButton(onPressed: _postEquipment, child: const Text('Post')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    setState(() => pickedImage = picked);
  }

  Future<void> _postEquipment() async {
    if (pickedImage == null) return;

    final ref = storage.ref().child('equipment_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(pickedImage!.path));
    final url = await ref.getDownloadURL();

    await firestore.collection('equipment').add({
      'title': title,
      'category': category,
      'price': price,
      'imageUrl': url,
      'ownerId': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }
}

class EditDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  const EditDialog({required this.item, super.key});

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late String title;
  late String category;
  late int price;

  @override
  void initState() {
    super.initState();
    title = widget.item['title'];
    category = widget.item['category'];
    price = widget.item['price'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Equipment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: TextEditingController(text: title), onChanged: (v) => title = v),
          const SizedBox(height: 8),
          TextField(controller: TextEditingController(text: price.toString()), onChanged: (v) => price = int.tryParse(v) ?? 0),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            initialValue: category,
            items: const [
              DropdownMenuItem(value: 'Cameras', child: Text('Cameras')),
              DropdownMenuItem(value: 'Lenses', child: Text('Lenses')),
              DropdownMenuItem(value: 'Audio', child: Text('Audio')),
              DropdownMenuItem(value: 'Lighting', child: Text('Lighting')),
              DropdownMenuItem(value: 'Tripods', child: Text('Tripods')),
              DropdownMenuItem(value: 'Gimbals', child: Text('Gimbals')),
              DropdownMenuItem(value: 'Control Panels', child: Text('Control Panels')),
            ],
            onChanged: (v) => setState(() => category = v!),
          ),
        ],
      ),
      actions: [
        FilledButton(onPressed: _save, child: const Text('Save')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }

  Future<void> _save() async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('equipment').doc(widget.item['id']).update({
      'title': title,
      'category': category,
      'price': price,
    });
    Navigator.pop(context);
  }
}

class BookingDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String userId;
  const BookingDialog({required this.item, required this.userId, super.key});

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final firestore = FirebaseFirestore.instance;

  final List<DateTime> selectedDates = [];

  @override
  Widget build(BuildContext context) {
    final price = widget.item['price'];
    final total = selectedDates.length * price;

    return AlertDialog(
      title: Text(widget.item['title']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select dates (multi-select)'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickDates,
            child: const Text('Pick Dates'),
          ),
          const SizedBox(height: 8),
          Text('Selected: ${selectedDates.length} days'),
          Text('Total: \$$total'),
        ],
      ),
      actions: [
        FilledButton(onPressed: _fakePay, child: const Text('Pay (Fake)')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }

  Future<void> _pickDates() async {
    final today = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked == null) return;

    selectedDates.clear();
    for (var i = 0; i <= picked.duration.inDays; i++) {
      selectedDates.add(picked.start.add(Duration(days: i)));
    }
    setState(() {});
  }

  Future<void> _fakePay() async {
    final bookingRef = firestore.collection('bookings').doc();
    await bookingRef.set({
      'equipmentId': widget.item['id'],
      'userId': widget.userId,
      'dates': selectedDates.map((d) => d.toIso8601String()).toList(),
      'total': selectedDates.length * widget.item['price'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment successful (fake)')));
    Navigator.pop(context);
  }
}

class EquipmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String? currentUserId;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onDelete;
  final Function(Map<String, dynamic>) onBook;

  const EquipmentCard({
    required this.item,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.onBook,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && currentUserId == item['ownerId'];

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(item['imageUrl'], width: double.infinity, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'], style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('\$${item['price']}/day'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14),
                      const SizedBox(width: 4),
                      Text(item['ownerId'].toString().substring(0, 6)),
                    ],
                  ),
                  if (isOwner)
                    Row(
                      children: [
                        TextButton(onPressed: () => onEdit(item), child: const Text('Edit')),
                        TextButton(onPressed: () => onDelete(item), child: const Text('Delete')),
                      ],
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(item['imageUrl']),
            const SizedBox(height: 8),
            Text('\$${item['price']}/day'),
            const SizedBox(height: 8),
            Text('Owner: ${item['ownerId']}'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => onBook(item), child: const Text('Book')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
