import 'package:flutter_test/flutter_test.dart';
import 'package:poc/core/result.dart';
import 'package:poc/modules/session/.index.dart';

/// Desembrulha um `Ok` (falha o teste se for `Fail`).
T _ok<T>(Result<T> result) {
  expect(result, isA<Ok<T>>());
  return (result as Ok<T>).value;
}

/// Codigo de um `Fail` (falha o teste se for `Ok`).
String _code<T>(Result<T> result) {
  expect(result, isA<Fail<T>>());
  return (result as Fail<T>).code;
}

void main() {
  group('SessionUser', () {
    test('nome vazio reprova com SESSION_NAME_EMPTY', () {
      final user = SessionUser.create(name: '  ', specialty: 'Rede');

      expect(_code(user), SessionFailureCodes.nameEmpty);
    });

    test('especialidade vazia reprova com SESSION_SPECIALTY_EMPTY', () {
      final user = SessionUser.create(name: 'Ana', specialty: '  ');

      expect(_code(user), SessionFailureCodes.specialtyEmpty);
    });

    test('valido normaliza nome e especialidade', () {
      final user = _ok(
        SessionUser.create(name: '  Ana  ', specialty: ' Rede '),
      );

      expect(user.name, 'Ana');
      expect(user.specialty, 'Rede');
    });
  });

  group('InMemorySessionProvider', () {
    test('demo entrega o tecnico de demonstracao', () {
      final session = InMemorySessionProvider.demo();

      expect(session.currentUser.name, 'Tecnico Demo');
      expect(session.currentUser.specialty, 'Rede');
    });

    test('injeta o usuario informado', () {
      final user = _ok(
        SessionUser.create(name: 'Bruno', specialty: 'Software'),
      );
      final session = InMemorySessionProvider(currentUser: user);

      expect(session.currentUser.name, 'Bruno');
    });
  });
}
