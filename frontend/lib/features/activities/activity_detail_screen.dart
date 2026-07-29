import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String fontFamily = 'Roboto';
    const Color primaryGreen = Color(0xFF1BA654);
    const Color lightGreenBadge = Color(0xFFC3DFCC);
    const Color textDark = Color(0xFF111827);
    const Color textGrey = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Image.network(
              'https://cdn.zmescience.com/wp-content/uploads/2021/01/17792024469_ab7df8ed1c_k-1024x659.webp', // Mangrove placeholder
              fit: BoxFit.cover,
            ),
          ),

          // 2. Custom App Bar / Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    _buildTopIconBtn(
                      icon: PhosphorIconsRegular.caretLeft,
                      onTap: () => context.pop(),
                    ),
                    // Center Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: lightGreenBadge.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Activity Details',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Menu Button
                    _buildTopIconBtn(
                      icon: PhosphorIconsRegular.dotsThreeVertical,
                      onTap: () {
                        // Handle menu options
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content Card (Bottom overlapping)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45 - 32, // Overlap by 32px
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Mangrove Vegetation Survey',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Badges Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: lightGreenBadge,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Submitted',
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          const Text(
                            'Due: 24 Jul 2026',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Asses the species composition, density and health of mangrove vegetation in Mtwapa Creek.',
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Info Items
                      _buildInfoItem(
                        icon: PhosphorIconsRegular.mapPin,
                        title: 'Location',
                        subtitle: 'Mtwapa Creek, Kilifi',
                      ),
                      const SizedBox(height: 24),
                      _buildSupervisorItem(context),
                      const SizedBox(height: 24),
                      _buildInfoItem(
                        icon: PhosphorIconsRegular.clock,
                        title: 'Duration',
                        subtitle: '1h 35m',
                      ),
                      const SizedBox(height: 24),
                      _buildInfoItem(
                        icon: PhosphorIconsRegular.package,
                        title: 'Objective',
                        subtitle: 'To evaluate the status of mangrove vegetation and identify threats.',
                        isMultiLineSubtitle: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Fixed Bottom Button
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showFeedbackModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'View Feedback',
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Top Buttons (Back, Menu)
  Widget _buildTopIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFC3DFCC).withOpacity(0.9), // Light green
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  // Standard Info Item
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isMultiLineSubtitle = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLineSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.black, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Special Supervisor Item with Feedback Link
  Widget _buildSupervisorItem(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(PhosphorIconsRegular.userCircle, color: Colors.black, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supervisor',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,
                  ),
                  children: [
                    TextSpan(text: 'Prof. Dr. Okeyo Benards, Status: '),
                    TextSpan(
                      text: 'Reviewed',
                      style: TextStyle(color: Color(0xFF1BA654)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showFeedbackModal(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'View Full Feedback ',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1BA654),
                      ),
                    ),
                    Icon(PhosphorIconsRegular.arrowRight, color: Color(0xFF1BA654), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom Sheet Modal for Feedback
  void _showFeedbackModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFC3DFCC),
                      child: Text(
                        'OB',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1BA654),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Prof. Dr. Okeyo Benards',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '25 Jul 2026',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Great job on the data collection. The density metrics align well with expectations for Mtwapa Creek. However, please ensure that you include more detailed photos of the observed threat areas (especially the polluted zones) in your next submission.',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
