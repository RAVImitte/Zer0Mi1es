import 'dart:math';

const pairingTokenAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const pairingTokenLength = 6;

abstract class CoupleRepository {
  Stream<String?> get activeCoupleId;

  Future<String> createCouple();

  Future<void> joinCouple(String rawToken);

  String generateRawToken() {
    final rnd = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        pairingTokenLength,
        (_) => pairingTokenAlphabet.codeUnitAt(
          rnd.nextInt(pairingTokenAlphabet.length),
        ),
      ),
    );
  }
}
