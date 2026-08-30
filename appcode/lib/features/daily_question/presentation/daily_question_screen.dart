import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../couple/data/supabase_couple_repository.dart';
import '../data/supabase_question_repository.dart';
import '../domain/daily_question_state.dart';
import '../../avatar/presentation/widgets/dynamic_person_avatar.dart';
import '../../avatar/presentation/avatar_view_model.dart';
import '../../home/presentation/widgets/partner_presence.dart';
import '../../home/data/supabase_connection_repository.dart';

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
  final _guessController = TextEditingController();
  final _editQuestionController = TextEditingController();
  bool _isEditingQuestion = false;
  bool _isEditingGuess = false;

  @override
  void dispose() {
    _answerController.dispose();
    _guessController.dispose();
    _editQuestionController.dispose();
    super.dispose();
  }

  void _submitAnswer(String connectionId) async {
    final text = _answerController.text.trim();
    final guess = _guessController.text.trim();
    if (text.isEmpty && guess.isEmpty) return;
    
    try {
      await ref.read(questionRepositoryProvider).submitAnswer(connectionId, text, guess);
      ref.invalidate(dailyQuestionStateProvider);
      setState(() => _isEditingGuess = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      }
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
    ref.listen<AsyncValue<DailyQuestionState>>(dailyQuestionStateProvider, (previous, next) {
      if (next.value != null) {
        final state = next.value!;
        if (_guessController.text.isEmpty && state.myGuess != null) {
          _guessController.text = state.myGuess!;
        }
        if (_answerController.text.isEmpty && state.myAnswer != null) {
          _answerController.text = state.myAnswer!;
        }
      }
    });

    final stateAsync = ref.watch(dailyQuestionStateProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final partnerNameAsync = ref.watch(partnerNameProvider);
    final partnerName = partnerNameAsync.value ?? 'Partner';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: stateAsync.when(
                data: (state) {
                  if (state.status == QuestionStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == QuestionStatus.waitingForCron) {
                    return _buildWaitingForCron();
                  }

                  final isCreator = state.creatorId == uid;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSparkBanner(state),
                            const SizedBox(height: 16),
                            _buildQuestionCard(state, isCreator),
                            const SizedBox(height: 24),
                            _buildDynamicContent(state, partnerName),
                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.secondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                const Text('Daily Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForCron() {
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
            const Text(
              "The daily question hasn't been generated.\nPlease ensure the cron job is running or you manually ran the generate function in Supabase.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkBanner(DailyQuestionState state) {
    // Determine badges based on state
    IconData myBadge = Icons.check_circle;
    Color myBadgeColor = AppColors.secondary;
    IconData partnerBadge = Icons.hourglass_bottom;
    Color partnerBadgeColor = Colors.orange;

    if (state.status == QuestionStatus.readyToAnswer) {
      myBadge = Icons.hourglass_bottom;
      myBadgeColor = Colors.orange;
      if (!state.partnerHasAnswered) {
        partnerBadge = Icons.hourglass_bottom;
        partnerBadgeColor = Colors.orange;
      } else {
        partnerBadge = Icons.check_circle;
        partnerBadgeColor = AppColors.accent;
      }
    } else if (state.status == QuestionStatus.waitingForPartner) {
      myBadge = Icons.check_circle;
      myBadgeColor = AppColors.secondary;
      partnerBadge = Icons.hourglass_bottom;
      partnerBadgeColor = Colors.orange;
    } else if (state.status == QuestionStatus.revealed) {
      myBadge = Icons.check_circle;
      myBadgeColor = AppColors.secondary;
      partnerBadge = Icons.check_circle;
      partnerBadgeColor = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildAvatarWithBadge(true, myBadge, myBadgeColor),
              const SizedBox(width: 8),
              const Icon(Icons.favorite, color: AppColors.secondary, size: 16),
              const SizedBox(width: 8),
              _buildAvatarWithBadge(false, partnerBadge, partnerBadgeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithBadge(bool isMe, IconData badgeIcon, Color badgeColor) {
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    
    Color parseColor(String str) {
      if (str.startsWith('#')) {
        final hex = str.substring(1);
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
      final Map<String, Color> oldMap = {
        'Red': Colors.red, 'Blue': Colors.blue, 'Green': Colors.green,
        'Yellow': Colors.yellow, 'Orange': Colors.orange, 'Purple': Colors.purple,
        'Black': Colors.black, 'White': Colors.white, 'Pink': Colors.pink, 'Teal': Colors.teal,
      };
      return oldMap[str] ?? Colors.transparent;
    }

    final roleAsync = isMe ? ref.watch(myRoleProvider) : ref.watch(partnerRoleProvider);
    final isBunny = roleAsync.value == 'bunny';
    
    Color topColor = AppColors.primary.withOpacity(0.2);
    Color bottomColor = AppColors.primary.withOpacity(0.2);

    if (activeCoupleId != null) {
      final outfitAsync = isMe 
        ? ref.watch(myOutfitProvider(activeCoupleId)) 
        : ref.watch(partnerOutfitProvider(activeCoupleId));
      
      final outfitValue = outfitAsync.value;
      if (outfitValue != null) {
        final parsedTop = parseColor(outfitValue['top_color'] as String);
        final parsedBottom = parseColor(outfitValue['bottom_color'] as String);
        if (parsedTop != Colors.transparent) topColor = parsedTop;
        if (parsedBottom != Colors.transparent) bottomColor = parsedBottom;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: OverflowBox(
              maxHeight: 45,
              maxWidth: 45,
              child: Transform.translate(
                offset: const Offset(0, 4),
                child: Transform.scale(
                  scale: 0.95,
                  child: DynamicPersonAvatar(
                    state: AnimationState.idle,
                    topColor: topColor,
                    bottomColor: bottomColor,
                    isBunny: isBunny,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: Icon(badgeIcon, size: 10, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(DailyQuestionState state, bool isCreator) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditingQuestion) ...[
            TextField(
              controller: _editQuestionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write a custom question...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4),
            ),
            if (isCreator && state.status == QuestionStatus.readyToAnswer) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  _editQuestionController.text = state.questionText ?? '';
                  setState(() => _isEditingQuestion = true);
                },
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Write custom question instead', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicContent(DailyQuestionState state, String partnerName) {
    if (state.status == QuestionStatus.readyToAnswer) {
      if (!state.partnerHasAnswered) {
        return _buildState1None(state, partnerName);
      } else {
        return _buildState2Partner(state, partnerName);
      }
    } else if (state.status == QuestionStatus.waitingForPartner) {
      return _buildState3You(state, partnerName);
    } else if (state.status == QuestionStatus.revealed) {
      return _buildState4Both(state, partnerName);
    }
    return const SizedBox();
  }

  Widget _buildGuessSection(DailyQuestionState state, String partnerName, {bool readOnly = false}) {
    if (state.myHasGuessed && !_isEditingGuess) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    const Text("Your Guess", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
                  ],
                ),
                if (!readOnly)
                  GestureDetector(
                    onTap: () => setState(() => _isEditingGuess = true),
                    child: const Icon(Icons.edit, size: 14, color: AppColors.accent),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(state.myGuess!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, size: 14, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(state.myHasGuessed ? "Update Your Guess" : "Guess ${partnerName}'s Answer", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
                ],
              ),
              if (state.myHasGuessed)
                GestureDetector(
                  onTap: () {
                    setState(() => _isEditingGuess = false);
                    _guessController.text = state.myGuess!; // Revert
                  },
                  child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _guessController,
            maxLines: 1,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g., Probably eating pizza...',
              hintStyle: TextStyle(color: AppColors.accent.withOpacity(0.5), fontSize: 13),
              filled: true,
              fillColor: AppColors.accent.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent.withOpacity(0.2)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                minimumSize: const Size(0, 36),
              ),
              onPressed: () => _submitAnswer(state.connectionId!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.myHasGuessed ? 'Update Guess' : 'Submit Guess', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.radar, size: 14),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  // S1: None (Neither answered)
  Widget _buildState1None(DailyQuestionState state, String partnerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNudgeCard(
          partnerName, 
          customText: state.partnerHasGuessed 
              ? "$partnerName just guessed your answer! 🎯\nAnswer now to see if they were right!" 
              : null
        ),
        const SizedBox(height: 16),
        _buildGuessSection(state, partnerName),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.edit, size: 14, color: AppColors.secondary),
            const SizedBox(width: 4),
            const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
            const Spacer(),
            Text('0/240', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          maxLines: 2,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Be honest, spontaneous and romantic...',
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
            filled: true,
            fillColor: AppColors.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () => _submitAnswer(state.connectionId!),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Submit My Answer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // S2: Partner Answered
  Widget _buildState2Partner(DailyQuestionState state, String partnerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.8), AppColors.primary.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Flexible(child: Text('$partnerName already answered!', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Answer below to reveal what $partnerName wrote!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildGuessSection(state, partnerName),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.edit, size: 14, color: AppColors.secondary),
            const SizedBox(width: 4),
            const Text('Your Answer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
            const Spacer(),
            Text('0/240', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _answerController,
          maxLines: 2,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Tell ${partnerName} your thoughts...",
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
            filled: true,
            fillColor: AppColors.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () => _submitAnswer(state.connectionId!),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Submit My Answer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // S3: You Answered
  Widget _buildState3You(DailyQuestionState state, String partnerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNudgeCard(
          partnerName, 
          customText: state.partnerHasGuessed 
              ? "$partnerName is guessing your answer right now! 👀" 
              : null
        ),
        const SizedBox(height: 16),
        _buildGuessSection(state, partnerName),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Flexible(child: Text('Your Answer Submitted', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Just now', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: Text(state.myAnswer ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4)),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
                child: const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text('${partnerName} hasn\'t responded yet...', style: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic), textAlign: TextAlign.center)),
            ],
          ),
        ),
      ],
    );
  }

  // S4: Both Answered
  Widget _buildState4Both(DailyQuestionState state, String partnerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Both Answered! Connection Unlocked', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Your Answer Block
        _buildFinalAnswerBlock(
          isMine: true,
          title: 'Your Answer',
          time: 'Today',
          answer: state.myAnswer ?? '',
          guessFeedback: state.partnerHasGuessed ? "${partnerName}'s Guess for You:" : null,
          guessText: state.partnerGuess,
          hasSpotOn: true,
        ),
        const SizedBox(height: 24),
        // Partner Answer Block
        _buildFinalAnswerBlock(
          isMine: false,
          title: "${partnerName}'s Answer",
          time: 'Today',
          answer: state.partnerAnswer ?? '',
          guessFeedback: state.myHasGuessed ? "Your Guess for ${partnerName}:" : null,
          guessText: state.myGuess,
        ),
      ],
    );
  }

  Widget _buildFinalAnswerBlock({
    required bool isMine,
    required String title,
    required String time,
    required String answer,
    String? guessFeedback,
    String? guessText,
    bool hasSpotOn = false,
  }) {
    final activeCoupleId = ref.watch(activeCoupleIdProvider).value;
    
    Color parseColor(String str) {
      if (str.startsWith('#')) {
        final hex = str.substring(1);
        if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
        if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      }
      return Colors.transparent;
    }

    final roleAsync = isMine ? ref.watch(myRoleProvider) : ref.watch(partnerRoleProvider);
    final isBunny = roleAsync.value == 'bunny';
    
    Color topColor = AppColors.primary.withOpacity(0.2);
    Color bottomColor = AppColors.primary.withOpacity(0.2);

    if (activeCoupleId != null) {
      final outfitAsync = isMine 
        ? ref.watch(myOutfitProvider(activeCoupleId)) 
        : ref.watch(partnerOutfitProvider(activeCoupleId));
      
      final outfitValue = outfitAsync.value;
      if (outfitValue != null) {
        final parsedTop = parseColor(outfitValue['top_color'] as String);
        final parsedBottom = parseColor(outfitValue['bottom_color'] as String);
        if (parsedTop != Colors.transparent) topColor = parsedTop;
        if (parsedBottom != Colors.transparent) bottomColor = parsedBottom;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: OverflowBox(
                        maxHeight: 35,
                        maxWidth: 35,
                        child: Transform.translate(
                          offset: const Offset(0, 3),
                          child: Transform.scale(
                            scale: 0.95,
                            child: DynamicPersonAvatar(
                              state: AnimationState.idle,
                              topColor: topColor,
                              bottomColor: bottomColor,
                              isBunny: isBunny,
                              size: 35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMine ? AppColors.secondary.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isMine ? AppColors.secondary.withOpacity(0.1) : AppColors.accent.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(answer, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.4)),
              if (guessFeedback != null && guessText != null && guessText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.radar, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Expanded(child: Text(guessFeedback, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('"$guessText"', style: const TextStyle(color: AppColors.accent, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionPill(IconData icon, String count, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(count, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildNudgeCard(String partnerName, {String? customText}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.hourglass_empty, color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(customText ?? "$partnerName hasn't answered yet", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () {
              final activeCoupleId = ref.read(activeCoupleIdProvider).value;
              if (activeCoupleId != null) {
                ref.read(connectionRepositoryProvider).sendSignal(activeCoupleId, 'nudge');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Nudge sent to $partnerName!')),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: AppColors.accent, size: 14),
                  SizedBox(width: 4),
                  Text('Nudge', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
