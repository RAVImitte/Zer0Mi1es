import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/partner_scene.dart';
import 'profile_setup_view_model.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    ref.read(profileSetupViewModelProvider.notifier).setupProfile(name);
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(profileSetupViewModelProvider);
    final isLoading = setupState.isLoading;
    final name = _nameController.text.trim();
    final scene = sceneForHour(DateTime.now().hour);

    ref.listen(profileSetupViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save that name. Try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'What should they call you?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'They’ll see this under your window. Just a first name is enough.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.givenName],
                  maxLength: 24,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(24),
                  ],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'If you create a code you’ll sit on the left. If you join theirs, you’ll sit on the right. We’ll show them your local time through your window.',
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading || name.isEmpty ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2A1614),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Continue'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}