// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'event_details.dart';
import 'login.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> rsvpEvents = [];

  int totalEvents = 0;
  int totalSkills = 0;
  int totalCauses = 0;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    fetchRsvpEvents();
  }

  Future<void> fetchUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
        totalSkills = (userData?['skills']?.length ?? 0);
        totalEvents = (userData?['events']?.length ?? 0);
        totalCauses = (userData?['causes']?.length ?? 0);
      });
    }
  }

  Future<void> fetchRsvpEvents() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('rsvps', arrayContains: uid)
        .orderBy('date', descending: false)
        .get();

    setState(() {
      rsvpEvents = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Store the document ID
        return data;
      }).toList();
    });
  }

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Upload the image to the server
      final imageUrl = await _uploadImageToServer(_profileImage!);

      if (imageUrl != null) {
        final user = FirebaseAuth.instance.currentUser;

        // Update the profile picture in Firestore with the returned URL
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .update({'profilePicture': imageUrl});

        setState(() {
          userData?['profilePicture'] = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error uploading profile picture")),
        );
      }
    }
  }

  Future<String?> _uploadImageToServer(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST',
          Uri.parse('https://catchafire-28b4936a7553.herokuapp.com/upload'));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        return data['viewLink']; // Assuming the server returns a 'viewLink' key
      } else {
        print("Failed to upload image to server.");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await user?.delete();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account deleted successfully")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _navigateToEventDetails(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          eventId: event['id'],
          eventTitle: event['title'] ?? 'Untitled Event',
          eventDate: event['date']?.toString() ?? '',
          eventLocation: event['location'] ?? '',
          eventDescription: event['description'] ?? '',
          imageUrl: event['imageUrl'],
          skills: event['skills']?.cast<String>(),
          onRsvpComplete: () {
            // This will be called when RSVP is completed
            fetchRsvpEvents();
          },
        ),
      ),
    );
  }

  String _formatEventDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day} ${_monthName(dateTime.month)}, ${dateTime.year}';
    }
    return 'No date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      body: SafeArea(
        child: userData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildCausesSection(),
                        const SizedBox(height: 20),
                        _buildSkillsSection(),
                        const SizedBox(height: 20),
                        _buildPastEventsSection(),
                        const SizedBox(height: 20),
                        _buildUpcomingEventsSection(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _updateProfilePicture,
                child: CircleAvatar(
                  radius: 35,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : NetworkImage(userData?['profilePicture'] ??
                              'https://www.example.com/default-avatar.jpg')
                          as ImageProvider,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: _updateProfilePicture,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userData?['fullName'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'GT Ultra',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined ${_formatJoinDate(userData?['createdAt'])}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully")),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              } else if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('Log Out')),
              const PopupMenuItem(
                  value: 'delete', child: Text('Delete Account')),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatJoinDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${_monthName(date.month)} ${date.year}';
    }
    return 'Unknown';
  }

  static String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month];
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(41, 37, 37, 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(label: 'Events', value: '$totalEvents'),
          _StatColumn(label: 'Skills', value: '$totalSkills'),
          _StatColumn(label: 'Causes', value: '$totalCauses'),
        ],
      ),
    );
  }

  Widget _buildCausesSection() {
    final causes = List<String>.from(userData?['causes'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Causes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'GT Ultra',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: causes.map((cause) => _customChip(cause)).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final skills = List<String>.from(userData?['skills'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Skills',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'GT Ultra',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((skill) => _customChip(skill)).toList(),
        ),
      ],
    );
  }

  Widget _buildPastEventsSection() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'GT Ultra',
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: const Text(
                  'No events posted yet.\nClick the "+" button to post an event!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final events = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index].data() as Map<String, dynamic>;
                // Add the document ID to the event data
                final eventWithId = Map<String, dynamic>.from(event);
                eventWithId['id'] = events[index].id;

                return _buildEventItem(
                  eventWithId,
                  onTap: () => _navigateToEventDetails(eventWithId),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event, {VoidCallback? onTap}) {
    final title = event['title'] ?? 'Untitled Event';
    final date = event['date'] is Timestamp
        ? (event['date'] as Timestamp).toDate()
        : DateTime.now();

    final formattedDate = '${date.day} ${_monthName(date.month)}, ${date.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title, style: const TextStyle(fontSize: 16))),
            Text(formattedDate, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'GT Ultra',
          ),
        ),
        const SizedBox(height: 12),
        rsvpEvents.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                child: const Text(
                  'You have not RSVP\'d to any upcoming events.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                children: rsvpEvents
                    .map((event) => _buildEventItem(
                          event,
                          onTap: () => _navigateToEventDetails(event),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _customChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: const Color.fromRGBO(41, 37, 37, 1),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Inter',
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontFamily: 'Inter',
            )),
      ],
    );
  }
}
