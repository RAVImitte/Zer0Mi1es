import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'couple_view_model.dart';
import '../../../core/theme/app_colors.dart';

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
        title: const Text('Partner'),
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
                      Text(
                        'Share a code, or join theirs.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Their 6-character code',
                        ),
                        maxLength: 6,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 8,
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: state.isLoading ? null : _joinCouple,
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Join'),
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
                        child: const Text('Create a code'),
                      ),
                    ] else ...[
                      // Token Generated State
                      Text(
                        'Share this code with them',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Column(
                          children: [
                            Text(
                              state.generatedToken!,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    letterSpacing: 10,
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
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied')),
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
