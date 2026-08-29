import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<AuthState> get authState;

  /// Current user session, null if not logged in
  Session? get currentSession;

  /// Sign in with email and password
  Future<void> signIn(String email, String password);

  /// Sign up with email and password
  Future<void> signUp(String email, String password);

  /// Sign out the current user
  Future<void> signOut();

  /// Set up user profile
  Future<void> setupProfile(String displayName);

  /// Delete the user account completely
  Future<void> deleteAccount();
}
