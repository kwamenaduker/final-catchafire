// Works as expected
// Except phone number, does not check for correctness
// Check in future? unsure

import 'package:catchafire/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cause_skills.dart';
import '../services/auth_service.dart';
import 'login.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signUp() async {
    // Reset error message
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    // Validate all fields are filled
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please fill in all fields';
        _isLoading = false;
      });
      return;
    }

    // Validate email format
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(_emailController.text.trim())) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    // Validate password strength
    if (!_isStrongPassword(_passwordController.text)) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Password must be at least 8 characters long, include 1 uppercase and 1 lowercase letter, a number, and a special character.';
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        try {
          await _firestoreService.createUser(user.uid, {
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'city': _cityController.text.trim(),
            'skills': [],
            'causes': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CauseAndSkillsPage()),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Error saving your profile: Please try again';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Account creation failed: Please try again';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getReadableErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  String _getReadableErrorMessage(String errorMessage) {
    // Convert Firebase error messages to user-friendly messages
    if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already registered. Please use a different email or log in.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorMessage.contains('operation-not-allowed')) {
      return 'Email/password accounts are not enabled. Please contact support.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Your password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    // Generic error message for any other errors
    return 'Signup failed. Please try again later.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 242, 230, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ready to change the world, Volunteer?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'GT Ultra',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Create an account to get started',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Form Fields
              buildTextField('Full Name', controller: _nameController),
              const SizedBox(height: 10),
              buildTextField('Email', controller: _emailController),
              const SizedBox(height: 10),
              buildTextField('Phone Number', controller: _phoneController),
              const SizedBox(height: 10),
              buildTextField('City/Location', controller: _cityController),
              const SizedBox(height: 10),
              buildTextField('Password',
                  controller: _passwordController, obscureText: true),
              const SizedBox(height: 10),
              buildTextField('Confirm Password',
                  controller: _confirmPasswordController, obscureText: true),

              const SizedBox(height: 20),

              // Sign Up Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildPrimaryButton('Sign Up', _signUp),

              // Error message display
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),

              // Log-in Option with Clickable "Log in" Link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(fontFamily: "GT Ultra", fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Log in",
                        style: TextStyle(
                          fontFamily: "GT Ultra",
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isStrongPassword(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecialChar =
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    return hasUppercase &&
        hasLowercase &&
        hasDigit &&
        hasSpecialChar &&
        hasMinLength;
  }

  Widget buildTextField(String hint,
      {bool obscureText = false, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color.fromRGBO(41, 37, 37, 1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color.fromRGBO(200, 196, 180, 1),
      ),
    );
  }

  Widget buildPrimaryButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFF6FE6FF)),
          ),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
