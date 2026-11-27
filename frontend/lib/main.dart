import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme.dart';
import 'core/services/api_service.dart';
import 'core/widgets/global_chatbot_overlay.dart';

import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/cart/presentation/bloc/cart_event.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow runtime font fetching with fallback to system fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  // Load default/development configuration fallback when running default main.dart
  const envApiUrl = String.fromEnvironment('API_URL');
  String effectiveApiUrl;
  try {
    effectiveApiUrl = envApiUrl.isNotEmpty ? envApiUrl : getDefaultBaseUrl();
  } catch (e) {
    debugPrint('[Startup Warning] Error resolving API URL: $e');
    effectiveApiUrl = 'http://localhost:8000';
  }
  final defaultEnv = AppEnvironment(
    name: 'default',
    apiUrl: effectiveApiUrl,
    useMock: false,
  );

  try {
    await initServiceLocator(defaultEnv);
  } catch (e) {
    debugPrint('[Startup Warning] initServiceLocator error: $e');
  }

  try {
    await ApiService.loadToken();
  } catch (e) {
    debugPrint('[Startup Warning] loadToken error: $e');
  }

  runApp(const TactileArchiveApp());
}

class TactileArchiveApp extends StatelessWidget {
  const TactileArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartBloc>(
          create: (_) => sl<CartBloc>()..add(CartStarted()),
        ),
        BlocProvider<HomeBloc>(create: (_) => sl<HomeBloc>()),
      ],
      child: MaterialApp.router(
        title: 'The Tactile Archive',
        debugShowCheckedModeBanner: false,
        theme: IvoryTheme.light,
        routerConfig: AppRouter.router,
        builder: (context, child) => GlobalChatbotOverlay(child: child),
      ),
    );
  }
}
