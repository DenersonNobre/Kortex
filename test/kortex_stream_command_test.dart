import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

void main() {
  group('KortexStreamResource', () {
    test('emite valores do stream como Data', () async {
      final controller = StreamController<String>();
      final resource = KortexStreamResource<String>(
        () => controller.stream,
        immediate: false,
      );

      resource.restart();
      expect(resource.state.value.isLoading, isTrue);

      controller.add('a');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(resource.state.value.valueOrNull, 'a');
      resource.dispose();
      await controller.close();
    });

    test('restart recaptura com previousValue e cancela anterior', () async {
      final first = StreamController<String>();
      final second = StreamController<String>();
      var calls = 0;
      final resource = KortexStreamResource<String>(
        () => ++calls == 1 ? first.stream : second.stream,
        immediate: false,
      );

      resource.restart();
      first.add('a');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(resource.state.value.valueOrNull, 'a');

      resource.restart();
      expect(first.hasListener, isFalse);

      final loading = resource.state.value;
      expect(loading.isRefreshing, isTrue);
      expect(loading.valueOrNull, 'a');

      second.add('b');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(resource.state.value.valueOrNull, 'b');

      resource.dispose();
      await first.close();
      await second.close();
    });

    test('dispose cancela a assinatura automaticamente', () async {
      final controller = StreamController<String>();
      final resource = KortexStreamResource<String>(
        () => controller.stream,
      );

      resource.dispose();

      expect(resource.isDisposed, isTrue);
      expect(controller.hasListener, isFalse);
      expect(() => resource.restart(), throwsStateError);
      await controller.close();
    });

    test('fábrica que lança publica erro', () {
      final resource = KortexStreamResource<String>(
        () => throw StateError('sem stream'),
        immediate: false,
      );

      resource.restart();

      expect(resource.state.value, isA<KortexAsyncError<String>>());
      resource.dispose();
    });

    test('erro do stream publica KortexAsyncError', () async {
      final controller = StreamController<String>();
      final resource = KortexStreamResource<String>(
        () => controller.stream,
        immediate: false,
      );

      resource.restart();
      controller.addError(StateError('falha'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(resource.state.value, isA<KortexAsyncError<String>>());
      resource.dispose();
      await controller.close();
    });
  });

  group('toStream', () {
    test('emite mudanças e para ao cancelar', () async {
      final signal = KortexSignal(1);
      final received = <int>[];
      final subscription = signal.toStream().listen(received.add);

      signal.value = 2;
      signal.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, [2, 3]);

      await subscription.cancel();
      signal.value = 99;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(received, [2, 3]);
    });
  });

  group('KortexCommand', () {
    test('executa, publica Data e alterna isExecuting', () async {
      final command = KortexCommand<String, int>(
        (_) => Future.value(42),
      );

      expect(command.isExecuting.value, isFalse);
      expect(command.state.value, isNull);

      final result = command.execute('p');
      expect(command.isExecuting.value, isTrue);

      expect(await result, 42);
      expect(command.isExecuting.value, isFalse);
      expect(command.state.value, isA<KortexAsyncData<int>>());
      command.dispose();
    });

    test('execute concorrente retorna null sem duplicar', () async {
      final gate = Completer<int>();
      var calls = 0;
      final command = KortexCommand<String, int>((_) {
        calls++;
        return gate.future;
      });

      final first = command.execute('a');
      expect(command.isExecuting.value, isTrue);

      expect(await command.execute('b'), isNull);
      expect(calls, 1);

      gate.complete(7);
      expect(await first, 7);
      expect(command.isExecuting.value, isFalse);
      command.dispose();
    });

    test('falha da ação publica erro e libera a trava', () async {
      final command = KortexCommand<String, int>(
        (_) => Future<int>.error(StateError('boom')),
      );

      expect(await command.execute('a'), isNull);
      expect(command.isExecuting.value, isFalse);
      expect(command.state.value, isA<KortexAsyncError<int>>());
      command.dispose();
    });

    test('dispose em voo descarta conclusão; execute lança StateError',
        () async {
      final gate = Completer<int>();
      final command = KortexCommand<String, int>((_) => gate.future);

      final inFlight = command.execute('a');
      command.dispose();
      gate.complete(7);
      await inFlight;

      expect(command.isDisposed, isTrue);
      expect(() => command.execute('b'), throwsStateError);
      expect(() => command.state.value, throwsStateError);
    });
  });
}
