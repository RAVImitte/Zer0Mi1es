import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/daily_question_state.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return SupabaseQuestionRepository(Supabase.instance.client);
});

abstract class QuestionRepository {
  Stream<DailyQuestionState> watchDailyQuestion(String coupleId);
  Future<void> submitAnswer(String connectionId, String answer, String guess);
  Future<void> editAnswer(String connectionId, String answer, String guess);
  Future<void> scheduleQuestionForTomorrow(String coupleId, String newQuestion);
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
          if (!controller.isClosed) controller.add(DailyQuestionState.waiting());
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

        // Check if partner answered/guessed (bypasses RLS)
        final partnerHasAnswered = await _client.rpc('has_partner_answered', params: {'connection_id': connectionId}) as bool;
        final partnerHasGuessed = await _client.rpc('has_partner_guessed', params: {'connection_id': connectionId}) as bool;

        QuestionStatus status;
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
            questionText: questionText,
            creatorId: creatorId,
            myAnswer: myAnswer,
            partnerAnswer: partnerAnswer,
            myGuess: myGuess,
            partnerGuess: partnerGuess,
            partnerHasAnswered: partnerHasAnswered,
            partnerHasGuessedRpc: partnerHasGuessed,
          ));
        }
      } catch (e, stack) {
        if (!controller.isClosed) controller.add(DailyQuestionState.waiting()); // Prevent hanging entirely, but we log the error
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

  Future<void> _triggerNotification(String table, String coupleId, Map<String, dynamic> record) async {
    try {
      await _client.functions.invoke('push-notification', body: {
        'table': table,
        'record': record,
      });
    } catch (e) {
      print('Failed to trigger notification: $e');
    }
  }

  @override
  Future<void> submitAnswer(String connectionId, String answer, String guess) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    // First, find the coupleId for this connectionId
    final connRes = await _client.from('daily_connections').select('couple_id').eq('id', connectionId).single();
    final coupleId = connRes['couple_id'] as String?;
    if (coupleId == null) return;

    final existing = await _client.from('daily_answers')
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
    
    _triggerNotification('daily_answers', coupleId, {
      'couple_id': coupleId,
      'user_id': uid,
    });
  }

  @override
  Future<void> editAnswer(String connectionId, String answer, String guess) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    await _client.from('daily_answers').update({
      'answer': answer,
      'guess': guess,
    }).eq('daily_connection_id', connectionId).eq('user_id', uid);
  }

  @override
  Future<void> scheduleQuestionForTomorrow(String coupleId, String newQuestion) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first;
    
    await _client.from('daily_connections').upsert({
      'couple_id': coupleId,
      'date': tomorrow,
      'creator_id': uid,
      'question': newQuestion,
    }, onConflict: 'couple_id, date');
  }
}
