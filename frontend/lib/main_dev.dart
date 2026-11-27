import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/services/api_service.dart';
import 'core/network/api_client.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read environment properties provided at compile time via --dart-define-from-file=.env.dev
  const envApiUrl = String.fromEnvironment('API_URL');
  final devEnv = AppEnvironment(
    name: 'dev',
    apiUrl: envApiUrl.isNotEmpty ? envApiUrl : getDefaultBaseUrl(),
    useMock: false,
  );

  await initServiceLocator(devEnv);

  await ApiService.loadToken();

  runApp(const TactileArchiveApp());
}
