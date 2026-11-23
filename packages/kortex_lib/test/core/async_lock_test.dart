import 'dart:async';

import 'package:kortex_lib/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncLock', () {
    test(
      'serializa ações: a segunda só inicia após a primeira terminar',
      () async {
        final lock = AsyncLock();
        final log = <String>[];
        final gate = Completer<void>();

        final f1 = lock.run(() async {
          log.add('a:in');
          await gate.future;
          log.add('a:out');
          return 1;
        });
        final f2 = lock.run(() async {
          log.add('b:in');
          log.add('b:out');
          return 2;
        });

        await Future<void>.delayed(Duration.zero);
        expect(log, ['a:in']);

        gate.complete();
        final results = await Future.wait([f1, f2]);

        expect(log, ['a:in', 'a:out', 'b:in', 'b:out']);
        expect(results, [1, 2]);
      },
    );

    test('exceção numa ação não bloqueia as seguintes', () async {
      final lock = AsyncLock();
      final log = <String>[];

      final f1 = lock.run<void>(() async {
        log.add('a');
        throw StateError('boom');
      });
      final f2 = lock.run<void>(() async {
        log.add('b');
      });

      await expectLater(f1, throwsA(isA<StateError>()));
      await f2;

      expect(log, ['a', 'b']);
    });

    test('ação única devolve o valor e libera o lock', () async {
      final lock = AsyncLock();
      final value = await lock.run(() async => 42);
      expect(value, 42);

      final prox = await lock.run(() async => 'ok');
      expect(prox, 'ok');
    });
  });
}
