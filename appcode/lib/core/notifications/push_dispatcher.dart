import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushDispatcher {
  PushDispatcher(this._client);

  final SupabaseClient _client;

  Future<void> notify({
    required String table,
    required Map<String, dynamic> record,
  }) async {
    try {
      await _client.functions.invoke('push-notification', body: {
        'table': table,
        'record': record,
      });
    } catch (e) {
      debugPrint('Failed to trigger notification: $e');
    }
  }
}
