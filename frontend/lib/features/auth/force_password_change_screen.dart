import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/toast_service.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

class ForcePasswordChangeScreen extends ConsumerStatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  ConsumerState<ForcePasswordChangeScreen> createState() =>
      _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState
    extends ConsumerState<ForcePasswordChangeScreen> {
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  void _submit() async {
    final currentPassword = _currentPwController.text;
    final newPassword = _newPwController.text;
    final confirmPassword = _confirmPwController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ToastService.showError('Please fill all fields');
      return;
    }

    if (newPassword != confirmPassword) {
      ToastService.showError('Passwords do not match');
      return;
    }

    // Client-side password check (matches backend eased rule: min 6 chars)
    if (newPassword.length < 6) {
      ToastService.showError('Password must be at least 6 characters long');
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await ApiClient().dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (response.statusCode == 200 && response.data['success'] == true) {
        ToastService.showSuccess('Password updated successfully');
        ref.read(authProvider.notifier).checkAuthStatus();
        context.go('/portal');
      } else {
        final errorMsg = ErrorHandler.getFriendlyErrorMessage(response.data);
        ToastService.showError(errorMsg);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final errorMsg = ErrorHandler.getFriendlyErrorMessage(e);
      ToastService.showError(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ToastService.showError(
        'Unexpected error: ${ErrorHandler.getFriendlyErrorMessage(e)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF1BA654);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- Bottom Wave Custom Painter ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 150, // Controls how high the wave reaches
              width: double.infinity,
              child: CustomPaint(painter: _BottomWavePainter()),
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
                    onPressed: () => context.pop(),
                    icon: Icon(
                      PhosphorIconsRegular.arrowLeft,
                      size: 28,
                      color: Colors.black,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: 24),

                  // --- Header ---
                  const Center(
                    child: Text(
                      'Create a new Password',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Subtitle ---
                  const Center(
                    child: Text(
                      'For your security, this is your first time signing\nin with a temporary password. Please create\na new password before accessing\nyour account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF737373),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Password Inputs ---
                  _buildPasswordField(
                    label: 'Current Password',
                    hint: 'Enter your temporary password',
                    controller: _currentPwController,
                    obscureText: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(
                    label: 'New Password',
                    hint: 'Create a strong password',
                    controller: _newPwController,
                    obscureText: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter your new password',
                    controller: _confirmPwController,
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 32),

                  // --- Submit Button ---
                  _loading
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
                              shadowColor: greenColor.withOpacity(0.5),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Update Password & Continue',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                  // Extra space at bottom to ensure content scrolls freely above the painted wave
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for the 3 password fields
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    const greenColor = Color(0xFF1BA654);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: greenColor, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: Icon(
                  obscureText
                      ? PhosphorIconsRegular.eyeClosed
                      : PhosphorIconsRegular.eye,
                  color: const Color(0xFF9CA3AF),
                  size: 22,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
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
