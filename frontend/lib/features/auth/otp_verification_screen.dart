import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String? email;

  const OtpVerificationScreen({super.key, this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // Controllers and FocusNodes for the 6 OTP fields
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  Timer? _timer;
  int _remainingSeconds = 168; // default 2:48
  bool _loading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _verify() async {
    setState(() => _loading = true);
    // Prototype: fake delay for verification
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _loading = false);

    // Navigate to reset password (forgot-password flow)
    context.go('/reset-password');
  }

  void _startTimer([int seconds = 168]) {
    _timer?.cancel();
    _remainingSeconds = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _resendCode() async {
    if (_loading) return;
    setState(() => _loading = true);
    // Stubbed API call
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _loading = false);
    // Restart timer
    _startTimer();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Verification code resent')));
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color(0xFF1BA654);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. --- Bottom Wave Custom Painter (Background) ---
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

          // 2. --- Paperplane SVG Graphic (Middle ground) ---
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(
                'lib/assets/Images/paperplane.svg',
                width: MediaQuery.of(context).size.width * 0.55,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 3. --- Main Content Form (Foreground) ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Back Arrow ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go('/forgot-password'),
                      icon: Icon(
                        PhosphorIconsRegular.arrowLeft,
                        size: 28,
                        color: Colors.black,
                      ),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- Header ---
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Subtitle (Dual Colored) ---
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: 'We sent a 6-digit code to\n',
                          style: TextStyle(color: Color(0xFF737373)),
                        ),
                        TextSpan(
                          text: (widget.email ?? '').isNotEmpty
                              ? (widget.email ?? '')
                              : 'your email',
                          style: TextStyle(color: greenColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // --- OTP Input Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => _buildOTPField(index, greenColor),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Timer Text (Dual Colored) ---
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Code will expire in ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: _formatDuration(_remainingSeconds),
                          style: TextStyle(color: greenColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Resend Code Button ---
                  TextButton(
                    onPressed: _remainingSeconds == 0 ? _resendCode : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        color: _remainingSeconds == 0
                            ? greenColor
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Verify Button ---
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: greenColor),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _verify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                  // Added space at the bottom to ensure scrolling works smoothly over the graphic
                  const SizedBox(height: 250),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the individual 6 OTP input boxes
  Widget _buildOTPField(int index, Color focusedColor) {
    return SizedBox(
      width: 50,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1, // Limits to 1 digit per box
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          counterText: "", // Hides the character counter below the field
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: focusedColor, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          // Auto-focus logic: move to next field if typed, previous if deleted
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

// Custom Painter to draw the smooth green wave at the bottom perfectly
class _BottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC3DFCC)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.4);

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
