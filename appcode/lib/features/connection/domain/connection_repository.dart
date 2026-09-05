import '../../avatar/domain/avatar_event.dart';
import 'love_drop_message.dart';

abstract class ConnectionRepository {
  Future<void> sendLoveDrop(String coupleId, String type, {String? message});

  Future<void> updateMood(String coupleId, String mood);

  Future<void> sendSignal(String coupleId, String signalType);

  Future<void> acknowledgeSignal(String signalId, String status);

  Stream<AvatarEvent> watchPartnerEvents(String coupleId);

  Stream<LoveDropMessage> watchLoveDrops(String coupleId);
}
