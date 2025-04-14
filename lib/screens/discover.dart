// ignore_for_file: avoid_print, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import 'event_details.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  final _locationService = LocationService();

  List<Map<String, dynamic>> _eventsFromDB = [];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _initLocation();
    await _loadEventsFromFirestore();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _saveLocationToFirestore(user.uid, pos.latitude, pos.longitude);
        }

        await _locationService.saveLocation(pos);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location updated and saved")),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _saveLocationToFirestore(
      String userId, double latitude, double longitude) async {
    try {
      // Using update() instead of set() to only update the location field
      // This preserves all other fields in the user document
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'lastUpdated': FieldValue
              .serverTimestamp(), // Optional: track when location was updated
        },
      });
    } catch (e) {
      // If the document doesn't exist yet (first-time users), create it
      if (e is FirebaseException && e.code == 'not-found') {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        print('Error saving location to Firestore: $e');
      }
    }
  }

  String? _convertGoogleDriveUrl(String url) {
    try {
      if (url.contains('drive.google.com/file/d/')) {
        // Extract file ID from Google Drive URL
        final regex = RegExp(r'/file/d/([^/\s]+)');
        final match = regex.firstMatch(url);
        if (match != null && match.groupCount >= 1) {
          final fileId = match.group(1)?.trim();
          if (fileId != null && fileId.isNotEmpty) {
            print('DEBUG: Extracted Google Drive file ID: $fileId');
            // Convert to direct download link
            return 'https://drive.google.com/uc?export=view&id=$fileId';
          }
        }
      }
      return url;
    } catch (e) {
      print('DEBUG: Error converting Google Drive URL: $e');
      return null;
    }
  }

  Future<void> _loadEventsFromFirestore() async {
    try {
      print('DEBUG: Starting to load events from Firestore');
      final snapshot =
          await FirebaseFirestore.instance.collection('events').get();
      print('DEBUG: Found ${snapshot.docs.length} events');

      final events = snapshot.docs.map((doc) {
        final data = doc.data();
        print('DEBUG: Processing event ${doc.id}');

        // Handle the image URL - convert Google Drive URLs
        String? imageUrl = data['imageUrl'] as String?;
        print(
            'DEBUG: Raw imageUrl from Firestore for event ${doc.id}: $imageUrl');

        if (imageUrl != null) {
          if (imageUrl.contains('drive.google.com')) {
            final convertedUrl = _convertGoogleDriveUrl(imageUrl);
            print('DEBUG: Converted Google Drive URL: $convertedUrl');
            imageUrl = convertedUrl;
          }

          if (imageUrl != null &&
              (imageUrl.startsWith('http://') ||
                  imageUrl.startsWith('https://'))) {
            print('DEBUG: Valid URL found for event ${doc.id}: $imageUrl');
          } else {
            print(
                'DEBUG: Invalid image URL format for event ${doc.id}, resetting to null');
            imageUrl = null;
          }
        }

        final eventData = {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Event',
          'latitude': data['latitude'] ?? 0.0,
          'longitude': data['longitude'] ?? 0.0,
          'organization': data['organization'] ?? 'Unknown Organization',
          'date': data['date'] ?? Timestamp.now(),
          'skills': data['skills'] ?? [],
          'location': data['location'] ?? 'Location not specified',
          'description': data['description'] ?? 'No description available',
          'imageUrl': imageUrl, // Keep the original URL
          'organizerId':
              data['userId'] ?? data['organizerId'], // Try both fields
        };
        print('DEBUG: Event ${doc.id} data:');
        print('DEBUG: - imageUrl: $imageUrl');
        print('DEBUG: - organizerId: ${eventData['organizerId']}');
        return eventData;
      }).toList();

      print('DEBUG: Setting state with ${events.length} events');
      setState(() {
        _eventsFromDB = events;
      });
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching events: $e');
      print('DEBUG: Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover Nearby',
          style: TextStyle(fontFamily: "GT Ultra", fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
        centerTitle: true,
      ),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Discover events and activities happening near you. Tap a marker to learn more!",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 10,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: _currentLocation!,
                        infoWindow: const InfoWindow(title: 'You Are Here'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                      ),
                      ..._eventsFromDB.map((event) {
                        return Marker(
                          markerId: MarkerId(event['id']),
                          position:
                              LatLng(event['latitude'], event['longitude']),
                          infoWindow: InfoWindow(
                            title: event['title'],
                            onTap: () {
                              final imageUrl = event['imageUrl'];
                              print(
                                  'DEBUG: Passing imageUrl to EventDetailPage: $imageUrl'); // Add debug print
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailPage(
                                    eventId: event['id'],
                                    eventTitle: event['title'],
                                    eventDate: event['date'] is Timestamp
                                        ? DateFormat('MMM dd, yyyy')
                                            .format(event['date'].toDate())
                                        : event['date'].toString(),
                                    eventLocation: event['location'],
                                    eventDescription: event['description'],
                                    imageUrl: event[
                                        'imageUrl'], // Pass the raw imageUrl
                                    skills: List<String>.from(
                                        event['skills'] ?? []),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showEventDetailsSheet(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Hosted by: ${event['organization']}'),
              Text('Location: ${event['location']}'),
              Text(
                  'Date: ${event['date'] is Timestamp ? DateFormat('MMM dd, yyyy').format(event['date'].toDate()) : event['date'].toString()}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailPage(
                        eventId: event['id'],
                        eventTitle: event['title'],
                        eventDate: event['date'] is Timestamp
                            ? DateFormat('MMM dd, yyyy')
                                .format(event['date'].toDate())
                            : event['date'].toString(),
                        eventLocation: event['location'],
                        eventDescription: event['description'],
                      ),
                    ),
                  );
                },
                child: const Text("View Details"),
              ),
            ],
          ),
        );
      },
    );
  }
}
