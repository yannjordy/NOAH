import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'services/cache_service.dart';
import 'services/background_service.dart';
import 'app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('FATAL: $error\n$stack');
    return true;
  };

    await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Platform.isAndroid) {
    try {
      BackgroundService.start();
    } catch (_) {}
  }

  try {
    final storage = StorageService();
    await storage.init();
    final cache = CacheService(storage);
    SupabaseService supabase = SupabaseService();
    try {
      await supabase.init();
    } catch (_) {
      // Supabase unavailable — app runs without auth features
    }
    runApp(NoahApp(storage: storage, cache: cache, supabase: supabase));
  } catch (e, s) {
    debugPrint('INIT ERROR: $e\n$s');
  }
}

class NoahApp extends StatelessWidget {
  final StorageService storage;
  final CacheService cache;
  final SupabaseService supabase;

  const NoahApp({
    super.key,
    required this.storage,
    required this.cache,
    required this.supabase,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOAH',
      home: AppShell(storage: storage, cache: cache, supabase: supabase),
    );
  }
}

// SplashGate supprimé — inutilisé
