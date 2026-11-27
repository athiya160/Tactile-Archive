import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/config/app_config.dart';
import 'core/config/api_config.dart';
import 'core/di/service_locator.dart';
import 'core/services/api_service.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (loads flavor-specific configurations automatically)
  try {
    await Firebase.initializeApp();

    // Configure Crashlytics to catch all unhandled Flutter exceptions
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    debugPrint('Firebase/Crashlytics initialization bypassed: $e');
  }

  // Validate and resolve production API URL via unified ApiConfig
  // Enforces HTTPS and rejects unset, loopback, or invalid URLs
  final String prodApiUrl;
  try {
    prodApiUrl = ApiConfig.resolveProductionApiUrl();
  } catch (e) {
    debugPrint('CRITICAL PRODUCTION CONFIGURATION ERROR: $e');
    rethrow;
  }

  final prodEnv = AppEnvironment(
    name: 'prod',
    apiUrl: prodApiUrl,
    useMock: false,
  );

  await initServiceLocator(prodEnv);

  await ApiService.loadToken();

  runApp(const TactileArchiveApp());
}
