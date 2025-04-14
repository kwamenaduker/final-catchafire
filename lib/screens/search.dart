import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event_details.dart';
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> filteredEvents = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('events').get();
    final events = querySnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();

    setState(() {
      allEvents = events;
      filteredEvents = events;
    });
  }

  void _searchEvents(String query) {
    final lowerQuery = query.toLowerCase();

    setState(() {
      searchQuery = query;
      filteredEvents = allEvents.where((event) {
        final title = event['title']?.toLowerCase() ?? '';
        final skills = List<String>.from(event['skills'] ?? []);
        final skillMatch =
            skills.any((s) => s.toLowerCase().contains(lowerQuery));
        return title.contains(lowerQuery) || skillMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontFamily: "GT Ultra", fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Field
            TextField(
              onChanged: _searchEvents,
              decoration: InputDecoration(
                hintText: 'Search events, skills...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Search Results
            Expanded(
              child: filteredEvents.isEmpty
                  ? const Center(child: Text('No events found.'))
                  : ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return _buildEventCard(
                          context,
                          image:
                              event['imageUrl'] ?? 'assets/default_event.jpg',
                          title: event['title'] ?? 'No Title',
                          organization: event['organization'] ?? 'Unknown Org',
                          location: event['location'] ?? 'Unknown Location',
                          date: event['date'] ?? '',
                          skills: List<String>.from(event['skills'] ?? []),
                          description: event['description'] ?? '',
                          eventId: event['id'],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context, {
    required String eventId,
    required String image,
    required String title,
    required String organization,
    required String location,
    required dynamic date,
    required List<String> skills,
    required String description,
  }) {
    String formattedDate = '';
    if (date is Timestamp) {
      DateTime dateTime = date.toDate();
      formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (date is String) {
      formattedDate = date;
    }

    Widget imageWidget;
    if (image.startsWith('https://drive.google.com/')) {
      final regex = RegExp(r'\/d\/([a-zA-Z0-9-_]+)\/');
      final match = regex.firstMatch(image);

      if (match != null) {
        final fileId = match.group(1);
        final directUrl = 'https://drive.google.com/uc?export=view&id=$fileId';
        imageWidget = Image.network(
          directUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = Image.asset(
          'assets/default_event.jpg',
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    } else if (image.startsWith('http') || image.startsWith('https')) {
      imageWidget = Image.network(
        image,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Image.asset(
        image,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(
              eventId: eventId,
              eventTitle: title,
              eventDate: formattedDate,
              eventLocation: location,
              eventDescription: description,
              imageUrl: image,
              skills: skills,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: imageWidget,
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(41, 37, 37, 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(244, 242, 230, 1),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(organization,
                      style: const TextStyle(
                          color: Color.fromRGBO(244, 242, 230, 1),
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Color.fromRGBO(244, 242, 230, 1)),
                      const SizedBox(width: 4),
                      Text(location,
                          style: const TextStyle(
                              color: Color.fromRGBO(244, 242, 230, 1))),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today,
                          size: 16, color: Color.fromRGBO(244, 242, 230, 1)),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(
                              color: Color.fromRGBO(244, 242, 230, 1))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((skill) => Chip(
                              label: Text(skill),
                              backgroundColor:
                                  const Color.fromRGBO(244, 242, 230, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide.none,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
