import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  await cacheNotificationData(message.data);
}

Future<void> cacheNotificationData(Map<String, dynamic> data) async {
  if (!data.containsKey('table') || !data.containsKey('type')) return;

  final table = data['table'] as String;
  final type = data['type'] as String;
  if (table != 'moods' && table != 'connection_signals' && table != 'love_drops') {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(CacheKeys.partnerAnimationTable, table);
  await prefs.setString(CacheKeys.partnerAnimationType, type);
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.watch(supabaseClientProvider));
});

class PushNotificationService {
  PushNotificationService(this._supabase);

  final SupabaseClient _supabase;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);

    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToSupabase(token);
    }
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      cacheNotificationData(message.data);
      if (message.notification != null) {
        _showLocalNotification(message.notification!);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      importance: Importance.max,
      priority: Priority.high,
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('profiles').update({'fcm_token': token}).eq('id', userId);
    } catch (e) {
      debugPrint('Error saving FCM Token: $e');
    }
  }
}
