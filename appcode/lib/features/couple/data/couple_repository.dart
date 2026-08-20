import 'dart:math';

abstract class CoupleRepository {
  /// Stream of the active couple ID for the current user
  Stream<String?> get activeCoupleId;

  /// Creates a couple and returns the raw pairing token to be shared
  Future<String> createCouple();

  /// Joins an existing couple using a raw token
  Future<void> joinCouple(String rawToken);

  /// Helper to generate a random 6-character alphanumeric token
  String generateRawToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 1, 0
    final rnd = Random.secure();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
