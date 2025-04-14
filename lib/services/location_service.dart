import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Gets the current GPS location
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  /// Saves location to Firestore under `locations` collection
  Future<void> saveLocation(Position pos) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('locations').add({
      'userId': user.uid,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
