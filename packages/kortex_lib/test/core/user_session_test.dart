import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  group('UserSession & InMemoryUserSession | Unit Tests', () {
    test('UserSessionData serializa e deserializa via fromMap e toMap', () {
      final data = UserSessionData.fromMap({
        'id': '10',
        'nome': 'Maria',
        'email': 'maria@test.com',
        'token': 'abc',
        'tipoToken': 'Bearer',
        'expiraEm': '3600',
      });

      expect(data.id, equals(10));
      expect(data.name, equals('Maria'));
      expect(data.email, equals('maria@test.com'));
      expect(data.token, equals('abc'));
      expect(data.tokenType, equals('Bearer'));
      expect(data.expiresAt, equals(3600));

      final map = data.toMap();
      expect(map['id'], equals(10));
      // Chaves de serialização são contrato legado congelado (português),
      // mesmo com identificadores Dart em inglês.
      expect(map['nome'], equals('Maria'));
      expect(map['tipoToken'], equals('Bearer'));
      expect(map['expiraEm'], equals(3600));
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('expiresAt'), isFalse);

      final copy = data.copyWith(name: 'Maria Silva');
      expect(copy.id, equals(10));
      expect(copy.name, equals('Maria Silva'));
    });

    test('InMemoryUserSession gerencia ciclo de vida da sessao', () {
      final session = InMemoryUserSession();
      expect(session.isAuthenticated, isFalse);
      expect(session.currentUser, isNull);

      const user = UserSessionData(
        id: 1,
        name: 'Admin',
        email: 'admin@compras.com',
      );

      session.startSession(user);
      expect(session.isAuthenticated, isTrue);
      expect(session.currentUser?.id, equals(1));
      expect(session.toMap()['nome'], equals('Admin'));

      session.update({
        'id': 1,
        'nome': 'Admin Master',
        'email': 'admin@compras.com',
      });
      expect(session.currentUser?.name, equals('Admin Master'));

      session.clearSession();
      expect(session.isAuthenticated, isFalse);
      expect(session.currentUser, isNull);
    });

    test('expiresAt futuro mantem autenticado; passado invalida sessao', () {
      final nowMs = DateTime(2026, 10, 11, 12, 0, 0).millisecondsSinceEpoch;
      final session = InMemoryUserSession(
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMs),
      );

      session.startSession(
        const UserSessionData(
          id: 1,
          name: 'Admin',
          email: 'admin@compras.com',
          expiresAt: 0, // sem expiração (compat retroativa)
        ),
      );
      expect(session.isAuthenticated, isTrue);

      session.startSession(
        UserSessionData(
          id: 1,
          name: 'Admin',
          email: 'admin@compras.com',
          expiresAt: nowMs + 60000, // +60s
        ),
      );
      expect(session.isAuthenticated, isTrue);

      session.startSession(
        UserSessionData(
          id: 1,
          name: 'Admin',
          email: 'admin@compras.com',
          expiresAt: nowMs - 1, // expirado
        ),
      );
      expect(session.isAuthenticated, isFalse);
    });
  });
}
