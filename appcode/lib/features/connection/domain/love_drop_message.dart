/// Same window as a voice drop — a thought for about a day, then it fades.
const kLoveNoteTtl = Duration(hours: 24);

class LoveDropMessage {
  const LoveDropMessage(this.type, this.message, {this.emoji, this.senderId});

  final String type;
  final String? message;
  final String? emoji;
  final String? senderId;
}

class LatestLoveNote {
  const LatestLoveNote({
    required this.senderId,
    required this.message,
    required this.createdAt,
    this.emoji,
  });

  final String senderId;
  final String message;
  final DateTime createdAt;
  final String? emoji;

  bool get isExpired => DateTime.now().isAfter(createdAt.add(kLoveNoteTtl));
}
