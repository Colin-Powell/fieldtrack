import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Broadcast Center & Notifications',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(PhosphorIcons.paperPlaneRight(), size: 18),
                label: const Text('Send Broadcast'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BA654),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildCategoryItem('All Messages', PhosphorIcons.tray(), true),
                        _buildCategoryItem('System Notifications', PhosphorIcons.cpu(), false),
                        _buildCategoryItem('University Announcements', PhosphorIcons.megaphone(), false),
                        _buildCategoryItem('Emergency Alerts', PhosphorIcons.warningCircle(), false),
                        _buildCategoryItem('Maintenance', PhosphorIcons.wrench(), false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: ListView(
                      children: [
                        _buildNotificationCard(
                          'System Update Completed',
                          'The backend has been successfully upgraded to version 2.4. All student GPS trackers should now sync automatically.',
                          'System Notifications',
                          'Just now',
                          Colors.blue,
                        ),
                        _buildNotificationCard(
                          'Field Work Deadline Approaching',
                          'Reminder to all students and supervisors that final field reports are due this Friday.',
                          'University Announcements',
                          '2 hours ago',
                          const Color(0xFF1BA654),
                        ),
                        _buildNotificationCard(
                          'Server Maintenance',
                          'Scheduled downtime will occur on Saturday from 2:00 AM to 4:00 AM EAT.',
                          'Maintenance',
                          'Yesterday',
                          Colors.purple,
                        ),
                        _buildNotificationCard(
                          'Security Alert',
                          'Multiple failed login attempts detected on the supervisor portal from unrecognized IPs.',
                          'Emergency Alerts',
                          'Yesterday',
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1BA654).withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1BA654) : const Color(0xFF6B7280),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1BA654) : const Color(0xFF4B5563),
          ),
        ),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNotificationCard(String title, String body, String category, String time, Color tagColor) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tagColor,
                  ),
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF1BA654))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
