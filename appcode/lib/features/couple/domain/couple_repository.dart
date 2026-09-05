import 'dart:math';

abstract class CoupleRepository {
  Stream<String?> get activeCoupleId;

  Future<String> createCouple();

  Future<void> joinCouple(String rawToken);

  String generateRawToken() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
