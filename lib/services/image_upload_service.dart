import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  static Future<String?> pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final fileName = 'equipment/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final ref = _storage.ref().child(fileName);

    // Both web and mobile: read as bytes — works everywhere
    final bytes = await picked.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return await ref.getDownloadURL();
  }
}
