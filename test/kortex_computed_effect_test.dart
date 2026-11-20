import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

/// Observador de teste que conta notificações (zera após assinar).
class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

void main() {
  group('KortexComputed', () {
    test('é lazy: sem leitor, marca dirty sem recomputar até ler', () {
      final source = KortexSignal(1);
      var runs = 0;
      final doubled = KortexComputed(() {
        runs++;
        return source.value * 2;
      });

      expect(runs, 0);

      source.value = 2;
      expect(runs, 0);

      expect(doubled.value, 4);
      expect(runs, 1);
    });

    test('usa cache entre leituras sem mudança', () {
      final source = KortexSignal(1);
      var runs = 0;
      final doubled = KortexComputed(() {
        runs++;
        return source.value * 2;
      });

      expect(doubled.value, 2);
      expect(doubled.value, 2);
      expect(runs, 1);
    });

    test('só notifica quando o derivado muda (equals)', () {
      final source = KortexSignal(5);
      final tens = KortexComputed(() => source.value ~/ 10);
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => tens.value);
      probe.reads = 0;

      source.value = 9;
      expect(probe.reads, 0);

      source.value = 15;
      expect(probe.reads, 1);
      expect(tens.value, 1);
    });

    test('invalidação em cascata recalcula uma vez por leitura', () {
      final source = KortexSignal(1);
      var runs1 = 0;
      var runs2 = 0;
      final step1 = KortexComputed(() {
        runs1++;
        return source.value * 2;
      });
      final step2 = KortexComputed(() {
        runs2++;
        return step1.value + 1;
      });

      expect(step2.value, 3);

      source.value = 2;
      expect(step2.value, 5);
      expect(runs1, 2);
      expect(runs2, 2);
    });

    test('peek computa sem assinar o leitor', () {
      final source = KortexSignal(1);
      final probe = _Probe();
      final doubled = KortexComputed(() => source.value * 2);
      KortexTracker.runWithObserver(probe, () => doubled.peek());
      probe.reads = 0;

      source.value = 2;

      expect(probe.reads, 0);
      expect(doubled.peek(), 4);
    });

    test('leitura após dispose lança StateError', () {
      final doubled = KortexComputed(() => 1)..dispose();

      expect(doubled.isDisposed, isTrue);
      expect(() => doubled.value, throwsStateError);
      expect(() => doubled.peek(), throwsStateError);
    });
  });

  group('KortexEffect', () {
    test('executa na criação e reexecuta na mudança', () {
      final source = KortexSignal(1);
      var runs = 0;
      KortexEffect((_) {
        source.value;
        runs++;
      });

      expect(runs, 1);

      source.value = 2;
      expect(runs, 2);
    });

    test('executa onCleanup anterior antes de reexecutar', () {
      final source = KortexSignal(1);
      final log = <String>[];
      KortexEffect((onCleanup) {
        source.value;
        log.add('run');
        onCleanup(() => log.add('cleanup'));
      });

      source.value = 2;

      expect(log, ['run', 'cleanup', 'run']);
    });

    test('ignora autoescrita síncrona do próprio sinal', () {
      final counter = KortexSignal(0);
      var runs = 0;
      KortexEffect((_) {
        runs++;
        counter.value = counter.value + 1;
      });

      expect(runs, 1);
      expect(counter.value, 1);
    });

    test('dispose executa cleanup e para de reagir', () {
      final source = KortexSignal(1);
      final log = <String>[];
      final effect = KortexEffect((onCleanup) {
        source.value;
        log.add('run');
        onCleanup(() => log.add('cleanup'));
      });

      effect.dispose();

      source.value = 2;

      expect(log, ['run', 'cleanup']);
    });

    test('debounce consolida mudanças rápidas em 1 reexecução', () async {
      final source = KortexSignal(1);
      var runs = 0;
      KortexEffect((_) {
        source.value;
        runs++;
      }, debounce: const Duration(milliseconds: 20));

      source.value = 2;
      source.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(runs, 2);
    });

    test('dispose cancela debounce pendente', () async {
      final source = KortexSignal(1);
      var runs = 0;
      final effect = KortexEffect((_) {
        source.value;
        runs++;
      }, debounce: const Duration(milliseconds: 30));

      source.value = 2;
      effect.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(runs, 1);
    });
  });
}
