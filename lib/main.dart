import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkinson_insole_app/firebase_options.dart';
import 'package:parkinson_insole_app/app.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/providers/telemetry_provider.dart';
import 'package:parkinson_insole_app/services/ble/esp32_ble_manager.dart';
import 'package:parkinson_insole_app/services/mock/mock_ble_service.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase if configured
  if (DefaultFirebaseOptions.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized successfully.');
    } catch (e, stack) {
      AppLogger.error('Firebase initialization failed', e, stack);
    }
  } else {
    AppLogger.warn('Firebase is not configured. Please add your credentials in lib/firebase_options.dart');
  }

  // Force dark status bar / navigation bar to match app theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF050A1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock to portrait orientation for a consistent medical UI
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Global Flutter error handler — logs instead of crashing
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter error: ${details.exception}',
      details.exception,
      details.stack,
    );
  };

  // ── BLE Service selection ──────────────────────────────────────────────
  // Uses MockBleService in development (no hardware needed).
  // Switch to Esp32BleManager for real hardware testing.
  //
  // This is controlled at runtime via SettingsProvider.useMockData.
  // For a quick manual override, set useMock = false below.
  const bool useMock = false; // ← false = real ESP32 BLE | true = mock/simulated

  final bleManager = useMock ? MockBleService() : Esp32BleManager();
  await bleManager.initialize();

  AppLogger.info('App starting — BLE mode: ${useMock ? "MOCK" : "ESP32"}');

  runApp(
    MultiProvider(
      providers: [
        // Settings must be first (other providers may read from it)
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),

        // BLE state — wraps the hardware/mock BLE manager
        ChangeNotifierProvider(
          create: (_) => BleProvider(bleManager),
        ),

        // Telemetry — parses raw BLE bytes into structured data
        ChangeNotifierProvider(
          create: (_) => TelemetryProvider(bleManager),
        ),
      ],
      child: const ParkinsonInsoleApp(),
    ),
  );
}
