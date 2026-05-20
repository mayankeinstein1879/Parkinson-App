import 'package:flutter/material.dart';

/// Central color palette for the Parkinson's Insole App.
/// All colors follow the futuristic dark medical-tech aesthetic.
/// Never use raw Color() values in widgets — always reference AppColors.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF050A1A); // Deep space navy
  static const Color surface        = Color(0xFF0D1B2E); // Slightly lighter panel
  static const Color cardBackground = Color(0xFF0A1628); // Glassmorphism base
  static const Color dialogBackground = Color(0xFF0F1E35);

  // ── Primary Accents ───────────────────────────────────────────────────────
  static const Color primaryCyan    = Color(0xFF00E5FF); // Electric teal/cyan
  static const Color secondaryPurple = Color(0xFF7B2FFF); // Deep violet
  static const Color accentGreen    = Color(0xFF00FF88); // Success / connected
  static const Color accentBlue     = Color(0xFF0080FF); // Info / link

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color connected      = Color(0xFF00FF88); // BLE connected
  static const Color disconnected   = Color(0xFF455A64); // BLE disconnected
  static const Color scanning       = Color(0xFFFF9800); // BLE scanning
  static const Color reconnecting   = Color(0xFFFFEB3B); // Auto-reconnect

  // ── Warning / Alert ───────────────────────────────────────────────────────
  static const Color warningOrange  = Color(0xFFFF6B35); // FOG risk medium
  static const Color alertRed       = Color(0xFFFF1744); // FOG risk high / SOS
  static const Color safeGreen      = Color(0xFF00E676); // Low risk / safe

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFE8F4FF); // Main text
  static const Color textSecondary  = Color(0xFF7B9BB5); // Subtitles / labels
  static const Color textDisabled   = Color(0xFF3D5066); // Disabled / placeholder
  static const Color textOnDark     = Color(0xFFFFFFFF);

  // ── Left / Right Insole Identity ──────────────────────────────────────────
  static const Color leftInsole     = Color(0xFF00E5FF); // Cyan for left
  static const Color rightInsole    = Color(0xFF7B2FFF); // Purple for right

  // ── Glow Effects (for BoxShadow) ──────────────────────────────────────────
  static const Color glowCyan       = Color(0x4400E5FF); // 27% opacity cyan
  static const Color glowPurple     = Color(0x447B2FFF); // 27% opacity purple
  static const Color glowGreen      = Color(0x4400FF88);
  static const Color glowRed        = Color(0x44FF1744);
  static const Color glowOrange     = Color(0x44FF6B35);

  // ── Gradient Helpers ──────────────────────────────────────────────────────
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0080FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7B2FFF), Color(0xFFAA00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF050A1A), Color(0xFF0D1B2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Card Border ───────────────────────────────────────────────────────────
  static const Color cardBorder     = Color(0x1A00E5FF); // Very subtle cyan border
  static const Color divider        = Color(0xFF1A2C42);

  /// Returns the FOG risk color based on percentage (0–100)
  static Color fogRiskColor(double percent) {
    if (percent < 30) return safeGreen;
    if (percent < 60) return warningOrange;
    return alertRed;
  }

  /// Returns glow color for an insole side
  static Color insoleGlow(bool isLeft) => isLeft ? glowCyan : glowPurple;

  /// Returns the identity color for an insole side
  static Color insoleColor(bool isLeft) => isLeft ? leftInsole : rightInsole;
}
