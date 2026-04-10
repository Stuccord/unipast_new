import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/core/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:unipast/core/splash_screen.dart';

class AppStartupWidget extends StatefulWidget {
  const AppStartupWidget({super.key});

  @override
  State<AppStartupWidget> createState() => _AppStartupWidgetState();
}

class _AppStartupWidgetState extends State<AppStartupWidget> {
  late Future<void> _initializationData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializationData = _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    try {
      // 1. Load Environment Variables
      await dotenv.load(fileName: "assets/.env");

      // 2. Initialize Supabase
      final url = SupabaseConfig.url;
      final key = SupabaseConfig.anonKey;

      if (url.isEmpty || !url.startsWith('http')) {
        throw Exception(
          'Supabase URL is missing or invalid: "$url"\n'
          'Please ensure your .env file is present and has SUPABASE_URL.'
        );
      }

      await Supabase.initialize(
        url: url,
        anonKey: key,
        debug: false,
      );

      // 3. Initialize Firebase (optional/resilient)
      // Check for Firebase init to avoid crashing if config is missing (common in Android/iOS)
      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
          debugPrint('Firebase initialized successfully.');
        } catch (e) {
          debugPrint('⚠️ Firebase init failed (likely missing google-services.json): $e');
          // Firebase initialization error is non-critical for core app startup.
          // We catch it here to prevent it from bubbling up and stopping the app.
        }
      }
    } catch (e, stack) {
      debugPrint('Startup Failure: $e\n$stack');
      setState(() {
        _errorMessage =
            "Startup Failed: $e\n\nCheck your .env config.";
      });
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _initializationData = _loadDependencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationData,
      builder: (context, snapshot) {
        // ERROR STATE
        if (snapshot.hasError || _errorMessage != null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: UniPastSplashScreen(
              errorMessage: _errorMessage ?? "An unexpected error occurred.",
              onRetry: _retry,
            ),
          );
        }

        // LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: UniPastSplashScreen(),
          );
        }

        // SUCCESS STATE: Hand over to the Riverpod/GoRouter application
        return const ProviderScope(
          child: UniPastApp(),
        );
      },
    );
  }
}
