import 'package:flutter/material.dart';

enum BadgeStatus {
  completed,
  inProgress,
  pending,
  rejected,
  offline
}

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String label;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case BadgeStatus.completed:
        bgColor = const Color(0xFFC3DFCC);
        textColor = const Color(0xFF1BA654);
        break;
      case BadgeStatus.inProgress:
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        break;
      case BadgeStatus.pending:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFF59E0B);
        break;
      case BadgeStatus.rejected:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        break;
      case BadgeStatus.offline:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
