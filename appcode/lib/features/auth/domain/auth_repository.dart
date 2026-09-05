import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authState;

  Session? get currentSession;

  Future<void> signIn(String email, String password);

  Future<void> signUp(String email, String password);

  Future<void> signOut();

  Future<void> setupProfile(String displayName);

  Future<void> deleteAccount();
}
