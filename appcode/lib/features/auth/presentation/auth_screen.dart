import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_auth_repository.dart';
import 'auth_view_model.dart';
import '../../../core/theme/app_colors.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(passwordRecoveryProvider) ||
        ref.read(authStateProvider).value?.event ==
            AuthChangeEvent.passwordRecovery) {
      _saveNewPassword();
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    if (_isLogin) {
      ref.read(authViewModelProvider.notifier).signIn(email, password);
    } else {
      ref.read(authViewModelProvider.notifier).signUp(email, password);
    }
  }

  Future<void> _saveNewPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a new password.')),
      );
      return;
    }
    await ref.read(authViewModelProvider.notifier).updatePassword(password);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter your email to reset your password.')),
      );
      return;
    }

    await ref.read(authViewModelProvider.notifier).resetPassword(email);
    if (!mounted) return;
    if (!ref.read(authViewModelProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email for a reset link.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;
    final recovering = ref.watch(passwordRecoveryProvider) ||
        ref.watch(authStateProvider).value?.event ==
            AuthChangeEvent.passwordRecovery;

    // Listen for errors
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        String errorMessage = 'An unexpected error occurred.';
        if (error is AuthException) {
          errorMessage = error.statusCode == '429'
              ? 'Too many attempts. Try again in a few minutes.'
              : error.message;
        } else {
          // Fallback to a cleaner string if it's a generic Exception
          errorMessage = error.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zero Miles',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                recovering ? 'Choose a new password' : 'A private room for two',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!recovering) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: recovering ? 'New password' : 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        recovering
                            ? 'Save password'
                            : (_isLogin ? 'Sign in' : 'Create account'),
                      ),
              ),
              if (!recovering && _isLogin)
                TextButton(
                  onPressed: isLoading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              if (!recovering)
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                  child: Text(
                    _isLogin
                        ? 'Need an account? Sign Up'
                        : 'Already have an account? Login',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
