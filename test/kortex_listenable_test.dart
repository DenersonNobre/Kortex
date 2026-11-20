import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';
import 'package:kortex/src/widgets/widgets.dart';

/// Observador de teste que conta notificações (zera após assinar).
class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

/// `ChangeNotifier` simples para a ponte genérica.
class _Counter extends ChangeNotifier {
  var value = 0;

  void bump() {
    value++;
    notifyListeners();
  }
}

void main() {
  group('KortexListenableSignal', () {
    testWidgets('ValueNotifier vira sinal reativo', (tester) async {
      final notifier = ValueNotifier<String>('a');
      final signal = notifier.toKortexSignal();
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => signal.value);
      probe.reads = 0;

      notifier.value = 'b';
      await tester.pump();

      expect(probe.reads, 1);
      expect(signal.value, 'b');
      signal.dispose();
      notifier.dispose();
    });

    testWidgets('TextEditingController: dispose preserva o dono', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'a');
      final signal = controller.toKortexSignal();
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => signal.value);
      probe.reads = 0;

      controller.text = 'b';
      await tester.pump();

      expect(probe.reads, 1);
      expect(signal.value.text, 'b');

      signal.dispose();

      controller.text = 'c';
      await tester.pump();

      expect(controller.text, 'c');
      expect(probe.reads, 1);
      controller.dispose();
    });

    testWidgets('Listenable genérico via toKortexSignalWith', (tester) async {
      final counter = _Counter();
      final signal = counter.toKortexSignalWith(() => counter.value);
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => signal.value);
      probe.reads = 0;

      counter.bump();
      await tester.pump();

      expect(probe.reads, 1);
      expect(signal.value, 1);
      signal.dispose();
      counter.dispose();
    });
  });

  group('KortexSignalListenable', () {
    test('espelha mudanças e para ao remover listener', () async {
      final signal = KortexSignal(1);
      final listenable = signal.toListenable();
      var calls = 0;
      void onChange() => calls++;

      listenable.addListener(onChange);
      signal.value = 2;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, 1);

      listenable.removeListener(onChange);
      signal.value = 3;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, 1);
      listenable.dispose();
    });

    test('addListener após dispose lança StateError', () {
      final signal = KortexSignal(1);
      final listenable = signal.toListenable()..dispose();

      expect(() => listenable.addListener(() {}), throwsStateError);
    });
  });
}
