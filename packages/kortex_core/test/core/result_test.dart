import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('IResult', () {
    test('success guarda o valor e encadeia helpers', () {
      final result = Success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.getOrNull(), 42);
      expect(result.getOrElse((_) => -1), 42);
      expect(result.mapSuccess((value) => value * 2).getOrNull(), 84);
      expect(
        result.mapFailure((failure) => failure).getOrNullFailure(),
        isNull,
      );
    });

    test('failure guarda a falha e transforma com helpers', () {
      const failure = ValidationFailure('Valor inválido', 'quantidade');
      final result = Failure(failure);

      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.getOrNull(), isNull);
      expect(result.getOrNullFailure(), same(failure));
      expect(result.getOrElse((_) => 99), 99);
      expect(
        result
            .mapFailure((_) => const NotFoundFailure('Sumiu'))
            .getOrNullFailure()
            ?.code,
        'NOT_FOUND',
      );
      expect(result.getOrThrow, throwsA(isA<StateError>()));
    });

    test('fold nomeado resolve os dois ramos', () {
      const ok = Success(1);
      const erro = Failure('x');

      expect(ok.fold(onSuccess: (v) => v, onFailure: (_) => -1), 1);
      expect(erro.fold(onSuccess: (_) => -1, onFailure: (f) => f), 'x');
    });

    test('switch exaustivo dispensa isSuccess/isFailure', () {
      const IResult<int, String> result = Success(7);

      final value = switch (result) {
        Success(value: final v) => v,
        Failure() => -1,
      };

      expect(value, 7);
    });
  });

  group('IFailure', () {
    test('expoe code, message, details/cause e toMap deterministico', () {
      const failure = ValidationFailure('Campo obrigatorio', 'email');

      expect(failure.code, equals('VALIDATION_ERROR'));
      expect(failure.cause, equals('email'));
      expect(failure.details, equals('email'));
      expect(
        failure.toMap(),
        equals({
          'code': 'VALIDATION_ERROR',
          'message': 'Campo obrigatorio',
          'details': 'email',
        }),
      );
      expect(failure.toMap(), equals(failure.toMap()));
    });

    test('toString carrega o code para o log', () {
      const failure = NotFoundFailure('Usuario nao encontrado');

      expect(failure.toString(), contains('NOT_FOUND'));
      expect(failure.toString(), contains('Usuario nao encontrado'));
    });

    test('é Exception e pode ser lançada', () {
      expect(const ValidationFailure('x'), isA<Exception>());
      expect(
        () => throw const ValidationFailure('x'),
        throwsA(isA<IFailure>()),
      );
    });
  });
}
