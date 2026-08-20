import 'package:riverpod_annotation/riverpod_annotation.dart';
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
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
}

@riverpod
Stream<AuthState> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authState;
}
