import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/partner_scene.dart';
import '../../../core/widgets/affection_toast.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/living_window.dart';
import 'couple_view_model.dart';
import '../../couple/data/supabase_couple_repository.dart';

class CoupleScreen extends ConsumerStatefulWidget {
  const CoupleScreen({super.key});

  @override
  ConsumerState<CoupleScreen> createState() => _CoupleScreenState();
}

class _CoupleScreenState extends ConsumerState<CoupleScreen> {
  final _chars = List<String>.filled(6, '');
  final _nodes = List.generate(6, (_) => FocusNode());
  final _controllers = List.generate(6, (_) => TextEditingController());

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String get _token => _chars.join();

  void _joinCouple() {
    final token = _token;
    if (token.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter all six characters')),
      );
      return;
    }
    ref.read(coupleViewModelProvider.notifier).joinCouple(token);
  }

  String _humanError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('expired')) return 'That code expired. Ask them for a new one.';
    if (lower.contains('used') || lower.contains('already')) {
      return 'That code is already used.';
    }
    if (lower.contains('self') || lower.contains('own')) {
      return 'You can’t join your own code.';
    }
    if (lower.contains('invalid') || lower.contains('not found')) {
      return 'That code doesn’t match. Check the six characters.';
    }
    return 'Couldn’t pair just now. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coupleViewModelProvider);
    final paired = ref.watch(activeCoupleIdProvider).value != null;

    ref.listen(coupleViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          previous?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_humanError(next.errorMessage!)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    ref.listen(activeCoupleIdProvider, (previous, next) {
      if (previous?.value == null && next.value != null && mounted) {
        HapticFeedback.mediumImpact();
        showAffectionToast(context, emoji: '🏡', label: 'You’re in the room');
        context.go(AppRoutes.home);
      }
    });

    if (paired && state.generatedToken == null) {
      return AppPage(
        title: 'Partner',
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'You’re paired. This room is just the two of you.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return AppPage(
      title: 'Partner',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: state.generatedToken == null
            ? _paths(state)
            : _waiting(state),
      ),
    );
  }

  Widget _paths(CoupleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share a code, or join theirs.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Text(
          'I have a code',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Letters and numbers, no I, O, 0, or 1.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 6; i++)
              SizedBox(
                width: 44,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp('[${_alphabet}${_alphabet.toLowerCase()}]'),
                    ),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) {
                    _chars[i] = v;
                    if (v.isNotEmpty && i < 5) {
                      _nodes[i + 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: state.isLoading ? null : _joinCouple,
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF2A1614),
                    strokeWidth: 2,
                  ),
                )
              : const Text('Join'),
        ),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: state.isLoading
              ? null
              : () =>
                  ref.read(coupleViewModelProvider.notifier).createCouple(),
          child: const Text('Create our room'),
        ),
      ],
    );
  }

  Widget _waiting(CoupleState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Share this code with them',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Text(
                state.generatedToken!,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      letterSpacing: 8,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expires in 24 hours',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Copy',
                    icon: Icon(AppIcons.copy, color: AppColors.secondary),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: state.generatedToken!));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Share',
                    icon: Icon(AppIcons.share, color: AppColors.primary),
                    onPressed: () {
                      Share.share(
                        'Join me in Zero Miles. Code: ${state.generatedToken}',
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(coupleViewModelProvider.notifier)
                          .cancelCreateCouple();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: LivingWindow(
            scene: PartnerScene.night,
            unpaired: true,
            child: const SizedBox.shrink(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Waiting for them to join…',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}