import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_question_repository.dart';
import '../domain/daily_question_state.dart';

final dailyQuestionStateProvider = StreamProvider.autoDispose<DailyQuestionState>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId == null) return Stream.value(DailyQuestionState.loading());
  return ref.watch(questionRepositoryProvider).watchDailyQuestion(coupleId);
});

class DailyQuestionScreen extends ConsumerStatefulWidget {
  const DailyQuestionScreen({super.key});

  @override
  ConsumerState<DailyQuestionScreen> createState() => _DailyQuestionScreenState();
}

class _DailyQuestionScreenState extends ConsumerState<DailyQuestionScreen> {
  final _answerController = TextEditingController();
  final _editQuestionController = TextEditingController();
  bool _isEditingQuestion = false;
  bool _isEditingAnswer = false;

  @override
  void dispose() {
    _answerController.dispose();
    _editQuestionController.dispose();
    super.dispose();
  }

  void _submitAnswer(String connectionId) async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    
    try {
      await ref.read(questionRepositoryProvider).submitAnswer(connectionId, text);
      ref.invalidate(dailyQuestionStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _updateAnswer(String connectionId) async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      setState(() => _isEditingAnswer = false);
      return;
    }
    
    try {
      await ref.read(questionRepositoryProvider).editAnswer(connectionId, text);
      setState(() => _isEditingAnswer = false);
      ref.invalidate(dailyQuestionStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  void _submitCustomQuestion(String coupleId) async {
    final text = _editQuestionController.text.trim();
    if (text.isEmpty) {
      setState(() => _isEditingQuestion = false);
      return;
    }
    
    try {
      await ref.read(questionRepositoryProvider).scheduleQuestionForTomorrow(coupleId, text);
      setState(() => _isEditingQuestion = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom question scheduled for tomorrow!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(dailyQuestionStateProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final partnerNameAsync = ref.watch(partnerNameProvider);
    final partnerName = partnerNameAsync.value ?? 'Partner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Question', style: TextStyle(color: AppColors.primary)),
      ),
      body: SafeArea(
        child: stateAsync.when(
          data: (state) {
            if (state.status == QuestionStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == QuestionStatus.waitingForCron) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 64, color: AppColors.primary),
                      const SizedBox(height: 24),
                      const Text(
                        "Today's question is not ready yet!",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "The daily question hasn't been generated.\nPlease ensure the cron job is running or you manually ran the generate function in Supabase.",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final isCreator = state.creatorId == uid;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Card
                  Card(
                    color: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text(
                            "TODAY'S QUESTION",
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 16),
                          if (_isEditingQuestion) ...[
                            TextField(
                              controller: _editQuestionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Write a custom question...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _submitCustomQuestion(ref.read(activeCoupleIdProvider).value!),
                              child: const Text('Save Custom Question'),
                            ),
                          ] else ...[
                            Text(
                              state.questionText ?? '',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                            if (isCreator && state.status == QuestionStatus.readyToAnswer) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  _editQuestionController.text = state.questionText ?? '';
                                  setState(() => _isEditingQuestion = true);
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Write custom question instead'),
                              ),
                            ]
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // State-specific UI
                  if (state.status == QuestionStatus.readyToAnswer) ...[
                    if (state.partnerHasAnswered) ...[
                      _buildAnswerCard('$partnerName\'s Answer', '', false, isHidden: true),
                      const SizedBox(height: 24),
                    ],
                    const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _answerController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _submitAnswer(state.connectionId!),
                      child: Text(
                        state.partnerHasAnswered ? 'Submit to reveal $partnerName\'s answer' : 'Submit',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else if (state.status == QuestionStatus.waitingForPartner) ...[
                    if (_isEditingAnswer) ...[
                      const Text('Edit Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _answerController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateAnswer(state.connectionId!),
                              child: const Text('Update Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => setState(() => _isEditingAnswer = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          TextButton.icon(
                            onPressed: () {
                              _answerController.text = state.myAnswer!;
                              setState(() => _isEditingAnswer = true);
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAnswerCard('', state.myAnswer!, true, hideTitle: true),
                    ],
                    const SizedBox(height: 24),
                    // Just simple text indicating they haven't answered yet
                    _buildAnswerCard('$partnerName\'s Answer', 'They haven\'t answered yet...', false, isWaitingText: true),
                  ] else if (state.status == QuestionStatus.revealed) ...[
                    if (_isEditingAnswer) ...[
                      const Text('Edit Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _answerController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateAnswer(state.connectionId!),
                              child: const Text('Update Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () => setState(() => _isEditingAnswer = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          TextButton.icon(
                            onPressed: () {
                              _answerController.text = state.myAnswer!;
                              setState(() => _isEditingAnswer = true);
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAnswerCard('', state.myAnswer!, true, hideTitle: true),
                    ],
                    const SizedBox(height: 24),
                    _buildAnswerCard('$partnerName\'s Answer', state.partnerAnswer!, false),
                  ]
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(String title, String text, bool isMine, {bool isHidden = false, bool hideTitle = false, bool isWaitingText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideTitle) ...[
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: isHidden ? EdgeInsets.zero : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: (isHidden || isWaitingText) ? Border.all(color: Colors.grey.shade300, style: BorderStyle.solid) : null,
          ),
          child: isHidden 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'This is a completely fake placeholder text string that is used solely to make the blur effect look like there is an actual answer written underneath. It provides enough visual mass so the blur works nicely.',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Hidden until they answer',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : isWaitingText
                  ? Row(
                      children: [
                        const Icon(Icons.hourglass_empty, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                      ],
                    )
                  : Text(text, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
