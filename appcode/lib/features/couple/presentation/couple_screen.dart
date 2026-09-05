import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'couple_view_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_view_model.dart';

class CoupleScreen extends ConsumerStatefulWidget {
  const CoupleScreen({super.key});

  @override
  ConsumerState<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends ConsumerState<CoupleScreen> {
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _joinCouple() {
    final token = _tokenController.text.trim().toUpperCase();
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token must be exactly 6 characters')),
      );
      return;
    }
    ref.read(coupleViewModelProvider.notifier).joinCouple(token);
  }

  void _createCouple() {
    ref.read(coupleViewModelProvider.notifier).createCouple();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coupleViewModelProvider);

    // Listen for errors
    ref.listen(coupleViewModelProvider, (previous, next) {
      if (next.errorMessage != null && previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect with Partner', style: TextStyle(color: AppColors.primary)),
        actions: [
          GestureDetector(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('Are you sure you want to completely delete your account? This will permanently delete your couple and all associated data.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          ref.read(authViewModelProvider.notifier).deleteAccount();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppColors.secondary),
              onPressed: () {
                ref.read(authViewModelProvider.notifier).signOut();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.generatedToken == null) ...[
                      const Text(
                        'Start a new journey together.',
                        style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Join Existing
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Partner\'s Connection Code',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.isLoading ? null : _joinCouple,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: state.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Join Couple', style: TextStyle(color: Colors.white)),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.surface)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            Expanded(child: Divider(color: AppColors.surface)),
                          ],
                        ),
                      ),
                      
                      // Create New
                      OutlinedButton(
                        onPressed: state.isLoading ? null : _createCouple,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        child: const Text('Create a Connection Code', style: TextStyle(color: AppColors.primary)),
                      ),
                    ] else ...[
                      // Token Generated State
                      const Text(
                        'Share this code with your partner',
                        style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              state.generatedToken!,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, color: AppColors.secondary),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: state.generatedToken!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Code copied to clipboard!')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(coupleViewModelProvider.notifier).cancelCreateCouple();
                                  },
                                  icon: const Icon(Icons.cancel, color: Colors.grey),
                                  label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Waiting for partner to join...',
                        style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
