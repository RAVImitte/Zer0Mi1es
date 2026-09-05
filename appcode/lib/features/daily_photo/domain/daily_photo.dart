class DailyPhoto {
  DailyPhoto({
    required this.id,
    required this.userId,
    required this.storagePath,
    this.comment,
    this.reactionEmoji,
    this.reactionText,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String storagePath;
  final String? comment;
  final String? reactionEmoji;
  final String? reactionText;
  final DateTime createdAt;

  factory DailyPhoto.fromJson(Map<String, dynamic> json) {
    return DailyPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storagePath: json['storage_path'] as String,
      comment: json['comment'] as String?,
      reactionEmoji: json['reaction_emoji'] as String?,
      reactionText: json['reaction_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
