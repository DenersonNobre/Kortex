import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

/// Observador de teste que conta notificações.
class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

/// Assina [probe] em [signal] com uma leitura rastreada.
///
/// A leitura de assinatura não conta como notificação (zera o contador).
void _subscribe(_Probe probe, IKortexReadonlySignal<int> signal) {
  KortexTracker.runWithObserver(probe, () => signal.value);
  probe.reads = 0;
}

void main() {
  group('KortexSignal', () {
    test('atribuir o mesmo valor não notifica (equals padrão)', () {
      final signal = KortexSignal(10);
      final probe = _Probe();
      _subscribe(probe, signal);

      signal.value = 10;

      expect(probe.reads, 0);
      expect(signal.value, 10);
    });

    test('equals customizado suprime notificação', () {
      final signal = KortexSignal(
        'Ola',
        equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
      );
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => signal.value);
      probe.reads = 0;

      signal.value = 'OLA';
      expect(probe.reads, 0);

      signal.value = 'Adeus';
      expect(probe.reads, 1);
      expect(signal.value, 'Adeus');
    });

    test('kortexBatch consolida 2 escritas em 1 notificação com valor final',
        () {
      final signal = KortexSignal(10);
      final probe = _Probe();
      _subscribe(probe, signal);

      kortexBatch(() {
        signal.value = 20;
        signal.value = 30;
      });

      expect(probe.reads, 1);
      expect(signal.value, 30);
    });

    test('exceção no batch descarrega fila e restaura profundidade', () {
      final signal = KortexSignal(10);
      final probe = _Probe();
      _subscribe(probe, signal);

      expect(
        () => kortexBatch(() {
          signal.value = 20;
          kortexBatch(() {
            signal.value = 30;
            throw StateError('falha');
          });
        }),
        throwsStateError,
      );

      expect(probe.reads, 1);
      expect(signal.value, 30);

      signal.value = 40;
      expect(probe.reads, 2);
    });

    test('update aplica e notifica uma vez', () {
      final signal = KortexSignal(10);
      final probe = _Probe();
      _subscribe(probe, signal);

      signal.update((current) => current + 5);

      expect(signal.value, 15);
      expect(probe.reads, 1);
    });

    test('peek e kortexUntracked não assinam', () {
      final signal = KortexSignal(10);
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () {
        signal.peek();
        kortexUntracked(() => signal.value);
      });

      signal.value = 99;

      expect(probe.reads, 0);
      expect(signal.peek(), 99);
    });

    test('leitura e escrita após dispose lançam StateError', () {
      final signal = KortexSignal(10)..dispose();

      expect(signal.isDisposed, isTrue);
      expect(() => signal.value, throwsStateError);
      expect(() => signal.peek(), throwsStateError);
      expect(() => signal.value = 99, throwsStateError);
      expect(() => signal.update((c) => c + 1), throwsStateError);
    });

    test('readonly reflete valor sem expor escrita', () {
      final signal = KortexSignal(10);
      final IKortexReadonlySignal<int> view = signal.readonly;

      signal.value = 42;

      expect(view.value, 42);
      expect(view.peek(), 42);
      expect(view.isDisposed, isFalse);
    });
  });
}
