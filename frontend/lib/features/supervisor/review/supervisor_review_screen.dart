import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// --- Design Tokens ---
class _Colors {
  static const white = Colors.white;
  static const primaryGreen = Color(0xFF1BA654);
  static const textDark = Color(0xFF111827);
  static const textBody = Color(0xFF374151);
  static const textFaint = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const cornerRadius = 48.0; // Updated all round corners to 48px
}

class SupervisorReviewScreen extends StatefulWidget {
  final String studentId;
  final String activityId;
  const SupervisorReviewScreen({
    super.key,
    required this.studentId,
    required this.activityId,
  });

  @override
  State<SupervisorReviewScreen> createState() => _SupervisorReviewScreenState();
}

class _SupervisorReviewScreenState extends State<SupervisorReviewScreen> {
  // --- State Variables ---
  double _rating = 4.5;
  String _selectedStatus = 'Approved';
  
  final TextEditingController _commentController = TextEditingController(
    text: 'Good observation and well decumented. Include more notes on\nspecies density measurements in your next submission.\n\nKeep up the good work.',
  );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Submit Feedback Logic
  void _submitFeedback() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback comments before submitting.'),
          backgroundColor: _Colors.red,
        ),
      );
      return;
    }

    Color modalColor = _Colors.primaryGreen;
    IconData modalIcon = PhosphorIconsFill.checkCircle;
    
    if (_selectedStatus == 'Request Revision') {
      modalColor = _Colors.orange;
      modalIcon = PhosphorIconsFill.warningCircle;
    } else if (_selectedStatus == 'Reject') {
      modalColor = _Colors.red;
      modalIcon = PhosphorIconsFill.xCircle;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Colors.cornerRadius),
        ),
        title: Row(
          children: [
            Icon(modalIcon, color: modalColor, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Feedback Submitted',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: _Colors.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'The field log has been marked as "$_selectedStatus" with a rating of $_rating stars.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            color: _Colors.textBody,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: modalColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT COLUMN ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title & Rating Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Feedback',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _Colors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC3DFCC).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                      ),
                      child: Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _Colors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Interactive Overall Rating Row
                Row(
                  children: [
                    const Text(
                      'Overall Rating',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _Colors.textDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: List.generate(5, (index) => _buildInteractiveStar(index)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Review Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _Colors.white,
                    borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                    border: Border.all(color: _Colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Review Status',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _Colors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusOption(
                        title: 'Approved',
                        subtitle: 'Activity meets requirements',
                        color: _Colors.primaryGreen,
                        isSelected: _selectedStatus == 'Approved',
                        onTap: () => setState(() => _selectedStatus = 'Approved'),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusOption(
                        title: 'Request Revision',
                        subtitle: 'Needs some changes',
                        color: _Colors.orange,
                        isSelected: _selectedStatus == 'Request Revision',
                        onTap: () => setState(() => _selectedStatus = 'Request Revision'),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusOption(
                        title: 'Reject',
                        subtitle: 'Does not meet requirements',
                        color: _Colors.red,
                        isSelected: _selectedStatus == 'Reject',
                        onTap: () => setState(() => _selectedStatus = 'Reject'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Attach Files Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _Colors.white,
                    borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                    border: Border.all(color: _Colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Attach Files (Optional)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _Colors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Upload supporting files',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: _Colors.textFaint,
                                ),
                              ),
                              Icon(PhosphorIconsRegular.uploadSimple, color: _Colors.textFaint, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),

          // ── RIGHT COLUMN ─────────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metadata Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  decoration: BoxDecoration(
                    color: _Colors.white,
                    borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                    border: Border.all(color: _Colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaColumn('Submitted by:', 'Jane Akinyi'),
                      _buildMetaColumn('Submission Time', '09:15 AM'),
                      _buildMetaColumn('Last Edited', '09:32 AM'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments Card - Wrapped in Expanded to fill available space!
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _Colors.white,
                      borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                      border: Border.all(color: _Colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Comments',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _Colors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: _commentController,
                              maxLines: null,
                              expands: true,
                              keyboardType: TextInputType.multiline,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter detailed feedback here...',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: _Colors.textFaint,
                                  fontSize: 15,
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                                color: _Colors.textDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: _Colors.textBody,
                                ),
                                children: [
                                  TextSpan(text: 'Revised on: '),
                                  TextSpan(
                                    text: '21 Jul 2026 | Prof Okeyo Benards',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: _Colors.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
                        side: const BorderSide(color: _Colors.red, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Colors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                        ),
                      ),
                      child: const Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ───────────────────────────────────────────────────

  Widget _buildInteractiveStar(int index) {
    int starIndex = index + 1;
    bool isFull = _rating >= starIndex;
    bool isHalf = _rating > (starIndex - 1) && _rating < starIndex;
    
    return GestureDetector(
      onTapDown: (details) {
        double localX = details.localPosition.dx;
        setState(() {
          if (localX < 14) {
            _rating = starIndex - 0.5; // Left half
          } else {
            _rating = starIndex.toDouble(); // Right half
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: isFull 
            ? const Icon(PhosphorIconsFill.star, color: _Colors.primaryGreen, size: 28)
            : isHalf
                ? Stack(
                    children: const [
                      Icon(PhosphorIconsRegular.star, color: _Colors.primaryGreen, size: 28),
                      ClipRect(
                        clipper: _HalfRectClipper(),
                        child: Icon(PhosphorIconsFill.star, color: _Colors.primaryGreen, size: 28),
                      ),
                    ],
                  )
                : const Icon(PhosphorIconsRegular.star, color: _Colors.primaryGreen, size: 28),
      ),
    );
  }

  Widget _buildStatusOption({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Ensure the whole row is clickable
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : _Colors.border,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _Colors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _Colors.textFaint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: _Colors.textFaint,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _Colors.textDark,
          ),
        ),
      ],
    );
  }
}

// Custom Clipper to achieve the perfect half-filled star look
class _HalfRectClipper extends CustomClipper<Rect> {
  const _HalfRectClipper();
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }
  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
