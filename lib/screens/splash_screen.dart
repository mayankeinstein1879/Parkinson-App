import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/utils/permission_handler.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Splash / launch screen.
/// Handles permission requests and navigates to BLE scan once ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _startUp();
  }

  Future<void> _startUp() async {
    // Load persisted settings first
    final settings = context.read<SettingsProvider>();
    await settings.loadSettings();

    if (!mounted) return;
    setState(() => _statusText = 'Checking permissions...');

    // Request BLE permissions
    final granted = await BlePermissionHandler.requestAllRequiredPermissions(context);

    if (!mounted) return;

    if (!granted) {
      setState(() => _statusText = 'Bluetooth permission required');
      AppLogger.ble('Permissions not granted on splash');
      // Wait 2s then go to scan anyway (user can re-grant in settings)
      await Future.delayed(const Duration(seconds: 2));
    } else {
      setState(() => _statusText = 'Ready');
      await Future.delayed(const Duration(milliseconds: 800));
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Animated background glow ────────────────────────────────────
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryCyan.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondaryPurple.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo: BT / foot icon with pulsing rings
                _LogoWidget(),
                const SizedBox(height: 32),

                // App name
                Text(
                  AppStrings.appName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron',
                    letterSpacing: 4,
                  ),
                ).animate().fade(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ).animate().fade(duration: 600.ms, delay: 600.ms),

                const SizedBox(height: 60),

                // Status text + spinner
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms, delay: 800.ms),

                const SizedBox(height: 40),

                // Version
                Text(
                  AppStrings.appVersion,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ).animate().fade(duration: 400.ms, delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Widget ───────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.2), width: 1),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(duration: 2000.ms, begin: const Offset(0.9, 0.9),
                   end: const Offset(1.1, 1.1), curve: Curves.easeInOut),

        // Mid ring
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.35), width: 1.5),
          ),
        ),

        // Inner filled circle with icon
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primaryCyan, AppColors.secondaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.glowCyan, blurRadius: 20, spreadRadius: 4),
            ],
          ),
          child: const Icon(Icons.medical_services, color: Colors.white, size: 32),
        ),
      ],
    ).animate().fade(duration: 800.ms).scale(
      duration: 800.ms,
      begin: const Offset(0.6, 0.6),
      end: const Offset(1.0, 1.0),
      curve: Curves.elasticOut,
    );
  }
}
