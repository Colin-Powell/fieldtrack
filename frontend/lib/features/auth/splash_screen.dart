import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();

    // Set up the spinning animation for the Phosphor icon
    _spinnerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Navigate to the welcome screen after a delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Stock Image
          Image.asset('lib/assets/Images/Splash.jpg', fit: BoxFit.cover),

          // 2. Green Color Overlay
          Container(
            // Using ARGB constant to represent the same color with 85% opacity
            color: const Color(0xD91B8A49),
          ),

          // 3. Foreground Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'lib/assets/Images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Main Title & Subtitle ---
                const Text(
                  'FieldTrack',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Student Field Activity\nMonitoring System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.2, // Adjusts line spacing perfectly
                    color: Colors.white,
                  ),
                ),

                const Spacer(),

                // --- Loading Spinner Section ---
                RotationTransition(
                  turns: _spinnerController,
                  child: Icon(
                    // Phosphor spinner gap matches the design perfectly
                    PhosphorIconsRegular.spinnerGap,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(
                  height: 64,
                ), // Gives it proper spacing from the bottom edge
              ],
            ),
          ),
        ],
      ),
    );
  }
}
