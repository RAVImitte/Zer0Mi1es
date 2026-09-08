import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_page.dart';
import '../../connection/data/supabase_connection_repository.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_question_repository.dart';
import '../domain/daily_question_state.dart';
import 'providers/question_providers.dart';

class DailyQuestionScreen extends ConsumerStatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  ConsumerState<DailyQuestionScreen> createState() =>
      _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends ConsumerState<DailyQuestionScreen> {
  final _answerController = TextEditingController();
  final _guessController = TextEditingController();
  final _tomorrowController = TextEditingController();
  bool _guessOpen = false;
  bool _askingTomorrow = false;
  bool _nudgeLocked = false;

  @override
  void dispose() {
    _answerController.dispose();
    _guessController.dispose();
    _tomorrowController.dispose();
    super.dispose();
  }

  String _first(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'them';
    return t.split(RegExp(r'\s+')).first;
  }

  Future<void> _save(
    DailyQuestionState state, {
    required bool requireAnswer,
  }) async {
    final answer = _answerController.text.trim();
    final guess = _guessController.text.trim();
    if (requireAnswer && answer.isEmpty) return;
    final id = state.connectionId;
    if (id == null) return;
    try {
      await ref.read(questionRepositoryProvider).submitAnswer(
            id,
            answer.isEmpty ? (state.myAnswer ?? '') : answer,
            guess,
          );
      ref.invalidate(dailyQuestionStateProvider);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(requireAnswer ? 'Shared with them' : 'Guess saved'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save that just now'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _scheduleTomorrow() async {
    final text = _tomorrowController.text.trim();
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (text.isEmpty || coupleId == null) {
      setState(() => _askingTomorrow = false);
      return;
    }
    try {
      await ref
          .read(questionRepositoryProvider)
          .scheduleQuestionForTomorrow(coupleId, text);
      setState(() => _askingTomorrow = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We’ll ask that tomorrow')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not schedule that'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _nudge(String partnerName) async {
    final coupleId = ref.read(activeCoupleIdProvider).value;
    if (coupleId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'nudge_$coupleId';
    final last = prefs.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < 10 * 60 * 1000) {
      if (!mounted) return;
      setState(() => _nudgeLocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Give ${_first(partnerName)} a little time')),
      );
      return;
    }
    try {
      await ref.read(connectionRepositoryProvider).sendSignal(coupleId, 'nudge');
      await prefs.setInt(key, now);
      if (!mounted) return;
      setState(() => _nudgeLocked = true);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nudge sent to ${_first(partnerName)}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send that nudge'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<DailyQuestionState>>(dailyQuestionStateProvider,
        (previous, next) {
      final state = next.value;
      if (state == null) return;
      if (_guessController.text.isEmpty && state.myGuess != null) {
        _guessController.text = state.myGuess!;
      }
      if (_answerController.text.isEmpty && state.myAnswer != null) {
        _answerController.text = state.myAnswer!;
      }
    });

    final stateAsync = ref.watch(dailyQuestionStateProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final partnerName = ref.watch(partnerNameProvider).value ?? 'Partner';
    final first = _first(partnerName);

    return AppPage(
      title: 'Today’s question',
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AppErrorState(
          message: 'Couldn’t open today’s question.',
          onRetry: () => ref.invalidate(dailyQuestionStateProvider),
        ),
        data: (state) {
          if (state.status == QuestionStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == QuestionStatus.waitingForCron) {
            return AppEmptyState(
              title: 'Tomorrow’s question is still on its way',
              subtitle: 'Come back in a bit.',
              icon: AppIcons.hourglass,
              action: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back to Home'),
              ),
            );
          }

          final isCreator = state.creatorId == uid;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _statusLine(state, first),
              const SizedBox(height: 16),
              _questionLetter(state, isCreator),
              const SizedBox(height: 24),
              _bodyFor(state, first),
            ],
          );
        },
      ),
    );
  }

  Widget _statusLine(DailyQuestionState state, String first) {
    final you = state.myAnswer != null && state.myAnswer!.isNotEmpty;
    final them = state.partnerHasAnswered;
    String copy;
    if (you && them) {
      copy = 'You’re both in';
    } else if (you) {
      copy = 'Waiting on $first';
    } else if (them) {
      copy = '$first already wrote something';
    } else {
      copy = 'Neither of you has written yet';
    }
    return Text(
      copy,
      style: Theme.of(context).textTheme.labelSmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _questionLetter(DailyQuestionState state, bool isCreator) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_askingTomorrow) ...[
            TextField(
              controller: _tomorrowController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What do you want to ask tomorrow?',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _scheduleTomorrow,
              child: const Text('Ask this tomorrow'),
            ),
            TextButton(
              onPressed: () => setState(() => _askingTomorrow = false),
              child: const Text('Cancel'),
            ),
          ] else ...[
            Text(
              state.questionText ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (isCreator && state.status == QuestionStatus.readyToAnswer) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _tomorrowController.text = state.questionText ?? '';
                  setState(() => _askingTomorrow = true);
                },
                child: const Text('Ask something tomorrow instead'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _bodyFor(
    DailyQuestionState state,
    String first,
  ) {
    switch (state.status) {
      case QuestionStatus.readyToAnswer:
        return _compose(
          state,
          first,
          partnerWrote: state.partnerHasAnswered,
        );
      case QuestionStatus.waitingForPartner:
        return _waiting(state, first);
      case QuestionStatus.revealed:
        return _revealed(state, first);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _compose(
    DailyQuestionState state,
    String first, {
    required bool partnerWrote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (partnerWrote)
          _note('$first already wrote something. Share yours to open it.')
        else
          _note('$first hasn’t answered yet.'),
        const SizedBox(height: 16),
        Text(
          'Your answer',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_answerController.text.length}/240',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          maxLines: 4,
          maxLength: 240,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tell $first…',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        _guessFold(state, first),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _answerController.text.trim().isEmpty
              ? null
              : () => _save(state, requireAnswer: true),
          child: const Text('Share my answer'),
        ),
      ],
    );
  }

  Widget _waiting(DailyQuestionState state, String first) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _note('$first hasn’t responded yet.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Text(
            state.myAnswer ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 16),
        _guessFold(state, first),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: _nudgeLocked ? null : () => _nudge(first),
          child: Text(_nudgeLocked ? 'Nudge sent' : 'Nudge $first'),
        ),
      ],
    );
  }

  Widget _revealed(DailyQuestionState state, String first) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _answerBlock('You', state.myAnswer ?? ''),
        if (state.partnerHasGuessed && (state.partnerGuess ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '$first guessed: “${state.partnerGuess}”',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
        const SizedBox(height: 20),
        _answerBlock(first, state.partnerAnswer ?? ''),
        if (state.myHasGuessed) ...[
          const SizedBox(height: 8),
          Text(
            'You guessed: “${state.myGuess}”',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }

  Widget _answerBlock(String title, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Text(answer, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }

  Widget _guessFold(DailyQuestionState state, String first) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _guessOpen,
        onExpansionChanged: (v) => setState(() => _guessOpen = v),
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Want to guess $first’s answer?',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        children: [
          TextField(
            controller: _guessController,
            decoration: const InputDecoration(
              hintText: 'Optional guess',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _save(state, requireAnswer: false),
              child: const Text('Save guess'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}