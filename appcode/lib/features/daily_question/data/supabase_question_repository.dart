import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/notifications/push_dispatcher.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../core/utils/iso_date.dart';
import '../domain/daily_question_state.dart';
import '../domain/question_repository.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return SupabaseQuestionRepository(ref.watch(supabaseClientProvider));
});

class SupabaseQuestionRepository implements QuestionRepository {
  SupabaseQuestionRepository(this._client) : _push = PushDispatcher(_client);

  final SupabaseClient _client;
  final PushDispatcher _push;

  @override
  Stream<DailyQuestionState> watchDailyQuestion(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(DailyQuestionState.loading());

    final controller = StreamController<DailyQuestionState>();

    Future<void> fetchState() async {
      try {
        final connectionRes = await _client
            .from('daily_connections')
            .select()
            .eq('couple_id', coupleId)
            .order('date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (connectionRes == null) {
          if (!controller.isClosed) controller.add(DailyQuestionState.waiting());
          return;
        }

        final connectionId = connectionRes['id'] as String;
        final answersRes = await _client
            .from('daily_answers')
            .select()
            .eq('daily_connection_id', connectionId);

        String? myAnswer;
        String? partnerAnswer;
        String? myGuess;
        String? partnerGuess;

        for (final row in answersRes) {
          if (row['user_id'] == uid) {
            myAnswer = row['answer'] as String?;
            myGuess = row['guess'] as String?;
          } else {
            partnerAnswer = row['answer'] as String?;
            partnerGuess = row['guess'] as String?;
          }
        }

        final partnerHasAnswered = await _client.rpc(
              'has_partner_answered',
              params: {'connection_id': connectionId},
            ) as bool;
        final partnerHasGuessed = await _client.rpc(
              'has_partner_guessed',
              params: {'connection_id': connectionId},
            ) as bool;

        final QuestionStatus status;
        if (myAnswer != null && myAnswer.isNotEmpty && partnerHasAnswered) {
          status = QuestionStatus.revealed;
        } else if (myAnswer != null && myAnswer.isNotEmpty) {
          status = QuestionStatus.waitingForPartner;
        } else {
          status = QuestionStatus.readyToAnswer;
        }

        if (!controller.isClosed) {
          controller.add(DailyQuestionState(
            status: status,
            connectionId: connectionId,
            questionText: connectionRes['question'] as String,
            creatorId: connectionRes['creator_id'] as String,
            myAnswer: myAnswer,
            partnerAnswer: partnerAnswer,
            myGuess: myGuess,
            partnerGuess: partnerGuess,
            partnerHasAnswered: partnerHasAnswered,
            partnerHasGuessedRpc: partnerHasGuessed,
          ));
        }
      } catch (_) {
        if (!controller.isClosed) controller.add(DailyQuestionState.waiting());
      }
    }

    fetchState();

    final channel = _client.channel('public:daily_questions:$coupleId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_connections',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'couple_id',
            value: coupleId,
          ),
          callback: (_) => fetchState(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'daily_answers',
          callback: (_) => fetchState(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> submitAnswer(
    String connectionId,
    String answer,
    String guess,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final connRes = await _client
        .from('daily_connections')
        .select('couple_id')
        .eq('id', connectionId)
        .single();
    final coupleId = connRes['couple_id'] as String?;
    if (coupleId == null) return;

    final existing = await _client
        .from('daily_answers')
        .select('id, answer, guess')
        .eq('daily_connection_id', connectionId)
        .eq('user_id', uid)
        .maybeSingle();

    if (existing != null) {
      final existingAnswer = existing['answer'] as String? ?? '';
      final existingGuess = existing['guess'] as String? ?? '';
      await _client.from('daily_answers').update({
        'answer': answer.isNotEmpty ? answer : existingAnswer,
        'guess': guess.isNotEmpty ? guess : existingGuess,
      }).eq('id', existing['id']);
    } else {
      await _client.from('daily_answers').insert({
        'daily_connection_id': connectionId,
        'user_id': uid,
        'answer': answer,
        'guess': guess,
      });
    }

    await _push.notify(table: 'daily_answers', record: {
      'couple_id': coupleId,
      'user_id': uid,
    });
  }

  @override
  Future<void> editAnswer(
    String connectionId,
    String answer,
    String guess,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    await _client.from('daily_answers').update({
      'answer': answer,
      'guess': guess,
    }).eq('daily_connection_id', connectionId).eq('user_id', uid);
  }

  @override
  Future<void> scheduleQuestionForTomorrow(
    String coupleId,
    String newQuestion,
  ) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;

    final tomorrow = isoDate(DateTime.now().add(const Duration(days: 1)));
    await _client.from('daily_connections').upsert({
      'couple_id': coupleId,
      'date': tomorrow,
      'creator_id': uid,
      'question': newQuestion,
    }, onConflict: 'couple_id, date');
  }
}
