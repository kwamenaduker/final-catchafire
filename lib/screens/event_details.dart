// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String eventDate;
  final String eventLocation;
  final String eventDescription;
  final String? imageUrl;
  final List<String>? skills;
  final Function? onRsvpComplete; // New callback for when RSVP is completed

  const EventDetailPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.eventDescription,
    this.imageUrl,
    this.skills,
    this.onRsvpComplete, // Added parameter
  });

  @override
  EventDetailPageState createState() => EventDetailPageState();
}

class EventDetailPageState extends State<EventDetailPage> {
  bool _hasRSVPed = false;
  String? _organizerPhone;
  bool _isLoadingPhone = true;

  @override
  void initState() {
    super.initState();
    _fetchOrganizerPhone();
  }

  Future<void> _fetchOrganizerPhone() async {
    try {
      print('DEBUG: Fetching event details for ${widget.eventId}');
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (!eventDoc.exists) {
        print('DEBUG: Event document not found');
        setState(() {
          _isLoadingPhone = false;
        });
        return;
      }

      print('DEBUG: Event data: ${eventDoc.data()}');

      // Get phone number directly from event document
      final phone = eventDoc.data()?['organizerPhone'] as String?;
      print('DEBUG: Raw phone value: $phone');
      print('DEBUG: Phone value type: ${phone?.runtimeType}');

      setState(() {
        _organizerPhone = phone;
        _isLoadingPhone = false;
        print('DEBUG: Set phone number to: $_organizerPhone');
      });
    } catch (e, stackTrace) {
      print('DEBUG: Error fetching organizer phone: $e');
      print('DEBUG: Stack trace: $stackTrace');
      setState(() {
        _isLoadingPhone = false;
      });
    }
  }

  void _rsvp(BuildContext context, String eventId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final eventRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);

      // Add the user to the rsvps array (if not already added)
      await eventRef.update({
        'rsvps': FieldValue.arrayUnion([uid])
      });

      // Optionally update the user's RSVPed events (if you're tracking it here)
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.update({
        'rsvps': FieldValue.arrayUnion([eventId])
      });

      setState(() {
        _hasRSVPed = true;
      });

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("RSVP Confirmed"),
          content: const Text("Thanks for your interest! You're on the list."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog

                // Call the callback function if it exists
                if (widget.onRsvpComplete != null) {
                  widget.onRsvpComplete!();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Added to your Upcoming Events."),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to RSVP. Please try again.")),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    if (_organizerPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organizer phone number not available')),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: _organizerPhone);
    print('DEBUG: Attempting to call: $_organizerPhone');

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    final Uri mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.eventLocation)}');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    }
  }

  Widget _buildCallButton() {
    print('DEBUG: Building call button with phone: $_organizerPhone');
    if (_isLoadingPhone) {
      return const Center(child: CircularProgressIndicator());
    }

    final phone = _organizerPhone;
    print('DEBUG: Phone number for button: $phone');

    return ElevatedButton(
      onPressed: _makePhoneCall,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color.fromRGBO(217, 217, 217, 1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Call',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Event Details - Image URL: ${widget.imageUrl}');

    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 249, 245, 1),
      appBar: AppBar(
        title: Text(widget.eventTitle),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                Builder(builder: (context) {
                  print(
                      'DEBUG: Attempting to load image from: ${widget.imageUrl}');
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        print(
                            'DEBUG: Image loading progress: ${loadingProgress?.expectedTotalBytes}');
                        if (loadingProgress == null) {
                          print('DEBUG: Image loaded successfully');
                          return child;
                        }
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('DEBUG: Error loading image: $error');
                        print('DEBUG: URL that failed: ${widget.imageUrl}');
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text('Failed to load image'),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'URL: ${widget.imageUrl}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
              const SizedBox(height: 20),
              Text(
                widget.eventTitle,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 6),
                  Text(widget.eventDate, style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(widget.eventLocation,
                          style: const TextStyle(fontSize: 16))),
                  IconButton(
                    icon: const Icon(Icons.map_outlined),
                    onPressed: _openInMaps,
                    tooltip: 'Open in Maps',
                  ),
                ],
              ),
              if (widget.skills != null && widget.skills!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: widget.skills!
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Colors.teal.shade100,
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'About this event',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                widget.eventDescription,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _rsvp(context, widget.eventId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color.fromRGBO(217, 217, 217, 1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasRSVPed
                                ? Icons.check_circle
                                : Icons.calendar_today,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hasRSVPed ? 'RSVP\'d' : 'RSVP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCallButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
