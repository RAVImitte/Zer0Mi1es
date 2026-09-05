import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../couple/data/supabase_couple_repository.dart';
import '../../data/supabase_question_repository.dart';
import '../../domain/daily_question_state.dart';

final dailyQuestionStateProvider =
    StreamProvider.autoDispose<DailyQuestionState>((ref) {
  final coupleId = ref.watch(activeCoupleIdProvider).value;
  if (coupleId == null) return Stream.value(DailyQuestionState.loading());
  return ref.watch(questionRepositoryProvider).watchDailyQuestion(coupleId);
});
