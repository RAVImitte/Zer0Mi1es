import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

part 'supabase_auth_repository.g.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<AuthState> get authState => _client.auth.onAuthStateChange;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
    // Note: Profiles are created here if we handle it client side,
    // but typically we can create a trigger on auth.users in DB.
    // We'll keep it simple for now and rely on user creation.
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> setupProfile(String displayName) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    await _client.from('profiles').upsert({
      'id': uid,
      'display_name': displayName,
      'registration_status': 'name_entered',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteAccount() async {
    // Call the RPC function to clean up couples and auth user
    await _client.rpc('delete_my_account');
    
    // Clear the local session just in case
    await signOut();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authState;
}

@riverpod
Stream<String> registrationStatus(Ref ref) async* {
  // Watch auth state to ensure this provider re-evaluates when the user logs in/out
  ref.watch(authStateProvider);

  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    yield 'signed_up';
    return;
  }

  // Yield instantly from cache to bypass Splash Screen waiting
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString('registration_status_cache');
  if (cached != null) yield cached;

  // Fetch initial value via HTTP request to prevent Splash Screen hanging if WebSocket fails
  try {
    final data = await client.from('profiles').select('registration_status').eq('id', uid).maybeSingle();
    final status = data?['registration_status'] as String? ?? 'signed_up';
    prefs.setString('registration_status_cache', status);
    yield status;
  } catch (e) {
    // If HTTP fails (e.g. no internet or bad anon key), fallback to cached or default
    yield cached ?? 'signed_up';
  }

  // Then start the real-time stream in the background
  await for (final rows in client.from('profiles').stream(primaryKey: ['id']).eq('id', uid)) {
    if (rows.isEmpty) {
      prefs.setString('registration_status_cache', 'signed_up');
      yield 'signed_up';
    } else {
      final status = rows.first['registration_status'] as String? ?? 'signed_up';
      prefs.setString('registration_status_cache', status);
      yield status;
    }
  }
}
