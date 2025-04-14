import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseService {
  // Upload image to Firebase Storage and return download URL
  static Future<String> uploadImageToStorage(File imageFile) async {
    final fileName =
        'events/${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Save event details to Firestore
  static Future<void> saveEventToFirestore(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('events').add(data);
  }
}
