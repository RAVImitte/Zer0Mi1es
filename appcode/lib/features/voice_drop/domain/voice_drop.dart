class VoiceDrop {
  const VoiceDrop({
    required this.id,
    required this.senderId,
    required this.storagePath,
    required this.durationMs,
    required this.expiresAt,
  });

  final String id;
  final String senderId;
  final String storagePath;
  final int durationMs;
  final DateTime expiresAt;

  factory VoiceDrop.fromMap(Map<String, dynamic> map) {
    return VoiceDrop(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      storagePath: map['storage_path'] as String,
      durationMs: map['duration_ms'] as int,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }
}