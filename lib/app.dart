import 'package:flutter/material.dart';
import 'package:parkinson_insole_app/screens/splash_screen.dart';
import 'package:parkinson_insole_app/screens/ble_scan_screen.dart';
import 'package:parkinson_insole_app/screens/device_connection_screen.dart';
import 'package:parkinson_insole_app/screens/dashboard_screen.dart';
import 'package:parkinson_insole_app/screens/device_status_screen.dart';
import 'package:parkinson_insole_app/screens/settings_screen.dart';
import 'package:parkinson_insole_app/screens/debug_screen.dart';
import 'package:parkinson_insole_app/theme/app_theme.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';

/// Root application widget.
class ParkinsonInsoleApp extends StatelessWidget {
  const ParkinsonInsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // ── Named routes ──────────────────────────────────────────────────
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
            page = const SplashScreen();
          case '/scan':
            page = const BleScanScreen();
          case '/connect':
            page = const DeviceConnectionScreen();
          case '/dashboard':
            page = const DashboardScreen();
          case '/status':
            page = const DeviceStatusScreen();
          case '/settings':
            page = const SettingsScreen();
          case '/debug':
            page = const DebugScreen();
          default:
            page = const SplashScreen();
        }

        // Use a slide-up transition for all routes
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
      },
    );
  }
}
