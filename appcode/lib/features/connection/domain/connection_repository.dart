import '../../avatar/domain/avatar_event.dart';
import 'love_drop_message.dart';

abstract class ConnectionRepository {
  Future<void> sendLoveDrop(String coupleId, String type, {String? message});

  Future<void> updateMood(String coupleId, String mood);

  Future<void> sendSignal(String coupleId, String signalType);

  Stream<AvatarEvent> watchPartnerEvents(String coupleId);

  Stream<LoveDropMessage> watchLoveDrops(String coupleId);
}
