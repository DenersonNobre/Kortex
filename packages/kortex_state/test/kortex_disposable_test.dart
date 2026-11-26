import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

import 'support/controller_lifecycle.dart';

/// Descartável de teste que registra cada chamada a `dispose()`.
class _Probe implements IKortexDisposable {
  _Probe(this.name, this.log);

  final String name;
  final List<String> log;
  var disposeCount = 0;

  @override
  void dispose() {
    disposeCount++;
    log.add(name);
  }
}

/// Controller de teste que registra a ordem entre `onDispose()` e o bag.
class _RecordingController extends IKortexController {
  _RecordingController(this.log);

  final List<String> log;

  @override
  void onDispose() => log.add('onDispose');

  void track(IKortexDisposable item) => autoDispose(item);
}

void main() {
  group('KortexDisposeBag', () {
    test('descarta em ordem reversa (LIFO) e marca isDisposed', () {
      final log = <String>[];
      final bag = KortexDisposeBag()
        ..add(_Probe('a', log))
        ..add(_Probe('b', log))
        ..add(_Probe('c', log));

      expect(bag.isDisposed, isFalse);
      bag.dispose();

      expect(log, ['c', 'b', 'a']);
      expect(bag.isDisposed, isTrue);
    });

    test('dispose é idempotente', () {
      final log = <String>[];
      final probe = _Probe('a', log);
      final bag = KortexDisposeBag()..add(probe);

      bag.dispose();
      bag.dispose();

      expect(probe.disposeCount, 1);
      expect(bag.isDisposed, isTrue);
    });

    test('item adicionado após dispose é descartado imediatamente', () {
      final log = <String>[];
      final bag = KortexDisposeBag()..dispose();
      final probe = _Probe('tardio', log);

      final same = bag.add(probe);

      expect(identical(same, probe), isTrue);
      expect(probe.disposeCount, 1);
      expect(log, ['tardio']);
    });

    test('callbacks executam no dispose e imediatamente se já descartado', () {
      final log = <String>[];
      final bag = KortexDisposeBag();
      bag.addCallback(() => log.add('callback'));

      expect(log, isEmpty);
      bag.dispose();
      expect(log, ['callback']);

      bag.addCallback(() => log.add('tardio'));
      expect(log, ['callback', 'tardio']);
    });

    test(
      'executa todos os callbacks mesmo quando um lança e preserva o erro',
      () {
        final log = <String>[];
        final bag = KortexDisposeBag()
          ..addCallback(() => log.add('first'))
          ..addCallback(() => throw StateError('boom'))
          ..addCallback(() => log.add('last'));

        expect(() => bag.dispose(), throwsStateError);
        expect(log, ['last', 'first']);
        expect(bag.isDisposed, isTrue);

        // Segunda chamada é idempotente e não reexecuta callbacks.
        bag.dispose();
        expect(log, ['last', 'first']);
      },
    );
  });

  group('IKortexController', () {
    test('dispose chama onDispose antes do bag e descarta em LIFO', () {
      final log = <String>[];
      final controller = track(_RecordingController(log));
      controller
        ..track(_Probe('a', log))
        ..track(_Probe('b', log));

      expect(controller.isDisposed, isFalse);
      controller.dispose();

      expect(log, ['onDispose', 'b', 'a']);
      expect(controller.isDisposed, isTrue);
    });

    test('dispose repetido não reexecuta onDispose', () {
      final log = <String>[];
      final controller = track(_RecordingController(log))..dispose();

      controller.dispose();

      expect(log, ['onDispose']);
    });
  });
}
