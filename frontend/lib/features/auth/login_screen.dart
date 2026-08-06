import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/toast_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _regController = TextEditingController();
  final _pwController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_student_identifier');
    if (savedId != null && savedId.isNotEmpty) {
      setState(() {
        _regController.text = savedId;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _regController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  void _submit() async {
    final identifier = _regController.text.trim();
    final password = _pwController.text;

    if (identifier.isEmpty || password.isEmpty) {
      ToastService.showError('Please fill all fields');
      return;
    }

    final isEmail = identifier.contains('@');

    final success = await ref.read(authProvider.notifier).login(
      email: isEmail ? identifier : null,
      registrationNo: isEmail ? null : identifier,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_student_identifier', identifier);
      } else {
        await prefs.remove('saved_student_identifier');
      }

      final user = ref.read(authProvider).user;
      if (user?.mustChangePassword == true) {
        context.go('/force-password-change');
      } else if (user?.role == 'STUDENT') {
        context.go('/portal');
      } else if (user?.role == 'ADMIN') {
        context.go('/admin');
      } else if (user?.role == 'SUPERVISOR') {
        context.go('/supervisor');
      } else {
        ToastService.showError('Unknown role. Access denied.');
        ref.read(authProvider.notifier).logout();
      }
    } else {
      final error = ref.read(authProvider).error ?? 'Login failed';
      ToastService.showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF1BA654); // Matched green color

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- Bottom Background Wave (pinned) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(painter: _BottomWavePainter()),
              ),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Back Arrow ---
                  IconButton(
                    onPressed: () => context.go('/welcome'),
                    icon: Icon(
                      PhosphorIconsRegular.arrowLeft,
                      size: 28,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 16),

                  // --- Header ---
                  const Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Login to continue',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Identifier Field ---
                  const Text(
                    'Email or Registration Number',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _regController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email or reg number',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: greenColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Password Field ---
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Roboto',
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: greenColor,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? PhosphorIconsRegular.eyeClosed
                                : PhosphorIconsRegular.eye,
                            color: const Color(0xFF9CA3AF),
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Options Row (Remember me & Forgot Password) ---
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: greenColor,
                          side: const BorderSide(color: greenColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: greenColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Login Button ---
                  ref.watch(authProvider).isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: greenColor),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw the smooth green wave at the bottom perfectly
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFC3DFCC) // Matches the light green wave color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);

    // Creates the smooth sine wave shape
    path.quadraticBezierTo(
      size.width * 0.25,
      -size.height * 0.1,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.0,
      size.width,
      size.height * 0.5,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

