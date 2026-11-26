import 'package:fake_async/fake_async.dart';
import 'package:kortex_core/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Debouncer', () {
    test('chamadas seguidas entregam só a última payload no fim da janela', () {
      final calls = <String>[];
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 100),
        callback: calls.add,
      );

      fakeAsync((async) {
        debouncer.call('primeira');
        debouncer.call('segunda');
        debouncer.call('ultima');
        expect(calls, isEmpty);
        async.elapse(const Duration(milliseconds: 100));
        expect(calls, ['ultima']);
        async.elapse(const Duration(milliseconds: 300));
        expect(calls, ['ultima']);
      });
    });

    test('chamada dentro da janela reseta o timer (payload do último)', () {
      final calls = <String>[];
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 100),
        callback: calls.add,
      );

      fakeAsync((async) {
        debouncer.call('a');
        async.elapse(const Duration(milliseconds: 99));
        debouncer.call('b');
        async.elapse(const Duration(milliseconds: 1));
        expect(calls, isEmpty);
        async.elapse(const Duration(milliseconds: 99));
        expect(calls, ['b']);
      });
    });

    test('cancel() descarta a execução pendente', () {
      final calls = <String>[];
      final debouncer = Debouncer<String>(
        duration: const Duration(milliseconds: 100),
        callback: calls.add,
      );

      fakeAsync((async) {
        debouncer.call('a');
        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 200));
        expect(calls, isEmpty);
        debouncer.call('b');
        async.elapse(const Duration(milliseconds: 100));
        expect(calls, ['b']);
      });
    });
  });
}
