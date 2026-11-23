import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

void main() {
  group('KortexSet', () {
    test('leitura rastreia e readonly bloqueia mutação externa', () {
      final set = kortexSet<int>([1, 2]);
      final probe = _Probe();

      final snapshot = KortexTracker.runWithObserver(
        probe,
        () => set.readonly.value,
      );
      probe.reads = 0;

      expect(snapshot, {1, 2});
      expect(() => snapshot.add(3), throwsUnsupportedError);

      expect(set.add(3), isTrue);
      expect(probe.reads, 1);
      expect(set.contains(3), isTrue);
      expect(set.length, 3);
    });

    test(
      'no-op em add repetido, remove ausente e clear vazio não notifica',
      () {
        final set = KortexSet<int>([1, 2]);
        final probe = _Probe();
        KortexTracker.runWithObserver(probe, () => set.length);
        probe.reads = 0;

        expect(set.add(1), isFalse);
        expect(set.remove(99), isFalse);
        expect(probe.reads, 0);

        set.clear();
        expect(probe.reads, 1);

        set.clear();
        expect(probe.reads, 1);
      },
    );

    test('addAll e replaceAll consolidam em 1 notificação', () {
      final set = KortexSet<int>([1]);
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => set.value);
      probe.reads = 0;

      set.addAll([2, 3, 4]);
      expect(probe.reads, 1);
      expect(set.peek(), {1, 2, 3, 4});

      set.replaceAll([1, 2, 3, 4]);
      expect(probe.reads, 1);

      set.replaceAll([10, 20]);
      expect(probe.reads, 2);
      expect(set.peek(), {10, 20});
    });

    test('acesso após dispose lança StateError', () {
      final set = KortexSet<int>([1, 2]);
      set.dispose();

      expect(set.isDisposed, isTrue);
      expect(() => set.value, throwsStateError);
      expect(() => set.peek(), throwsStateError);
      expect(() => set.add(3), throwsStateError);
      expect(() => set.clear(), throwsStateError);
    });

    test('extensão .kortexSet cria KortexSet a partir de Set', () {
      final set = {1, 2}.kortexSet;
      final IKortexSet<int> readonly = set.readonly;

      expect(set, isA<KortexSet<int>>());
      expect(readonly.value, {1, 2});

      set.dispose();
    });
  });
}
