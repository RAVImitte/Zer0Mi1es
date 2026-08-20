import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase.
  // We use fromEnvironment so secrets are not hardcoded in source control.
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://placeholder.supabase.co'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'placeholder_key'),
  );

  runApp(
    const ProviderScope(
      child: Zer0Mi1esApp(),
    ),
  );
}
