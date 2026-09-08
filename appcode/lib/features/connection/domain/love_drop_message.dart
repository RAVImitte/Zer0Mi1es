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
    this.emoji,
  });

  final String senderId;
  final String message;
  final String? emoji;
}
