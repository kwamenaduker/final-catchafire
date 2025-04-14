// ignore_for_file: use_build_context_synchronously
// Works as expected, maintaining

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class CauseAndSkillsPage extends StatefulWidget {
  const CauseAndSkillsPage({super.key});

  @override
  CauseAndSkillsPageState createState() => CauseAndSkillsPageState();
}

class CauseAndSkillsPageState extends State<CauseAndSkillsPage> {
  // Track selected causes and skills
  final Set<String> selectedCauses = {};
  final Set<String> selectedSkills = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      appBar: AppBar(
        title: const Text(
          'Tell Us About You',
          style: TextStyle(fontFamily: "Inter", fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromRGBO(41, 37, 37, 1),
        foregroundColor: const Color.fromRGBO(244, 242, 230, 1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Consistent padding
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction Text
              const Text(
                'To help us understand your interests and skills, please select the causes and skills you are most passionate about. This will help match you with relevant volunteer opportunities!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Inter",
                  color: Color.fromRGBO(41, 37, 37, 1),
                ),
              ),
              const SizedBox(height: 20),

              // Causes Section
              const Text(
                'Causes You Care About',
                style: TextStyle(
                    fontFamily: "GT Ultra",
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildChips(
                  [
                    'Education',
                    'Environment',
                    'Science & Technology',
                    'Health',
                    'Childcare'
                  ],
                  selectedCauses,
                ),
              ),
              const SizedBox(height: 20),

              // Skills Section
              const Text(
                'Skills You Can Offer',
                style: TextStyle(
                    fontFamily: "GT Ultra",
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildChips(
                  [
                    'Graphic Design',
                    'Fundraising',
                    'Training',
                    'Event Planning',
                    'Communications'
                  ],
                  selectedSkills,
                ),
              ),
              const SizedBox(height: 30),

              // Save & Continue Button with Validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    // Validation: Ensure at least one cause and one skill are selected
                    if (selectedCauses.isEmpty || selectedSkills.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select at least one cause and one skill.'),
                        ),
                      );
                      return;
                    }

                    // Get the current user's UID
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      try {
                        // Update Firestore with the selected causes and skills
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          'causes': selectedCauses.toList(),
                          'skills': selectedSkills.toList(),
                        });

                        // Navigate to HomePage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Error saving selections: ${e.toString()}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User not signed in')),
                      );
                    }
                  },
                  child: const Text(
                    'Save & Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the chips
  List<Widget> _buildChips(List<String> items, Set<String> selectedItems) {
    return items.map((item) {
      return GestureDetector(
        onTap: () {
          setState(() {
            if (selectedItems.contains(item)) {
              selectedItems.remove(item); // Deselect if already selected
            } else {
              selectedItems.add(item); // Select the item
            }
          });
        },
        child: Chip(
          label: Text(
            item,
            style: const TextStyle(
              fontSize: 16, // Larger text size
              fontWeight: FontWeight.bold, // Bold text
            ),
          ),
          backgroundColor: selectedItems.contains(item)
              ? const Color.fromRGBO(41, 37, 37, 1) // Dark when selected
              : const Color.fromRGBO(244, 242, 230, 0.7), // Lighter when not
          labelStyle: TextStyle(
            color: selectedItems.contains(item)
                ? Colors.white
                : const Color.fromRGBO(41, 37, 37, 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: selectedItems.contains(item)
                ? Colors.white
                : const Color.fromRGBO(41, 37, 37, 1),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
    }).toList();
  }
}
