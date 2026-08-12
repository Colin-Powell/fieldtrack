import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldtrack/features/supervisor/repositories/student_repository.dart';
import 'package:fieldtrack/features/activities/providers/student_activities_provider.dart';
import 'package:fieldtrack/core/providers/auth_provider.dart';
import 'package:fieldtrack/core/network/api_result.dart';
import 'package:fieldtrack/core/network/error_handler.dart';

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

class SupervisorReviewScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String activityId;
  final String studentName;
  const SupervisorReviewScreen({
    super.key,
    required this.studentId,
    required this.activityId,
    required this.studentName,
  });

  @override
  ConsumerState<SupervisorReviewScreen> createState() => _SupervisorReviewScreenState();
}

class _SupervisorReviewScreenState extends ConsumerState<SupervisorReviewScreen> {
  // --- State Variables ---
  double _rating = 0.0;
  String _selectedStatus = 'Approved';
  bool _isSubmitting = false;
  
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Submit Feedback Logic
  Future<void> _submitFeedback() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your feedback comments before submitting.'),
          backgroundColor: _Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = StudentRepository();
      final supervisorId = ref.read(authProvider).user?.id ?? '';
      
      if (supervisorId.isEmpty) {
        throw Exception('Supervisor not authenticated');
      }
      
      String mappedStatus = 'APPROVED';
      if (_selectedStatus == 'Request Revision') mappedStatus = 'REVISION_REQUESTED';
      if (_selectedStatus == 'Reject') mappedStatus = 'REJECTED';

      await repo.submitReview(
        widget.studentId,
        widget.activityId,
        reviewerId: supervisorId,
        rating: _rating,
        status: mappedStatus,
        comments: _commentController.text,
      );

      if (!mounted) return;

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
              onPressed: () {
                Navigator.pop(ctx);
                // Invalidate providers so the activity status refreshes on return
                ref.invalidate(activityDetailsProvider(widget.activityId));
                ref.invalidate(studentActivitiesByStudentIdProvider(widget.studentId));
                // Navigate back to student profile (don't use Navigator.pop — we're embedded in a tab)
                context.go('/supervisor/student/${widget.studentId}');
              },
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${ErrorHandler.getFriendlyErrorMessage(e)}'),
            backgroundColor: _Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(activityDetailsProvider(widget.activityId));
    final activityResult = activityAsync.asData?.value;
    final activity = activityResult is Success ? (activityResult as Success).data : null;
    
    // Attempt to grab dates and dynamic student name
    String subTime = '-';
    String lastEdited = '-';
    String finalStudentName = widget.studentName;
    if (activity != null) {
      if (activity['timestamp'] != null) {
        subTime = DateFormat('hh:mm a').format(DateTime.parse(activity['timestamp']).toLocal());
      }
      if (activity['user'] != null && activity['user']['name'] != null) {
        finalStudentName = activity['user']['name'];
      }
    }
    
    String revisedOnText = '';
    if (activity != null && activity['reviews'] != null) {
      final reviews = activity['reviews'] as List<dynamic>;
      if (reviews.isNotEmpty) {
        final lastReview = reviews.last;
        final revDateStr = lastReview['createdAt'] != null 
          ? DateFormat('dd MMM yyyy').format(DateTime.parse(lastReview['createdAt']).toLocal()) 
          : '';
        final reviewerName = lastReview['reviewer']?['name'] ?? 'Unknown';
        if (revDateStr.isNotEmpty) {
          revisedOnText = '$revDateStr | $reviewerName';
        }
      }
    }

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
                      _buildMetaColumn('Submitted by:', finalStudentName),
                      _buildMetaColumn('Submission Time', subTime),
                      _buildMetaColumn('Last Edited', lastEdited),
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
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: _Colors.textBody,
                                ),
                                children: revisedOnText.isNotEmpty ? [
                                  const TextSpan(text: 'Revised on: '),
                                  TextSpan(
                                    text: revisedOnText,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: _Colors.textDark),
                                  ),
                                ] : [],
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
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Colors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 22),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_Colors.cornerRadius),
                        ),
                      ),
                      child: _isSubmitting 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
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

