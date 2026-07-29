import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const RoundedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary 
        ? Colors.transparent 
        : (color ?? const Color(0xFF1BA654));
        
    final fgColor = isSecondary 
        ? (textColor ?? const Color(0xFF1BA654)) 
        : (textColor ?? Colors.white);
        
    final borderSide = isSecondary 
        ? BorderSide(color: color ?? const Color(0xFF1BA654)) 
        : BorderSide.none;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: borderSide,
    );

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
