import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../couple/data/supabase_couple_repository.dart';
import '../../../daily_question/data/supabase_question_repository.dart';

final outfitCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (uid == null || coupleId == null) return Stream.value(false);
  final today = DateTime.now().toIso8601String().split('T').first;
  
  return client.from('daily_outfits').stream(primaryKey: ['id'])
    .eq('couple_id', coupleId).eq('user_id', uid).eq('date', today)
    .map((data) => data.isNotEmpty);
});

final photoCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (uid == null || coupleId == null) return Stream.value(false);
  final today = DateTime.now().toIso8601String().split('T').first;
  
  return client.from('daily_photos').stream(primaryKey: ['id'])
    .eq('couple_id', coupleId).eq('user_id', uid).eq('date', today)
    .map((data) => data.isNotEmpty);
});

final questionCompletedProvider = StreamProvider.autoDispose<bool>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId == null) return Stream.value(false);
  
  final repo = ref.watch(questionRepositoryProvider);
  return repo.watchDailyQuestion(coupleId).map((state) => state.myAnswer != null);
});

class DailyStatus extends ConsumerWidget {
  const DailyStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOutfit = ref.watch(outfitCompletedProvider).value ?? false;
    final hasPhoto = ref.watch(photoCompletedProvider).value ?? false;
    final hasQuestion = ref.watch(questionCompletedProvider).value ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Rituals',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                icon: Icons.checkroom, 
                label: 'Outfit', 
                isCompleted: hasOutfit,
                onTap: () => context.push('/outfit'),
              ),
              _buildStatusItem(
                icon: Icons.photo_camera, 
                label: 'Photo', 
                isCompleted: hasPhoto,
                onTap: () => context.push('/daily_photo'),
              ),
              _buildStatusItem(
                icon: Icons.question_answer,
                label: 'Question',
                isCompleted: hasQuestion,
                onTap: () => context.push('/daily_question'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required bool isCompleted,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
              border: Border.all(
                color: isCompleted ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
