import 'daily_question_state.dart';

abstract class QuestionRepository {
  Stream<DailyQuestionState> watchDailyQuestion(String coupleId);

  Future<void> submitAnswer(String connectionId, String answer, String guess);

  Future<void> editAnswer(String connectionId, String answer, String guess);

  Future<void> scheduleQuestionForTomorrow(String coupleId, String newQuestion);
}
