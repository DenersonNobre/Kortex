import 'package:flutter_test/flutter_test.dart';
import 'package:kortex/src/reactive/reactive.dart';

class _Probe implements IKortexObserver {
  var reads = 0;

  @override
  void onRead(IKortexReactiveNode node) => reads++;
}

void main() {
  group('KortexList (UC-09.01)', () {
    test(
      'leitura via value/length/[] rastreia e readonly bloqueia mutação',
      () {
        final list = kortexList<int>([1, 2]);
        final probe = _Probe();

        final snapshot = KortexTracker.runWithObserver(
          probe,
          () => list.readonly.value,
        );
        probe.reads = 0;

        expect(snapshot, [1, 2]);
        expect(() => snapshot.add(3), throwsUnsupportedError);

        list.add(3);
        expect(probe.reads, 1);
        expect(list.length, 3);
        expect(list[2], 3);
      },
    );

    test(
      'no-op em remove ausente, clear vazio e mesmo índice não notifica',
      () {
        final list = KortexList<int>([1, 2]);
        final probe = _Probe();
        KortexTracker.runWithObserver(probe, () => list.length);
        probe.reads = 0;

        expect(list.remove(99), isFalse);
        list[0] = 1;
        expect(probe.reads, 0);

        list.clear();
        expect(probe.reads, 1);

        list.clear();
        expect(probe.reads, 1);
      },
    );

    test('addAll e replaceAll consolidam em 1 notificação', () {
      final list = KortexList<int>([1]);
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => list.value);
      probe.reads = 0;

      list.addAll([2, 3, 4]);
      expect(probe.reads, 1);
      expect(list.peek(), [1, 2, 3, 4]);

      list.replaceAll([1, 2, 3, 4]);
      expect(probe.reads, 1);

      list.replaceAll([10, 20]);
      expect(probe.reads, 2);
      expect(list.peek(), [10, 20]);
    });

    test('acesso após dispose lança StateError', () {
      final list = KortexList<int>([1, 2]);
      list.dispose();

      expect(list.isDisposed, isTrue);
      expect(() => list.value, throwsStateError);
      expect(() => list.peek(), throwsStateError);
      expect(() => list.add(3), throwsStateError);
      expect(() => list.clear(), throwsStateError);
    });
  });

  group('KortexMap (UC-09.02)', () {
    test('leitura rastreia e readonly bloqueia mutação externa', () {
      final map = kortexMap<String, int>({'a': 1});
      final probe = _Probe();

      final snapshot = KortexTracker.runWithObserver(
        probe,
        () => map.readonly.value,
      );
      probe.reads = 0;

      expect(snapshot, {'a': 1});
      expect(() => snapshot['b'] = 2, throwsUnsupportedError);

      map['b'] = 2;
      expect(probe.reads, 1);
      expect(map['b'], 2);
      expect(map.containsKey('a'), isTrue);
    });

    test('no-op em mesmo valor, remove ausente e clear vazio não notifica', () {
      final map = KortexMap<String, int>({'a': 1});
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => map.length);
      probe.reads = 0;

      map['a'] = 1;
      expect(map.remove('z'), isNull);
      expect(probe.reads, 0);

      map.clear();
      expect(probe.reads, 1);

      map.clear();
      expect(probe.reads, 1);
    });

    test('addAll e replaceAll consolidam em 1 notificação', () {
      final map = KortexMap<String, int>();
      final probe = _Probe();
      KortexTracker.runWithObserver(probe, () => map.value);
      probe.reads = 0;

      map.addAll({'a': 1, 'b': 2});
      expect(probe.reads, 1);

      map.replaceAll({'a': 1, 'b': 2});
      expect(probe.reads, 1);

      map.replaceAll({'c': 3});
      expect(probe.reads, 2);
      expect(map.peek(), {'c': 3});
    });

    test('acesso após dispose lança StateError', () {
      final map = KortexMap<String, int>({'a': 1});
      map.dispose();

      expect(map.isDisposed, isTrue);
      expect(() => map.value, throwsStateError);
      expect(() => map.peek(), throwsStateError);
      expect(() => map['a'] = 2, throwsStateError);
      expect(() => map.clear(), throwsStateError);
    });

    test('extensões .kortexList e .kortexMap criam coleções reativas', () {
      final list = [1, 2].kortexList;
      final map = {'a': 1}.kortexMap;
      final listSignal = [1, 2].kortex;

      expect(list, isA<KortexList<int>>());
      expect(map, isA<KortexMap<String, int>>());
      expect(listSignal, isA<KortexSignal<List<int>>>());

      list.add(3);
      map['b'] = 2;
      expect(list.peek(), [1, 2, 3]);
      expect(map.peek(), {'a': 1, 'b': 2});

      list.dispose();
      map.dispose();
      listSignal.dispose();
    });
  });
}
