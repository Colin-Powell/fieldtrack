import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Title Section ---
              const Text(
                'Welcome to',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 40,
                  fontWeight: FontWeight.w900, // Extra bold to match design
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const Text(
                'FieldTrack',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A34A), // Vibrant green matching the design
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),

              // --- Subtitle Section ---
              const Text(
                'Track your field activities,\nstay accountable and\nmake data reliable',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF525252), // Dark grey
                  height: 1.4, // Matches the spacing in the design perfectly
                ),
              ),

              const Spacer(),

              Center(
                child: SvgPicture.asset(
                  'lib/assets/Images/welcome.svg',
                  height: 340,
                  fit: BoxFit.contain,
                ),
              ),

              const Spacer(),

              // --- Get Started Button ---
              SizedBox(
                width: double.infinity,
                height: 56, // Tall, prominent button
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), // Matching green
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // Perfect pill shape
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // --- Supervisor Login Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => context.go('/supervisor/login'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF16A34A), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Supervisor Portal',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom safe space
            ],
          ),
        ),
      ),
    );
  }
}
