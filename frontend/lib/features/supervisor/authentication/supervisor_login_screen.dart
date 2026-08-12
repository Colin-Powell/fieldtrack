import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../main_supervisor.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/error_handler.dart';

class SupervisorLoginScreen extends ConsumerStatefulWidget {
  const SupervisorLoginScreen({super.key});

  @override
  ConsumerState<SupervisorLoginScreen> createState() => _SupervisorLoginScreenState();
}

class _SupervisorLoginScreenState extends ConsumerState<SupervisorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
    final savedId = prefs.getString('saved_supervisor_identifier');
    if (savedId != null && savedId.isNotEmpty) {
      setState(() {
        _emailController.text = savedId;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      final success = await ref.read(authProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _pwController.text,
      );

      if (!mounted) return;

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('saved_supervisor_identifier', _emailController.text.trim());
        } else {
          await prefs.remove('saved_supervisor_identifier');
        }

        final user = ref.read(authProvider).user;
        if (user?.role == 'SUPERVISOR') {
          context.go('/supervisor/dashboard');
        } else {
          rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Access denied. This portal is for supervisors only.'),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(authProvider.notifier).logout();
        }
      } else {
        final error = ref.read(authProvider).error ?? 'Login failed';
        rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Login Exception: $e\n$stackTrace');
      if (!mounted) return;
      rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                // --- Left Split: Image with Green Overlay ---
                Expanded(flex: 5, child: _buildLeftCover()),
                // --- Right Split: Form ---
                Expanded(flex: 5, child: _buildRightForm(isDesktop: true)),
              ],
            );
          }

          // --- Mobile Layout: Stack with Bottom Wave ---
          return Stack(
            children: [
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
              _buildRightForm(isDesktop: false),
            ],
          );
        },
      ),
    );
  }

  // ─── Left Cover (Desktop Only) ──────────────────────────────────────────
  Widget _buildLeftCover() {
    const greenColor = Color(0xFF1BA654);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          // Example university/campus placeholder image
          image: NetworkImage(
            'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&q=80&w=1000',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: greenColor.withOpacity(0.85), // Green overlay
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'FieldTrack\nSupervisor Portal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Monitor student field attachments, review activity logs in real-time, and generate comprehensive evaluation reports.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Right Form (Desktop & Mobile) ──────────────────────────────────────
  Widget _buildRightForm({required bool isDesktop}) {
    const greenColor = Color(0xFF1BA654);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64.0 : 24.0,
            vertical: 24.0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Back Arrow ---
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/welcome');
                      }
                    },
                    icon: Icon(
                      PhosphorIcons.arrowLeft(),
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Header ---
                  Text(
                    'Supervisor Login',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 36 : 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please sign in to access the supervisor portal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- Email Field ---
                  const Text(
                    'University Email',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g., supervisor@university.edu',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
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
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Password Field ---
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pwController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontFamily: 'Poppins',
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
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
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? PhosphorIcons.eyeClosed()
                                : PhosphorIcons.eye(),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                              side: const BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Remember me',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push('/supervisor/forgot-password'),
                        style: TextButton.styleFrom(
                          foregroundColor: greenColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

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
                                fontFamily: 'Poppins',
                                fontSize: 16,
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
        ),
      ),
    );
  }
}

// ─── Mobile Bottom Wave Painter ───────────────────────────────────────────
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFE8F6ED) // Very light green wave
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
