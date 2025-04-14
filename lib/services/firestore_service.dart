import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add user data
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection("users").doc(uid).set(userData);
  }

  // Get all causes
  Future<List<Map<String, dynamic>>> getCauses() async {
    var snapshot = await _db.collection("causes").get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  //Get Location
  Future<void> addLocation(double latitude, double longitude) async {
    await _db.collection("locations").add({
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

}



