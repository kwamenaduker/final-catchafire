// ignore_for_file: avoid_print

import 'package:catchafire/screens/discover.dart';
import 'package:catchafire/screens/search.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile.dart';
import 'event_details.dart';
import 'post.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeContent(),
    SearchPage(),
    const SizedBox.shrink(),
    DiscoverPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      body: SafeArea(child: _screens[_currentIndex]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostPage()),
          );
        },
        backgroundColor: const Color.fromRGBO(41, 37, 37, 1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != 2) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        selectedItemColor: const Color.fromRGBO(41, 37, 37, 1),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _scrollController = ScrollController();

  Future<List<Map<String, dynamic>>> _loadEventsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('events').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        String? imageUrl = data['imageUrl'] as String?;
        
        // Convert Google Drive URLs
        if (imageUrl != null && imageUrl.contains('drive.google.com/file/d/')) {
          final regex = RegExp(r'/file/d/([^/\s]+)');
          final match = regex.firstMatch(imageUrl);
          if (match != null && match.groupCount >= 1) {
            final fileId = match.group(1)?.trim();
            if (fileId != null && fileId.isNotEmpty) {
              imageUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
            }
          }
        }

        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Event',
          'organization': data['organization'] ?? 'Unknown Organization',
          'location': data['location'] ?? 'Location not specified',
          'date': data['date'] ?? Timestamp.now(),
          'description': data['description'] ?? 'No description available',
          'imageUrl': imageUrl,
          'skills': List<String>.from(data['skills'] ?? []),
        };
      }).toList();
    } catch (e) {
      print('Error loading events: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadEventsFromFirestore(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('No events found.'));
              }

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  _buildWelcomeSection(),
                  ...snapshot.data!.map((event) => _buildEventCard(event)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(
                eventId: event['id'],
                eventTitle: event['title'],
                eventDate: event['date'] is Timestamp 
                    ? DateFormat('MMM dd, yyyy').format(event['date'].toDate())
                    : event['date'].toString(),
                eventLocation: event['location'],
                eventDescription: event['description'],
                imageUrl: event['imageUrl'],
                skills: List<String>.from(event['skills'] ?? []),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event['imageUrl'] != null) ...[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  event['imageUrl'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(41, 37, 37, 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'],
                      style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(244, 242, 230, 1),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(event['organization'],
                      style: const TextStyle(
                          color: Color.fromRGBO(244, 242, 230, 1),
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Color.fromRGBO(244, 242, 230, 1)),
                      const SizedBox(width: 4),
                      Text(event['location'],
                          style: const TextStyle(
                              color: Color.fromRGBO(244, 242, 230, 1))),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          size: 16, color: Color.fromRGBO(244, 242, 230, 1)),
                      const SizedBox(width: 4),
                      Text(event['date'] is Timestamp 
                          ? DateFormat('MMM dd, yyyy').format(event['date'].toDate())
                          : event['date'].toString(),
                          style: const TextStyle(
                              color: Color.fromRGBO(244, 242, 230, 1))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<String>.from(event['skills'] ?? []).map((skill) {
                      return Chip(
                        label: Text(skill),
                        backgroundColor:
                            const Color.fromRGBO(244, 242, 230, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/logo.png', width: 120),
          const CircleAvatar(
            backgroundColor: Color.fromRGBO(41, 37, 37, 1),
            radius: 18,
            child:
                Icon(Icons.notifications_none, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String greeting = 'Hello 👋';

              if (snapshot.connectionState == ConnectionState.waiting) {
                greeting = 'Hello 👋';
              } else if (snapshot.hasData && snapshot.data != null) {
                try {
                  // Get the full name from Firestore
                  String fullName = snapshot.data!.get('fullName') ?? '';

                  // Extract the first name (everything before the first space)
                  String firstName = fullName.split(' ').first;

                  if (firstName.isNotEmpty) {
                    greeting = 'Hello, $firstName 👋';
                  }
                } catch (e) {
                  greeting = 'Hello 👋';
                }
              }

              return Text(
                greeting,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(41, 37, 37, 1)),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Find events and opportunities to contribute to causes you care about.',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color.fromRGBO(41, 37, 37, 1)),
          ),
        ],
      ),
    );
  }
}
