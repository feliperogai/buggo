import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Hive/.env/Supabase setup happens after the first frame (see
  // SplashScreen), so the splash animation is the first thing the user
  // sees instead of a static native icon waiting on it to finish.
  runApp(
    const ProviderScope(
      child: BuggoApp(),
    ),
  );
}
