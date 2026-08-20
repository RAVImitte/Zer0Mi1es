enum QuestionStatus {
  loading,
  waitingForCron, // Cron hasn't created the question for today yet
  readyToAnswer, // The question is available, but you haven't answered
  waitingForPartner, // You answered, waiting for partner to answer
  revealed, // Both answered, answers are visible
}

class DailyQuestionState {
  final QuestionStatus status;
  final String? connectionId;
  final String? questionText;
  final String? creatorId;
  final String? myAnswer;
  final String? partnerAnswer;
  final bool partnerHasAnswered;

  const DailyQuestionState({
    required this.status,
    this.connectionId,
    this.questionText,
    this.creatorId,
    this.myAnswer,
    this.partnerAnswer,
    this.partnerHasAnswered = false,
  });
  
  factory DailyQuestionState.loading() => const DailyQuestionState(status: QuestionStatus.loading);
  factory DailyQuestionState.waiting() => const DailyQuestionState(status: QuestionStatus.waitingForCron);
}
