import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/auth_repository.dart';

part 'supabase_auth_repository.g.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

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
  }

  @override
  Future<void> resetPassword(String email) async {
    // Hosted Supabase Auth must also allow this redirect URL (operator gate).
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'zeromiles://login-callback',
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
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
      'registration_status': RegistrationStatus.nameEntered,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> syncTimezone(String ianaName) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || ianaName.isEmpty) return;
    await _client.from('profiles').update({
      'timezone': ianaName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  @override
  Future<void> deleteAccount() async {
    await _client.rpc('delete_my_account');
    await signOut();
  }
}

class PasswordRecovery extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(authStateProvider, (_, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        state = true;
      } else if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated) {
        state = false;
      }
    });
    return ref.read(authStateProvider).value?.event ==
        AuthChangeEvent.passwordRecovery;
  }

  void complete() => state = false;
}

final passwordRecoveryProvider =
    NotifierProvider<PasswordRecovery, bool>(PasswordRecovery.new);

bool isPasswordRecovering(Ref ref) {
  return ref.read(passwordRecoveryProvider);
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authState;
}

@riverpod
Stream<String> registrationStatus(Ref ref) async* {
  ref.watch(authStateProvider);

  final client = ref.watch(supabaseClientProvider);
  final uid = client.auth.currentUser?.id;
  if (uid == null) {
    yield RegistrationStatus.signedUp;
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getString(CacheKeys.registrationStatus);
  if (cached != null) yield cached;

  try {
    final data = await client
        .from('profiles')
        .select('registration_status')
        .eq('id', uid)
        .maybeSingle();
    final status =
        data?['registration_status'] as String? ?? RegistrationStatus.signedUp;
    prefs.setString(CacheKeys.registrationStatus, status);
    yield status;
  } catch (_) {
    yield cached ?? RegistrationStatus.signedUp;
  }

  await for (final rows
      in client.from('profiles').stream(primaryKey: ['id']).eq('id', uid)) {
    if (rows.isEmpty) {
      prefs.setString(
          CacheKeys.registrationStatus, RegistrationStatus.signedUp);
      yield RegistrationStatus.signedUp;
    } else {
      final status = rows.first['registration_status'] as String? ??
          RegistrationStatus.signedUp;
      prefs.setString(CacheKeys.registrationStatus, status);
      yield status;
    }
  }
}
