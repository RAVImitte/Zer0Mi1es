import 'love_drop_message.dart';

abstract class ConnectionRepository {
  Future<void> sendLoveDrop(
    String coupleId,
    String type, {
    String? message,
    String? emoji,
  });

  Future<void> updateMood(String coupleId, String mood);

  Future<void> sendSignal(String coupleId, String signalType);

  Future<void> acknowledgeSignal(String signalId, String status);

  Stream<LoveDropMessage> watchLoveDrops(String coupleId);

  Future<List<LatestLoveNote>> fetchLatestNotes(String coupleId);
}
