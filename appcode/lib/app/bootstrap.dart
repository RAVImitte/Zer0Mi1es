import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../core/config/env.dart';
import '../features/notifications/data/push_notification_service.dart';
import '../firebase_options.dart';
import 'app.dart';

Future<void> recoverExistingSession(GoTrueClient auth) async {
  if (auth.currentSession == null) return;
  try {
    await auth.refreshSession();
  } on AuthRetryableFetchException {
    // Network/5xx: SDK already kept the persisted session.
    return;
  } on AuthException {
    try {
      await auth.signOut();
    } catch (_) {
      // Local session is already cleared; don't block runApp.
    }
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  if (!Env.isConfigured) {
    runApp(const MissingServerConfigApp());
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  await recoverExistingSession(Supabase.instance.client.auth);

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: Zer0Mi1esApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
