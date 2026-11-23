import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Observable', () {
    test('entrega o valor corrente a assinante posterior', () {
      expect(Observable<int>(7).value, 7);
    });

    test('notifica quando o valor muda', () {
      final observed = <int>[];
      final observable = Observable<int>(0)..on(observed.add);

      observable
        ..value = 1
        ..value = 2;

      expect(observed, [1, 2]);
      expect(observable.value, 2);
    });

    test('não notifica quando o valor não muda', () {
      final observed = <int>[];
      final observable = Observable<int>(5)..on(observed.add);

      observable.value = 5;

      expect(observed, isEmpty);
    });

    test('notifica todos os assinantes ativos', () {
      final first = <int>[];
      final second = <int>[];
      final observable = Observable<int>(0)
        ..on(first.add)
        ..on(second.add);

      observable.value = 8;

      expect(first, [8]);
      expect(second, [8]);
    });

    test('token cancelado não recebe novas mudanças', () {
      final observed = <int>[];
      final observable = Observable<int>(0);
      final token = observable.on(observed.add);

      observable.value = 1;
      token.cancel();
      observable.value = 2;

      expect(observed, [1]);
      expect(token.isActive, isFalse);
    });

    test('cancel é idempotente', () {
      final token = Observable<int>(0).on((_) {});

      token
        ..cancel()
        ..cancel();

      expect(token.isActive, isFalse);
    });

    test('cancel após dispose do observable é seguro', () {
      final token = Observable<int>(0).on((_) {});

      expect(token.cancel, returnsNormally);
    });

    test('não faz replay do valor corrente na assinatura', () {
      final observed = <int>[];
      Observable<int>(9).on(observed.add);

      expect(observed, isEmpty);
    });

    test('o token expõe o valor corrente', () {
      expect(Observable<int>(4).on((_) {}).value, 4);
    });

    test('o token de um observable descartado nasce inativo', () {
      final token = Observable<int>(0).on((_) {});
      token.observable.dispose();

      expect(token.isActive, isFalse);
    });

    test('assinar após dispose devolve token inativo e não notifica', () {
      final observed = <int>[];
      final observable = Observable<int>(0)..dispose();

      final token = observable.on(observed.add);
      observable.value = 3;

      expect(token.isActive, isFalse);
      expect(observed, isEmpty);
    });

    test('descarte impede notificar assinantes existentes', () {
      final observed = <int>[];
      final observable = Observable<int>(0)..on(observed.add);

      observable
        ..dispose()
        ..value = 3;

      expect(observed, isEmpty);
    });

    test('descarte é idempotente', () {
      final observable = Observable<int>(0);

      expect(observable.dispose, returnsNormally);
    });

    test('removeListener cancela o token correspondente', () {
      final observed = <int>[];
      final observable = Observable<int>(0);
      final token = observable.on(observed.add);

      observable.removeListener(token);
      observable.value = 2;

      expect(token.isActive, isFalse);
      expect(observed, isEmpty);
    });

    test('extensao .bind e helper bindOf criam Observables reativos', () {
      final obsInt = 10.bind;
      expect(obsInt, isA<Observable<int>>());
      expect(obsInt.value, 10);
      final obsString = 'teste'.bind;
      expect(obsString.value, 'teste');
      final obsNullable = bindOf<String>();
      expect(obsNullable, isA<Observable<String?>>());
      expect(obsNullable.value, isNull);
      final obsInitial = bindOf<int>(42);
      expect(obsInitial.value, 42);
    });
  });
}
