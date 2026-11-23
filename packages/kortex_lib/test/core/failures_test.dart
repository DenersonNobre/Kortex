import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/kortex_lib.dart';

void main() {
  group('IFailures | Unit Tests', () {
    test('FailureCode centraliza constantes nominais sem strings magicas', () {
      expect(FailureCode.validation, equals('VALIDATION_ERROR'));
      expect(FailureCode.notFound, equals('NOT_FOUND'));
      expect(FailureCode.unauthorized, equals('UNAUTHORIZED'));
      expect(FailureCode.conflict, equals('CONFLICT'));
      expect(FailureCode.infrastructure, equals('INFRASTRUCTURE_ERROR'));
      expect(FailureCode.unexpected, equals('UNEXPECTED_ERROR'));
    });

    test('ValidationFailure contem codigo e detalhes opcionais', () {
      const failure = ValidationFailure('Campo obrigatorio', 'email');
      expect(failure.code, equals(FailureCode.validation));
      expect(failure.message, equals('Campo obrigatorio'));
      expect(failure.cause, equals('email'));
      expect(failure.details, equals('email'));
      expect(failure.toString(), contains('VALIDATION_ERROR'));
      expect(failure.toString(), contains('Campo obrigatorio'));
    });

    test('NotFoundFailure identifica entidade ausente', () {
      const failure = NotFoundFailure('Usuario nao encontrado');
      expect(failure.code, equals(FailureCode.notFound));
      expect(failure, isA<IFailure>());
    });

    test('UnauthorizedFailure identifica falha de credenciais', () {
      const failure = UnauthorizedFailure('Token expirado');
      expect(failure.code, equals(FailureCode.unauthorized));
      expect(failure, isA<IFailure>());
    });

    test('ConflictFailure identifica conflito de estado', () {
      const failure = ConflictFailure('Email ja cadastrado');
      expect(failure.code, equals(FailureCode.conflict));
      expect(failure, isA<IFailure>());
    });

    test('InfrastructureFailure mapeia erro de persistencia/rede', () {
      final failure = InfrastructureFailure(
        'Erro ao conectar',
        Exception('Socket closed'),
      );
      expect(failure.code, equals(FailureCode.infrastructure));
      expect(failure.cause, isA<Exception>());
      expect(failure, isA<IFailure>());
    });

    test(
      'UnexpectedFailure encapsula erro e stack trace sem strings magicas',
      () {
        final error = StateError('falha grave de runtime');
        final stack = StackTrace.current;
        final failure = UnexpectedFailure(error: error, stackTrace: stack);

        expect(failure.code, equals(FailureCode.unexpected));
        expect(failure.error, same(error));
        expect(failure.stackTrace, same(stack));
        expect(failure.cause, same(error));
        expect(failure.message, contains('falha grave de runtime'));

        final map = failure.toMap();
        expect(map['code'], equals(FailureCode.unexpected));
        expect(map['error'], contains('falha grave de runtime'));
        expect(map['stackTrace'], isNotNull);
      },
    );

    test('IResult com IFailure permite fold semantico', () {
      final IResult<int, IFailure> resultado = Failure(
        const ValidationFailure('Quantidade deve ser > 0'),
      );

      final mensagem = resultado.fold(
        onSuccess: (data) => 'Sucesso: $data',
        onFailure: (fail) => switch (fail) {
          final ValidationFailure v => 'Validacao: ${v.message}',
          final NotFoundFailure n => '404: ${n.message}',
          final UnexpectedFailure u => 'Inesperado: ${u.error}',
          _ => 'Erro generico: ${fail.message}',
        },
      );

      expect(mensagem, equals('Validacao: Quantidade deve ser > 0'));
    });
  });
}
