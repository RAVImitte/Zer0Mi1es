import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/auth_copy.dart';
import '../../../core/utils/partner_scene.dart';
import 'auth_view_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;
  bool _awaitingEmail = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!isValidEmail(email) || password.isEmpty) return false;
    if (!_isLogin && password.length < 8) return false;
    return true;
  }

  void _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = email.isEmpty
          ? 'Enter your email'
          : (isValidEmail(email) ? null : 'That doesn’t look like an email');
      if (password.isEmpty) {
        _passwordError = 'Enter your password';
      } else if (!_isLogin && password.length < 8) {
        _passwordError = 'Use at least 8 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _submit() {
    _validate();
    if (!_canSubmit) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      ref.read(authViewModelProvider.notifier).signIn(email, password);
    } else {
      ref.read(authViewModelProvider.notifier).signUp(email, password);
    }
  }

  Future<void> _forgot() async {
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _emailError = 'Enter the email for this account');
      return;
    }
    await ref.read(authViewModelProvider.notifier).resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('If that account exists, we sent a reset link.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;
    final scene = sceneForHour(DateTime.now().hour);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              humanizeAuthError(next.error!, isSignIn: _isLogin),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      if (!next.hasError &&
          !next.isLoading &&
          previous?.isLoading == true &&
          !_isLogin) {
        final hasSession =
            Supabase.instance.client.auth.currentSession != null;
        if (!hasSession) {
          setState(() => _awaitingEmail = true);
        }
      }
    });

    if (_awaitingEmail) {
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: sceneWash(scene),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Check your email',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a confirmation link to ${_emailController.text.trim()}. Open it, then come back and sign in.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _awaitingEmail = false;
                      _isLogin = true;
                    }),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sceneWash(scene),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Text(
                          'Zero Miles',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppColors.primary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A private room for two. No feed. No one else.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: _emailError,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: [
                            _isLogin
                                ? AutofillHints.password
                                : AutofillHints.newPassword,
                          ],
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure ? AppIcons.eye : AppIcons.eyeSlash,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : _forgot,
                              child: const Text('Forgot password?'),
                            ),
                          )
                        else
                          const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isLoading || !_canSubmit ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2A1614),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isLogin ? 'Sign in' : 'Create account'),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    _emailError = null;
                                    _passwordError = null;
                                  });
                                },
                          child: Text(
                            _isLogin
                                ? 'Need an account? Sign up'
                                : 'Already have an account? Sign in',
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}