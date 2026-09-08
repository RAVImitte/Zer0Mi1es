import 'package:supabase_flutter/supabase_flutter.dart';

String humanizeAuthError(Object error, {bool isSignIn = false}) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return 'Wrong email or password.';
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'That email already has an account.';
    }
    if (message.contains('email not confirmed')) {
      return 'Check your email to confirm your account.';
    }
    final looksLikeLength = message.contains('at least') ||
        message.contains('too short') ||
        message.contains('weak password') ||
        message.contains('password should');
    if (!isSignIn && looksLikeLength) {
      return 'Use at least 8 characters for your password.';
    }
    if (isSignIn && message.contains('password')) {
      return 'Wrong email or password.';
    }
    return error.message;
  }
  return 'Something went wrong. Try again.';
}

bool isValidEmail(String email) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}