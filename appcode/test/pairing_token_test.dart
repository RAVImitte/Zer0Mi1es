import 'package:flutter_test/flutter_test.dart';
import 'package:zer0mi1es/features/couple/domain/couple_repository.dart';

class _TestCoupleRepository extends CoupleRepository {
  @override
  Stream<String?> get activeCoupleId => const Stream.empty();

  @override
  Future<String> createCouple() => throw UnimplementedError();

  @override
  Future<void> joinCouple(String rawToken) => throw UnimplementedError();
}

void main() {
  test('pairing alphabet is 6-char Crockford without I/O/0/1', () {
    expect(pairingTokenLength, 6);
    expect(pairingTokenAlphabet, 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789');
    expect(pairingTokenAlphabet.contains('I'), isFalse);
    expect(pairingTokenAlphabet.contains('O'), isFalse);
    expect(pairingTokenAlphabet.contains('0'), isFalse);
    expect(pairingTokenAlphabet.contains('1'), isFalse);
  });

  test('generateRawToken uses that alphabet and length', () {
    final repo = _TestCoupleRepository();
    final allowed = pairingTokenAlphabet.split('').toSet();

    for (var i = 0; i < 40; i++) {
      final token = repo.generateRawToken();
      expect(token.length, pairingTokenLength);
      expect(token.split('').toSet().difference(allowed), isEmpty);
    }
  });
}
