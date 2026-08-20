import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/daily_question_state.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return SupabaseQuestionRepository(Supabase.instance.client);
});

abstract class QuestionRepository {
  Stream<DailyQuestionState> watchDailyQuestion(String coupleId);
  Future<void> submitAnswer(String connectionId, String answer);
  Future<void> editAnswer(String connectionId, String answer);
  Future<void> overwriteQuestion(String connectionId, String newQuestion);
}

class SupabaseQuestionRepository implements QuestionRepository {
  final SupabaseClient _client;

  SupabaseQuestionRepository(this._client);

  @override
  Stream<DailyQuestionState> watchDailyQuestion(String coupleId) {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.value(DailyQuestionState.loading());

    final controller = StreamController<DailyQuestionState>();

    // Helper to fetch the current state
    Future<void> fetchState() async {
      try {
        // Fetch the most recent connection (avoids timezone issues)
        final connectionRes = await _client
            .from('daily_connections')
            .select()
            .eq('couple_id', coupleId)
            .order('date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (connectionRes == null) {
          controller.add(DailyQuestionState.waiting());
          return;
        }

        final connectionId = connectionRes['id'] as String;
        final questionText = connectionRes['question'] as String;
        final creatorId = connectionRes['creator_id'] as String;

        // Fetch answers for this connection
        // RLS allows reading if we have submitted ours
        final answersRes = await _client
            .from('daily_answers')
            .select()
            .eq('daily_connection_id', connectionId);

        String? myAnswer;
        String? partnerAnswer;

        for (final row in answersRes) {
          if (row['user_id'] == uid) {
            myAnswer = row['answer'] as String;
          } else {
            partnerAnswer = row['answer'] as String;
          }
        }

        // Check if partner answered (bypasses RLS)
        final partnerHasAnswered = await _client.rpc('has_partner_answered', params: {'connection_id': connectionId}) as bool;

        QuestionStatus status;
        if (myAnswer != null && partnerAnswer != null) {
          status = QuestionStatus.revealed;
        } else if (myAnswer != null) {
          status = QuestionStatus.waitingForPartner;
        } else {
          status = QuestionStatus.readyToAnswer;
        }

        controller.add(DailyQuestionState(
          status: status,
          connectionId: connectionId,
          questionText: questionText,
          creatorId: creatorId,
          myAnswer: myAnswer,
          partnerAnswer: partnerAnswer,
          partnerHasAnswered: partnerHasAnswered,
        ));
      } catch (e, stack) {
        print('Error fetching daily question: $e');
        print(stack);
        controller.add(DailyQuestionState.waiting()); // Prevent hanging entirely, but we log the error
      }
    }

    // Initial fetch
    fetchState();

    // Subscribe to changes in connections and answers
    final channel = _client.channel('public:daily_questions:$coupleId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'daily_connections',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'couple_id', value: coupleId),
      callback: (_) => fetchState(),
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'daily_answers',
      // We can't easily filter by couple_id on daily_answers without a join, 
      // but we can just refetch state whenever ANY answer changes (or we could omit filter, but it might be noisy).
      // For V1, we refetch state when any answer is inserted.
      callback: (_) => fetchState(),
    ).subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<void> submitAnswer(String connectionId, String answer) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    await _client.from('daily_answers').insert({
      'daily_connection_id': connectionId,
      'user_id': uid,
      'answer': answer,
    });
  }

  @override
  Future<void> editAnswer(String connectionId, String answer) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    await _client.from('daily_answers').update({
      'answer': answer,
    }).eq('daily_connection_id', connectionId).eq('user_id', uid);
  }

  @override
  Future<void> overwriteQuestion(String connectionId, String newQuestion) async {
    await _client.from('daily_connections').update({
      'question': newQuestion,
    }).eq('id', connectionId);
  }
}
