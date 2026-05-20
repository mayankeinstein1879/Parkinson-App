import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide theme configuration.
/// Uses a futuristic dark medical-tech aesthetic with neon cyan/purple accents.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.secondaryPurple,
        surface: AppColors.surface,
        error: AppColors.alertRed,
        onPrimary: AppColors.background,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),

      // ── Text Theme ────────────────────────────────────────────────────────
      textTheme: _buildTextTheme(),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.primaryCyan),
        titleTextStyle: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        toolbarTextStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCyan,
          foregroundColor: AppColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          side: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryCyan,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryCyan;
          return AppColors.textDisabled;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.glowCyan;
          return AppColors.surface;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryCyan;
          return AppColors.textDisabled;
        }),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryCyan,
        inactiveTrackColor: AppColors.surface,
        thumbColor: AppColors.primaryCyan,
        overlayColor: AppColors.glowCyan,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        valueIndicatorColor: AppColors.primaryCyan,
        valueIndicatorTextStyle: GoogleFonts.orbitron(
          color: AppColors.background,
          fontSize: 12,
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.inter(color: AppColors.textDisabled),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryCyan,
        unselectedItemColor: AppColors.textDisabled,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        textStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
        actionTextColor: AppColors.primaryCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        titleTextStyle: GoogleFonts.orbitron(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      // Display styles — Orbitron for futuristic headings
      displayLarge: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w400),

      // Headlines — Orbitron
      headlineLarge: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),

      // Titles — Orbitron with reduced weight
      titleLarge: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
        letterSpacing: 0.5),
      titleMedium: GoogleFonts.orbitron(
        color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: 0.3),
      titleSmall: GoogleFonts.orbitron(
        color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),

      // Body — Inter for readability
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.inter(
        color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400),

      // Labels — Inter
      labelLarge: GoogleFonts.inter(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
        letterSpacing: 0.5),
      labelMedium: GoogleFonts.inter(
        color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.inter(
        color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.w500,
        letterSpacing: 0.3),
    );
  }
}
