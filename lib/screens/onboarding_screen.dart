// Complete, works as intended
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'signup.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = index == 3;
              });
            },
            children: [
              buildPage(
                title: "Bridging paths to stronger communities",
                description:
                    " Whether you are representing your organisation or just looking to volunteer, Catchafire is for you. Create and track opportunities to make lasting impact",
                imageAsset: "assets/onboarding1.png",
              ),
              buildPage(
                title: "Turn your skills into something more",
                description:
                    "On Catchafire, your skills support nonprofits on the frontlines solving critical community issues. Build your resume and portfolio while directly supporting the causes you care about.",
                imageAsset: "assets/onboarding2.png",
              ),
              buildPage(
                title: "Connections that make a difference",
                description:
                    "Find and sign up for volunteer events or post your own events for people to join the causes you care about.",
                imageAsset: "assets/onboarding3.png",
              ),
              buildPage(
                title: "Be part of something bigger",
                description:
                    "A community awaits you. Sign up or log in to start making a difference today.",
                imageAsset: "assets/onboarding4.png",
              ),
            ],
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: WormEffect(
                  dotColor: Colors.grey,
                  activeDotColor: Colors.deepPurple,
                ),
              ),
            ),
          ),
          if (onLastPage)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: buildPrimaryButton(
                      'Sign Up',
                      () {
                        // Navigate to sign up
                        Navigator.push(
                          // or to use Navigator.pushReplacement?? idk
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          else
            Positioned(
              bottom: 20,
              right: 20,
              child: TextButton(
                onPressed: () => _controller.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
                child: Text("Next"),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPage({
    required String title,
    required String description,
    required String imageAsset,
  }) {
    return Column(
      children: [
        // Top image section
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.infinity,
          color: Color.fromRGBO(41, 37, 37, 1),
          child: Image.asset(
            imageAsset,
            fit: BoxFit.contain,
          ),
        ),

        // Text section
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.infinity,
          color: Color.fromRGBO(244, 242, 230, 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'GT Ultra',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
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
}
