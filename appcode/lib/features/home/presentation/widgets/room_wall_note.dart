import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../daily_question/domain/daily_question_state.dart';
import '../../../daily_question/presentation/providers/question_providers.dart';

/// Letter pinned on the wall above the two windows.
class RoomWallNote extends ConsumerWidget {
  const RoomWallNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleId = ref.watch(activeCoupleIdProvider).value;
    final state = coupleId == null
        ? null
        : ref.watch(dailyQuestionStateProvider).asData?.value;

    final unpaired = coupleId == null;
    final question = state?.questionText?.trim();
    final hasQuestion = question != null && question.isNotEmpty;

    final String eyebrow;
    final String body;
    if (unpaired) {
      eyebrow = 'This room';
      body = 'Pair so both windows are lit.';
    } else if (!hasQuestion) {
      eyebrow = 'Today';
      body = 'Today’s question is still on its way.';
    } else {
      eyebrow = switch (state!.status) {
        QuestionStatus.revealed => 'You both wrote',
        QuestionStatus.waitingForPartner => 'Waiting on them',
        _ => 'Today',
      };
      body = question;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(unpaired ? AppRoutes.couple : AppRoutes.dailyQuestion);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(2, 18),
            painter: _TwinePainter(),
          ),
          Transform.rotate(
            angle: -0.035,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Material(
                color: const Color(0xFFDCC9B4),
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF8A6A55),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontFamily: AppTheme.displayFamily,
                                  color: const Color(0xFF2A1614),
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: -7,
                      left: 0,
                      right: 0,
                      child: Center(child: _Pin()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: const Color(0xFF5A2030), width: 1),
      ),
    );
  }
}

class _TwinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC4B49A)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
