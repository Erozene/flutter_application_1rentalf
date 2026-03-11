import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/equipment.dart';

class EquipmentService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<List<Equipment>> getEquipment({String? category}) {
    // Simple query - no orderBy to avoid needing composite indexes
    Query query = _firestore
        .collection('equipment')
        .where('available', isEqualTo: true);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(Equipment.fromFirestore).toList(),
        );
  }

  Stream<List<Equipment>> getMyListings(String ownerId) {
    return _firestore
        .collection('equipment')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs.map(Equipment.fromFirestore).toList());
  }

  Future<String> uploadImage(File imageFile) async {
    final ref = _storage
        .ref()
        .child('equipment/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = await ref.putFile(imageFile);
    return await task.ref.getDownloadURL();
  }

  Future<void> addEquipment(Equipment item) async {
    await _firestore.collection('equipment').add(item.toMap());
  }

  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    await _firestore.collection('equipment').doc(id).update(data);
  }

  Future<void> deleteEquipment(String id) async {
    await _firestore.collection('equipment').doc(id).delete();
  }

  Future<Equipment?> getEquipmentById(String id) async {
    final doc = await _firestore.collection('equipment').doc(id).get();
    if (!doc.exists) return null;
    return Equipment.fromFirestore(doc);
  }
}
