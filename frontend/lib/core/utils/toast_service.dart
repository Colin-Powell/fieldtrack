import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A context-free toast service using a global navigator key.
/// Register the key in your MaterialApp: navigatorKey: ToastService.navigatorKey
class ToastService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showSuccess(String message) {
    _showPill(message, const Color(0xFF169B45), PhosphorIconsFill.checkCircle);
  }

  static void showError(String message) {
    _showPill(message, const Color(0xFFEF4444), PhosphorIconsFill.warningCircle);
  }

  static void showInfo(String message) {
    _showPill(message, const Color(0xFF3B82F6), PhosphorIconsFill.info);
  }

  static void _showPill(String message, Color color, IconData icon) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: color,
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

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
    });
  }
}
