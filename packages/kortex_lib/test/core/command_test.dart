import 'dart:async';

import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Command', () {
    test('publica sucesso e encerra estado de execução', () async {
      final command = Command<int, String, int>(
        (param) async => Success(param! * 2),
        mapException: (_, _) => 'inesperado',
      );

      await command.run(21);

      expect(command.result.value?.getOrNull(), 42);
      expect(command.isExecuting.value, isFalse);
      command.dispose();
    });

    test('preserva falha esperada devolvida pela ação', () async {
      final command = Command<int, String, void>(
        (_) async => Failure('negado'),
        mapException: (_, _) => 'inesperado',
      );

      await command.run();

      expect(command.result.value?.getOrNullFailure(), 'negado');
      command.dispose();
    });

    test('mapeia exceção inesperada com stack trace', () async {
      StackTrace? recebido;
      final command = Command<int, String, void>(
        (_) async => throw StateError('quebrou'),
        mapException: (error, stackTrace) {
          recebido = stackTrace;
          return error.toString();
        },
      );

      await command.run();

      expect(command.result.value?.getOrNullFailure(), 'Bad state: quebrou');
      expect(recebido, isNotNull);
      command.dispose();
    });

    test('ignora execução enquanto outra está em andamento', () async {
      final completude = Completer<IResult<int, String>>();
      var chamadas = 0;
      final command = Command<int, String, int>((_) {
        chamadas++;
        return completude.future;
      }, mapException: (_, _) => 'inesperado');

      final primeira = command.run(1);
      await command.run(2);

      expect(chamadas, 1);
      expect(command.isExecuting.value, isTrue);
      completude.complete(Success(1));
      await primeira;
      expect(command.isExecuting.value, isFalse);
      command.dispose();
    });

    test('canExecute impede iniciar a ação', () async {
      var chamadas = 0;
      final command = Command<int, String, void>((_) async {
        chamadas++;
        return Success(1);
      }, mapException: (_, _) => 'inesperado')..canExecute.value = false;

      await command.run();

      expect(chamadas, 0);
      expect(command.result.value, isNull);
      command.dispose();
    });

    test('não permite uso após dispose', () async {
      final command = Command<int, String, void>(
        (_) async => Success(1),
        mapException: (_, _) => 'inesperado',
      );
      command.dispose();

      await expectLater(command.run(), throwsStateError);
    });

    test('notifica observador nas transições de estado', () async {
      final eventos = <bool>[];
      final command = Command<int, String, void>(
        (_) async => Success(1),
        mapException: (_, _) => 'inesperado',
      );
      command.isExecuting.on((_) => eventos.add(command.isExecuting.value));

      await command.run();

      expect(eventos, [true, false]);
      command.dispose();
    });

    test('limpa resultado anterior ao iniciar nova execução', () async {
      final command = Command<int, String, int>(
        (param) async => Success(param! * 2),
        mapException: (_, _) => 'inesperado',
      );

      await command.run(1);
      expect(command.result.value?.getOrNull(), 2);

      await command.run(2);
      expect(command.result.value?.getOrNull(), 4);
      command.dispose();
    });

    test('ignora resultado publicado após dispose', () async {
      final completude = Completer<IResult<int, String>>();
      final command = Command<int, String, void>(
        (_) => completude.future,
        mapException: (_, _) => 'inesperado',
      );

      final emCurso = command.run();
      command.dispose();
      completude.complete(Success(7));
      await emCurso;

      expect(command.result.value, isNull);
    });
  });

  group('NoParam', () {
    test('marca comandos sem parâmetro', () {
      expect(const NoParam(), isA<NoParam>());
    });
  });
}
