import 'package:supabase_flutter/supabase_flutter.dart';

String humanizeAuthError(Object error) {
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
    if (message.contains('password')) {
      return 'Use at least 8 characters for your password.';
    }
    return error.message;
  }
  return 'Something went wrong. Try again.';
}

bool isValidEmail(String email) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}