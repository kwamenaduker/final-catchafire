// Login done, should work with Firebase Authentication
import "package:flutter/material.dart";
import '../services/auth_service.dart';
import 'signup.dart';
import 'home.dart';

AuthService authService = AuthService();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      await authService.signIn(email, password);
      if (!mounted) return; // Check if widget is still mounted

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted

      // Show a user-friendly error message
      String errorMessage = _getReadableErrorMessage(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  String _getReadableErrorMessage(String errorMessage) {
    // Convert Firebase error messages to user-friendly messages
    if (errorMessage.contains('user-not-found')) {
      return "No account found with this email. Please check your email or sign up.";
    } else if (errorMessage.contains('wrong-password')) {
      return "Incorrect password. Please try again.";
    } else if (errorMessage.contains('invalid-email')) {
      return "Please enter a valid email address.";
    } else if (errorMessage.contains('user-disabled')) {
      return "This account has been disabled. Please contact support.";
    } else if (errorMessage.contains('too-many-requests')) {
      return "Too many failed login attempts. Please try again later.";
    } else if (errorMessage.contains('network-request-failed')) {
      return "Network error. Please check your internet connection.";
    } else if (errorMessage.contains('email-already-in-use')) {
      return "This email is already in use. Please use a different email or try logging in.";
    }
    // Generic error message for any other errors
    return "Couldn't log in. Please try again later.";
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(244, 242, 230, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GT Ultra',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Log into your account',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField('Email', controller: emailController),
                  const SizedBox(height: 10),
                  buildTextField('Password',
                      obscureText: true, controller: passwordController),
                  const SizedBox(height: 10),
                  buildPrimaryButton('Login', _login),
                  const Spacer(),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "New to Catchafire? ",
                          style:
                              TextStyle(fontFamily: "GT Ultra", fontSize: 12),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign up",
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        fillColor: Color.fromRGBO(200, 196, 180, 1),
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

  Widget buildSecondaryButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
