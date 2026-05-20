import 'package:flutter/material.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

/// A glowing gradient button with optional loading state and icon.
class GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final bool isDestructive; // Uses red/danger gradient

  const GlowButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ??
        (isDestructive ? AppColors.alertRed : AppColors.primaryCyan);

    final gradient = isDestructive
        ? AppColors.dangerGradient
        : LinearGradient(
            colors: [effectiveColor, effectiveColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return MouseRegion(
      cursor: onPressed != null && !isLoading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: onPressed != null && !isLoading ? gradient : null,
          color: onPressed == null || isLoading
              ? AppColors.surface
              : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed != null && !isLoading
              ? [
                  BoxShadow(
                    color: effectiveColor.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
          border: Border.all(
            color: effectiveColor.withOpacity(onPressed != null ? 0.6 : 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                ),
              )
            else if (icon != null)
              Icon(icon, size: 18, color: AppColors.background),
            if ((isLoading || icon != null) && label.isNotEmpty)
              const SizedBox(width: 8),
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  color: isLoading || onPressed == null
                      ? AppColors.textDisabled
                      : AppColors.background,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontFamily: 'Orbitron',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
